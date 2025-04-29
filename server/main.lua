local QBCore = exports['qb-core']:GetCoreObject()

-- Event to pay tour guide at end of tour
RegisterNetEvent('ss-tourguide:server:PayTourGuide', function(amount, basePay, tipAmount, rating)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is a tour guide
    if Player.PlayerData.job.name ~= "tourguide" then
        TriggerClientEvent('QBCore:Notify', src, "You must be a tour guide to receive tour payments!", "error")
        return
    end
    
    -- Add payment to player
    Player.Functions.AddMoney("cash", amount, "tour-guide-payment")
    
    -- Send notification
    TriggerClientEvent('QBCore:Notify', src, "You received $" .. amount .. " ($" .. basePay .. " + $" .. tipAmount .. " tip) for your " .. rating .. "-star tour!", "success")
    
    -- Log payment
    TriggerEvent('qb-log:server:CreateLog', 'tourguide', 'Tour Payment', 'green', Player.PlayerData.name .. ' received $' .. amount .. ' for completing a tour with a ' .. rating .. '-star rating.')
end)

-- Add items to shared
Citizen.CreateThread(function()
    -- Tour Guide Manual
    QBCore.Functions.AddItem('tourguide_manual', {
        name = 'tourguide_manual',
        label = 'Tour Guide Manual',
        weight = 150,
        type = 'item',
        image = 'tourguide_manual.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'A comprehensive guide to Los Santos landmarks and attractions.'
    })
    
    -- Tour Guide Badge
    QBCore.Functions.AddItem('tourguide_badge', {
        name = 'tourguide_badge',
        label = 'Tour Guide Badge',
        weight = 50,
        type = 'item',
        image = 'tourguide_badge.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'Official Los Santos Tour Guide certification badge.'
    })
end)

-- Item usage
QBCore.Functions.CreateUseableItem("tourguide_manual", function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    TriggerClientEvent('ss-tourguide:client:OpenTourMenu', src)
end)

QBCore.Functions.CreateUseableItem("tourguide_badge", function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Just a simple notification
    TriggerClientEvent('QBCore:Notify', src, "You proudly display your Tour Guide Badge!", "primary")
end)

-- Command to get tour guide items (admin only)
QBCore.Commands.Add('givetouritems', 'Give tour guide items (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.name == "tourguide" then
        Player.Functions.AddItem('tourguide_manual', 1)
        Player.Functions.AddItem('tourguide_badge', 1)
        TriggerClientEvent('QBCore:Notify', src, "You received your tour guide equipment!", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "You must be a tour guide to receive these items!", "error")
    end
end, 'admin')