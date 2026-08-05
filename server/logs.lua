CJ = CJ or {}
CJ.Log = CJ.Log or {}

local levels = {
    info = 'INFO',
    warn = 'WARN',
    error = 'ERROR',
    debug = 'DEBUG'
}

local colours = {
    info = 3447003,
    warn = 15844367,
    error = 15158332
}

---@param level 'info'|'warn'|'error'|'debug'
---@param message string
function CJ.Log.Write(level, message)
    level = levels[level] and level or 'info'

    if level ~= 'debug' or Config.Debug then
        print(('[%s] [%s] %s'):format(CJ.Version.Name, levels[level], message))
    end
end

---@param channel string
---@param title string
---@param description string
---@param fields? table[]
---@param colour? number
function CJ.Log.Discord(channel, title, description, fields, colour)
    local webhook = Config.Webhooks[channel]

    if not CJ.Utils.IsNonEmptyString(webhook) then
        CJ.Log.Write('debug', ('Webhook não configurado: %s'):format(channel))
        return false
    end

    local payload = {
        username = CJ.Version.Name,
        embeds = {
            {
                title = title,
                description = description,
                color = colour or colours.info,
                fields = fields or {},
                footer = { text = ('v%s'):format(CJ.Version.Version) },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    }

    PerformHttpRequest(webhook, function(statusCode)
        if statusCode < 200 or statusCode >= 300 then
            CJ.Log.Write('warn', ('Falha ao enviar webhook "%s" (HTTP %s).'):format(channel, statusCode))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })

    return true
end

exports('Log', CJ.Log.Write)
exports('DiscordLog', CJ.Log.Discord)
