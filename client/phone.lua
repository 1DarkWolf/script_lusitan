CJ = CJ or {}

CreateThread(function()
    while GetResourceState('lb-phone') ~= 'started' do
        Wait(500)
    end

    Wait(500)
    local resourceName = GetCurrentResourceName()
    local success, reason = exports['lb-phone']:AddCustomApp({
        identifier = Config.LBPhone.appIdentifier,
        name = Config.LBPhone.appName,
        description = Config.LBPhone.appDescription,
        developer = Config.CompanyName,
        defaultApp = true,
        ui = 'phone/index.html',
        icon = ('https://cfx-nui-%s/%s'):format(resourceName, Config.LBPhone.appIcon),
        fixBlur = true
    })

    if not success then
        CJ.Utils.Debug(('Não foi possível registar a app LB Phone: %s'):format(reason or 'erro desconhecido'))
    end
end)

RegisterNUICallback('getLotteryResults', function(_, callback)
    callback(CJ.Callbacks.Await('cj:server:getPublishedLotteryResults') or {})
end)
