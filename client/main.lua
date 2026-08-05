CJ = CJ or {}

CreateThread(function()
    CJ.Utils.Debug(('Cliente iniciado (v%s)'):format(CJ.Version.Version))
end)

exports('GetVersion', function()
    return CJ.Version
end)

exports('Notify', CJ.Framework.Notify)
