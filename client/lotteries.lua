CJ = CJ or {}

RegisterNetEvent('cj:client:openLotteriesMenu', function()
    local menu = { { header = 'Lotarias', isMenuHeader = true } }
    for gameId, lottery in pairs(Config.Lotteries) do
        menu[#menu + 1] = {
            header = lottery.label,
            txt = ('€%s'):format(lottery.price),
            params = { event = 'cj:client:buyLottery', args = { gameId = gameId } }
        }
    end
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('cj:client:buyLottery', function(data)
    TriggerServerEvent('cj:server:purchaseLottery', data.gameId)
end)
