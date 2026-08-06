CJ = CJ or {}
CJ.Admin = CJ.Admin or {}

local QBCore = exports['qb-core']:GetCoreObject()

local function allowed(source)
    if source == 0 then return true end
    for _, permission in ipairs(Config.AdminPermissions) do
        if QBCore.Functions.HasPermission(source, permission) then return true end
    end
    return false
end

local function reply(source, message, kind)
    if source == 0 then print(('[%s] %s'):format(CJ.Version.Name, message))
    else CJ.Framework.Notify(source, message, kind or 'primary') end
end

local function guarded(commandName, callback)
    return function(source, args)
        if not allowed(source) then
            CJ.Security.Reject(source, 'admin_command', 'sem permissão')
            return
        end
        CJ.Log.Discord('admin', 'Comando administrativo', ('%s executou /%s %s'):format(GetPlayerName(source) or 'console', commandName, table.concat(args, ' ')))
        callback(source, args)
    end
end

RegisterCommand('drawnow', guarded('drawnow', function(source, args)
    local gameId = args[1]
    if not gameId then reply(source, 'Uso: /drawnow [jogo]', 'error'); return end
    local draw = CJ.Draws.Run(gameId, ('admin:%s:%s'):format(gameId, CJ.Utils.GenerateUUID()))
    reply(source, draw and 'Sorteio executado.' or 'Não foi possível executar o sorteio.', draw and 'success' or 'error')
end), false)

RegisterCommand('resetdraw', guarded('resetdraw', function(source, args)
    if not args[1] then reply(source, 'Uso: /resetdraw [draw_key]', 'error'); return end
    local deleted = CJ.Draws.DeleteResult(args[1])
    reply(source, deleted and 'Resultado removido.' or 'Resultado não encontrado.', deleted and 'success' or 'error')
end), false)

RegisterCommand('addjackpot', guarded('addjackpot', function(source, args)
    local amount = tonumber(args[2])
    local total = args[1] and amount and CJ.Jackpot.Add(args[1], amount)
    reply(source, total and ('Jackpot atualizado: €%s.'):format(total) or 'Uso: /addjackpot [nome] [valor]', total and 'success' or 'error')
end), false)

RegisterCommand('setjackpot', guarded('setjackpot', function(source, args)
    local success = args[1] and tonumber(args[2]) and CJ.Jackpot.Set(args[1], tonumber(args[2]))
    reply(source, success and 'Jackpot definido.' or 'Uso: /setjackpot [nome] [valor]', success and 'success' or 'error')
end), false)

RegisterCommand('resetjackpot', guarded('resetjackpot', function(source, args)
    local success = args[1] and CJ.Jackpot.Set(args[1], 0)
    reply(source, success and 'Jackpot reposto.' or 'Uso: /resetjackpot [nome]', success and 'success' or 'error')
end), false)

RegisterCommand('addmoney', guarded('addmoney', function(source, args)
    local amount = tonumber(args[1])
    local success = amount and CJ.Finance.Credit(amount, nil, 'admin_credit')
    reply(source, success and 'Saldo da empresa atualizado.' or 'Uso: /addmoney [valor]', success and 'success' or 'error')
end), false)

RegisterCommand('giveticket', guarded('giveticket', function(source, args)
    local target, ticketType, option = tonumber(args[1]), args[2], args[3]
    if ticketType ~= 'scratch' or not Config.ScratchCards[option] then
        reply(source, 'Uso: /giveticket [id] scratch [bronze|silver|gold|diamond]', 'error'); return
    end
    local ticket = CJ.Tickets.Issue(target, 'scratch', { cardId = option, prize = 0 })
    reply(source, ticket and 'Bilhete entregue.' or 'Não foi possível entregar o bilhete.', ticket and 'success' or 'error')
end), false)

RegisterCommand('removeticket', guarded('removeticket', function(source, args)
    local success = args[1] and CJ.Tickets.Cancel(args[1])
    reply(source, success and 'Bilhete cancelado.' or 'Bilhete não encontrado ou já utilizado.', success and 'success' or 'error')
end), false)

RegisterCommand('lotteryreload', guarded('lotteryreload', function(source)
    reply(source, 'A recarregar o recurso.', 'primary')
    ExecuteCommand(('restart %s'):format(GetCurrentResourceName()))
end), false)
