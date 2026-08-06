CJ = CJ or {}
CJ.Loyalty = CJ.Loyalty or {}

local function levelFor(points)
    local current = Config.Loyalty.levels[1]
    for _, level in ipairs(Config.Loyalty.levels) do
        if points >= level.points then current = level end
    end
    return current
end

---@param citizenId string
---@return table|nil
function CJ.Loyalty.Get(citizenId)
    if not CJ.Utils.IsNonEmptyString(citizenId) then return nil end
    MySQL.insert.await('INSERT IGNORE INTO `cj_loyalty` (`citizenid`) VALUES (?)', { citizenId })
    local rows = CJ.Database.Query('SELECT `citizenid`, `points`, `total_spent`, `total_won` FROM `cj_loyalty` WHERE `citizenid` = ? LIMIT 1', { citizenId })
    local profile = rows and rows[1] or nil
    if profile then
        profile.points, profile.total_spent, profile.total_won = tonumber(profile.points), tonumber(profile.total_spent), tonumber(profile.total_won)
        profile.level = levelFor(profile.points)
    end
    return profile
end

---@param citizenId string
---@param amount number
function CJ.Loyalty.AddPurchase(citizenId, amount)
    amount = tonumber(amount)
    if not CJ.Utils.IsNonEmptyString(citizenId) or not amount or amount <= 0 then return false end
    local points = math.floor(amount * Config.Loyalty.pointsPerCurrency)
    return MySQL.update.await([[INSERT INTO `cj_loyalty` (`citizenid`, `points`, `total_spent`) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE `points` = `points` + VALUES(`points`), `total_spent` = `total_spent` + VALUES(`total_spent`)]], { citizenId, points, amount }) ~= nil
end

---@param citizenId string
---@param amount number
function CJ.Loyalty.AddWinnings(citizenId, amount)
    amount = tonumber(amount)
    if not CJ.Utils.IsNonEmptyString(citizenId) or not amount or amount <= 0 then return false end
    return MySQL.update.await([[INSERT INTO `cj_loyalty` (`citizenid`, `total_won`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `total_won` = `total_won` + VALUES(`total_won`)]], { citizenId, amount }) ~= nil
end

CJ.Callbacks.Register('cj:server:getLoyaltyProfile', function(source)
    return CJ.Loyalty.Get(CJ.Framework.GetCitizenId(source))
end)

CJ.Callbacks.Register('cj:server:getLoyaltyRanking', function()
    return CJ.Database.Query('SELECT `citizenid`, `points`, `total_spent`, `total_won` FROM `cj_loyalty` ORDER BY `points` DESC LIMIT 20') or {}
end)

exports('GetLoyaltyProfile', CJ.Loyalty.Get)
exports('AddLoyaltyPurchase', CJ.Loyalty.AddPurchase)
exports('AddLoyaltyWinnings', CJ.Loyalty.AddWinnings)
