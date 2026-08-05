CJ = CJ or {}
CJ.Company = CJ.Company or {}

local QBCore = exports['qb-core']:GetCoreObject()
local vendorPed

---@return boolean
function CJ.Company.IsOpen()
    local hour = GetClockHours()
    local openingHours = Config.Company.OpeningHours

    if openingHours.open < openingHours.close then
        return hour >= openingHours.open and hour < openingHours.close
    end

    return hour >= openingHours.open or hour < openingHours.close
end

local function notifyClosed()
    CJ.Framework.Notify(('O %s está fechado neste momento.'):format(Config.CompanyName), 'error')
end

local function canOpenBossMenu()
    local playerData = QBCore.Functions.GetPlayerData()
    return playerData.job and playerData.job.name == Config.CompanyJob and playerData.job.isboss == true
end

local function openBossMenu()
    if not canOpenBossMenu() then
        CJ.Framework.Notify(CJ.T('general.no_permission'), 'error')
        return
    end

    if GetResourceState('qb-management') ~= 'started' then
        CJ.Framework.Notify('O recurso qb-management não está disponível.', 'error')
        return
    end

    TriggerEvent('qb-bossmenu:client:OpenMenu')
end

local function openCompanyTerminal()
    if not CJ.Company.IsOpen() then
        notifyClosed()
        return
    end

    exports['qb-menu']:openMenu({
        {
            header = Config.CompanyName,
            isMenuHeader = true
        },
        {
            header = 'Jogos disponíveis',
            txt = 'A seleção de jogos será adicionada em breve.',
            disabled = true
        },
        {
            header = 'Fechar',
            params = { event = 'qb-menu:client:closeMenu' }
        }
    })
end

local function addTargets()
    if not Config.UseTarget then
        return
    end

    exports['qb-target']:AddTargetEntity(vendorPed, {
        options = {
            {
                icon = 'fas fa-ticket',
                label = ('Falar com %s'):format(Config.CompanyName),
                action = openCompanyTerminal
            }
        },
        distance = Config.Company.Counter.distance
    })

    if Config.Company.BossMenu.enabled then
        exports['qb-target']:AddBoxZone('cj_boss_menu', Config.Company.BossMenu.coords, 1.0, 1.0, {
            name = 'cj_boss_menu',
            heading = Config.Company.Npc.coords.w,
            debugPoly = Config.Debug,
            minZ = Config.Company.BossMenu.coords.z - 1.0,
            maxZ = Config.Company.BossMenu.coords.z + 1.0
        }, {
            options = {
                {
                    icon = 'fas fa-briefcase',
                    label = 'Gestão da empresa',
                    canInteract = canOpenBossMenu,
                    action = openBossMenu
                }
            },
            distance = Config.Company.BossMenu.distance
        })
    end
end

local function createBlip()
    if not Config.Company.Blip.enabled then
        return
    end

    local coords = Config.Company.Npc.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Company.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Company.Blip.scale)
    SetBlipColour(blip, Config.Company.Blip.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Company.Blip.label)
    EndTextCommandSetBlipName(blip)
end

CreateThread(function()
    local npc = Config.Company.Npc
    lib.requestModel(npc.model)

    vendorPed = CreatePed(0, joaat(npc.model), npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.coords.w, false, false)
    SetEntityInvincible(vendorPed, true)
    SetBlockingOfNonTemporaryEvents(vendorPed, true)
    FreezeEntityPosition(vendorPed, true)
    TaskStartScenarioInPlace(vendorPed, npc.scenario, 0, true)

    addTargets()
    createBlip()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and DoesEntityExist(vendorPed) then
        DeleteEntity(vendorPed)
    end
end)
