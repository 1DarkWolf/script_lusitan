CJ = CJ or {}

local QBCore = exports['qb-core']:GetCoreObject()

local function getLocalRole()
    local job = QBCore.Functions.GetPlayerData().job
    if not job or job.name ~= Config.CompanyJob then
        return nil
    end

    local level = type(job.grade) == 'table' and job.grade.level or job.grade
    for key, role in pairs(Config.EmployeeRoles) do
        if role.grade == tonumber(level) then
            return key, role
        end
    end
end

function CJ.EmployeesCanManage()
    local _, role = getLocalRole()
    return role and (role.permissions.hire or role.permissions.promote or role.permissions.fire) or false
end

local function requestTargetSource(title, eventName, roleKey)
    local response = exports['qb-input']:ShowInput({
        header = title,
        submitText = 'Confirmar',
        inputs = {
            {
                text = 'ID do jogador',
                name = 'target',
                type = 'number',
                isRequired = true
            }
        }
    })

    if response and response.target then
        TriggerServerEvent(eventName, response.target, roleKey)
    end
end

RegisterNetEvent('cj:client:openEmployeeMenu', function()
    if not CJ.EmployeesCanManage() then
        CJ.Framework.Notify(CJ.T('general.no_permission'), 'error')
        return
    end

    local menu = {
        { header = 'Gestão de empregados', isMenuHeader = true },
        {
            header = 'Contratar',
            icon = 'fas fa-user-plus',
            params = { event = 'cj:client:selectEmployeeRole', args = { action = 'hire' } }
        },
        {
            header = 'Promover',
            icon = 'fas fa-arrow-up',
            params = { event = 'cj:client:selectEmployeeRole', args = { action = 'promote' } }
        },
        {
            header = 'Despedir',
            icon = 'fas fa-user-minus',
            params = { event = 'cj:client:requestEmployeeFire' }
        }
    }

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('cj:client:selectEmployeeRole', function(data)
    local menu = {
        { header = data.action == 'hire' and 'Selecionar cargo para contratação' or 'Selecionar novo cargo', isMenuHeader = true }
    }

    for key, role in pairs(Config.EmployeeRoles) do
        menu[#menu + 1] = {
            header = role.label,
            txt = ('Cargo %d'):format(role.grade),
            params = {
                event = 'cj:client:requestEmployeeAssignment',
                args = { action = data.action, roleKey = key }
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('cj:client:requestEmployeeAssignment', function(data)
    local title = data.action == 'hire' and 'Contratar empregado' or 'Promover empregado'
    local eventName = data.action == 'hire' and 'cj:server:hireEmployee' or 'cj:server:promoteEmployee'
    requestTargetSource(title, eventName, data.roleKey)
end)

RegisterNetEvent('cj:client:requestEmployeeFire', function()
    requestTargetSource('Despedir empregado', 'cj:server:fireEmployee')
end)
