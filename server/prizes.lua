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
    local rows = CJ.Database.Query([[SELECT `id`, `citizenid`, `amount` FROM `cj_prize_claims`
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
    MySQL.update.await([[UPDATE `cj_prize_claims` SET `status` = 'paid', `approved_by` = ?, `paid_at` = CURRENT_TIMESTAMP
        WHERE `id` = ? AND `status` = 'pending']], { CJ.Framework.GetCitizenId(source), claim.id })
    CJ.Loyalty.AddWinnings(claim.citizenid, claim.amount)
    CJ.Framework.Notify(source, 'Prémio aprovado e pago.', 'success')
    CJ.Framework.Notify(target.PlayerData.source, ('O teu prémio de €%s foi aprovado.'):format(claim.amount), 'success')
end)

CJ.Callbacks.Register('cj:server:getPendingPrizeClaims', CJ.Prizes.GetPending)
exports('QueuePrizeClaim', CJ.Prizes.Queue)
