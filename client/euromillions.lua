CJ = CJ or {}

local function parseSelection(value)
    local values = {}
    for token in tostring(value):gmatch('%d+') do values[#values + 1] = tonumber(token) end
    return values
end

RegisterNetEvent('cj:client:openEuromillionsMenu', function()
    exports['qb-menu']:openMenu({
        { header = 'Euromilhões', isMenuHeader = true },
        { header = 'Quick Pick', txt = 'Gerar chave aleatória no servidor.', params = { event = 'cj:client:buyEuromillionsQuickPick' } },
        { header = 'Escolher chave', txt = '5 números (1-50) e 2 estrelas (1-12).', params = { event = 'cj:client:buyEuromillionsManual' } }
    })
end)

RegisterNetEvent('cj:client:buyEuromillionsQuickPick', function()
    TriggerServerEvent('cj:server:purchaseEuromillions', { quickPick = true })
end)

RegisterNetEvent('cj:client:buyEuromillionsManual', function()
    local response = exports['qb-input']:ShowInput({
        header = 'Chave Euromilhões',
        submitText = 'Comprar',
        inputs = {
            { text = '5 números separados por vírgulas', name = 'numbers', type = 'text', isRequired = true },
            { text = '2 estrelas separadas por vírgulas', name = 'stars', type = 'text', isRequired = true }
        }
    })
    if response then TriggerServerEvent('cj:server:purchaseEuromillions', { numbers = parseSelection(response.numbers), stars = parseSelection(response.stars) }) end
end)
