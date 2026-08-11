CJ = CJ or {}

local GAME_ID = 'totoloto'

local function uniqueNumbers(count, maximum)
    local values, used = {}, {}
    while #values < count do
        local value = math.random(1, maximum)
        if not used[value] then
            used[value] = true
            values[#values + 1] = value
        end
    end
    table.sort(values)
    return values
end

local function validNumbers(values)
    if type(values) ~= 'table' or #values ~= 5 then return false end
    local used = {}
    for _, value in ipairs(values) do
        value = tonumber(value)
        if not value or value ~= math.floor(value) or value < 1 or value > 49 or used[value] then return false end
        used[value] = true
    end
    return true
end

local function matches(values, winning)
    local set, count = {}, 0
    for _, value in ipairs(winning) do set[value] = true end
    for _, value in ipairs(values) do if set[value] then count = count + 1 end end
    return count
end

CJ.Security.RegisterEvent('cj:server:purchaseTotoloto', function(source, selection)
    if not CJ.Company.IsOpen() then CJ.Framework.Notify(source, ('O %s está fechado neste momento.'):format(Config.CompanyName), 'error'); return end
    local sellerMetadata = CJ.Company.GetSellerMetadata(source)
    if not sellerMetadata then CJ.Framework.Notify(source, 'Dirige-te a um ponto de venda para comprar.', 'error'); return end
    selection = type(selection) == 'table' and selection or {}
    local numbers, luckyNumber
    if selection.quickPick == true then
        numbers, luckyNumber = uniqueNumbers(5, 49), math.random(1, 13)
    else
        numbers, luckyNumber = selection.numbers, tonumber(selection.luckyNumber)
        if not validNumbers(numbers) or not luckyNumber or luckyNumber ~= math.floor(luckyNumber) or luckyNumber < 1 or luckyNumber > 13 then
            CJ.Security.Reject(source, 'cj:server:purchaseTotoloto', 'chave inválida')
            return
        end
    end

    if CJ.Framework.GetMoney(source) < Config.Totoloto.price or not CJ.Framework.RemoveMoney(source, Config.Totoloto.price, 'centrojogos-totoloto-purchase') then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error')
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(Config.Totoloto.price, citizenId, 'totoloto_purchase', sellerMetadata) then
        CJ.Framework.AddMoney(source, Config.Totoloto.price, 'centrojogos-totoloto-refund')
        return
    end

    local ticket = CJ.Tickets.Issue(source, 'draw', {
        game = GAME_ID,
        drawKey = CJ.Draws.GetNextDrawKey(GAME_ID),
        numbers = numbers,
        luckyNumber = luckyNumber
    })
    if not ticket then
        CJ.Finance.Debit(Config.Totoloto.price, citizenId, 'totoloto_issue_reversal')
        CJ.Framework.AddMoney(source, Config.Totoloto.price, 'centrojogos-totoloto-refund')
        return
    end

    CJ.Framework.Notify(source, 'Aposta Totoloto registada.', 'success')
end)

CJ.Draws.RegisterGame(GAME_ID, {
    label = Config.Totoloto.label,
    schedule = Config.Totoloto.schedule,
    draw = function()
        return { numbers = uniqueNumbers(5, 49), luckyNumber = math.random(1, 13) }
    end
})

CJ.Security.RegisterEvent('cj:server:checkTotolotoTicket', function(source, ticketId)
    if not CJ.Company.IsOpen() or not CJ.Company.IsNearCounter(source) then
        CJ.Framework.Notify(source, 'Dirige-te ao balcão para levantar este prémio.', 'error')
        return
    end

    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    local payload = ticket and json.decode(ticket.payload) or nil
    if not ticket or ticket.ticket_type ~= 'draw' or not payload or payload.game ~= GAME_ID then
        CJ.Security.Reject(source, 'cj:server:checkTotolotoTicket', 'bilhete inválido')
        return
    end

    local draw = CJ.Draws.GetResultByKey(payload.drawKey)
    if not draw then
        CJ.Framework.Notify(source, 'Este sorteio ainda não foi realizado.', 'primary')
        return
    end

    local numberMatches = matches(payload.numbers, draw.result.numbers)
    local luckyMatch = payload.luckyNumber == draw.result.luckyNumber and 1 or 0
    local prize = Config.Totoloto.prizes[('%s+%s'):format(numberMatches, luckyMatch)] or 0
    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then return end

    if prize > 0 and not CJ.Framework.AddMoney(source, prize, 'centrojogos-totoloto-prize') then
        CJ.Tickets.Restore(source, consumed)
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end
    if prize > 0 then
        CJ.Prizes.LogWin(source, prize, Config.Totoloto.label, ticket.ticket_id)
    end

    CJ.Framework.Notify(source, prize > 0 and ('Tiveste %s números certos: ganhaste €%s.'):format(numberMatches, prize) or 'Não tiveste prémio neste bilhete.', prize > 0 and 'success' or 'error')
end)
