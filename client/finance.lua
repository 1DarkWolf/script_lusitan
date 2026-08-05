CJ = CJ or {}

local function requestAmount(title, eventName)
    local response = exports['qb-input']:ShowInput({
        header = title,
        submitText = 'Confirmar',
        inputs = {
            {
                text = 'Valor',
                name = 'amount',
                type = 'number',
                isRequired = true
            }
        }
    })

    if response and response.amount then
        TriggerServerEvent(eventName, response.amount)
    end
end

RegisterNetEvent('cj:client:openFinanceMenu', function()
    exports['qb-menu']:openMenu({
        {
            header = 'Conta da empresa',
            isMenuHeader = true
        },
        {
            header = 'Consultar saldo',
            icon = 'fas fa-wallet',
            params = {
                event = 'cj:client:showCompanyBalance'
            }
        },
        {
            header = 'Depositar',
            icon = 'fas fa-arrow-down',
            params = {
                event = 'cj:client:requestCompanyDeposit'
            }
        },
        {
            header = 'Levantar',
            icon = 'fas fa-arrow-up',
            params = {
                event = 'cj:client:requestCompanyWithdrawal'
            }
        }
    })
end)

RegisterNetEvent('cj:client:showCompanyBalance', function()
    local balance = CJ.Callbacks.Await('cj:server:getCompanyBalance')

    if balance == nil then
        CJ.Framework.Notify(CJ.T('general.no_permission'), 'error')
        return
    end

    CJ.Framework.Notify(('Saldo da empresa: €%s'):format(balance), 'primary')
end)

RegisterNetEvent('cj:client:requestCompanyDeposit', function()
    requestAmount('Depositar na conta da empresa', 'cj:server:depositCompanyFunds')
end)

RegisterNetEvent('cj:client:requestCompanyWithdrawal', function()
    requestAmount('Levantar da conta da empresa', 'cj:server:withdrawCompanyFunds')
end)
