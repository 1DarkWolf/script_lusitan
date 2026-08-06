CJ = CJ or {}
CJ.Employees = CJ.Employees or {}

local function getGradeLevel(player)
    local grade = player and player.PlayerData.job and player.PlayerData.job.grade
    return type(grade) == 'table' and tonumber(grade.level) or tonumber(grade)
end

---@param source number
---@return string|nil, table|nil
function CJ.Employees.GetRole(source)
    local player = CJ.Framework.GetPlayer(source)
    local job = player and player.PlayerData.job

    if not job or job.name ~= Config.CompanyJob then
        return nil, nil
    end

    local gradeLevel = getGradeLevel(player)
    for key, role in pairs(Config.EmployeeRoles) do
        if role.grade == gradeLevel then
            return key, role
        end
    end

    return nil, nil
end

---@param source number
---@param permission string
---@return boolean
function CJ.Employees.HasPermission(source, permission)
    local _, role = CJ.Employees.GetRole(source)
    return role and role.permissions[permission] == true or false
end

---@param citizenId string
---@param roleKey string
---@param managerCitizenId? string
---@return boolean
local function saveEmployee(citizenId, roleKey, managerCitizenId)
    local company = CJ.Company.Get()
    if not company then
        return false
    end

    local result = MySQL.insert.await([[INSERT INTO `cj_company_employees` (`company_id`, `citizenid`, `grade`, `hired_by`)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE `grade` = VALUES(`grade`), `hired_by` = VALUES(`hired_by`)]], {
        company.id,
        citizenId,
        roleKey,
        managerCitizenId
    })

    return result ~= nil
end

---@param action string
---@param actorCitizenId string
---@param targetCitizenId string
---@param previousRole? string
---@param nextRole? string
local function audit(action, actorCitizenId, targetCitizenId, previousRole, nextRole)
    MySQL.insert.await([[INSERT INTO `cj_employee_audits` (`action`, `actor_citizenid`, `target_citizenid`, `previous_grade`, `new_grade`)
        VALUES (?, ?, ?, ?, ?)]], { action, actorCitizenId, targetCitizenId, previousRole, nextRole })
end

---@param source number
---@param targetSource number
---@param roleKey string
---@param action 'hire'|'promote'
local function assignRole(source, targetSource, roleKey, action)
    local role = Config.EmployeeRoles[roleKey]

    if type(targetSource) ~= 'number' or not role or source == targetSource then
        CJ.Security.Reject(source, 'cj:server:manageEmployee', 'dados inválidos')
        return
    end

    local target = CJ.Framework.GetPlayer(targetSource)
    if not target then
        CJ.Security.Reject(source, 'cj:server:manageEmployee', 'jogador não encontrado')
        return
    end

    local permission = action == 'hire' and 'hire' or 'promote'
    local _, actorRole = CJ.Employees.GetRole(source)
    local previousRoleKey, previousRole = CJ.Employees.GetRole(targetSource)

    if not CJ.Employees.HasPermission(source, permission) or not actorRole or role.grade >= actorRole.grade then
        CJ.Security.Reject(source, 'cj:server:manageEmployee', 'sem permissão para atribuir este cargo')
        return
    end

    if action == 'hire' and previousRole then
        CJ.Framework.Notify(source, 'Este jogador já pertence à empresa.', 'error')
        return
    end

    if action == 'promote' and (not previousRole or previousRole.grade >= actorRole.grade or role.grade <= previousRole.grade) then
        CJ.Security.Reject(source, 'cj:server:manageEmployee', 'promoção inválida')
        return
    end

    target.Functions.SetJob(Config.CompanyJob, role.grade)

    local actorCitizenId = CJ.Framework.GetCitizenId(source)
    local targetCitizenId = CJ.Framework.GetCitizenId(targetSource)
    if not saveEmployee(targetCitizenId, roleKey, actorCitizenId) then
        CJ.Log.Write('error', ('Não foi possível guardar o empregado %s.'):format(targetCitizenId))
    end

    audit(action, actorCitizenId, targetCitizenId, previousRoleKey, roleKey)
    CJ.Framework.Notify(source, ('%s ficou com o cargo %s.'):format(GetPlayerName(targetSource), role.label), 'success')
    CJ.Framework.Notify(targetSource, ('Foste colocado no cargo %s.'):format(role.label), 'success')
    CJ.Log.Discord('employees', 'Gestão de empregado', ('%s atribuiu o cargo %s a %s.'):format(GetPlayerName(source), role.label, GetPlayerName(targetSource)))
end

CJ.Security.RegisterEvent('cj:server:hireEmployee', function(source, targetSource, roleKey)
    assignRole(source, tonumber(targetSource), roleKey, 'hire')
end)

CJ.Security.RegisterEvent('cj:server:promoteEmployee', function(source, targetSource, roleKey)
    assignRole(source, tonumber(targetSource), roleKey, 'promote')
end)

CJ.Security.RegisterEvent('cj:server:fireEmployee', function(source, targetSource)
    targetSource = tonumber(targetSource)
    if type(targetSource) ~= 'number' then
        CJ.Security.Reject(source, 'cj:server:fireEmployee', 'dados inválidos')
        return
    end

    local target = CJ.Framework.GetPlayer(targetSource)
    local _, actorRole = CJ.Employees.GetRole(source)
    local previousRoleKey, previousRole = CJ.Employees.GetRole(targetSource)

    if not target or source == targetSource or not CJ.Employees.HasPermission(source, 'fire') or not actorRole or not previousRole or previousRole.grade >= actorRole.grade then
        CJ.Security.Reject(source, 'cj:server:fireEmployee', 'pedido inválido')
        return
    end

    target.Functions.SetJob(Config.UnemployedJob, Config.UnemployedGrade)
    MySQL.update.await('DELETE FROM `cj_company_employees` WHERE `citizenid` = ?', { CJ.Framework.GetCitizenId(targetSource) })

    local actorCitizenId = CJ.Framework.GetCitizenId(source)
    local targetCitizenId = CJ.Framework.GetCitizenId(targetSource)
    audit('fire', actorCitizenId, targetCitizenId, previousRoleKey, nil)
    CJ.Framework.Notify(source, ('%s foi despedido.'):format(GetPlayerName(targetSource)), 'success')
    CJ.Framework.Notify(targetSource, 'Foste despedido do Centro de Jogos.', 'error')
    CJ.Log.Discord('employees', 'Empregado despedido', ('%s despediu %s.'):format(GetPlayerName(source), GetPlayerName(targetSource)))
end)

exports('GetEmployeeRole', CJ.Employees.GetRole)
exports('HasEmployeePermission', CJ.Employees.HasPermission)
