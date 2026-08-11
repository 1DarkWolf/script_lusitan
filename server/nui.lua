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

CJ.Callbacks.Register('cj:server:getShopCatalog', function()
    local scratchCards = {}
    for cardId, card in pairs(Config.ScratchCards) do
        scratchCards[#scratchCards + 1] = {
            id = cardId,
            label = card.label,
            price = card.price,
            stock = CJ.Stock.Get(cardId)
        }
    end
    table.sort(scratchCards, function(left, right) return left.price < right.price end)

    local lotteries = {}
    for gameId, lottery in pairs(Config.Lotteries) do
        lotteries[#lotteries + 1] = { id = gameId, label = lottery.label, price = lottery.price }
    end
    table.sort(lotteries, function(left, right) return left.price < right.price end)

    return {
        scratchCards = scratchCards,
        maxScratchQuantity = Config.MaxScratchPurchaseQuantity,
        games = {
            euromillions = { label = Config.Euromillions.label, price = Config.Euromillions.price },
            totoloto = { label = Config.Totoloto.label, price = Config.Totoloto.price },
            eurodreams = { label = Config.EuroDreams.label, price = Config.EuroDreams.price },
            joker = { label = Config.Joker.label, price = Config.Joker.price }
        },
        lotteries = lotteries
    }
end)

CJ.Callbacks.Register('cj:server:getCompanyDashboard', function(source)
    if not CJ.Employees.HasPermission(source, 'view_sales') and not CJ.Employees.HasPermission(source, 'validate_prizes') and not CJ.Company.IsBoss(source) then
        return nil
    end

    local company = CJ.Company.Get()
    if not company then return nil end
    local transactions = CJ.Database.Query([[SELECT `type`, `amount`, `created_at` FROM `cj_transactions`
        WHERE `company_id` = ? ORDER BY `created_at` DESC LIMIT 20]], { company.id }) or {}
    local employees = CJ.Database.Query([[SELECT `citizenid`, `grade`, `hired_at` FROM `cj_company_employees`
        WHERE `company_id` = ? ORDER BY `hired_at` DESC LIMIT 20]], { company.id }) or {}
    return { balance = CJ.Company.GetBalance(), transactions = transactions, employees = employees, claims = CJ.Prizes.GetPending(source) }
end)
