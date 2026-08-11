CJ = CJ or {}
CJ.Prizes = CJ.Prizes or {}

---@param citizenId string
---@param amount number
---@param reason string
---@return boolean
function CJ.Prizes.Queue(citizenId, amount, reason)
    return MySQL.insert.await([[INSERT INTO `cj_prize_claims` (`citizenid`, `amount`, `reason`)
        VALUES (?, ?, ?)]], { citizenId, amount, reason }) ~= nil
end

---@param source number
---@param amount number
---@param gameLabel string
---@param ticketId? string
function CJ.Prizes.LogWin(source, amount, gameLabel, ticketId)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    local citizenId = CJ.Framework.GetCitizenId(source)
    local pendingApproval = amount > Config.AutoPayLimit
    local fields = {
        { name = 'Jogador', value = GetPlayerName(source) or 'Desconhecido', inline = true },
        { name = 'Citizen ID', value = citizenId or 'N/D', inline = true },
        { name = 'Jogo', value = gameLabel or 'Centro de Jogos', inline = true },
        { name = 'Prémio', value = ('€%s'):format(amount), inline = true },
        { name = 'Estado', value = pendingApproval and 'Aguarda aprovação de um trabalhador' or 'Pago automaticamente', inline = true }
    }
    if ticketId then
        fields[#fields + 1] = { name = 'Bilhete', value = ('#%s'):format(ticketId:sub(1, 8)), inline = true }
    end

    return CJ.Log.Discord('prizes', 'Prémio ganho', ('%s ganhou €%s em %s.'):format(
        GetPlayerName(source) or 'Um jogador', amount, gameLabel or 'Centro de Jogos'
    ), fields, pendingApproval and 15844367 or 3066993)
end

---@param source number
---@return table
function CJ.Prizes.GetPending(source)
    if not CJ.Employees.HasPermission(source, 'validate_prizes') then
        return {}
    end
    return CJ.Database.Query([[SELECT `id`, `citizenid`, `amount`, `reason`, `created_at`
        FROM `cj_prize_claims` WHERE `status` = 'pending' ORDER BY `created_at` ASC LIMIT 30]]) or {}
end

CJ.Security.RegisterEvent('cj:server:approvePrizeClaim', function(source, claimId)
    if not CJ.Employees.HasPermission(source, 'validate_prizes') then
        CJ.Security.Reject(source, 'cj:server:approvePrizeClaim', 'sem permissão')
        return
    end
    local rows = CJ.Database.Query([[SELECT `id`, `citizenid`, `amount`, `reason` FROM `cj_prize_claims`
        WHERE `id` = ? AND `status` = 'pending' LIMIT 1]], { tonumber(claimId) })
    local claim = rows and rows[1]
    if not claim then
        CJ.Framework.Notify(source, 'Pedido de prémio não encontrado.', 'error')
        return
    end
    local target = exports['qb-core']:GetCoreObject().Functions.GetPlayerByCitizenId(claim.citizenid)
    if not target then
        CJ.Framework.Notify(source, 'O jogador tem de estar online para receber o prémio.', 'error')
        return
    end
    local amount = tonumber(claim.amount)
    if not CJ.Finance.Debit(amount, claim.citizenid, 'prize_claim_payout', Config.Company.Finance.maxPrizeTransaction) then
        CJ.Framework.Notify(source, 'A empresa não tem saldo suficiente para pagar este prémio.', 'error')
        return
    end
    if not target.Functions.AddMoney(Config.MoneyType, amount, 'centrojogos-prize-validation') then
        CJ.Finance.Credit(amount, claim.citizenid, 'prize_claim_reversal', nil, Config.Company.Finance.maxPrizeTransaction)
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end
    local approverCitizenId = CJ.Framework.GetCitizenId(source)
    MySQL.update.await([[UPDATE `cj_prize_claims` SET `status` = 'paid', `approved_by` = ?, `paid_at` = CURRENT_TIMESTAMP
        WHERE `id` = ? AND `status` = 'pending']], { approverCitizenId, claim.id })
    CJ.Loyalty.AddWinnings(claim.citizenid, claim.amount)
    CJ.Log.Discord('prize_approvals', 'Prémio aprovado e pago', ('%s aprovou o pagamento de €%s a %s.'):format(
        GetPlayerName(source) or 'Um trabalhador', amount, GetPlayerName(target.PlayerData.source) or claim.citizenid
    ), {
        { name = 'Trabalhador', value = GetPlayerName(source) or 'Desconhecido', inline = true },
        { name = 'Citizen ID do trabalhador', value = approverCitizenId or 'N/D', inline = true },
        { name = 'Jogador pago', value = GetPlayerName(target.PlayerData.source) or claim.citizenid, inline = true },
        { name = 'Citizen ID do jogador', value = claim.citizenid, inline = true },
        { name = 'Prémio', value = ('€%s'):format(amount), inline = true },
        { name = 'Pedido', value = ('#%s — %s'):format(claim.id, claim.reason or 'prémio'), inline = false }
    }, 3066993)
    CJ.Framework.Notify(source, 'Prémio aprovado e pago.', 'success')
    CJ.Framework.Notify(target.PlayerData.source, ('O teu prémio de €%s foi aprovado.'):format(claim.amount), 'success')
end)

CJ.Callbacks.Register('cj:server:getPendingPrizeClaims', CJ.Prizes.GetPending)
exports('QueuePrizeClaim', CJ.Prizes.Queue)
