CJ = CJ or {}
CJ.Tickets = CJ.Tickets or {}

local QBCore = exports['qb-core']:GetCoreObject()

local function getTicketItemName(ticketType)
    return Config.TicketItems[ticketType]
end

---@param ticketId string
---@return table|nil
function CJ.Tickets.Get(ticketId)
    if not CJ.Utils.IsNonEmptyString(ticketId) then
        return nil
    end

    local rows = CJ.Database.Query([[SELECT `ticket_id`, `ticket_type`, `owner_citizenid`, `payload`, `signature`, `status`, `item_name`, `created_at`
        FROM `cj_tickets` WHERE `ticket_id` = ? LIMIT 1]], { ticketId })

    return rows and rows[1] or nil
end

---@param source number
---@param ticket table
---@return table|nil
function CJ.Tickets.FindInventoryItem(source, ticket)
    local player = CJ.Framework.GetPlayer(source)
    if not player then
        return nil
    end

    for _, item in pairs(player.PlayerData.items or {}) do
        local info = item.info or {}
        if item.name == ticket.item_name and info.ticket_id == ticket.ticket_id and info.signature == ticket.signature then
            return item
        end
    end

    return nil
end

---@param source number
---@param ticketId string
---@return table|nil
function CJ.Tickets.ValidateOwnership(source, ticketId)
    local ticket = CJ.Tickets.Get(ticketId)
    local citizenId = CJ.Framework.GetCitizenId(source)

    if not ticket or ticket.status ~= 'issued' or ticket.owner_citizenid ~= citizenId then
        return nil
    end

    return CJ.Tickets.FindInventoryItem(source, ticket) and ticket or nil
end

---@param source number
---@param ticketType string
---@param payload table
---@return table|nil
function CJ.Tickets.Issue(source, ticketType, payload)
    if not CJ.Security.IsValidPlayer(source) or not getTicketItemName(ticketType) or type(payload) ~= 'table' then
        return nil
    end

    local citizenId = CJ.Framework.GetCitizenId(source)
    local itemName = getTicketItemName(ticketType)
    local ticketId = CJ.Utils.GenerateUUID()
    local signature = CJ.Utils.GenerateToken()
    local created = MySQL.insert.await([[INSERT INTO `cj_tickets` (`ticket_id`, `ticket_type`, `owner_citizenid`, `payload`, `signature`, `item_name`)
        VALUES (?, ?, ?, ?, ?, ?)]], {
        ticketId,
        ticketType,
        citizenId,
        json.encode(payload),
        signature,
        itemName
    })

    if not created then
        CJ.Log.Write('error', 'Não foi possível criar um bilhete na base de dados.')
        return nil
    end

    local metadata = {
        ticket_id = ticketId,
        signature = signature,
        ticket_type = ticketType,
        description = ('Bilhete %s'):format(ticketId:sub(1, 8))
    }

    local player = CJ.Framework.GetPlayer(source)
    if not player or not player.Functions.AddItem(itemName, 1, false, metadata, 'centrojogos-ticket-issue') then
        MySQL.update.await('UPDATE `cj_tickets` SET `status` = ? WHERE `ticket_id` = ?', { 'cancelled', ticketId })
        return nil
    end

    return CJ.Tickets.Get(ticketId)
end

---@param source number
---@param ticketId string
---@return table|nil
function CJ.Tickets.Consume(source, ticketId)
    local ticket = CJ.Tickets.ValidateOwnership(source, ticketId)
    if not ticket then
        return nil
    end

    local item = CJ.Tickets.FindInventoryItem(source, ticket)
    local affectedRows = MySQL.update.await([[UPDATE `cj_tickets` SET `status` = 'redeemed', `redeemed_at` = CURRENT_TIMESTAMP
        WHERE `ticket_id` = ? AND `status` = 'issued']], { ticketId })

    if affectedRows ~= 1 then
        return nil
    end

    local player = CJ.Framework.GetPlayer(source)
    if not player.Functions.RemoveItem(ticket.item_name, 1, item.slot, 'centrojogos-ticket-consume') then
        MySQL.update.await('UPDATE `cj_tickets` SET `status` = ? WHERE `ticket_id` = ?', { 'issued', ticketId })
        return nil
    end

    ticket.status = 'redeemed'
    return ticket
end

---@param source number
---@param ticket table
---@return boolean
function CJ.Tickets.Restore(source, ticket)
    local player = CJ.Framework.GetPlayer(source)
    if not player or not ticket or ticket.status ~= 'redeemed' then
        return false
    end

    local metadata = {
        ticket_id = ticket.ticket_id,
        signature = ticket.signature,
        ticket_type = ticket.ticket_type,
        description = ('Bilhete %s'):format(ticket.ticket_id:sub(1, 8))
    }

    if not player.Functions.AddItem(ticket.item_name, 1, false, metadata, 'centrojogos-ticket-restore') then
        return false
    end

    local affectedRows = MySQL.update.await([[UPDATE `cj_tickets` SET `status` = 'issued', `redeemed_at` = NULL
        WHERE `ticket_id` = ? AND `status` = 'redeemed']], { ticket.ticket_id })
    return affectedRows == 1
end

---@param ticketId string
---@return boolean
function CJ.Tickets.Cancel(ticketId)
    return MySQL.update.await([[UPDATE `cj_tickets` SET `status` = 'cancelled'
        WHERE `ticket_id` = ? AND `status` = 'issued']], { ticketId }) == 1
end

local function registerUsableTicket(itemName)
    QBCore.Functions.CreateUseableItem(itemName, function(source, item)
        local metadata = item.info or {}
        local ticket = CJ.Tickets.ValidateOwnership(source, metadata.ticket_id)

        if not ticket or ticket.signature ~= metadata.signature then
            CJ.Security.Reject(source, 'ticket_use', 'bilhete inválido ou sem posse')
            CJ.Framework.Notify(source, 'Este bilhete não é válido.', 'error')
            return
        end

        local payload = json.decode(ticket.payload) or {}
        if ticket.ticket_type == 'scratch' then
            payload = { cardId = payload.cardId }
        end

        TriggerClientEvent('cj:client:openTicket', source, {
            ticketId = ticket.ticket_id,
            ticketType = ticket.ticket_type,
            payload = payload,
            createdAt = ticket.created_at
        })
    end)
end

CreateThread(function()
    for _, itemName in pairs(Config.TicketItems) do
        registerUsableTicket(itemName)
    end
end)

exports('IssueTicket', CJ.Tickets.Issue)
exports('GetTicket', CJ.Tickets.Get)
exports('ValidateTicketOwnership', CJ.Tickets.ValidateOwnership)
exports('ConsumeTicket', CJ.Tickets.Consume)
exports('RestoreTicket', CJ.Tickets.Restore)
exports('CancelTicket', CJ.Tickets.Cancel)
