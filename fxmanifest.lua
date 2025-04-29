fx_version 'cerulean'
game 'gta5'

author 'SyntaxScripts'
description 'QB-Core Tour Guide Job'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua', -- Essential for UI and other lib functions
    'config.lua',
    'locales/en.lua', -- Optional: Add locale file if used
}

server_scripts {
    '@qb-core/shared/locale.lua', -- Make sure QBCore locale is loaded if using L()
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/zones.lua',
    'client/ui.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*' -- Add any images/fonts used in the UI here
}

dependencies {
    'qb-core',
    'qb-target', -- Or your preferred targeting script
    'ox_lib'     -- Required for UI and other helpers
}

lua54 'yes'