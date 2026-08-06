Config = {}

Config.Debug = false
Config.Locale = 'pt'
Config.Framework = 'qb'
Config.MoneyType = 'bank'

Config.CompanyJob = 'centrojogos'
Config.CompanyName = 'Centro de Jogos'

Config.UseTarget = true
Config.UseOxLibNotifications = true
Config.AutoPayLimit = 5000
Config.CacheDefaultTtl = 60

Config.Company = {
    Npc = {
        model = 'a_m_y_business_01',
        coords = vector4(-47.23, -1758.67, 29.42, 50.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    Counter = {
        coords = vector3(-47.23, -1758.67, 29.42),
        distance = 2.0
    },
    Blip = {
        enabled = true,
        sprite = 500,
        colour = 2,
        scale = 0.75,
        label = 'Centro de Jogos'
    },
    OpeningHours = {
        open = 8,
        close = 23
    },
    BossMenu = {
        enabled = true,
        coords = vector3(-44.95, -1758.16, 29.42),
        distance = 1.5
    },
    Finance = {
        maxTransaction = 50000
    }
}

Config.EmployeeRoles = {
    intern = {
        grade = 0,
        label = 'Estagiário',
        permissions = { sell_games = true }
    },
    employee = {
        grade = 1,
        label = 'Funcionário',
        permissions = { sell_games = true, validate_prizes = true }
    },
    supervisor = {
        grade = 2,
        label = 'Supervisor',
        permissions = { sell_games = true, validate_prizes = true, view_sales = true, manage_stock = true, hire = true }
    },
    manager = {
        grade = 3,
        label = 'Gerente',
        permissions = {
            sell_games = true,
            validate_prizes = true,
            view_sales = true,
            withdraw_company_money = true,
            manage_stock = true,
            hire = true,
            fire = true,
            promote = true
        }
    }
}

Config.UnemployedJob = 'unemployed'
Config.UnemployedGrade = 0

Config.TicketItems = {
    draw = 'lottery_ticket',
    scratch = 'scratch_ticket'
}

Config.DrawScheduler = {
    enabled = true,
    checkInterval = 60000
}

Config.Jackpot = {
    cacheTtl = 30,
    maximumAmount = 1000000000
}

Config.ScratchCards = {
    bronze = {
        label = 'Raspadinha Bronze',
        price = 2,
        prizes = {
            { weight = 8000, amount = 0 },
            { weight = 1500, amount = 2 },
            { weight = 450, amount = 5 },
            { weight = 49, amount = 20 },
            { weight = 1, amount = 100 }
        }
    },
    silver = {
        label = 'Raspadinha Prata',
        price = 5,
        prizes = {
            { weight = 7700, amount = 0 },
            { weight = 1800, amount = 5 },
            { weight = 450, amount = 15 },
            { weight = 49, amount = 50 },
            { weight = 1, amount = 250 }
        }
    },
    gold = {
        label = 'Raspadinha Ouro',
        price = 10,
        prizes = {
            { weight = 7400, amount = 0 },
            { weight = 2100, amount = 10 },
            { weight = 450, amount = 30 },
            { weight = 49, amount = 100 },
            { weight = 1, amount = 500 }
        }
    },
    diamond = {
        label = 'Raspadinha Diamante',
        price = 20,
        prizes = {
            { weight = 7000, amount = 0 },
            { weight = 2500, amount = 20 },
            { weight = 450, amount = 75 },
            { weight = 49, amount = 250 },
            { weight = 1, amount = 1000 }
        }
    }
}

Config.Security = {
    DefaultRateLimit = {
        maxAttempts = 5,
        windowSeconds = 10
    },
    EventRateLimits = {}
}

Config.Webhooks = {
    purchases = '',
    jackpots = '',
    employees = '',
    admin = '',
    security = ''
}
