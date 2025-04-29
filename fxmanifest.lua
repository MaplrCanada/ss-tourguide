fx_version 'cerulean'
game 'gta5'

author 'SyntaxScripts'
description 'Tour Guide Job for QBCore Framework'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/*.png',
    'html/fonts/*.ttf'
}

lua54 'yes'