-- Adicione estes itens em qb-core/shared/items.lua e reinicie qb-core.
-- Todos usam a mesma imagem por defeito; pode criar uma imagem própria para cada jogo se preferir.
scratch_ticket = { name = 'scratch_ticket', label = 'Raspadinha', weight = 0, type = 'item', image = 'scratch_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Uma raspadinha do Centro de Jogos.' },

-- Cartão sem prémio. Será o resultado do futuro crafting e o dono escolhe no painel qual stock quer repor.
scratch_blank = { name = 'scratch_blank', label = 'Raspadinha em branco', weight = 0, type = 'item', image = 'scratch_ticket.png', unique = false, useable = false, shouldClose = true, description = 'Cartão em branco para reabastecer o stock do Centro de Jogos.' },
euromillions_ticket = { name = 'euromillions_ticket', label = 'Bilhete Euromilhões', weight = 0, type = 'item', image = 'euromillions_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete de Euromilhões do Centro de Jogos.' },
totoloto_ticket = { name = 'totoloto_ticket', label = 'Bilhete Totoloto', weight = 0, type = 'item', image = 'totoloto_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete de Totoloto do Centro de Jogos.' },
eurodreams_ticket = { name = 'eurodreams_ticket', label = 'Bilhete EuroDreams', weight = 0, type = 'item', image = 'eurodreams_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete de EuroDreams do Centro de Jogos.' },
joker_ticket = { name = 'joker_ticket', label = 'Bilhete Joker', weight = 0, type = 'item', image = 'joker_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete Joker do Centro de Jogos.' },
lottery_classic_ticket = { name = 'lottery_classic_ticket', label = 'Bilhete Lotaria Clássica', weight = 0, type = 'item', image = 'lottery_classic_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete de Lotaria Clássica do Centro de Jogos.' },
lottery_popular_ticket = { name = 'lottery_popular_ticket', label = 'Bilhete Lotaria Popular', weight = 0, type = 'item', image = 'lottery_popular_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete de Lotaria Popular do Centro de Jogos.' },
lottery_instant_ticket = { name = 'lottery_instant_ticket', label = 'Bilhete Lotaria Instantânea', weight = 0, type = 'item', image = 'lottery_instant_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Um bilhete de Lotaria Instantânea do Centro de Jogos.' },

-- Mantenha temporariamente este item se já existirem bilhetes antigos no inventário.
lottery_ticket = { name = 'lottery_ticket', label = 'Bilhete de lotaria antigo', weight = 0, type = 'item', image = 'lottery_ticket.png', unique = true, useable = true, shouldClose = true, description = 'Bilhete emitido antes da atualização do Centro de Jogos.' },
