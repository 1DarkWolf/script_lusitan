CJ = CJ or {}
CJ.Database = CJ.Database or {}
CJ.Cache = CJ.Cache or {}

local preparedQueries = {}
local cache = {}

local function isExpired(entry)
    return entry.expiresAt ~= nil and entry.expiresAt <= os.time()
end

---@param name string
---@param query string
---@return boolean
function CJ.Database.Prepare(name, query)
    if not CJ.Utils.IsNonEmptyString(name) or not CJ.Utils.IsNonEmptyString(query) then
        CJ.Utils.Debug('Tentativa de registar uma query preparada inválida.')
        return false
    end

    preparedQueries[name] = query
    return true
end

---@param name string
---@param parameters? table
---@return table|number|nil
function CJ.Database.Execute(name, parameters)
    local query = preparedQueries[name]

    if not query then
        CJ.Utils.Debug(('Query preparada não encontrada: %s'):format(name))
        return nil
    end

    return MySQL.prepare.await(query, parameters or {})
end

---@param query string
---@param parameters? table
---@return table|nil
function CJ.Database.Query(query, parameters)
    if not CJ.Utils.IsNonEmptyString(query) then
        return nil
    end

    return MySQL.query.await(query, parameters or {})
end

---@param query string
---@param parameters? table
---@return any
function CJ.Database.Scalar(query, parameters)
    if not CJ.Utils.IsNonEmptyString(query) then
        return nil
    end

    return MySQL.scalar.await(query, parameters or {})
end

---@param key string
---@param value any
---@param ttlSeconds? number
function CJ.Cache.Set(key, value, ttlSeconds)
    if not CJ.Utils.IsNonEmptyString(key) then
        return
    end

    ttlSeconds = tonumber(ttlSeconds) or Config.CacheDefaultTtl

    cache[key] = {
        value = value,
        expiresAt = os.time() + math.max(1, ttlSeconds)
    }
end

---@param key string
---@return any
function CJ.Cache.Get(key)
    local entry = cache[key]

    if not entry then
        return nil
    end

    if isExpired(entry) then
        cache[key] = nil
        return nil
    end

    return entry.value
end

---@param key string
---@param loader fun(): any
---@param ttlSeconds? number
---@return any
function CJ.Cache.GetOrSet(key, loader, ttlSeconds)
    local value = CJ.Cache.Get(key)

    if value ~= nil then
        return value
    end

    if type(loader) ~= 'function' then
        return nil
    end

    value = loader()
    if value ~= nil then
        CJ.Cache.Set(key, value, ttlSeconds)
    end

    return value
end

---@param key string
function CJ.Cache.Remove(key)
    cache[key] = nil
end

function CJ.Cache.Clear()
    cache = {}
end

exports('PrepareQuery', CJ.Database.Prepare)
exports('ExecutePreparedQuery', CJ.Database.Execute)
exports('QueryDatabase', CJ.Database.Query)
exports('GetCache', CJ.Cache.Get)
exports('SetCache', CJ.Cache.Set)
exports('RemoveCache', CJ.Cache.Remove)
