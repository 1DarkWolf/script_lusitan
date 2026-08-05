CJ = CJ or {}
CJ.Company = CJ.Company or {}

local companyCacheKey = 'company:primary'

---@return table|nil
function CJ.Company.Get()
    return CJ.Cache.GetOrSet(companyCacheKey, function()
        local rows = CJ.Database.Query('SELECT `id`, `name`, `balance` FROM `cj_companies` WHERE `name` = ? LIMIT 1', {
            Config.CompanyName
        })

        return rows and rows[1] or nil
    end, Config.CacheDefaultTtl)
end

---@return number
function CJ.Company.GetBalance()
    local company = CJ.Company.Get()
    return company and tonumber(company.balance) or 0
end

---@param source number
---@return boolean
function CJ.Company.IsBoss(source)
    local player = CJ.Framework.GetPlayer(source)
    local job = player and player.PlayerData.job
    return job and job.name == Config.CompanyJob and job.isboss == true or false
end

---@param transactionType string
---@param amount number
---@param citizenId? string
---@param metadata? table
function CJ.Company.RecordTransaction(transactionType, amount, citizenId, metadata)
    local company = CJ.Company.Get()
    if not company then
        return false
    end

    return MySQL.insert.await([[INSERT INTO `cj_transactions` (`company_id`, `citizenid`, `type`, `amount`, `metadata`)
        VALUES (?, ?, ?, ?, ?)]], {
        company.id,
        citizenId,
        transactionType,
        amount,
        metadata and json.encode(metadata) or nil
    }) ~= nil
end
