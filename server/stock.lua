CJ = CJ or {}
CJ.Stock = CJ.Stock or {}

local function validCardId(cardId)
    return type(cardId) == 'string' and Config.ScratchCards[cardId] and cardId or nil
end

local function validAmount(amount)
    amount = tonumber(amount)
    return amount and amount > 0 and amount == math.floor(amount) and amount or nil
end

local function companyId()
    local company = CJ.Company.Get()
    return company and company.id or nil
end

local function isNearOwnerDashboard(source)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end

    local npc = Config.OwnerDashboard.Npc
    local coords = GetEntityCoords(ped)
    local target = vector3(npc.coords.x, npc.coords.y, npc.coords.z)
    return #(coords - target) <= (Config.OwnerDashboard.distance + 1.5)
end

local function ensure(cardId)
    local id = companyId()
    if not id or not validCardId(cardId) then return false end
    return MySQL.insert.await([[INSERT IGNORE INTO `cj_store_stock` (`company_id`, `stock_key`, `quantity`)
        VALUES (?, ?, 0)]], { id, cardId }) ~= nil
end

---@param cardId string
---@return number
function CJ.Stock.Get(cardId)
    if not ensure(cardId) then return 0 end
    local rows = CJ.Database.Query([[SELECT `quantity` FROM `cj_store_stock`
        WHERE `company_id` = ? AND `stock_key` = ? LIMIT 1]], { companyId(), cardId })
    return rows and rows[1] and tonumber(rows[1].quantity) or 0
end

---@return table[]
function CJ.Stock.GetAll()
    local stock = {}
    for cardId, card in pairs(Config.ScratchCards) do
        stock[#stock + 1] = {
            cardId = cardId,
            label = card.label,
            quantity = CJ.Stock.Get(cardId)
        }
    end
    table.sort(stock, function(left, right) return left.label < right.label end)
    return stock
end

---@param cardId string
---@param amount number
---@return number|nil
function CJ.Stock.Add(cardId, amount)
    amount = validAmount(amount)
    if not amount or not ensure(cardId) then return nil end
    local id = companyId()
    if MySQL.update.await([[UPDATE `cj_store_stock` SET `quantity` = `quantity` + ?
        WHERE `company_id` = ? AND `stock_key` = ?]], { amount, id, cardId }) ~= 1 then
        return nil
    end
    return CJ.Stock.Get(cardId)
end

---@param cardId string
---@param amount number
---@return boolean
function CJ.Stock.Take(cardId, amount)
    amount = validAmount(amount)
    if not amount or not ensure(cardId) then return false end
    return MySQL.update.await([[UPDATE `cj_store_stock` SET `quantity` = `quantity` - ?
        WHERE `company_id` = ? AND `stock_key` = ? AND `quantity` >= ?]], { amount, companyId(), cardId, amount }) == 1
end

CJ.Security.RegisterEvent('cj:server:restockScratch', function(source, cardId, requestedAmount)
    local amount = validAmount(requestedAmount)
    local itemName = Config.ScratchStockItems[cardId]
    local player = CJ.Framework.GetPlayer(source)

    if not CJ.Company.IsBoss(source) or not isNearOwnerDashboard(source) or not amount or not itemName or not player then
        CJ.Security.Reject(source, 'cj:server:restockScratch', 'pedido de reposição inválido')
        return
    end

    local item = player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        CJ.Framework.Notify(source, 'Não tens cartões em branco suficientes.', 'error')
        return
    end

    if not player.Functions.RemoveItem(itemName, amount, false, 'centrojogos-stock-restock') then
        return
    end

    local total = CJ.Stock.Add(cardId, amount)
    if not total then
        player.Functions.AddItem(itemName, amount, false, nil, 'centrojogos-stock-restock-reversal')
        CJ.Framework.Notify(source, CJ.T('general.system_error'), 'error')
        return
    end

    CJ.Company.RecordTransaction('scratch_restock', 0, CJ.Framework.GetCitizenId(source), { cardId = cardId, quantity = amount })
    CJ.Framework.Notify(source, ('Stock de %s atualizado: %s unidades.'):format(Config.ScratchCards[cardId].label, total), 'success')
    CJ.Log.Discord('employees', 'Reposição de raspadinhas', ('%s adicionou %s unidades de %s ao stock.'):format(GetPlayerName(source), amount, Config.ScratchCards[cardId].label))
end)

exports('GetScratchStock', CJ.Stock.Get)
exports('GetAllScratchStock', CJ.Stock.GetAll)
exports('AddScratchStock', CJ.Stock.Add)
exports('TakeScratchStock', CJ.Stock.Take)
