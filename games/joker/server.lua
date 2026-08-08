CJ = CJ or {}
local GAME_ID = 'joker'

local function code()
    return ('%06d'):format(math.random(0, 999999))
end

local function matchingPositions(first, second)
    local matches = 0
    for index = 1, 6 do
        if first:sub(index, index) == second:sub(index, index) then matches = matches + 1 end
    end
    return matches
end

CJ.Security.RegisterEvent('cj:server:purchaseJoker', function(source)
    if not CJ.Company.IsOpen() then CJ.Framework.Notify(source, ('O %s está fechado neste momento.'):format(Config.CompanyName), 'error'); return end
    local sellerMetadata = CJ.Company.GetSellerMetadata(source)
    if not sellerMetadata then CJ.Framework.Notify(source, 'Dirige-te a um ponto de venda para comprar.', 'error'); return end
    if CJ.Framework.GetMoney(source) < Config.Joker.price or not CJ.Framework.RemoveMoney(source, Config.Joker.price, 'centrojogos-joker-purchase') then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error')
        return
    end
    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(Config.Joker.price, citizenId, 'joker_purchase', sellerMetadata) then
        CJ.Framework.AddMoney(source, Config.Joker.price, 'centrojogos-joker-refund')
        return
    end
    local ticket = CJ.Tickets.Issue(source, 'draw', { game = GAME_ID, drawKey = CJ.Draws.GetNextDrawKey(GAME_ID), code = code() })
    if not ticket then
        CJ.Finance.Debit(Config.Joker.price, citizenId, 'joker_issue_reversal')
        CJ.Framework.AddMoney(source, Config.Joker.price, 'centrojogos-joker-refund')
        return
    end
    CJ.Framework.Notify(source, 'Bilhete Joker registado.', 'success')
end)

CJ.Draws.RegisterGame(GAME_ID, { label = Config.Joker.label, schedule = Config.Joker.schedule, draw = function() return { code = code() } end })

CJ.Security.RegisterEvent('cj:server:checkJokerTicket', function(source, ticketId)
    if not CJ.Company.IsOpen() or not CJ.Company.IsNearCounter(source) then
        CJ.Framework.Notify(source, 'Dirige-te ao balcão para levantar este prémio.', 'error')
        return
    end

    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    local payload = ticket and json.decode(ticket.payload) or nil
    if not ticket or ticket.ticket_type ~= 'draw' or not payload or payload.game ~= GAME_ID then
        CJ.Security.Reject(source, 'cj:server:checkJokerTicket', 'bilhete inválido')
        return
    end
    local draw = CJ.Draws.GetResultByKey(payload.drawKey)
    if not draw then CJ.Framework.Notify(source, 'Este sorteio ainda não foi realizado.', 'primary'); return end
    local matches = matchingPositions(payload.code, draw.result.code)
    local prize = Config.Joker.prizes[matches] or 0
    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then return end
    if prize > 0 and not CJ.Framework.AddMoney(source, prize, 'centrojogos-joker-prize') then
        CJ.Tickets.Restore(source, consumed); CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error'); return
    end
    CJ.Framework.Notify(source, prize > 0 and ('Acertaste %s posições: ganhaste €%s.'):format(matches, prize) or 'Não tiveste prémio neste bilhete.', prize > 0 and 'success' or 'error')
end)
