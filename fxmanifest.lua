fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author '1DarkWolf'
description 'Centro de Jogos - recurso QBCore para FiveM'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/version.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/framework.lua',
    'shared/locales.lua',
    'locales/pt.lua',
    'locales/en.lua'
}

client_scripts {
    'client/callbacks.lua',
    'client/company.lua',
    'client/finance.lua',
    'client/employees.lua',
    'client/tickets.lua',
    'client/draws.lua',
    'client/jackpot.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/logs.lua',
    'server/security.lua',
    'server/callbacks.lua',
    'server/company.lua',
    'server/employees.lua',
    'server/finance.lua',
    'server/tickets.lua',
    'server/draws.lua',
    'server/jackpot.lua',
    'server/main.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/css/*.css',
    'nui/js/*.js',
    'nui/img/*.*',
    'nui/sounds/*.*'
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-menu',
    'qb-input',
    'ox_lib',
    'oxmysql'
}
