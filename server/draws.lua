CJ = CJ or {}
CJ.Draws = CJ.Draws or {}

local games = {}

local function hasScheduledDay(schedule, weekday)
    if not schedule.days or #schedule.days == 0 then
        return true
    end

    for _, day in ipairs(schedule.days) do
        if day == weekday then
            return true
        end
    end

    return false
end

local function shouldRun(schedule, time)
    return schedule.hour == time.hour and schedule.minute == time.min and hasScheduledDay(schedule, time.wday)
end

local function drawKey(gameId, time)
    return ('%s:%04d-%02d-%02d-%02d-%02d'):format(gameId, time.year, time.month, time.day, time.hour, time.min)
end

---@param gameId string
---@param definition {label: string, schedule: table, draw: fun(): table}
---@return boolean
function CJ.Draws.RegisterGame(gameId, definition)
    if not CJ.Utils.IsNonEmptyString(gameId) or type(definition) ~= 'table' or type(definition.draw) ~= 'function' then
        return false
    end

    if type(definition.schedule) ~= 'table' or type(definition.schedule.hour) ~= 'number' or type(definition.schedule.minute) ~= 'number' then
        return false
    end

    if definition.jackpot then
        if not CJ.Utils.IsNonEmptyString(definition.jackpot.name) then
            return false
        end

        if not CJ.Jackpot.Ensure(definition.jackpot.name, definition.jackpot.initialAmount) then
            return false
        end
    end

    games[gameId] = definition
    CJ.Log.Write('info', ('Jogo registado para sorteios: %s'):format(gameId))
    return true
end

---@param gameId string
---@return table|nil
function CJ.Draws.GetLatestResult(gameId)
    local rows = CJ.Database.Query([[SELECT `game_id`, `draw_key`, `result`, `drawn_at`
        FROM `cj_draw_results` WHERE `game_id` = ? ORDER BY `drawn_at` DESC LIMIT 1]], { gameId })

    if not rows or not rows[1] then
        return nil
    end

    local result = rows[1]
    result.result = json.decode(result.result) or {}
    return result
end

---@param key string
---@return table|nil
function CJ.Draws.GetResultByKey(key)
    local rows = CJ.Database.Query('SELECT `game_id`, `draw_key`, `result`, `drawn_at` FROM `cj_draw_results` WHERE `draw_key` = ? LIMIT 1', { key })
    if not rows or not rows[1] then return nil end
    rows[1].result = json.decode(rows[1].result) or {}
    return rows[1]
end

---@param key string
---@return boolean
function CJ.Draws.DeleteResult(key)
    return MySQL.update.await('DELETE FROM `cj_draw_results` WHERE `draw_key` = ?', { key }) == 1
end

---@param gameId string
---@param key string
---@return table|nil
function CJ.Draws.Run(gameId, key)
    local definition = games[gameId]
    if not definition then
        return nil
    end

    local existing = CJ.Database.Scalar('SELECT `id` FROM `cj_draw_results` WHERE `draw_key` = ? LIMIT 1', { key })
    if existing then
        return nil
    end

    local success, result = pcall(definition.draw, key)
    if not success or type(result) ~= 'table' then
        CJ.Log.Write('error', ('Falha ao gerar sorteio %s: %s'):format(gameId, result or 'resultado inválido'))
        return nil
    end

    local inserted = MySQL.insert.await([[INSERT INTO `cj_draw_results` (`game_id`, `draw_key`, `result`)
        VALUES (?, ?, ?)]], { gameId, key, json.encode(result) })
    if not inserted then
        return nil
    end

    if definition.jackpot and result.claimJackpot == true then
        local jackpotAmount = CJ.Jackpot.Claim(definition.jackpot.name)
        if not jackpotAmount then
            CJ.Log.Write('warn', ('O jogo %s assinalou um jackpot, mas não foi possível reclamá-lo.'):format(gameId))
        else
            result.jackpotAmount = jackpotAmount
            MySQL.update.await('UPDATE `cj_draw_results` SET `result` = ? WHERE `id` = ?', { json.encode(result), inserted })
        end
    end

    local payload = {
        gameId = gameId,
        label = definition.label or gameId,
        result = result
    }

    TriggerClientEvent('cj:client:drawCompleted', -1, payload)
    CJ.Log.Discord('jackpots', 'Sorteio concluído', ('O sorteio %s foi concluído.'):format(payload.label))
    return payload
end

---@param gameId string
---@return string|nil
function CJ.Draws.GetNextDrawKey(gameId)
    local definition = games[gameId]
    if not definition then return nil end

    local now = os.time()
    for offset = 0, 8 do
        local candidate = os.date('*t', now + (offset * 86400))
        if hasScheduledDay(definition.schedule, candidate.wday) then
            local scheduled = os.time({ year = candidate.year, month = candidate.month, day = candidate.day, hour = definition.schedule.hour, min = definition.schedule.minute, sec = 0 })
            if scheduled > now then
                return drawKey(gameId, os.date('*t', scheduled))
            end
        end
    end
end

local function checkSchedules()
    if not Config.DrawScheduler.enabled then
        return
    end

    local currentTime = os.date('*t')
    for gameId, definition in pairs(games) do
        if shouldRun(definition.schedule, currentTime) then
            CJ.Draws.Run(gameId, drawKey(gameId, currentTime))
        end
    end
end

local function scheduleNextCheck()
    SetTimeout(Config.DrawScheduler.checkInterval, function()
        checkSchedules()
        scheduleNextCheck()
    end)
end

CreateThread(function()
    scheduleNextCheck()
end)

CJ.Callbacks.Register('cj:server:getLatestDrawResult', function(_, gameId)
    if not CJ.Utils.IsNonEmptyString(gameId) then
        return nil
    end

    return CJ.Draws.GetLatestResult(gameId)
end)

exports('RegisterDrawGame', CJ.Draws.RegisterGame)
exports('RunDraw', CJ.Draws.Run)
exports('GetLatestDrawResult', CJ.Draws.GetLatestResult)
exports('GetDrawResultByKey', CJ.Draws.GetResultByKey)
exports('DeleteDrawResult', CJ.Draws.DeleteResult)
exports('GetNextDrawKey', CJ.Draws.GetNextDrawKey)
