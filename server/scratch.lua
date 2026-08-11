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

CJ.Security.RegisterEvent('cj:server:purchaseScratch', function(source, cardId, requestedQuantity)
    if not CJ.Company.IsOpen() then
        CJ.Framework.Notify(source, ('O %s está fechado neste momento.'):format(Config.CompanyName), 'error')
        return
    end
    local sellerMetadata = CJ.Company.GetSellerMetadata(source)
    if not sellerMetadata then
        CJ.Framework.Notify(source, 'Dirige-te a um ponto de venda para comprar.', 'error')
        return
    end
    local card = Config.ScratchCards[cardId]
    if not card then
        CJ.Security.Reject(source, 'cj:server:purchaseScratch', 'raspadinha inválida')
        return
    end

    local quantity = tonumber(requestedQuantity) or 1
    if quantity ~= math.floor(quantity) or quantity < 1 or quantity > Config.MaxScratchPurchaseQuantity then
        CJ.Security.Reject(source, 'cj:server:purchaseScratch', 'quantidade inválida')
        return
    end

    if CJ.Stock.Get(cardId) < quantity then
        CJ.Framework.Notify(source, 'Não há stock suficiente desta raspadinha. Volta mais tarde.', 'error')
        return
    end

    local total = card.price * quantity
    if CJ.Framework.GetMoney(source) < total then
        CJ.Framework.Notify(source, CJ.T('games.insufficient_funds'), 'error')
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    local purchased = 0
    for _ = 1, quantity do
        if not CJ.Stock.Take(cardId, 1) then
            break
        end
        if not CJ.Framework.RemoveMoney(source, card.price, 'centrojogos-scratch-purchase') then
            CJ.Stock.Add(cardId, 1)
            break
        end

        if not CJ.Finance.Credit(card.price, citizenId, 'scratch_purchase', sellerMetadata) then
            CJ.Stock.Add(cardId, 1)
            CJ.Framework.AddMoney(source, card.price, 'centrojogos-scratch-refund')
            break
        end

        local ticket = CJ.Tickets.Issue(source, 'scratch', {
            cardId = cardId,
            prize = selectPrize(card)
        })

        if not ticket then
            CJ.Stock.Add(cardId, 1)
            CJ.Finance.Debit(card.price, citizenId, 'scratch_issue_reversal')
            CJ.Framework.AddMoney(source, card.price, 'centrojogos-scratch-refund')
            break
        end

        purchased = purchased + 1
    end

    if purchased == 0 then
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    local paid = card.price * purchased
    local message = purchased == 1 and ('Compraste uma %s.'):format(card.label)
        or ('Compraste %s %s.'):format(purchased, card.label)
    if purchased < quantity then
        message = message .. ' Não foi possível concluir a quantidade total.'
    end
    CJ.Framework.Notify(source, message, 'success')
    CJ.Log.Discord('purchases', 'Compra de raspadinhas', ('%s comprou %s x %s por €%s.'):format(GetPlayerName(source), purchased, card.label, paid))
end)

CJ.Security.RegisterEvent('cj:server:redeemScratch', function(source, ticketId)
    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    if not ticket or ticket.ticket_type ~= 'scratch' then
        CJ.Security.Reject(source, 'cj:server:redeemScratch', 'bilhete inválido')
        return
    end

    local payload = json.decode(ticket.payload) or {}
    local prize = tonumber(payload.prize)
    if not prize or prize < 0 or prize > Config.ScratchMaximumPrize then
        CJ.Security.Reject(source, 'cj:server:redeemScratch', 'prémio inválido')
        return
    end

    local consumed = CJ.Tickets.Consume(source, ticketId)
    if not consumed then
        CJ.Security.Reject(source, 'cj:server:redeemScratch', 'bilhete já utilizado')
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)

    if prize > 0 and prize <= Config.AutoPayLimit then
        if not CJ.Finance.Debit(prize, citizenId, 'scratch_prize', Config.Company.Finance.maxPrizeTransaction) then
            CJ.Tickets.Restore(source, consumed)
            CJ.Framework.Notify(source, 'A empresa não tem saldo disponível para este prémio.', 'error')
            return
        end

        if not CJ.Framework.AddMoney(source, prize, 'centrojogos-scratch-prize') then
            CJ.Finance.Credit(prize, citizenId, 'scratch_prize_reversal', nil, Config.Company.Finance.maxPrizeTransaction)
            CJ.Tickets.Restore(source, consumed)
            CJ.Log.Write('error', ('Falha ao pagar raspadinha %s ao jogador %s.'):format(ticketId, source))
            CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
            return
        end
    elseif prize > 0 then
        -- Prémios altos são colocados em cj_prize_claims e descontados da empresa na aprovação.
        local claimId = CJ.Framework.AddMoney(source, prize, 'centrojogos-scratch-prize')
        if not claimId then
            CJ.Tickets.Restore(source, consumed)
            CJ.Log.Write('error', ('Falha ao registar prémio pendente da raspadinha %s.'):format(ticketId))
            CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
            return
        end

        local receiptIssued, receiptFailure = CJ.Prizes.IssueScratchReceipt(source, claimId, ticket, card, prize)
        if not receiptIssued then
            local receiptMessage = receiptFailure == 'missing_item'
                and 'O recibo de prémio não está configurado no inventário. Contacta a administração.'
                or 'Não foi possível entregar o recibo. Liberta espaço no inventário e tenta novamente.'
            if CJ.Prizes.CancelPending(claimId, citizenId) then
                CJ.Tickets.Restore(source, consumed)
                CJ.Framework.Notify(source, receiptMessage, 'error')
                TriggerClientEvent('cj:client:scratchResult', source, {
                    error = ('%s O bilhete foi devolvido ao teu inventário.'):format(receiptMessage),
                    ticketRestored = true
                })
            else
                CJ.Framework.Notify(source, 'O prémio ficou pendente, mas não foi possível entregar o recibo. Contacta um trabalhador.', 'error')
                TriggerClientEvent('cj:client:scratchResult', source, {
                    error = 'O prémio ficou pendente. Contacta um trabalhador para validação.',
                    pendingApproval = true
                })
            end
            CJ.Log.Write('error', ('Falha ao entregar recibo do prémio pendente da raspadinha %s.'):format(ticketId))
            return
        end
        CJ.Framework.Notify(source, 'Recebeste um recibo de prémio no inventário.', 'success')
    end

    if prize > 0 then
        CJ.Prizes.LogWin(source, prize, card.label, ticket.ticket_id)
    end
    CJ.Framework.Notify(source, prize > 0 and ('Ganhaste €%s!'):format(prize) or 'Não tiveste prémio desta vez.', prize > 0 and 'success' or 'error')
    TriggerClientEvent('cj:client:scratchResult', source, {
        prize = prize,
        pendingApproval = prize > Config.AutoPayLimit
    })
    CJ.Log.Discord('purchases', 'Raspadinha revelada', ('%s revelou uma raspadinha: €%s.'):format(GetPlayerName(source), prize))
end)
