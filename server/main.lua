CJ = CJ or {}

CreateThread(function()
    CJ.Log.Write('info', ('v%s: %s'):format(CJ.Version.Version, CJ.T('general.resource_started')))
end)

exports('GetVersion', function()
    return CJ.Version
end)

exports('GetPlayerBySource', CJ.Framework.GetPlayer)
exports('GetCitizenId', CJ.Framework.GetCitizenId)
exports('Notify', CJ.Framework.Notify)
