CJ = CJ or {}

RegisterNetEvent('cj:client:openTicket', function(ticket)
    CJ.Framework.Notify(('Bilhete %s aberto. A interface deste jogo será apresentada aqui.'):format(ticket.ticketId:sub(1, 8)), 'primary')
end)
