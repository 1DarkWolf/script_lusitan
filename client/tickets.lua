CJ = CJ or {}

RegisterNetEvent('cj:client:openTicket', function(ticket)
    if ticket.ticketType == 'scratch' then
        TriggerEvent('cj:client:openScratchTicket', ticket)
        return
    end

    if ticket.ticketType == 'draw' and ticket.payload.game == 'euromillions' then
        TriggerServerEvent('cj:server:checkEuromillionsTicket', ticket.ticketId)
        return
    end

    if ticket.ticketType == 'draw' and ticket.payload.game == 'totoloto' then
        TriggerServerEvent('cj:server:checkTotolotoTicket', ticket.ticketId)
        return
    end

    if ticket.ticketType == 'draw' and ticket.payload.game == 'eurodreams' then
        TriggerServerEvent('cj:server:checkEuroDreamsTicket', ticket.ticketId)
        return
    end

    CJ.Framework.Notify(('Bilhete %s aberto. A interface deste jogo será apresentada aqui.'):format(ticket.ticketId:sub(1, 8)), 'primary')
end)
