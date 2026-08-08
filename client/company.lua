CJ = CJ or {}
CJ.Company = CJ.Company or {}

local QBCore = exports['qb-core']:GetCoreObject()
local vendorPeds = {}

local function notifyClosed()
    CJ.Framework.Notify(('O %s está fechado neste momento.'):format(Config.CompanyName), 'error')
end

local function canOpenBossMenu()
    local playerData = QBCore.Functions.GetPlayerData()
    return playerData.job and playerData.job.name == Config.CompanyJob and playerData.job.isboss == true
end

local function openBossMenu()
    if not canOpenBossMenu() then
        CJ.Framework.Notify(CJ.T('general.no_permission'), 'error')
        return
    end

    if GetResourceState('qb-management') ~= 'started' then
        CJ.Framework.Notify('O recurso qb-management não está disponível.', 'error')
        return
    end

    TriggerEvent('qb-bossmenu:client:OpenMenu')
end

local function openCompanyTerminal()
    if not CJ.Callbacks.Await('cj:server:isCompanyOpen') then
        notifyClosed()
        return
    end

    exports['qb-menu']:openMenu({
        {
            header = Config.CompanyName,
            isMenuHeader = true
        },
        {
            header = 'Abrir painel de apostas',
            txt = 'Comprar jogos, consultar bilhetes e resultados.',
            icon = 'fas fa-display',
            params = { event = 'cj:client:openDashboard' }
        },
        {
            header = 'Raspadinhas',
            txt = 'Compra uma raspadinha e descobre o teu prémio.',
            icon = 'fas fa-ticket',
            params = { event = 'cj:client:openScratchMenu' }
        },
        {
            header = 'Euromilhões',
            txt = 'Escolhe a tua chave ou usa Quick Pick.',
            icon = 'fas fa-star',
            params = { event = 'cj:client:openEuromillionsMenu' }
        },
        {
            header = 'Totoloto',
            txt = 'Escolhe cinco números e o número da sorte.',
            icon = 'fas fa-circle-dot',
            params = { event = 'cj:client:openTotolotoMenu' }
        },
        {
            header = 'EuroDreams',
            txt = 'Escolhe seis números e o número Dream.',
            icon = 'fas fa-moon',
            params = { event = 'cj:client:openEuroDreamsMenu' }
        },
        {
            header = 'Joker',
            txt = 'Compra um código Joker para o próximo sorteio.',
            icon = 'fas fa-hashtag',
            params = { event = 'cj:client:buyJoker' }
        },
        {
            header = 'Lotarias',
            txt = 'Lotaria Clássica, Popular e Instantânea.',
            icon = 'fas fa-clover',
            params = { event = 'cj:client:openLotteriesMenu' }
        },
        {
            header = 'Levantar prémios',
            txt = 'Apresenta no balcão os bilhetes de sorteios já realizados.',
            icon = 'fas fa-money-bill-wave',
            params = { event = 'cj:client:openPrizeClaimMenu' }
        },
        {
            header = 'Fechar',
            params = { event = 'qb-menu:client:closeMenu' }
        }
    })
end

local claimEvents = {
    euromillions = 'cj:server:checkEuromillionsTicket',
    totoloto = 'cj:server:checkTotolotoTicket',
    eurodreams = 'cj:server:checkEuroDreamsTicket',
    joker = 'cj:server:checkJokerTicket',
    classic = 'cj:server:checkLotteryTicket',
    popular = 'cj:server:checkLotteryTicket',
    instant = 'cj:server:checkLotteryTicket'
}

RegisterNetEvent('cj:client:openPrizeClaimMenu', function()
    local tickets = CJ.Callbacks.Await('cj:server:getClaimableTickets') or {}
    if #tickets == 0 then
        CJ.Framework.Notify('Não tens bilhetes prontos para levantamento.', 'primary')
        return
    end

    local menu = {
        { header = 'Levantar prémios', isMenuHeader = true }
    }

    for _, ticket in ipairs(tickets) do
        menu[#menu + 1] = {
            header = ticket.label,
            txt = ('Bilhete #%s'):format(ticket.ticketId:sub(1, 8)),
            icon = 'fas fa-ticket',
            params = {
                event = 'cj:client:claimPrizeTicket',
                args = ticket
            }
        }
    end

    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('cj:client:claimPrizeTicket', function(ticket)
    local eventName = ticket and claimEvents[ticket.game]
    if eventName and ticket.ticketId then
        TriggerServerEvent(eventName, ticket.ticketId)
    end
end)

local function addVendorTarget(ped, seller)
    if not Config.UseTarget then
        return
    end

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                icon = 'fas fa-ticket',
                label = ('Falar com %s'):format(seller.label),
                action = openCompanyTerminal
            }
        },
        distance = seller.distance
    })
end

local function addBossTargets()
    if not Config.UseTarget then return end
    if Config.Company.BossMenu.enabled then
        exports['qb-target']:AddBoxZone('cj_boss_menu', Config.Company.BossMenu.coords, 1.0, 1.0, {
            name = 'cj_boss_menu',
            heading = Config.Company.Npc.coords.w,
            debugPoly = Config.Debug,
            minZ = Config.Company.BossMenu.coords.z - 1.0,
            maxZ = Config.Company.BossMenu.coords.z + 1.0
        }, {
            options = {
                {
                    icon = 'fas fa-briefcase',
                    label = 'Gestão da empresa',
                    canInteract = canOpenBossMenu,
                    action = openBossMenu
                },
                {
                    icon = 'fas fa-wallet',
                    label = 'Conta da empresa',
                    canInteract = canOpenBossMenu,
                    action = function()
                        TriggerEvent('cj:client:openFinanceMenu')
                    end
                },
                {
                    icon = 'fas fa-users',
                    label = 'Gestão de empregados',
                    canInteract = function()
                        return CJ.EmployeesCanManage()
                    end,
                    action = function()
                        TriggerEvent('cj:client:openEmployeeMenu')
                    end
                }
            },
            distance = Config.Company.BossMenu.distance
        })
    end
end

local function createBlip(seller)
    if not seller.Blip or not seller.Blip.enabled then
        return
    end

    local coords = seller.Npc.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, seller.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, seller.Blip.scale)
    SetBlipColour(blip, seller.Blip.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(seller.Blip.label or seller.label)
    EndTextCommandSetBlipName(blip)
end

CreateThread(function()
    for _, seller in ipairs(Config.Sellers) do
        local npc = seller.Npc
        lib.requestModel(npc.model)

        local ped = CreatePed(0, joaat(npc.model), npc.coords.x, npc.coords.y, npc.coords.z - 1.0, npc.coords.w, false, false)
        vendorPeds[#vendorPeds + 1] = ped
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        TaskStartScenarioInPlace(ped, npc.scenario, 0, true)

        addVendorTarget(ped, seller)
        createBlip(seller)
    end

    addBossTargets()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(vendorPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
