CJ = CJ or {}
local GAME_ID = 'eurodreams'

local function pick(count, maximum)
    local values, used = {}, {}
    while #values < count do
        local value = math.random(1, maximum)
        if not used[value] then used[value] = true; values[#values + 1] = value end
    end
    table.sort(values)
    return values
end

local function valid(values)
    if type(values) ~= 'table' or #values ~= 6 then return false end
    local used = {}
    for _, value in ipairs(values) do
        value = tonumber(value)
        if not value or value ~= math.floor(value) or value < 1 or value > 40 or used[value] then return false end
        used[value] = true
    end
    return true
end

local function countMatches(values, winning)
    local set, count = {}, 0
    for _, value in ipairs(winning) do set[value] = true end
    for _, value in ipairs(values) do if set[value] then count = count + 1 end end
    return count
end

CJ.Security.RegisterEvent('cj:server:purchaseEuroDreams', function(source, selection)
    if not CJ.Company.IsOpen() then CJ.Framework.Notify(source, ('O %s está fechado neste momento.'):format(Config.CompanyName), 'error'); return end
    local sellerMetadata = CJ.Company.GetSellerMetadata(source)
    if not sellerMetadata then CJ.Framework.Notify(source, 'Dirige-te a um ponto de venda para comprar.', 'error'); return end
    selection = type(selection) == 'table' and selection or {}
    local numbers, dreamNumber
    if selection.quickPick then
        numbers, dreamNumber = pick(6, 40), math.random(1, 5)
    else
        numbers, dreamNumber = selection.numbers, tonumber(selection.dreamNumber)
        if not valid(numbers) or not dreamNumber or dreamNumber < 1 or dreamNumber > 5 or dreamNumber ~= math.floor(dreamNumber) then
            CJ.Security.Reject(source, 'cj:server:purchaseEuroDreams', 'chave inválida')
            return
        end
    end
    if CJ.Framework.GetMoney(source) < Config.EuroDreams.price or not CJ.Framework.RemoveMoney(source, Config.EuroDreams.price, 'centrojogos-eurodreams-purchase') then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error')
        return
    end
    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(Config.EuroDreams.price, citizenId, 'eurodreams_purchase', sellerMetadata) then
        CJ.Framework.AddMoney(source, Config.EuroDreams.price, 'centrojogos-eurodreams-refund')
        return
    end
    if not CJ.Tickets.Issue(source, 'draw', { game = GAME_ID, drawKey = CJ.Draws.GetNextDrawKey(GAME_ID), numbers = numbers, dreamNumber = dreamNumber }) then
        CJ.Finance.Debit(Config.EuroDreams.price, citizenId, 'eurodreams_issue_reversal')
        CJ.Framework.AddMoney(source, Config.EuroDreams.price, 'centrojogos-eurodreams-refund')
        return
    end
    CJ.Framework.Notify(source, 'Aposta EuroDreams registada.', 'success')
end)

CJ.Draws.RegisterGame(GAME_ID, { label = Config.EuroDreams.label, schedule = Config.EuroDreams.schedule, draw = function()
    return { numbers = pick(6, 40), dreamNumber = math.random(1, 5) }
end })

CJ.Security.RegisterEvent('cj:server:checkEuroDreamsTicket', function(source, ticketId)
    if not CJ.Company.IsOpen() or not CJ.Company.IsNearCounter(source) then
        CJ.Framework.Notify(source, 'Dirige-te ao balcão para levantar este prémio.', 'error')
        return
    end

    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    local payload = ticket and json.decode(ticket.payload) or nil
    if not ticket or ticket.ticket_type ~= 'draw' or not payload or payload.game ~= GAME_ID then
        CJ.Security.Reject(source, 'cj:server:checkEuroDreamsTicket', 'bilhete inválido')
        return
    end
    local draw = CJ.Draws.GetResultByKey(payload.drawKey)
    if not draw then CJ.Framework.Notify(source, 'Este sorteio ainda não foi realizado.', 'primary'); return end
    local numbers = countMatches(payload.numbers, draw.result.numbers)
    local dream = payload.dreamNumber == draw.result.dreamNumber and 1 or 0
    local prize = Config.EuroDreams.prizes[('%s+%s'):format(numbers, dream)] or 0
    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then return end
    if prize > 0 and not CJ.Framework.AddMoney(source, prize, 'centrojogos-eurodreams-prize') then
        CJ.Tickets.Restore(source, consumed); CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error'); return
    end
    CJ.Framework.Notify(source, prize > 0 and ('Ganhaste €%s.'):format(prize) or 'Não tiveste prémio neste bilhete.', prize > 0 and 'success' or 'error')
end)
