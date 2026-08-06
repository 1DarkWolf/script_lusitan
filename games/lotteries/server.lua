CJ = CJ or {}

local function number(maximum)
    return math.random(1, maximum)
end

local function instantPrize(prizes)
    local total, current = 0, 0
    for _, prize in ipairs(prizes) do total = total + prize.weight end
    local roll = math.random(1, total)
    for _, prize in ipairs(prizes) do
        current = current + prize.weight
        if roll <= current then return prize.amount end
    end
    return 0
end

local function registerScheduledLottery(gameId)
    local lottery = Config.Lotteries[gameId]
    CJ.Draws.RegisterGame(gameId, { label = lottery.label, schedule = lottery.schedule, draw = function() return { number = number(lottery.maximumNumber) } end })
end

registerScheduledLottery('classic')
registerScheduledLottery('popular')

CJ.Security.RegisterEvent('cj:server:purchaseLottery', function(source, gameId)
    if not CJ.Company.IsOpen() then CJ.Framework.Notify(source, ('O %s está fechado neste momento.'):format(Config.CompanyName), 'error'); return end
    local lottery = Config.Lotteries[gameId]
    if not lottery then CJ.Security.Reject(source, 'cj:server:purchaseLottery', 'jogo inválido'); return end
    if CJ.Framework.GetMoney(source) < lottery.price or not CJ.Framework.RemoveMoney(source, lottery.price, 'centrojogos-lottery-purchase') then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error'); return
    end
    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(lottery.price, citizenId, gameId .. '_purchase') then
        CJ.Framework.AddMoney(source, lottery.price, 'centrojogos-lottery-refund'); return
    end
    local payload = { game = gameId }
    if gameId == 'instant' then
        payload.prize = instantPrize(lottery.prizes)
    else
        payload.number = number(lottery.maximumNumber)
        payload.drawKey = CJ.Draws.GetNextDrawKey(gameId)
    end
    if not CJ.Tickets.Issue(source, 'draw', payload) then
        CJ.Finance.Debit(lottery.price, citizenId, gameId .. '_issue_reversal')
        CJ.Framework.AddMoney(source, lottery.price, 'centrojogos-lottery-refund')
        return
    end
    CJ.Framework.Notify(source, ('Bilhete %s registado.'):format(lottery.label), 'success')
end)

CJ.Security.RegisterEvent('cj:server:checkLotteryTicket', function(source, ticketId)
    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    local payload = ticket and json.decode(ticket.payload) or nil
    local lottery = payload and Config.Lotteries[payload.game] or nil
    if not ticket or ticket.ticket_type ~= 'draw' or not lottery then
        CJ.Security.Reject(source, 'cj:server:checkLotteryTicket', 'bilhete inválido'); return
    end
    local prize = 0
    if payload.game == 'instant' then
        prize = tonumber(payload.prize) or 0
    else
        local draw = CJ.Draws.GetResultByKey(payload.drawKey)
        if not draw then CJ.Framework.Notify(source, 'Este sorteio ainda não foi realizado.', 'primary'); return end
        prize = payload.number == draw.result.number and lottery.prize or 0
    end
    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then return end
    if prize > 0 and not CJ.Framework.AddMoney(source, prize, 'centrojogos-lottery-prize') then
        CJ.Tickets.Restore(source, consumed); CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error'); return
    end
    CJ.Framework.Notify(source, prize > 0 and ('Ganhaste €%s.'):format(prize) or 'Não tiveste prémio neste bilhete.', prize > 0 and 'success' or 'error')
end)
