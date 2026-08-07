CJ = CJ or {}
CJ.Phone = CJ.Phone or {}

local function labelForGame(gameId)
    if gameId == 'euromillions' then return Config.Euromillions.label end
    if gameId == 'totoloto' then return Config.Totoloto.label end
    if gameId == 'eurodreams' then return Config.EuroDreams.label end
    if gameId == 'joker' then return Config.Joker.label end
    return Config.Lotteries[gameId] and Config.Lotteries[gameId].label or gameId
end

---@return table[]
function CJ.Phone.GetPublishedLotteryResults()
    local rows = CJ.Database.Query([[SELECT `game_id`, `draw_key`, `result`, `drawn_at`
        FROM `cj_draw_results` WHERE `id` IN (
            SELECT `latest_id` FROM (
                SELECT MAX(`id`) AS `latest_id` FROM `cj_draw_results` GROUP BY `game_id`
            ) AS `latest_results`
        ) ORDER BY `drawn_at` DESC]]) or {}

    for _, row in ipairs(rows) do
        row.label = labelForGame(row.game_id)
        row.result = json.decode(row.result) or {}
    end

    return rows
end

CJ.Callbacks.Register('cj:server:getPublishedLotteryResults', CJ.Phone.GetPublishedLotteryResults)
exports('GetPublishedLotteryResults', CJ.Phone.GetPublishedLotteryResults)
