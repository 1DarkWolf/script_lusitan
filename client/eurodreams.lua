CJ = CJ or {}

local function parseNumbers(value)
    local numbers = {}
    for token in tostring(value):gmatch('%d+') do numbers[#numbers + 1] = tonumber(token) end
    return numbers
end

RegisterNetEvent('cj:client:openEuroDreamsMenu', function()
    exports['qb-menu']:openMenu({
        { header = 'EuroDreams', isMenuHeader = true },
        { header = 'Quick Pick', txt = 'Gerar chave aleatória no servidor.', params = { event = 'cj:client:buyEuroDreamsQuickPick' } },
        { header = 'Escolher chave', txt = '6 números (1-40) e número Dream (1-5).', params = { event = 'cj:client:buyEuroDreamsManual' } }
    })
end)

RegisterNetEvent('cj:client:buyEuroDreamsQuickPick', function()
    TriggerServerEvent('cj:server:purchaseEuroDreams', { quickPick = true })
end)

RegisterNetEvent('cj:client:buyEuroDreamsManual', function()
    local response = exports['qb-input']:ShowInput({
        header = 'Chave EuroDreams', submitText = 'Comprar', inputs = {
            { text = '6 números separados por vírgulas', name = 'numbers', type = 'text', isRequired = true },
            { text = 'Número Dream', name = 'dreamNumber', type = 'number', isRequired = true }
        }
    })
    if response then TriggerServerEvent('cj:server:purchaseEuroDreams', { numbers = parseNumbers(response.numbers), dreamNumber = tonumber(response.dreamNumber) }) end
end)
