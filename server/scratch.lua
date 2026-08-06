CJ = CJ or {}
CJ.Scratch = CJ.Scratch or {}

local function selectPrize(card)
    local totalWeight = 0
    for _, prize in ipairs(card.prizes) do
        totalWeight = totalWeight + prize.weight
    end

    local roll = math.random(1, totalWeight)
    local currentWeight = 0
    for _, prize in ipairs(card.prizes) do
        currentWeight = currentWeight + prize.weight
        if roll <= currentWeight then
            return prize.amount
        end
    end

    return 0
end

CJ.Security.RegisterEvent('cj:server:purchaseScratch', function(source, cardId)
    local card = Config.ScratchCards[cardId]
    if not card then
        CJ.Security.Reject(source, 'cj:server:purchaseScratch', 'raspadinha inválida')
        return
    end

    if CJ.Framework.GetMoney(source) < card.price then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error')
        return
    end

    if not CJ.Framework.RemoveMoney(source, card.price, 'centrojogos-scratch-purchase') then
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(card.price, citizenId, 'scratch_purchase') then
        CJ.Framework.AddMoney(source, card.price, 'centrojogos-scratch-refund')
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    local ticket = CJ.Tickets.Issue(source, 'scratch', {
        cardId = cardId,
        prize = selectPrize(card)
    })

    if not ticket then
        CJ.Finance.Debit(card.price, citizenId, 'scratch_issue_reversal')
        CJ.Framework.AddMoney(source, card.price, 'centrojogos-scratch-refund')
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    CJ.Framework.Notify(source, ('Compraste uma %s.'):format(card.label), 'success')
    CJ.Log.Discord('purchases', 'Compra de raspadinha', ('%s comprou %s por €%s.'):format(GetPlayerName(source), card.label, card.price))
end)

CJ.Security.RegisterEvent('cj:server:redeemScratch', function(source, ticketId)
    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    if not ticket or ticket.ticket_type ~= 'scratch' then
        CJ.Security.Reject(source, 'cj:server:redeemScratch', 'bilhete inválido')
        return
    end

    local payload = json.decode(ticket.payload) or {}
    local prize = tonumber(payload.prize)
    if not prize or prize < 0 or prize > Config.AutoPayLimit then
        CJ.Security.Reject(source, 'cj:server:redeemScratch', 'prémio inválido')
        return
    end

    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then
        CJ.Security.Reject(source, 'cj:server:redeemScratch', 'bilhete já utilizado')
        return
    end

    if prize > 0 and not CJ.Framework.AddMoney(source, prize, 'centrojogos-scratch-prize') then
        CJ.Tickets.Restore(source, consumed)
        CJ.Log.Write('error', ('Falha ao pagar raspadinha %s ao jogador %s.'):format(ticketId, source))
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    CJ.Framework.Notify(source, prize > 0 and ('Ganhaste €%s!'):format(prize) or 'Não tiveste prémio desta vez.', prize > 0 and 'success' or 'error')
    TriggerClientEvent('cj:client:scratchResult', source, { prize = prize })
    CJ.Log.Discord('purchases', 'Raspadinha revelada', ('%s revelou uma raspadinha: €%s.'):format(GetPlayerName(source), prize))
end)
