CJ = CJ or {}

local GAME_ID = 'euromillions'

local function uniqueNumbers(count, maximum)
    local values, used = {}, {}
    while #values < count do
        local value = math.random(1, maximum)
        if not used[value] then used[value] = true; values[#values + 1] = value end
    end
    table.sort(values)
    return values
end

local function validSelection(values, count, maximum)
    if type(values) ~= 'table' or #values ~= count then return false end
    local used = {}
    for _, value in ipairs(values) do
        value = tonumber(value)
        if not value or value ~= math.floor(value) or value < 1 or value > maximum or used[value] then return false end
        used[value] = true
    end
    return true
end

local function calculateMatches(values, winning)
    local set, count = {}, 0
    for _, value in ipairs(winning) do set[value] = true end
    for _, value in ipairs(values) do if set[value] then count = count + 1 end end
    return count
end

CJ.Security.RegisterEvent('cj:server:purchaseEuromillions', function(source, selection)
    if not CJ.Company.IsOpen() then CJ.Framework.Notify(source, ('O %s está fechado neste momento.'):format(Config.CompanyName), 'error'); return end
    local sellerMetadata = CJ.Company.GetSellerMetadata(source)
    if not sellerMetadata then CJ.Framework.Notify(source, 'Dirige-te a um ponto de venda para comprar.', 'error'); return end
    selection = type(selection) == 'table' and selection or {}
    local numbers, stars
    if selection.quickPick == true then
        numbers, stars = uniqueNumbers(5, 50), uniqueNumbers(2, 12)
    else
        numbers, stars = selection.numbers, selection.stars
        if not validSelection(numbers, 5, 50) or not validSelection(stars, 2, 12) then
            CJ.Security.Reject(source, 'cj:server:purchaseEuromillions', 'chave inválida')
            return
        end
    end

    if CJ.Framework.GetMoney(source) < Config.Euromillions.price or not CJ.Framework.RemoveMoney(source, Config.Euromillions.price, 'centrojogos-euromillions-purchase') then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error')
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(Config.Euromillions.price, citizenId, 'euromillions_purchase', sellerMetadata) then
        CJ.Framework.AddMoney(source, Config.Euromillions.price, 'centrojogos-euromillions-refund')
        return
    end

    local ticket = CJ.Tickets.Issue(source, 'draw', { game = GAME_ID, drawKey = CJ.Draws.GetNextDrawKey(GAME_ID), numbers = numbers, stars = stars })
    if not ticket then
        CJ.Finance.Debit(Config.Euromillions.price, citizenId, 'euromillions_issue_reversal')
        CJ.Framework.AddMoney(source, Config.Euromillions.price, 'centrojogos-euromillions-refund')
        return
    end
    CJ.Framework.Notify(source, 'Aposta Euromilhões registada.', 'success')
end)

CJ.Draws.RegisterGame(GAME_ID, {
    label = Config.Euromillions.label,
    schedule = Config.Euromillions.schedule,
    draw = function()
        return { numbers = uniqueNumbers(5, 50), stars = uniqueNumbers(2, 12) }
    end
})

CJ.Security.RegisterEvent('cj:server:checkEuromillionsTicket', function(source, ticketId)
    if not CJ.Company.IsOpen() or not CJ.Company.IsNearCounter(source) then
        CJ.Framework.Notify(source, 'Dirige-te ao balcão para levantar este prémio.', 'error')
        return
    end

    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    local payload = ticket and json.decode(ticket.payload) or nil
    if not ticket or ticket.ticket_type ~= 'draw' or not payload or payload.game ~= GAME_ID then
        CJ.Security.Reject(source, 'cj:server:checkEuromillionsTicket', 'bilhete inválido')
        return
    end

    local draw = CJ.Draws.GetResultByKey(payload.drawKey)
    if not draw then
        CJ.Framework.Notify(source, 'Este sorteio ainda não foi realizado.', 'primary')
        return
    end

    local numbers = calculateMatches(payload.numbers, draw.result.numbers)
    local stars = calculateMatches(payload.stars, draw.result.stars)
    local prize = Config.Euromillions.prizes[('%s+%s'):format(numbers, stars)] or 0
    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then return end

    if prize > 0 and not CJ.Framework.AddMoney(source, prize, 'centrojogos-euromillions-prize') then
        CJ.Tickets.Restore(source, consumed)
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end
    if prize > 0 then
        CJ.Prizes.LogWin(source, prize, Config.Euromillions.label, ticket.ticket_id)
    end

    CJ.Framework.Notify(source, prize > 0 and ('Tiveste %s números e %s estrelas: ganhaste €%s.'):format(numbers, stars, prize) or 'Não tiveste prémio neste bilhete.', prize > 0 and 'success' or 'error')
end)

exports('CalculateEuromillionsMatches', function(numbers, stars, result)
    return calculateMatches(numbers, result.numbers), calculateMatches(stars, result.stars)
end)
