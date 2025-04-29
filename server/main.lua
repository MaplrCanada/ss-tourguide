local QBCore = exports['qb-core']:GetCoreObject()
local tourCooldowns = {} -- Store player source and cooldown end time

-- Helper function for debugging server-side
local function debugLog(msg)
    if Config.Debug then
        print(("^3[DEBUG | %s | SERVER] %s^0"):format(GetCurrentResourceName(), msg))
    end
end

-- Toggle Duty
RegisterNetEvent('tourguide:server:toggleDuty', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.PlayerData.job.name == Config.JobName then
        local newDutyState = not Player.PlayerData.job.onduty
        Player.Functions.SetJobDuty(newDutyState)
        TriggerClientEvent('QBCore:Notify', src, "Tour Guide Duty: " .. (newDutyState and "ON" or "OFF"), newDutyState and "success" or "error")
        TriggerClientEvent('tourguide:client:updateDutyState', src, newDutyState)
        debugLog(('Player %s (%s) toggled duty to %s'):format(Player.PlayerData.name, src, tostring(newDutyState)))
    else
        TriggerClientEvent('QBCore:Notify', src, "You are not a tour guide.", "error")
    end
end)

-- Request Vehicle Spawn (Server validates and spawns to prevent exploits)
QBCore.Functions.CreateCallback('tourguide:server:spawnVehicle', function(source, cb, vehicleModel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(false); return end

    if Player.PlayerData.job.name ~= Config.JobName or not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, "You must be an on-duty tour guide.", "error")
        cb(false)
        return
    end

    -- Check if a valid model was requested
    local vehicleData = Config.Vehicles[vehicleModel]
    if not vehicleData then
        TriggerClientEvent('QBCore:Notify', src, "Invalid vehicle selected.", "error")
        cb(false)
        return
    end

    -- Spawn the vehicle
    QBCore.Functions.SpawnVehicle(src, vehicleData.model, Config.Locations.vehicleSpawn, function(veh)
        if veh then
            SetVehicleNumberPlateText(veh, "TOUR"..tostring(math.random(100, 999)))
            SetEntityAsMissionEntity(veh, true, true) -- Keep it from despawning easily
            local plate = GetVehicleNumberPlateText(veh)
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate) -- Give keys if using vehiclekeys
            TriggerClientEvent('QBCore:Notify', src, "Your " .. vehicleData.label .. " is ready.", "success")
            debugLog(('Spawned %s (%s) for player %s (%s)'):format(vehicleData.label, vehicleData.model, Player.PlayerData.name, src))
            cb(NetworkGetNetworkIdFromEntity(veh)) -- Return NetID to client
        else
            TriggerClientEvent('QBCore:Notify', src, "Failed to spawn vehicle. Location might be blocked.", "error")
            cb(false)
        end
    end)
end)

-- Finish Tour and Process Payment
RegisterNetEvent('tourguide:server:finishTour', function(rating)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.PlayerData.job.name ~= Config.JobName then
        debugLog(('Player %s (%s) tried to finish tour without job.'):format(Player.PlayerData.name, src))
        return -- Silently ignore if not the right job
    end

    -- Validate rating (basic check)
    rating = tonumber(rating) or 0.0
    if rating < 0.0 then rating = 0.0 end
    if rating > 1.0 then rating = 1.0 end

    -- Check cooldown
    local currentTime = GetGameTimer() -- Use game timer for simplicity across restarts might be needed
    if tourCooldowns[src] and currentTime < tourCooldowns[src] then
         local remaining = math.ceil((tourCooldowns[src] - currentTime) / 1000)
         TriggerClientEvent('QBCore:Notify', src, ("You need to wait %s more seconds before starting another tour."):format(remaining), "warning")
         debugLog(('Player %s (%s) tried to finish tour too soon (on cooldown).'):format(Player.PlayerData.name, src))
         return
    end

    local paymentAmount = Config.Payment.base + math.floor(Config.Payment.ratingMultiplier * rating)
    local feedbackText = Config.Payment.ratingTiers[1].text -- Default to worst

    -- Find appropriate feedback text
    for i = #Config.Payment.ratingTiers, 1, -1 do
        if rating >= Config.Payment.ratingTiers[i].threshold then
            feedbackText = Config.Payment.ratingTiers[i].text
            break
        end
    end

    -- Add money (can use different types like 'cash' or 'bank')
    Player.Functions.AddMoney('cash', paymentAmount, "tourguide-payment")

    TriggerClientEvent('QBCore:Notify', src, ("Tour Complete! Rating: %.1f%%. %s"):format(rating * 100, feedbackText), "success", 8000)
    TriggerClientEvent('QBCore:Notify', src, ("You earned $%s"):format(paymentAmount), "success", 8000)
    debugLog(('Player %s (%s) finished tour. Rating: %.2f, Payment: %s'):format(Player.PlayerData.name, src, rating, paymentAmount))

    -- Set cooldown
    tourCooldowns[src] = currentTime + (Config.CooldownSeconds * 1000)

    -- Clear cooldown entry after it expires (optional cleanup)
    SetTimeout(Config.CooldownSeconds * 1000, function()
        if tourCooldowns[src] == currentTime + (Config.CooldownSeconds * 1000) then -- Ensure it wasn't overwritten by a newer cooldown
           tourCooldowns[src] = nil
           debugLog(('Cooldown expired for player %s'):format(src))
        end
    end)
end)

-- Add Blip (if qb-blips is used)
Citizen.CreateThread(function()
    if exports['qb-blips'] then
        exports['qb-blips']:AddBlip('tourguide_duty', Config.DutyBlip)
        debugLog("Tour Guide duty blip added.")
    else
        debugLog("qb-blips not found, skipping blip creation.")
    end
end)

-- Handle player disconnect/job change - cleanup cooldown
AddEventHandler('QBCore:Server:PlayerLeft', function(source)
    if tourCooldowns[source] then
        tourCooldowns[source] = nil
        debugLog(('Removed cooldown for disconnected player %s'):format(source))
    end
end)

AddEventHandler('QBCore:Server:SetJob', function(source, job, lastJob)
    if tourCooldowns[source] and job.name ~= Config.JobName then
        tourCooldowns[source] = nil -- Remove cooldown if they change job
        debugLog(('Removed cooldown for player %s due to job change'):format(source))
    end
end)

debugLog("Server script loaded.")