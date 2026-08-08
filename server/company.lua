CJ = CJ or {}
CJ.Company = CJ.Company or {}

local companyCacheKey = 'company:primary'

---@return boolean
function CJ.Company.IsOpen()
    local hour = os.date('*t').hour
    local openingHours = Config.Company.OpeningHours
    if openingHours.open < openingHours.close then
        return hour >= openingHours.open and hour < openingHours.close
    end
    return hour >= openingHours.open or hour < openingHours.close
end

---@param source number
---@return table|nil
function CJ.Company.GetNearbySeller(source)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then
        return nil
    end

    local coords = GetEntityCoords(ped)
    for _, seller in ipairs(Config.Sellers or {}) do
        local npc = seller.Npc
        local distance = tonumber(seller.distance) or Config.Company.Counter.distance
        if npc and npc.coords and seller.id and #(coords - vector3(npc.coords.x, npc.coords.y, npc.coords.z)) <= (distance + 1.5) then
            return seller
        end
    end

    return nil
end

---@param source number
---@return boolean
function CJ.Company.IsNearCounter(source)
    return CJ.Company.GetNearbySeller(source) ~= nil
end

---@param source number
---@return table|nil
function CJ.Company.GetSellerMetadata(source)
    local seller = CJ.Company.GetNearbySeller(source)
    if not seller then return nil end
    return { sellerId = seller.id, sellerLabel = seller.label }
end

CJ.Callbacks.Register('cj:server:isCompanyOpen', function()
    return CJ.Company.IsOpen()
end)

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
