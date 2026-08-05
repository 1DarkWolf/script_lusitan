CJ = CJ or {}
CJ.Callbacks = CJ.Callbacks or {}

local registeredCallbacks = {}

---@param name string
---@param handler fun(source: number, ...: any): any
---@return boolean
function CJ.Callbacks.Register(name, handler)
    if not CJ.Utils.IsNonEmptyString(name) or type(handler) ~= 'function' then
        CJ.Utils.Debug('Tentativa de registar um callback inválido.')
        return false
    end

    if registeredCallbacks[name] then
        CJ.Utils.Debug(('Callback substituído: %s'):format(name))
    end

    registeredCallbacks[name] = true
    lib.callback.register(name, handler)
    return true
end

---@param name string
---@return boolean
function CJ.Callbacks.Exists(name)
    return registeredCallbacks[name] == true
end

exports('RegisterCallback', CJ.Callbacks.Register)
exports('CallbackExists', CJ.Callbacks.Exists)
