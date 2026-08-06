CJ = CJ or {}

RegisterNetEvent('cj:client:jackpotUpdated', function(jackpot)
    SendNUIMessage({ action = 'jackpotUpdated', jackpot = jackpot })
end)
