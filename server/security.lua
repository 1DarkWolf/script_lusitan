CJ = CJ or {}
CJ.Security = CJ.Security or {}

local rateLimits = {}
local registeredEvents = {}

local function getLimit(action)
    return Config.Security.EventRateLimits[action] or Config.Security.DefaultRateLimit
end

---@param source number
---@return boolean
function CJ.Security.IsValidPlayer(source)
    return type(source) == 'number' and source > 0 and CJ.Framework.GetPlayer(source) ~= nil
end

---@param source number
---@param action string
---@return boolean allowed
function CJ.Security.CheckRateLimit(source, action)
    local limit = getLimit(action)
    local key = ('%s:%s'):format(source, action)
    local now = os.time()
    local entry = rateLimits[key]

    if not entry or entry.resetAt <= now then
        rateLimits[key] = { attempts = 1, resetAt = now + limit.windowSeconds }
        return true
    end

    entry.attempts = entry.attempts + 1
    return entry.attempts <= limit.maxAttempts
end

---@param source number
---@param action string
---@param reason string
function CJ.Security.Reject(source, action, reason)
    local playerName = GetPlayerName(source) or 'desconhecido'
    local message = ('Evento bloqueado: %s (%s) — %s'):format(action, playerName, reason)

    CJ.Log.Write('warn', message)
    CJ.Log.Discord('security', 'Evento bloqueado', message, {
        { name = 'Jogador', value = ('%s (`%s`)'):format(playerName, source), inline = true },
        { name = 'Evento', value = action, inline = true }
    }, 15158332)
end

---@param eventName string
---@param handler fun(source: number, ...: any)
---@return boolean
function CJ.Security.RegisterEvent(eventName, handler)
    if not CJ.Utils.IsNonEmptyString(eventName) or type(handler) ~= 'function' then
        return false
    end

    if registeredEvents[eventName] then
        CJ.Log.Write('warn', ('Evento protegido já registado: %s'):format(eventName))
        return false
    end

    registeredEvents[eventName] = true
    RegisterNetEvent(eventName, function(...)
        local playerSource = source

        if not CJ.Security.IsValidPlayer(playerSource) then
            CJ.Security.Reject(playerSource, eventName, 'origem inválida')
            return
        end

        if not CJ.Security.CheckRateLimit(playerSource, eventName) then
            CJ.Security.Reject(playerSource, eventName, 'limite de pedidos excedido')
            return
        end

        handler(playerSource, ...)
    end)

    return true
end

AddEventHandler('playerDropped', function()
    local prefix = ('%s:'):format(source)

    for key in pairs(rateLimits) do
        if key:sub(1, #prefix) == prefix then
            rateLimits[key] = nil
        end
    end
end)

exports('IsValidPlayer', CJ.Security.IsValidPlayer)
exports('CheckRateLimit', CJ.Security.CheckRateLimit)
exports('RegisterProtectedEvent', CJ.Security.RegisterEvent)
