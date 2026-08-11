CJ = CJ or {}

local dashboardOpen = false

local function isCompanyEmployee()
    local playerData = CJ.Framework.GetPlayerData()
    local job = playerData and playerData.job
    return job and job.name == Config.CompanyJob or false
end

CreateThread(function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAll' })
end)

RegisterNetEvent('cj:client:openDashboard', function()
    dashboardOpen = true
    SetNuiFocus(true, true)
    local isEmployee = isCompanyEmployee()
    SendNUIMessage({
        action = 'openDashboard',
        canViewCompany = isEmployee,
        canViewTickets = isEmployee
    })
end)

RegisterNUICallback('loadDashboard', function(data, callback)
    if data.section == 'tickets' then callback(CJ.Callbacks.Await('cj:server:getPlayerTickets'))
    elseif data.section == 'results' then callback(CJ.Callbacks.Await('cj:server:getRecentResults'))
    elseif data.section == 'company' then callback(CJ.Callbacks.Await('cj:server:getCompanyDashboard'))
    else callback({}) end
end)

RegisterNUICallback('buyGame', function(data, callback)
    callback({ ok = true })
end)

RegisterNUICallback('loadShopCatalog', function(_, callback)
    callback(CJ.Callbacks.Await('cj:server:getShopCatalog'))
end)

RegisterNUICallback('purchaseScratch', function(data, callback)
    TriggerServerEvent('cj:server:purchaseScratch', data.cardId, tonumber(data.quantity))
    callback({ ok = true })
end)

RegisterNUICallback('purchaseEuromillions', function(data, callback)
    TriggerServerEvent('cj:server:purchaseEuromillions', data.selection or {})
    callback({ ok = true })
end)

RegisterNUICallback('purchaseTotoloto', function(data, callback)
    TriggerServerEvent('cj:server:purchaseTotoloto', data.selection or {})
    callback({ ok = true })
end)

RegisterNUICallback('purchaseEuroDreams', function(data, callback)
    TriggerServerEvent('cj:server:purchaseEuroDreams', data.selection or {})
    callback({ ok = true })
end)

RegisterNUICallback('purchaseJoker', function(_, callback)
    TriggerServerEvent('cj:server:purchaseJoker')
    callback({ ok = true })
end)

RegisterNUICallback('purchaseLottery', function(data, callback)
    TriggerServerEvent('cj:server:purchaseLottery', data.gameId)
    callback({ ok = true })
end)

RegisterNUICallback('loadClaimableTickets', function(_, callback)
    callback(CJ.Callbacks.Await('cj:server:getClaimableTickets'))
end)

RegisterNUICallback('claimPrizeTicket', function(data, callback)
    TriggerEvent('cj:client:claimPrizeTicket', { game = data.game, ticketId = data.ticketId })
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
