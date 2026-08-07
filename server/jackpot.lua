CJ = CJ or {}
CJ.Jackpot = CJ.Jackpot or {}

local function cacheKey(name)
    return ('jackpot:%s'):format(name)
end

local function isValidAmount(amount)
    amount = tonumber(amount)
    return amount and amount > 0 and amount == math.floor(amount) and amount <= Config.Jackpot.maximumAmount and amount or nil
end

local function isActive(jackpot)
    return jackpot and (jackpot.is_active == true or tonumber(jackpot.is_active) == 1)
end

---@param name string
---@param initialAmount? number
---@return table|nil
function CJ.Jackpot.Ensure(name, initialAmount)
    if not CJ.Utils.IsNonEmptyString(name) then
        return nil
    end

    local company = CJ.Company.Get()
    if not company then
        return nil
    end

    MySQL.insert.await([[INSERT IGNORE INTO `cj_jackpots` (`company_id`, `name`, `amount`)
        VALUES (?, ?, ?)]], { company.id, name, tonumber(initialAmount) or 0 })

    return CJ.Jackpot.Get(name, true)
end

---@param name string
---@param forceRefresh? boolean
---@return table|nil
function CJ.Jackpot.Get(name, forceRefresh)
    if not CJ.Utils.IsNonEmptyString(name) then
        return nil
    end

    local key = cacheKey(name)
    if not forceRefresh then
        local cached = CJ.Cache.Get(key)
        if cached then
            return cached
        end
    end

    local company = CJ.Company.Get()
    if not company then
        return nil
    end

    local rows = CJ.Database.Query([[SELECT `id`, `name`, `amount`, `is_active`, `updated_at`
        FROM `cj_jackpots` WHERE `company_id` = ? AND `name` = ? LIMIT 1]], { company.id, name })
    local jackpot = rows and rows[1] or nil

    if jackpot then
        jackpot.amount = tonumber(jackpot.amount)
        CJ.Cache.Set(key, jackpot, Config.Jackpot.cacheTtl)
    end

    return jackpot
end

---@param name string
---@param amount number
---@return number|nil
function CJ.Jackpot.Add(name, amount)
    amount = isValidAmount(amount)
    local jackpot = CJ.Jackpot.Ensure(name)
    if not amount or not isActive(jackpot) then
        return nil
    end

    local affectedRows = MySQL.update.await([[UPDATE `cj_jackpots` SET `amount` = `amount` + ?
        WHERE `id` = ? AND `amount` + ? <= ?]], { amount, jackpot.id, amount, Config.Jackpot.maximumAmount })
    if affectedRows ~= 1 then
        return nil
    end

    local updated = CJ.Jackpot.Get(name, true)
    TriggerClientEvent('cj:client:jackpotUpdated', -1, { name = name, amount = updated.amount })
    return updated.amount
end

---@param name string
---@return number|nil
function CJ.Jackpot.Claim(name)
    local jackpot = CJ.Jackpot.Get(name, true)
    if not isActive(jackpot) or jackpot.amount <= 0 then
        return nil
    end

    local amount = jackpot.amount
    local affectedRows = MySQL.update.await([[UPDATE `cj_jackpots` SET `amount` = 0
        WHERE `id` = ? AND `amount` = ? AND `is_active` = 1]], { jackpot.id, amount })
    if affectedRows ~= 1 then
        return nil
    end

    CJ.Cache.Remove(cacheKey(name))
    TriggerClientEvent('cj:client:jackpotUpdated', -1, { name = name, amount = 0 })
    CJ.Log.Discord('jackpots', 'Jackpot atribuído', ('O jackpot %s de €%s foi atribuído.'):format(name, amount))
    return amount
end

---@param name string
---@param amount number
---@return boolean
function CJ.Jackpot.Set(name, amount)
    amount = tonumber(amount)
    local jackpot = CJ.Jackpot.Ensure(name)
    if not jackpot or not amount or amount < 0 or amount > Config.Jackpot.maximumAmount or amount ~= math.floor(amount) then
        return false
    end

    local affectedRows = MySQL.update.await('UPDATE `cj_jackpots` SET `amount` = ? WHERE `id` = ?', { amount, jackpot.id })
    if affectedRows ~= 1 then
        return false
    end

    CJ.Cache.Remove(cacheKey(name))
    TriggerClientEvent('cj:client:jackpotUpdated', -1, { name = name, amount = amount })
    return true
end

CJ.Callbacks.Register('cj:server:getJackpot', function(_, name)
    return CJ.Jackpot.Get(name)
end)

exports('EnsureJackpot', CJ.Jackpot.Ensure)
exports('GetJackpot', CJ.Jackpot.Get)
exports('AddToJackpot', CJ.Jackpot.Add)
exports('ClaimJackpot', CJ.Jackpot.Claim)
exports('SetJackpot', CJ.Jackpot.Set)
