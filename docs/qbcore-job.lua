-- Adicione esta definição em qb-core/shared/jobs.lua e reinicie qb-core.
QBShared.Jobs['centrojogos'] = {
    label = 'Centro de Jogos',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'intern', label = 'Estagiário', payment = 30 },
        ['1'] = { name = 'employee', label = 'Funcionário', payment = 45 },
        ['2'] = { name = 'supervisor', label = 'Supervisor', payment = 60 },
        ['3'] = { name = 'manager', label = 'Gerente', payment = 80, isboss = true }
    }
}
