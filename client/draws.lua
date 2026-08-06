CJ = CJ or {}

RegisterNetEvent('cj:client:drawCompleted', function(draw)
    CJ.Framework.Notify(('Resultado disponível: %s.'):format(draw.label), 'primary')
end)
