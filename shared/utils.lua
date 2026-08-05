CJ = CJ or {}
CJ.Utils = {}

---Writes a message only when debug mode is enabled.
---@param message string
function CJ.Utils.Debug(message)
    if Config.Debug then
        print(('[%s] %s'):format(CJ.Version.Name, message))
    end
end

---@param value any
---@return boolean
function CJ.Utils.IsNonEmptyString(value)
    return type(value) == 'string' and value:match('%S') ~= nil
end

---@param value number
---@param minimum number
---@param maximum number
---@return number
function CJ.Utils.Clamp(value, minimum, maximum)
    return math.min(math.max(value, minimum), maximum)
end
