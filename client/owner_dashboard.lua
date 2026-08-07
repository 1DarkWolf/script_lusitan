CJ = CJ or {}

local QBCore = exports['qb-core']:GetCoreObject()
local ownerPed

local function isOwner()
    local job = QBCore.Functions.GetPlayerData().job
    return job and job.name == Config.CompanyJob and job.isboss == true
end

local function openOwnerDashboard()
    if not isOwner() then
        CJ.Framework.Notify(CJ.T('general.no_permission'), 'error')
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openOwnerDashboard' })
end

local function openRestockMenu()
    if not isOwner() then return end

    local menu = {
        { header = 'Reabastecer raspadinhas', isMenuHeader = true }
    }

    for cardId, card in pairs(Config.ScratchCards) do
        menu[#menu + 1] = {
            header = card.label,
            txt = 'Entrega cartões em branco do teu inventário ao stock da loja.',
            icon = 'fas fa-boxes-stacked',
            params = { event = 'cj:client:requestScratchRestock', args = { cardId = cardId } }
        }
    end

    exports['qb-menu']:openMenu(menu)
end

RegisterNetEvent('cj:client:requestScratchRestock', function(data)
    local card = data and Config.ScratchCards[data.cardId]
    if not card then return end

    local response = exports['qb-input']:ShowInput({
        header = ('Reabastecer %s'):format(card.label),
        submitText = 'Adicionar ao stock',
        inputs = {
            { text = 'Quantidade de cartões em branco', name = 'amount', type = 'number', isRequired = true }
        }
    })

    if response and response.amount then
        TriggerServerEvent('cj:server:restockScratch', data.cardId, tonumber(response.amount))
    end
end)

CreateThread(function()
    local npc = Config.OwnerDashboard.Npc
    lib.requestModel(npc.model)
    ownerPed = CreatePed(0, joaat(npc.model), npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.coords.w, false, false)
    SetEntityInvincible(ownerPed, true)
    SetBlockingOfNonTemporaryEvents(ownerPed, true)
    FreezeEntityPosition(ownerPed, true)
    TaskStartScenarioInPlace(ownerPed, npc.scenario, 0, true)

    exports['qb-target']:AddTargetEntity(ownerPed, {
        options = {
            {
                icon = 'fas fa-chart-line',
                label = 'Dashboard da empresa',
                canInteract = isOwner,
                action = openOwnerDashboard
            },
            {
                icon = 'fas fa-boxes-stacked',
                label = 'Reabastecer raspadinhas',
                canInteract = isOwner,
                action = openRestockMenu
            }
        },
        distance = Config.OwnerDashboard.distance
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and DoesEntityExist(ownerPed) then
        DeleteEntity(ownerPed)
    end
end)
