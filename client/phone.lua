CJ = CJ or {}

local function registerResultsApp()
    if GetResourceState('lb-phone') ~= 'started' then
        return
    end

    local resourceName = GetCurrentResourceName()
    local success, reason = exports['lb-phone']:AddCustomApp({
        identifier = Config.LBPhone.appIdentifier,
        name = Config.LBPhone.appName,
        description = Config.LBPhone.appDescription,
        developer = Config.CompanyName,
        defaultApp = true,
        ui = ('%s/phone/index.html'):format(resourceName),
        icon = ('https://cfx-nui-%s/%s'):format(resourceName, Config.LBPhone.appIcon),
        fixBlur = true
    })

    if not success then
        CJ.Utils.Debug(('Não foi possível registar a app LB Phone: %s'):format(reason or 'erro desconhecido'))
    end
end

CreateThread(function()
    while GetResourceState('lb-phone') ~= 'started' do
        Wait(500)
    end

    Wait(500)
    registerResultsApp()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'lb-phone' then return end
    CreateThread(function()
        Wait(500)
        registerResultsApp()
    end)
end)

RegisterNUICallback('getLotteryResults', function(_, callback)
    callback(CJ.Callbacks.Await('cj:server:getPublishedLotteryResults') or {})
end)
