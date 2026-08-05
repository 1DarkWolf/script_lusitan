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
