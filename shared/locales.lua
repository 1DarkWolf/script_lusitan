CJ = CJ or {}
CJ.Locales = CJ.Locales or {}

local function resolveKey(locale, key)
    local value = locale

    for segment in key:gmatch('[^.]+') do
        if type(value) ~= 'table' then
            return nil
        end

        value = value[segment]
    end

    return value
end

---@param key string
---@param ... any
---@return string
function CJ.T(key, ...)
    local locale = CJ.Locales[Config.Locale] or CJ.Locales.pt or {}
    local value = resolveKey(locale, key) or resolveKey(CJ.Locales.en or {}, key)

    if type(value) ~= 'string' then
        CJ.Utils.Debug(('Tradução em falta: %s'):format(key))
        return key
    end

    if select('#', ...) > 0 then
        return value:format(...)
    end

    return value
end
