CJ = CJ or {}

RegisterNetEvent('cj:client:openTicket', function(ticket)
    if ticket.ticketType == 'scratch' then
        TriggerEvent('cj:client:openScratchTicket', ticket)
        return
    end

    if ticket.ticketType == 'draw' then
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'openTicketCard', ticket = ticket })
        return
    end

    CJ.Framework.Notify(('Bilhete %s aberto. A interface deste jogo será apresentada aqui.'):format(ticket.ticketId:sub(1, 8)), 'primary')
end)
