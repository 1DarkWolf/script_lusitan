CJ = CJ or {}

CJ.Callbacks.Register('cj:server:getPlayerTickets', function(source)
    local citizenId = CJ.Framework.GetCitizenId(source)
    local rows = CJ.Database.Query([[SELECT `ticket_id`, `ticket_type`, `payload`, `status`, `created_at`
        FROM `cj_tickets` WHERE `owner_citizenid` = ? ORDER BY `created_at` DESC LIMIT 30]], { citizenId }) or {}

    for _, ticket in ipairs(rows) do
        local payload = json.decode(ticket.payload) or {}
        ticket.payload = {
            game = payload.game or payload.cardId or ticket.ticket_type,
            drawKey = payload.drawKey
        }
        ticket.ticket_id = ticket.ticket_id:sub(1, 8)
    end
    return rows
end)

CJ.Callbacks.Register('cj:server:getRecentResults', function()
    local rows = CJ.Database.Query([[SELECT `game_id`, `result`, `drawn_at`
        FROM `cj_draw_results` ORDER BY `drawn_at` DESC LIMIT 20]]) or {}
    for _, result in ipairs(rows) do result.result = json.decode(result.result) or {} end
    return rows
end)
