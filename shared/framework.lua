CJ = CJ or {}
CJ.Framework = {}

local QBCore = exports['qb-core']:GetCoreObject()

if IsDuplicityVersion() then
    ---@param source number
    ---@return table|nil
    function CJ.Framework.GetPlayer(source)
        return QBCore.Functions.GetPlayer(source)
    end

    ---@param source number
    ---@return string|nil
    function CJ.Framework.GetCitizenId(source)
        local player = CJ.Framework.GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end

    ---@param source number
    ---@param moneyType? string
    ---@return number
    function CJ.Framework.GetMoney(source, moneyType)
        local player = CJ.Framework.GetPlayer(source)
        return player and player.PlayerData.money[moneyType or Config.MoneyType] or 0
    end

    ---@param source number
    ---@param amount number
    ---@param reason string
    ---@param moneyType? string
    ---@return boolean
    function CJ.Framework.RemoveMoney(source, amount, reason, moneyType)
        local player = CJ.Framework.GetPlayer(source)
        return player and player.Functions.RemoveMoney(moneyType or Config.MoneyType, amount, reason) or false
    end

    ---@param source number
    ---@param amount number
    ---@param reason string
    ---@param moneyType? string
    ---@return boolean
    function CJ.Framework.AddMoney(source, amount, reason, moneyType)
        local player = CJ.Framework.GetPlayer(source)
        return player and player.Functions.AddMoney(moneyType or Config.MoneyType, amount, reason) or false
    end

    ---@param source number
    ---@param message string
    ---@param notificationType? string
    ---@param duration? number
    function CJ.Framework.Notify(source, message, notificationType, duration)
        TriggerClientEvent('QBCore:Notify', source, message, notificationType or 'primary', duration or 5000)
    end
else
    ---@return table
    function CJ.Framework.GetPlayerData()
        return QBCore.Functions.GetPlayerData()
    end

    ---@param message string
    ---@param notificationType? string
    ---@param duration? number
    function CJ.Framework.Notify(message, notificationType, duration)
        QBCore.Functions.Notify(message, notificationType or 'primary', duration or 5000)
    end
end
