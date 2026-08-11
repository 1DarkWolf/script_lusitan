CJ = CJ or {}
CJ.Finance = CJ.Finance or {}

local function isValidAmount(amount)
    amount = tonumber(amount)
    return amount and amount > 0 and amount == math.floor(amount) and amount <= Config.Company.Finance.maxTransaction and amount or nil
end

local function isNearOwnerDashboard(source)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end

    local npc = Config.OwnerDashboard.Npc
    return #(GetEntityCoords(ped) - vector3(npc.coords.x, npc.coords.y, npc.coords.z)) <= (Config.OwnerDashboard.distance + 1.5)
end

---@param amount number
---@param citizenId? string
---@param transactionType? string
---@param metadata? table
---@return boolean
function CJ.Finance.Credit(amount, citizenId, transactionType, metadata)
    amount = isValidAmount(amount)
    local company = CJ.Company.Get()

    if not amount or not company then
        return false
    end

    local affectedRows = MySQL.update.await('UPDATE `cj_companies` SET `balance` = `balance` + ? WHERE `id` = ?', {
        amount,
        company.id
    })

    if affectedRows ~= 1 then
        return false
    end

    CJ.Cache.Remove('company:primary')
    CJ.Company.RecordTransaction(transactionType or 'credit', amount, citizenId, metadata)
    if citizenId and transactionType and transactionType:sub(-9) == '_purchase' and CJ.Loyalty then
        CJ.Loyalty.AddPurchase(citizenId, amount)
    end
    return true
end

---@param amount number
---@param citizenId? string
---@param transactionType? string
---@return boolean
function CJ.Finance.Debit(amount, citizenId, transactionType)
    amount = isValidAmount(amount)
    local company = CJ.Company.Get()

    if not amount or not company then
        return false
    end

    local affectedRows = MySQL.update.await('UPDATE `cj_companies` SET `balance` = `balance` - ? WHERE `id` = ? AND `balance` >= ?', {
        amount,
        company.id,
        amount
    })

    if affectedRows ~= 1 then
        return false
    end

    CJ.Cache.Remove('company:primary')
    CJ.Company.RecordTransaction(transactionType or 'debit', -amount, citizenId)
    return true
end

CJ.Callbacks.Register('cj:server:getCompanyBalance', function(source)
    if not CJ.Company.IsBoss(source) then
        return nil
    end

    return CJ.Company.GetBalance()
end)

CJ.Callbacks.Register('cj:server:ownerFinanceOperation', function(source, action, requestedAmount)
    local amount = isValidAmount(requestedAmount)
    if not CJ.Company.IsBoss(source) or not isNearOwnerDashboard(source) or (action ~= 'deposit' and action ~= 'withdraw') or not amount then
        return { ok = false, message = 'Operação inválida.' }
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    if action == 'deposit' then
        if CJ.Framework.GetMoney(source) < amount or not CJ.Framework.RemoveMoney(source, amount, 'centrojogos-company-deposit') then
            return { ok = false, message = 'Não tens dinheiro suficiente.' }
        end
        if not CJ.Finance.Credit(amount, citizenId, 'boss_deposit') then
            CJ.Framework.AddMoney(source, amount, 'centrojogos-company-deposit-refund')
            return { ok = false, message = CJ.T('general.system_error') }
        end
        CJ.Log.Discord('employees', 'Depósito na empresa', ('%s depositou €%s.'):format(GetPlayerName(source), amount))
        return { ok = true, message = ('Depositaste €%s na empresa.'):format(amount), balance = CJ.Company.GetBalance() }
    end

    if not CJ.Finance.Debit(amount, citizenId, 'boss_withdrawal') then
        return { ok = false, message = 'A empresa não tem saldo suficiente.' }
    end
    if not CJ.Framework.AddMoney(source, amount, 'centrojogos-company-withdrawal') then
        CJ.Finance.Credit(amount, citizenId, 'withdrawal_reversal')
        return { ok = false, message = CJ.T('general.system_error') }
    end
    CJ.Log.Discord('employees', 'Levantamento da empresa', ('%s levantou €%s.'):format(GetPlayerName(source), amount))
    return { ok = true, message = ('Levantaste €%s da empresa.'):format(amount), balance = CJ.Company.GetBalance() }
end)

CJ.Security.RegisterEvent('cj:server:depositCompanyFunds', function(source, requestedAmount)
    local amount = isValidAmount(requestedAmount)

    if not CJ.Company.IsBoss(source) or not amount or CJ.Framework.GetMoney(source) < amount then
        CJ.Security.Reject(source, 'cj:server:depositCompanyFunds', 'pedido inválido')
        return
    end

    if not CJ.Framework.RemoveMoney(source, amount, 'centrojogos-company-deposit') then
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Credit(amount, citizenId, 'boss_deposit') then
        CJ.Framework.AddMoney(source, amount, 'centrojogos-company-deposit-refund')
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    CJ.Framework.Notify(source, ('Depositaste €%s na conta da empresa.'):format(amount), 'success')
    CJ.Log.Discord('employees', 'Depósito na empresa', ('%s depositou €%s.'):format(GetPlayerName(source), amount))
end)

CJ.Security.RegisterEvent('cj:server:withdrawCompanyFunds', function(source, requestedAmount)
    local amount = isValidAmount(requestedAmount)

    if not CJ.Company.IsBoss(source) or not amount then
        CJ.Security.Reject(source, 'cj:server:withdrawCompanyFunds', 'pedido inválido')
        return
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    if not CJ.Finance.Debit(amount, citizenId, 'boss_withdrawal') then
        CJ.Framework.Notify(source, 'A empresa não tem saldo suficiente.', 'error')
        return
    end

    if not CJ.Framework.AddMoney(source, amount, 'centrojogos-company-withdrawal') then
        CJ.Finance.Credit(amount, citizenId, 'withdrawal_reversal')
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    CJ.Framework.Notify(source, ('Levantaste €%s da conta da empresa.'):format(amount), 'success')
    CJ.Log.Discord('employees', 'Levantamento da empresa', ('%s levantou €%s.'):format(GetPlayerName(source), amount))
end)

exports('GetCompanyBalance', CJ.Company.GetBalance)
exports('CreditCompany', CJ.Finance.Credit)
exports('DebitCompany', CJ.Finance.Debit)
