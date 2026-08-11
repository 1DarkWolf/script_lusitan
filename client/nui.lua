CJ = CJ or {}

local dashboardOpen = false

CreateThread(function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAll' })
end)

RegisterNetEvent('cj:client:openDashboard', function()
    dashboardOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openDashboard' })
end)

RegisterNUICallback('loadDashboard', function(data, callback)
    if data.section == 'tickets' then callback(CJ.Callbacks.Await('cj:server:getPlayerTickets'))
    elseif data.section == 'results' then callback(CJ.Callbacks.Await('cj:server:getRecentResults'))
    elseif data.section == 'profile' then callback(CJ.Callbacks.Await('cj:server:getLoyaltyProfile'))
    elseif data.section == 'ranking' then callback(CJ.Callbacks.Await('cj:server:getLoyaltyRanking'))
    elseif data.section == 'company' then callback(CJ.Callbacks.Await('cj:server:getCompanyDashboard'))
    else callback({}) end
end)

RegisterNUICallback('buyGame', function(data, callback)
    SetNuiFocus(false, false)
    dashboardOpen = false
    SendNUIMessage({ action = 'closeDashboard' })
    local events = {
        scratch = 'cj:client:openScratchMenu', euromillions = 'cj:client:openEuromillionsMenu',
        totoloto = 'cj:client:openTotolotoMenu', eurodreams = 'cj:client:openEuroDreamsMenu',
        joker = 'cj:client:buyJoker', lotteries = 'cj:client:openLotteriesMenu'
    }
    if events[data.game] then TriggerEvent(events[data.game]) end
    callback({ ok = true })
end)

RegisterNUICallback('closeDashboard', function(_, callback)
    dashboardOpen = false
    SetNuiFocus(false, false)
    callback({ ok = true })
end)

RegisterNUICallback('closeTicketCard', function(_, callback)
    SetNuiFocus(false, false)
    callback({ ok = true })
end)

RegisterNUICallback('loadOwnerAnalytics', function(_, callback)
    callback(CJ.Callbacks.Await('cj:server:getOwnerAnalytics'))
end)

RegisterNUICallback('restockScratch', function(data, callback)
    TriggerServerEvent('cj:server:restockScratch', data.cardId, tonumber(data.amount))
    callback({ ok = true })
end)

RegisterNUICallback('ownerFinance', function(data, callback)
    callback(CJ.Callbacks.Await('cj:server:ownerFinanceOperation', data.action, tonumber(data.amount)))
end)

RegisterNUICallback('closeOwnerDashboard', function(_, callback)
    SetNuiFocus(false, false)
    callback({ ok = true })
end)

RegisterNUICallback('approvePrize', function(data, callback)
    TriggerServerEvent('cj:server:approvePrizeClaim', data.claimId)
    callback({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and dashboardOpen then SetNuiFocus(false, false) end
end)
