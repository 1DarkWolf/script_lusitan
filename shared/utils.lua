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

---@return string
function CJ.Utils.GenerateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return template:gsub('[xy]', function(character)
        local value = math.random(0, 15)
        if character == 'y' then
            value = (value % 4) + 8
        end

        return ('%x'):format(value)
    end)
end

---@return string
function CJ.Utils.GenerateToken()
    return CJ.Utils.GenerateUUID():gsub('-', '') .. CJ.Utils.GenerateUUID():gsub('-', '')
end
