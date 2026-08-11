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
-- Prémios acima deste valor ficam pendentes para aprovação de um funcionário.
-- É também o limite máximo que uma raspadinha pode atribuir.
Config.ScratchMaximumPrize = 90000
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
        open = 0,
        close = 23
    },
    BossMenu = {
        enabled = true,
        coords = vector3(-44.95, -1758.16, 29.42),
        distance = 1.5
    },
    Finance = {
        maxTransaction = 50000,
        -- Limite interno para pagamentos de prémios; não altera o limite de levantamentos do patrão.
        maxPrizeTransaction = 1000000000
    }
}

-- Adicione ou remova estabelecimentos nesta lista. Cada NPC vende todos os jogos
-- e as respetivas vendas aparecem separadamente no dashboard do dono.
Config.Sellers = {
    {
        id = 'loja_central',
        label = 'Centro de Jogos - Loja Central',
        Npc = Config.Company.Npc,
        distance = Config.Company.Counter.distance,
        Blip = Config.Company.Blip
    },
    -- Exemplo para uma segunda loja:
    -- {
    --     id = 'loja_praia',
    --     label = 'Centro de Jogos - Praia',
    --     Npc = { model = 'a_f_y_business_01', coords = vector4(-1200.0, -1500.0, 4.4, 120.0), scenario = 'WORLD_HUMAN_CLIPBOARD' },
    --     distance = 2.0,
    --     Blip = { enabled = true, sprite = 500, colour = 2, scale = 0.75, label = 'Centro de Jogos - Praia' }
    -- }
}

-- No Lua, domingo corresponde a 1 em os.date('*t').wday. O relatório é enviado
-- uma vez por semana e o respetivo estado mantém-se mesmo após reinícios.
Config.WeeklySalesReport = {
    enabled = true,
    day = 1,
    hour = 23,
    minute = 5
}

Config.OwnerDashboard = {
    Npc = {
        model = 'a_m_y_business_01',
        coords = vector4(-44.5937, -1754.9481, 29.4210, 101.3066),
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    distance = 2.0
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
    -- Mantém o item antigo para raspadinhas já emitidas antes desta atualização.
    scratch = 'scratch_ticket',
    scratch_bronze = 'scratch_bronze_ticket',
    scratch_silver = 'scratch_silver_ticket',
    scratch_gold = 'scratch_gold_ticket',
    scratch_diamond = 'scratch_diamond_ticket',
    euromillions = 'euromillions_ticket',
    totoloto = 'totoloto_ticket',
    eurodreams = 'eurodreams_ticket',
    joker = 'joker_ticket',
    classic = 'lottery_classic_ticket',
    popular = 'lottery_popular_ticket',
    instant = 'lottery_instant_ticket',

    -- Mantém os bilhetes antigos utilizáveis depois da atualização.
    legacy_draw = 'lottery_ticket'
}

Config.LBPhone = {
    appIdentifier = 'centrojogos-results',
    appName = 'Resultados',
    appDescription = 'Resultados oficiais do Centro de Jogos.',
    appIcon = 'phone/icon.svg'
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
    -- Os pesos de cada categoria somam 10.000. O retorno médio é 55% do preço,
    -- deixando uma margem esperada de 45% para a empresa no longo prazo.
    bronze = {
        label = 'Raspadinha Bronze',
        price = 100,
        prizes = {
            { weight = 5045, amount = 0 },
            { weight = 2700, amount = 50 },
            { weight = 1500, amount = 100 },
            { weight = 500, amount = 200 },
            { weight = 200, amount = 500 },
            { weight = 50, amount = 1000 },
            { weight = 5, amount = 3000 }
        }
    },
    silver = {
        label = 'Raspadinha Prata',
        price = 500,
        prizes = {
            { weight = 5045, amount = 0 },
            { weight = 2700, amount = 250 },
            { weight = 1500, amount = 500 },
            { weight = 500, amount = 1000 },
            { weight = 200, amount = 2500 },
            { weight = 50, amount = 5000 },
            { weight = 5, amount = 15000 }
        }
    },
    gold = {
        label = 'Raspadinha Ouro',
        price = 1000,
        prizes = {
            { weight = 5045, amount = 0 },
            { weight = 2700, amount = 500 },
            { weight = 1500, amount = 1000 },
            { weight = 500, amount = 2000 },
            { weight = 200, amount = 5000 },
            { weight = 50, amount = 10000 },
            { weight = 5, amount = 30000 }
        }
    },
    diamond = {
        label = 'Raspadinha Diamante',
        price = 3000,
        prizes = {
            { weight = 5045, amount = 0 },
            { weight = 2700, amount = 1500 },
            { weight = 1500, amount = 3000 },
            { weight = 500, amount = 6000 },
            { weight = 200, amount = 15000 },
            { weight = 50, amount = 30000 },
            { weight = 5, amount = 90000 }
        }
    }
}

-- O futuro sistema de crafting cria apenas este item. No painel de gestão,
-- o dono escolhe qual tipo de raspadinha pretende reabastecer.
Config.ScratchStockItem = 'scratch_blank'
Config.ScratchPrizeReceiptItem = 'scratch_prize_receipt'

-- Limite por compra no painel de apostas. Evita pedidos excessivos e mantém
-- o jogador livre para comprar vários bilhetes de uma só vez.
Config.MaxScratchPurchaseQuantity = 20

Config.Euromillions = {
    label = 'Euromilhões',
    price = 300,
    schedule = { days = { 3, 6 }, hour = 20, minute = 30 },
    prizes = {
        ['5+2'] = 10000000,
        ['5+1'] = 2000000,
        ['5+0'] = 500000,
        ['4+2'] = 200000,
        ['4+1'] = 75000,
        ['4+0'] = 25000,
        ['3+2'] = 10000,
        ['3+1'] = 5000,
        ['3+0'] = 3000,
        ['2+2'] = 5000,
        ['2+1'] = 4500
    }
}

Config.Totoloto = {
    label = 'Totoloto',
    price = 200,
    schedule = { days = { 4, 7 }, hour = 20, minute = 30 },
    prizes = {
        ['5+1'] = 5000000,
        ['5+0'] = 1000000,
        ['4+1'] = 200000,
        ['4+0'] = 40000,
        ['3+1'] = 10000,
        ['3+0'] = 5000,
        ['2+1'] = 9000
    }
}

Config.EuroDreams = {
    label = 'EuroDreams',
    price = 200,
    schedule = { days = {}, hour = 20, minute = 30 },
    prizes = {
        ['6+1'] = 5000000, ['6+0'] = 1000000, ['5+1'] = 300000, ['5+0'] = 75000,
        ['4+1'] = 20000, ['4+0'] = 8000, ['3+1'] = 3000, ['3+0'] = 1200
    }
}

Config.Joker = {
    label = 'Joker',
    price = 100,
    schedule = { days = {}, hour = 21, minute = 0 },
    prizes = { [6] = 1000000, [5] = 50000, [4] = 5000, [3] = 2000 }
}

Config.Lotteries = {
    classic = { label = 'Lotaria Clássica', price = 200, schedule = { days = { 1 }, hour = 20, minute = 0 }, maximumNumber = 100000, prize = 8000000 },
    popular = { label = 'Lotaria Popular', price = 200, schedule = { days = { 4 }, hour = 20, minute = 0 }, maximumNumber = 50000, prize = 4000000 },
    instant = { label = 'Lotaria Instantânea', price = 200, prizes = { { weight = 8000, amount = 0 }, { weight = 1500, amount = 200 }, { weight = 450, amount = 800 }, { weight = 49, amount = 3000 }, { weight = 1, amount = 20000 } } }
}

Config.Loyalty = {
    pointsPerCurrency = 1,
    levels = {
        { id = 'bronze', label = 'Bronze', points = 0 },
        { id = 'silver', label = 'Prata', points = 100 },
        { id = 'gold', label = 'Ouro', points = 500 },
        { id = 'diamond', label = 'Diamante', points = 1500 }
    }
}

Config.AdminPermissions = { 'god', 'admin' }

Config.Security = {
    DefaultRateLimit = {
        maxAttempts = 5,
        windowSeconds = 10
    },
    EventRateLimits = {}
}

Config.Webhooks = {
    purchases = 'https://discord.com/api/webhooks/1536683519936299048/EiAdFZ7LQ6sxPUsQoabfta0gBUr0cFthvskjIyC9MMuk9MT-08hbMjkyXqRLhS3UKz7D',
    jackpots = 'https://discord.com/api/webhooks/1536683926624542724/PAAppoFqtpfkd_D5y-GRwRf9Pt2M-_H8VqUR2zCeOZ-6L8kGZ1_vpjbXmOhAFDQMyJ5D',
    employees = 'https://discord.com/api/webhooks/1536683977128157296/KhOKoo5pdWJWVO-EG6WPoix4QghrlT410LgMgzRA3oouFMoE8FXrd_I4VJltrPsLXt0D',
    admin = 'https://discord.com/api/webhooks/1536684020585205780/Usb1T5QhEbSdlgDgcQjelCdNLwFxByIzD8eed3PKNd44bcAdtSfj2FH_0PpC5LtEg_N9',
    security = 'https://discord.com/api/webhooks/1536684071487275060/9QrBth9RCvaF-Z1fW6HN3Z4dE7szRYtVp3iTwLpCnOQ4X7vf3vGIi2_jsdAACR4aECQO',
    weekly_sales = 'https://discord.com/api/webhooks/1536684115099910174/DQ6Dy6bkTLHkylhvhKsfOhd38aMbIVwzCy5mHE7XJhox6rmEnDEA7_a_4fVlKj-isNo8',
    prizes = 'https://discord.com/api/webhooks/1536697403409694770/dPhm8RSxwJ3vKDXdNBMMFb1eJAL-lj_fW747yVEsVXsMpN4n4pfJ_NP5rcWGxT17OpVZ',
    prize_approvals = 'https://discord.com/api/webhooks/1536697363266015253/6ZRVD38a4se5FWJGl01Uy6Yr59ythavtYui_HxQBZLZDPf3GwOtAx8Uh2qsjM-jpx0Q-'
}
