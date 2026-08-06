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
