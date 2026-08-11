CJ = CJ or {}

local activeTicket
local redemptionRequested = false

RegisterNetEvent('cj:client:openScratchMenu', function()
    local menu = {
        { header = 'Raspadinhas', isMenuHeader = true }
    }

    for cardId, card in pairs(Config.ScratchCards) do
        menu[#menu + 1] = {
            header = card.label,
            txt = ('€%s'):format(card.price),
            params = {
                event = 'cj:client:purchaseScratch',
                args = { cardId = cardId }
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('cj:client:purchaseScratch', function(data)
    TriggerServerEvent('cj:server:purchaseScratch', data.cardId)
end)

RegisterNetEvent('cj:client:openScratchTicket', function(ticket)
    local card = Config.ScratchCards[ticket.payload.cardId]
    if not card then
        CJ.Framework.Notify(CJ.T('general.invalid_input'), 'error')
        return
    end

    activeTicket = ticket
    redemptionRequested = false
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openScratch',
        card = { id = ticket.payload.cardId, label = card.label, price = card.price }
    })
end)

RegisterNUICallback('scratchComplete', function(_, callback)
    if activeTicket and not redemptionRequested then
        redemptionRequested = true
        TriggerServerEvent('cj:server:redeemScratch', activeTicket.ticketId)
    end

    callback({ ok = true })
end)

RegisterNUICallback('closeScratch', function(_, callback)
    SetNuiFocus(false, false)
    activeTicket = nil
    redemptionRequested = false
    callback({ ok = true })
end)

RegisterNetEvent('cj:client:scratchResult', function(result)
    if not activeTicket then
        return
    end

    if result.ticketRestored then
        redemptionRequested = false
    end

    SendNUIMessage({
        action = 'scratchResult',
        prize = result.prize,
        pendingApproval = result.pendingApproval == true,
        error = result.error
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
