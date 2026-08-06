CJ = CJ or {}

local function parseNumbers(value)
    local numbers = {}
    for token in tostring(value):gmatch('%d+') do numbers[#numbers + 1] = tonumber(token) end
    return numbers
end

RegisterNetEvent('cj:client:openTotolotoMenu', function()
    exports['qb-menu']:openMenu({
        { header = 'Totoloto', isMenuHeader = true },
        { header = 'Quick Pick', txt = 'Gerar uma chave aleatória no servidor.', params = { event = 'cj:client:buyTotolotoQuickPick' } },
        { header = 'Escolher chave', txt = '5 números (1-49) e número da sorte (1-13).', params = { event = 'cj:client:buyTotolotoManual' } }
    })
end)

RegisterNetEvent('cj:client:buyTotolotoQuickPick', function()
    TriggerServerEvent('cj:server:purchaseTotoloto', { quickPick = true })
end)

RegisterNetEvent('cj:client:buyTotolotoManual', function()
    local response = exports['qb-input']:ShowInput({
        header = 'Chave Totoloto',
        submitText = 'Comprar',
        inputs = {
            { text = '5 números separados por vírgulas', name = 'numbers', type = 'text', isRequired = true },
            { text = 'Número da sorte', name = 'luckyNumber', type = 'number', isRequired = true }
        }
    })
    if response then
        TriggerServerEvent('cj:server:purchaseTotoloto', { numbers = parseNumbers(response.numbers), luckyNumber = tonumber(response.luckyNumber) })
    end
end)
