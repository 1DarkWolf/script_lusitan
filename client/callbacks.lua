CJ = CJ or {}
CJ.Callbacks = CJ.Callbacks or {}

---@param name string
---@param ... any
---@return any
function CJ.Callbacks.Await(name, ...)
    if not CJ.Utils.IsNonEmptyString(name) then
        CJ.Utils.Debug('Tentativa de executar um callback inválido.')
        return nil
    end

    return lib.callback.await(name, false, ...)
end

---@param name string
---@param callback fun(...: any)
---@param ... any
function CJ.Callbacks.Call(name, callback, ...)
    if not CJ.Utils.IsNonEmptyString(name) or type(callback) ~= 'function' then
        CJ.Utils.Debug('Tentativa de executar um callback inválido.')
        return
    end

    lib.callback(name, false, callback, ...)
end

exports('AwaitCallback', CJ.Callbacks.Await)
exports('CallCallback', CJ.Callbacks.Call)
