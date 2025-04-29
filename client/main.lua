local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isOnDuty = false
local currentTour = nil -- { key, poiIndex, poiData, startTime, npcPassengers = {}, npcRatings = {}, vehicleNetId, targetBlip }
local currentQuiz = nil -- { poiIndex, npcIndex, questionData }
local isInPOIZone = false
local spawnedVehicle = nil -- Store the entity handle of the job vehicle

-- Helper function for debugging client-side
local function debugLog(msg)
    if Config.Debug then
        print(("^5[DEBUG | %s | CLIENT MAIN] %s^0"):format(GetCurrentResourceName(), msg))
    end
end

-- Load Ped Models needed for NPCs
Citizen.CreateThread(function()
    for _, model in ipairs(Config.NPCModels) do
        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do
            Citizen.Wait(100)
        end
        debugLog(("Loaded NPC model: %s"):format(model))
    end
    RequestModel(GetHashKey("tourbus")) -- Preload default bus model
    while not HasModelLoaded(GetHashKey("tourbus")) do Citizen.Wait(10) end
    RequestModel(GetHashKey("coach")) -- Preload other bus model
    while not HasModelLoaded(GetHashKey("coach")) do Citizen.Wait(10) end
    debugLog("Preloaded vehicle models.")
end)

-- Get PlayerData on startup and job change
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isOnDuty = PlayerData.job.onduty and PlayerData.job.name == Config.JobName
    TriggerServerEvent('QBCore:Server:SetMetaData', 'job:' .. Config.JobName .. ':onduty', isOnDuty) -- Sync duty state if needed by other scripts
    debugLog(("Player loaded. Job: %s, OnDuty: %s"):format(PlayerData.job.name, tostring(isOnDuty)))
    SetupTargets() -- Setup targets once player data is available
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
    local wasOnDuty = isOnDuty
    isOnDuty = PlayerData.job.onduty and PlayerData.job.name == Config.JobName
    TriggerServerEvent('QBCore:Server:SetMetaData', 'job:' .. Config.JobName .. ':onduty', isOnDuty)
    if wasOnDuty and not isOnDuty and currentTour then
        debugLog("Went off duty during a tour. Forcing end.")
        ForceEndTour("You went off duty.") -- End tour if player goes off duty
    end
    debugLog(("Job updated. Job: %s, OnDuty: %s"):format(PlayerData.job.name, tostring(isOnDuty)))
    SetupTargets() -- Re-evaluate targets based on new job/duty status
end)

RegisterNetEvent('tourguide:client:updateDutyState', function(dutyState)
    isOnDuty = dutyState
    PlayerData.job.onduty = dutyState -- Keep local PlayerData consistent
    TriggerServerEvent('QBCore:Server:SetMetaData', 'job:' .. Config.JobName .. ':onduty', isOnDuty)
    debugLog(("Received duty state update from server: %s"):format(tostring(isOnDuty)))
    SetupTargets() -- Re-evaluate targets
end)


-- QB-Target Integration
function SetupTargets()
    -- Remove existing targets first to prevent duplicates
    exports['qb-target']:RemoveZone("tourguide_duty_target")
    exports['qb-target']:RemoveZone("tourguide_vehicle_target")

    -- Duty Toggle Target
    exports['qb-target']:AddBoxZone("tourguide_duty_target", Config.Locations.duty, 1.5, 1.5, {
        name = "tourguide_duty_target",
        heading = 0,
        debugPoly = Config.Debug,
        minZ = Config.Locations.duty.z - 1.0,
        maxZ = Config.Locations.duty.z + 1.0,
    }, {
        options = {
            {
                type = "client",
                event = "tourguide:client:toggleDuty",
                icon = Config.Target.duty.icon,
                label = Config.Target.duty.label,
                job = Config.Target.duty.job, -- Let qb-target handle job check
            },
        },
        distance = 2.0
    })
    debugLog("Duty target setup.")

    -- Vehicle Spawn Target
    exports['qb-target']:AddBoxZone("tourguide_vehicle_target", Config.Locations.vehicleSpawn - vector4(0,0,0.5,0), 3.0, 2.0, { -- Slightly lower target zone
        name = "tourguide_vehicle_target",
        heading = Config.Locations.vehicleSpawn.w,
        debugPoly = Config.Debug,
        minZ = Config.Locations.vehicleSpawn.z - 1.5,
        maxZ = Config.Locations.vehicleSpawn.z + 1.5,
    }, {
        options = {
            {
                type = "client",
                event = "tourguide:client:openVehicleMenu",
                icon = Config.Target.vehicle.icon,
                label = Config.Target.vehicle.label,
                job = Config.Target.vehicle.job,
                canInteract = function() return isOnDuty end, -- Add extra check for on duty status
            },
        },
        distance = 2.5
    })
    debugLog("Vehicle target setup.")
end

-- Event Handlers for Targets
RegisterNetEvent('tourguide:client:toggleDuty', function()
    TriggerServerEvent('tourguide:server:toggleDuty')
end)

RegisterNetEvent('tourguide:client:openVehicleMenu', function()
    if not isOnDuty then
        QBCore.Functions.Notify("You must be on duty.", "error")
        return
    end
    if currentTour then
        QBCore.Functions.Notify("You are already on a tour.", "warning")
        return
    end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        QBCore.Functions.Notify("You already have a tour vehicle spawned. Finish your tour or store it.", "warning")
        -- Optionally add logic here to despawn the old one if needed
        return
    end

    local vehicleOptions = {}
    for key, data in pairs(Config.Vehicles) do
        table.insert(vehicleOptions, {
            title = data.label,
            description = "Spawn the " .. data.label,
            event = "tourguide:client:spawnVehicle",
            args = key -- Pass the vehicle key (e.g., "tourbus")
        })
    end

    if #vehicleOptions > 0 then
        exports['qb-menu']:openMenu(vehicleOptions) -- Using qb-menu for simplicity here, can replace with ox_lib context or NUI
        -- Alternatively, use ox_lib context menu:
        -- lib.registerContext({ id = 'tourguide_vehicle_menu', title = 'Select Tour Vehicle', options = vehicleOptions })
        -- lib.showContext('tourguide_vehicle_menu')
    else
        QBCore.Functions.Notify("No tour vehicles configured.", "error")
    end
end)

RegisterNetEvent('tourguide:client:spawnVehicle', function(vehicleKey)
    if not vehicleKey then return end
    debugLog(("Requesting spawn for vehicle key: %s"):format(vehicleKey))

    QBCore.Functions.TriggerCallback('tourguide:server:spawnVehicle', function(netId)
        if netId then
            local attempts = 0
            while not NetworkDoesNetworkIdExist(netId) and attempts < 20 do -- Wait for entity to exist locally
                Citizen.Wait(100)
                attempts = attempts + 1
            end
            if NetworkDoesNetworkIdExist(netId) then
                spawnedVehicle = NetToVeh(netId)
                debugLog(("Vehicle spawned successfully. NetID: %s, Entity: %s"):format(netId, spawnedVehicle))
                -- Optional: Automatically warp player into driver's seat
                -- TaskWarpPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1)
                QBCore.Functions.Notify("Drive to the loading zone to pick up tourists.", "inform", 5000)

                -- Start checking for the loading zone
                CheckLoadingZone(spawnedVehicle)
            else
                QBCore.Functions.Notify("Vehicle could not be found after spawning.", "error")
                debugLog("Failed to get vehicle entity from NetID.")
                spawnedVehicle = nil
            end
        else
             debugLog("Server denied or failed vehicle spawn.")
             spawnedVehicle = nil
        end
    end, vehicleKey)
end)

-- NPC Loading Logic
function CheckLoadingZone(vehicle)
    local zone = lib.zones.box({
        coords = Config.Locations.npcLoadZone,
        size = vec3(5.0, 5.0, 3.0),
        debug = Config.Debug,
        onEnter = function(self)
            local playerPed = PlayerPedId()
            local currentVehicle = GetVehiclePedIsIn(playerPed, false)
            if currentVehicle == vehicle and GetPedInVehicleSeat(currentVehicle, -1) == playerPed then
                debugLog("Entered NPC loading zone with correct vehicle.")
                QBCore.Functions.Notify("Tourists are boarding...", "inform")
                LoadNPCs(vehicle)
                self:remove() -- Remove the zone checker once NPCs are loaded
            end
        end,
        onExit = function()
            -- Optional: Notify player they left the zone if needed
        end,
        inside = function(self)
             -- Can add checks here if needed, e.g., check if vehicle stopped
        end
    })
    -- Add a timeout or condition to remove this zone if player drives away without loading
    Citizen.CreateThread(function()
        Citizen.Wait(30000) -- Wait 30 seconds
        if zone and zone.remove then -- Check if zone still exists (wasn't removed by onEnter)
            debugLog("NPC loading zone check timed out.")
            zone:remove()
        end
    end)
end

function LoadNPCs(vehicle)
    if not DoesEntityExist(vehicle) then
        debugLog("Vehicle does not exist for NPC loading.")
        return
    end

    currentTour = { -- Initialize basic tour state
        key = nil, -- Will be set when tour type is selected
        poiIndex = 0,
        poiData = nil,
        startTime = GetGameTimer(),
        npcPassengers = {},
        npcRatings = {}, -- Store individual NPC rating { npcIndex = number (0-1), correct = 0, total = 0 }
        vehicleNetId = VehToNet(vehicle),
        targetBlip = nil
    }

    local touristCount = 0
    local spawnOffset = vector3(3.0, 0.0, 0.0) -- Initial spawn offset from the zone center

    Citizen.CreateThread(function()
        for i = 1, Config.MaxNPCs do
            local model = Config.NPCModels[math.random(#Config.NPCModels)]
            local spawnPos = Config.Locations.npcLoadZone + spawnOffset * i -- Spread them out slightly
            local npc = CreatePed(4, GetHashKey(model), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, true)
            while not DoesEntityExist(npc) do Citizen.Wait(0) end -- Ensure ped exists

            SetPedAsMissionEntity(npc, true, true)
            SetPedKeepTask(npc, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            SetPedCombatAttrib(npc, 46, true) -- BF_CanNeverPanic
            SetPedFleeAttributes(npc, 0, 0)

            local seatIndex = i -- Try to seat them sequentially (0 is front passenger)
            if GetVehicleMaxNumberOfPassengers(vehicle) <= seatIndex then
                seatIndex = GetVehicleMaxNumberOfPassengers(vehicle) - 1 -- Put in last available seat if needed
            end

            if IsVehicleSeatFree(vehicle, seatIndex) then
                debugLog(("Spawning NPC %s (%s) for seat %s"):format(i, model, seatIndex))
                TaskEnterVehicle(npc, vehicle, 10000, seatIndex, 1.0, 1, 0) -- Task them to enter the vehicle
                table.insert(currentTour.npcPassengers, { entity = npc, assignedSeat = seatIndex })
                currentTour.npcRatings[i] = { correct = 0, total = 0, rating = 0.5 } -- Initialize rating (0.5 = neutral)
                touristCount = touristCount + 1
            else
                debugLog(("Seat %s occupied, skipping NPC %s"):format(seatIndex, i))
                DeleteEntity(npc) -- Delete ped if seat isn't free
            end
            Citizen.Wait(500) -- Stagger NPC spawning/tasking slightly
        end

        -- Wait for NPCs to get in (basic check)
        Citizen.Wait(10000) -- Give them 10 seconds
        local seatedCount = 0
        for _, npcData in pairs(currentTour.npcPassengers) do
            if DoesEntityExist(npcData.entity) and GetVehiclePedIsIn(npcData.entity, false) == vehicle then
                seatedCount = seatedCount + 1
            else
                 debugLog("An NPC failed to board, removing...")
                 if DoesEntityExist(npcData.entity) then DeleteEntity(npcData.entity) end
                 -- Consider removing from npcPassengers table here if needed
            end
        end

        if seatedCount > 0 then
            QBCore.Functions.Notify(("Boarding complete. %s tourists joined."):format(seatedCount), "success")
            debugLog("NPC loading complete. Opening tour selection.")
            OpenTourSelectionUI() -- Now ask the player which tour they want
        else
            QBCore.Functions.Notify("No tourists boarded the bus.", "error")
            debugLog("No NPCs successfully boarded.")
            CleanupTour(false) -- Cleanup if no one boarded
        end
    end)
end

-- Tour Selection
function OpenTourSelectionUI()
    local tourOptions = {}
    for key, data in pairs(Config.Tours) do
        table.insert(tourOptions, {
            key = key,
            label = data.label,
            time = data.estimatedTime
        })
    end
    ShowTourSelection(tourOptions) -- Function from client/ui.lua
end

-- Start Selected Tour
RegisterNetEvent('tourguide:client:startTour', function(tourKey)
    if not currentTour or not Config.Tours[tourKey] then
        debugLog("Attempted to start invalid tour.")
        return
    end

    debugLog(("Starting tour: %s"):format(tourKey))
    currentTour.key = tourKey
    currentTour.poiIndex = 1 -- Start at the first POI
    currentTour.poiData = Config.Tours[tourKey].pointsOfInterest
    QBCore.Functions.Notify("Tour starting! Proceed to the first point of interest.", "inform")
    SetNuiVisibility(true) -- Show the main tour UI
    UpdateTourUIState() -- Initial UI update
    SetNextPOITarget()
end)

-- Tour Progression
function SetNextPOITarget()
    if not currentTour or currentTour.poiIndex > #currentTour.poiData then
        debugLog("No more POIs or tour not active.")
        EndTourSequence() -- Reached the end
        return
    end

    local poi = currentTour.poiData[currentTour.poiIndex]
    debugLog(("Setting next POI: #%s - %s at %s"):format(currentTour.poiIndex, poi.name, tostring(poi.coords)))

    -- Remove previous blip/zone
    if currentTour.targetBlip then
        RemoveBlip(currentTour.targetBlip)
        currentTour.targetBlip = nil
    end
    RemovePOIZone() -- Function from client/zones.lua

    -- Create new blip
    currentTour.targetBlip = AddBlipForCoord(poi.coords.x, poi.coords.y, poi.coords.z)
    SetBlipSprite(currentTour.targetBlip, 1) -- Standard blip sprite
    SetBlipColour(currentTour.targetBlip, 5) -- Yellow
    SetBlipRoute(currentTour.targetBlip, true)
    SetBlipRouteColour(currentTour.targetBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(("POI %d: %s"):format(currentTour.poiIndex, poi.name))
    EndTextCommandSetBlipName(currentTour.targetBlip)

    -- Create new POI zone
    CreatePOIZones(poi.coords) -- Function from client/zones.lua

    UpdateTourUIState() -- Update UI with new POI info
end

-- POI Interaction
RegisterNetEvent('tourguide:client:enteredPOI', function()
    if not currentTour or isInPOIZone then return end -- Prevent double triggers

    local poi = currentTour.poiData[currentTour.poiIndex]
    if not poi then return end

    debugLog(("Entered POI zone for: %s"):format(poi.name))
    isInPOIZone = true
    QBCore.Functions.Notify(("Arrived at: %s"):format(poi.name), "inform")

    -- Display POI info on NUI
    ShowPOIInfo({ name = poi.name, info = poi.info })

    -- Trigger Quiz after a short delay (allow player to read info)
    if poi.quiz and #currentTour.npcPassengers > 0 then
        Citizen.Wait(5000) -- Wait 5 seconds
        if isInPOIZone and currentTour and currentTour.poiData[currentTour.poiIndex] == poi then -- Check if still valid
            StartQuizForPOI(poi.quiz)
        end
    else
        debugLog("No quiz for this POI or no passengers.")
        -- Maybe automatically enable "Next POI" button if no quiz?
        UpdateTourUIState() -- Update UI to potentially show "Next POI" button now
    end
end)

RegisterNetEvent('tourguide:client:exitedPOI', function()
    if not currentTour or not isInPOIZone then return end
    debugLog("Exited POI zone.")
    isInPOIZone = false
    -- Maybe hide POI info/quiz if player drives away? Or just leave it until next POI is triggered.
    HideQuiz() -- Hide quiz if they leave zone
    currentQuiz = nil
    UpdateTourUIState()
end)

-- Quiz Logic
function StartQuizForPOI(quizData)
    if not currentTour or #currentTour.npcPassengers == 0 then return end

    local randomNpcIndex = math.random(#currentTour.npcPassengers)
    local npcData = currentTour.npcPassengers[randomNpcIndex]
    if not npcData or not DoesEntityExist(npcData.entity) then
        debugLog("Selected NPC for quiz does not exist, skipping quiz.")
        UpdateTourUIState() -- Allow proceeding
        return
    end

    debugLog(("Starting quiz for POI #%s, asking NPC index %s"):format(currentTour.poiIndex, randomNpcIndex))
    currentQuiz = {
        poiIndex = currentTour.poiIndex,
        npcIndex = randomNpcIndex,
        questionData = quizData,
        correctAnswer = quizData.a
    }

    -- Show quiz on NUI
    ShowQuiz({ q = quizData.q, options = quizData.options })
    QBCore.Functions.Notify("A tourist has a question! Answer via the tour panel.", "inform", 7000)

    -- Optional: Make the chosen NPC wave or do an animation
    TaskPlayAnim(npcData.entity, "gestures@f@standing@casual", "gesture_hello", 8.0, -8.0, 2000, 0, 0, false, false, false)

    UpdateTourUIState() -- Update UI to show quiz is active
end

RegisterNetEvent('tourguide:client:processQuizAnswer', function(selectedAnswer)
    if not currentTour or not currentQuiz then
        debugLog("Received quiz answer but no active quiz.")
        return
    end

    local poiIndex = currentQuiz.poiIndex
    local npcIndex = currentQuiz.npcIndex
    local correctAnswer = currentQuiz.correctAnswer

    if not currentTour.npcRatings[npcIndex] then
        debugLog("Error: Rating data missing for NPC index " .. npcIndex)
        currentQuiz = nil
        HideQuiz()
        UpdateTourUIState()
        return
    end

    currentTour.npcRatings[npcIndex].total = currentTour.npcRatings[npcIndex].total + 1
    local npcEntity = currentTour.npcPassengers[npcIndex].entity

    if selectedAnswer == correctAnswer then
        debugLog("Quiz answer correct!")
        QBCore.Functions.Notify("Correct!", "success")
        currentTour.npcRatings[npcIndex].correct = currentTour.npcRatings[npcIndex].correct + 1
        if DoesEntityExist(npcEntity) then TaskPlayAnim(npcEntity, "anim@mp_player_intcelebrationfemale@nod_yes", "nod_yes", 8.0, -8.0, 1500, 0, 0, false, false, false) end -- Nod yes animation
    else
        debugLog("Quiz answer incorrect.")
        QBCore.Functions.Notify(("Incorrect. The answer was: %s"):format(correctAnswer), "error", 5000)
         if DoesEntityExist(npcEntity) then TaskPlayAnim(npcEntity, "anim@mp_player_intcelebrationfemale@shake_head_no", "shake_head_no", 8.0, -8.0, 1500, 0, 0, false, false, false) end -- Shake head no
    end

    -- Update individual NPC rating (simple average)
    currentTour.npcRatings[npcIndex].rating = currentTour.npcRatings[npcIndex].correct / currentTour.npcRatings[npcIndex].total

    currentQuiz = nil
    HideQuiz() -- Hide quiz from NUI
    UpdateTourUIState() -- Update UI (e.g., enable "Next POI" button)
end)

-- Proceed to Next POI
RegisterNetEvent('tourguide:client:proceedToNextPOI', function()
    if not currentTour then return end
    if currentQuiz then
        QBCore.Functions.Notify("Please answer the current quiz question first.", "warning")
        return
    end
    if not isInPOIZone then
        QBCore.Functions.Notify("You must be at the current Point of Interest.", "warning")
        return
    end

    debugLog("Proceeding to next POI.")
    currentTour.poiIndex = currentTour.poiIndex + 1
    isInPOIZone = false -- Reset zone status
    SetNextPOITarget() -- Setup blip/zone for the next one
end)

-- End Tour Sequence (Normal Completion)
function EndTourSequence()
    if not currentTour then return end
    debugLog("Reached end of POI list. Returning to depot.")
    QBCore.Functions.Notify("Tour route complete! Please return the tourists to the drop-off zone.", "inform", 7000)

    -- Remove last POI target
    if currentTour.targetBlip then RemoveBlip(currentTour.targetBlip); currentTour.targetBlip = nil; end
    RemovePOIZone()

    -- Set blip for drop-off zone
    currentTour.targetBlip = AddBlipForCoord(Config.Locations.npcDespawnZone.x, Config.Locations.npcDespawnZone.y, Config.Locations.npcDespawnZone.z)
    SetBlipSprite(currentTour.targetBlip, 489) -- Tourbus sprite
    SetBlipColour(currentTour.targetBlip, 2) -- Green
    SetBlipRoute(currentTour.targetBlip, true)
    SetBlipRouteColour(currentTour.targetBlip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Tour Drop-off")
    EndTextCommandSetBlipName(currentTour.targetBlip)

    UpdateTourUIState() -- Update UI to show "Return to Depot" state

    -- Start checking for drop-off zone
    CheckDespawnZone()
end

-- Check for Drop-off Zone
function CheckDespawnZone()
    local zone = lib.zones.box({
        coords = Config.Locations.npcDespawnZone,
        size = vec3(6.0, 6.0, 3.0), -- Make slightly larger maybe
        debug = Config.Debug,
        onEnter = function(self)
            if not currentTour then self:remove(); return; end -- Tour ended prematurely

            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(vehicle) and NetToVeh(currentTour.vehicleNetId) == vehicle and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                debugLog("Entered NPC despawn zone.")
                QBCore.Functions.Notify("Tourists are disembarking...", "inform")
                UnloadNPCs(vehicle)
                self:remove() -- Remove the zone checker
            end
        end,
        onExit = function() end -- Not needed usually
    })

    -- Timeout for cleanup
    Citizen.CreateThread(function()
        Citizen.Wait(60000) -- Give 1 minute to return
        if zone and zone.remove then
            debugLog("NPC despawn zone check timed out.")
            zone:remove()
            -- Consider forcing end tour if they take too long?
        end
    end)
end

-- NPC Unloading
function UnloadNPCs(vehicle)
    if not currentTour or not currentTour.npcPassengers then return end
    debugLog("Unloading NPCs.")

    Citizen.CreateThread(function()
        for i, npcData in ipairs(currentTour.npcPassengers) do
            if DoesEntityExist(npcData.entity) and GetVehiclePedIsIn(npcData.entity, false) == vehicle then
                TaskLeaveVehicle(npcData.entity, vehicle, 0)
                Citizen.Wait(250) -- Stagger leaving slightly
            end
        end

        Citizen.Wait(5000) -- Wait for them to get out

        -- Calculate final rating
        local totalCorrect = 0
        local totalAsked = 0
        for _, ratingData in pairs(currentTour.npcRatings) do
            totalCorrect = totalCorrect + ratingData.correct
            totalAsked = totalAsked + ratingData.total
        end
        local finalRating = 0.5 -- Default if no questions asked
        if totalAsked > 0 then
            finalRating = totalCorrect / totalAsked
        end
        debugLog(("Final rating calculated: %.2f (%s/%s)"):format(finalRating, totalCorrect, totalAsked))

        -- Send result to server
        TriggerServerEvent('tourguide:server:finishTour', finalRating)

        -- Despawn NPCs after a short walk
        for i, npcData in ipairs(currentTour.npcPassengers) do
            if DoesEntityExist(npcData.entity) then
                local walkTo = GetOffsetFromEntityInWorldCoords(npcData.entity, 0.0, 5.0, 0.0) -- Walk forward 5m
                TaskGoStraightToCoord(npcData.entity, walkTo.x, walkTo.y, walkTo.z, 1.0, 3000, 0.0, 0.1)
            end
        end

        Citizen.Wait(4000) -- Wait for walk task

        debugLog("Cleaning up after successful tour.")
        CleanupTour(true) -- Full cleanup after successful completion
    end)
end

-- Update Tour UI State (Call this whenever something changes)
function UpdateTourUIState()
    if not currentTour or not IsNuiVisible() then return end -- Only update if on tour and UI is meant to be shown

    local stateData = {
        onTour = true,
        tourName = Config.Tours[currentTour.key]?.label or "Unknown Tour",
        currentPOIIndex = currentTour.poiIndex,
        totalPOIs = #currentTour.poiData,
        poiName = "N/A",
        distance = -1,
        npcCount = #currentTour.npcPassengers,
        avgRating = CalculateAverageRating(),
        quizActive = (currentQuiz ~= nil),
        atPOI = isInPOIZone,
        returning = false, -- Flag if tour route is done, returning to depot
    }

    local targetCoords = nil
    if currentTour.poiIndex <= #currentTour.poiData then
        local poi = currentTour.poiData[currentTour.poiIndex]
        stateData.poiName = poi.name
        targetCoords = poi.coords
    else
        -- We are in the return phase
        stateData.poiName = "Return to Depot"
        stateData.returning = true
        targetCoords = Config.Locations.npcDespawnZone
    end

    if targetCoords then
        local playerCoords = GetEntityCoords(PlayerPedId())
        stateData.distance = #(playerCoords - targetCoords) -- Vdist
    end

    -- Send the data to the NUI frame
    SendNUIMessage('updateState', stateData)
    debugLog("Updated NUI state.")
end

-- Calculate Average Rating (Client-side for UI display)
function CalculateAverageRating()
    if not currentTour or not currentTour.npcRatings then return 0.0 end
    local totalCorrect = 0
    local totalAsked = 0
    for _, ratingData in pairs(currentTour.npcRatings) do
        totalCorrect = totalCorrect + ratingData.correct
        totalAsked = totalAsked + ratingData.total
    end
    if totalAsked == 0 then return 0.5 end -- Return neutral if no questions asked yet
    return totalCorrect / totalAsked
end

-- Force End Tour (e.g., player died, vehicle destroyed, went off duty)
RegisterNetEvent('tourguide:client:forceEndTour', function(reason)
    if not currentTour then return end
    debugLog(("Forcing end of tour. Reason: %s"):format(reason or "Unknown"))
    QBCore.Functions.Notify("Tour cancelled. " .. (reason or ""), "error", 7000)
    CleanupTour(false) -- Cleanup without payment
end)

-- Cleanup Function
function CleanupTour(wasSuccessful)
    debugLog(("Running cleanup. Successful: %s"):format(tostring(wasSuccessful)))
    SetNuiVisibility(false) -- Hide the tour UI

    if currentTour then
        -- Remove blip
        if currentTour.targetBlip then RemoveBlip(currentTour.targetBlip); end
        -- Remove zones
        RemovePOIZone()
        -- Despawn NPCs immediately if tour failed or wasn't successful unloading
        if not wasSuccessful and currentTour.npcPassengers then
            debugLog("Force despawning NPCs due to unsuccessful end.")
            for _, npcData in ipairs(currentTour.npcPassengers) do
                if DoesEntityExist(npcData.entity) then
                    DeleteEntity(npcData.entity)
                end
            end
        end
         -- Despawn vehicle ONLY if it's the one we spawned and maybe check ownership?
         -- Be careful not to delete player-owned vehicles if that feature is added later.
         if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
             local netId = VehToNet(spawnedVehicle)
             if netId == currentTour.vehicleNetId then -- Ensure it's the same vehicle we tracked
                debugLog(("Despawning tour vehicle: %s (NetID: %s)"):format(spawnedVehicle, netId))
                SetEntityAsMissionEntity(spawnedVehicle, false, true) -- Allow despawn
                DeleteVehicle(spawnedVehicle)
             else
                 debugLog("Spawned vehicle handle doesn't match tour vehicle NetID. Not deleting.")
             end
         end
    end

    -- Reset state variables
    currentTour = nil
    currentQuiz = nil
    isInPOIZone = false
    spawnedVehicle = nil -- Clear spawned vehicle reference

    debugLog("Cleanup complete.")
end

-- Monitoring Thread (Vehicle destruction, player death etc)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Check every second

        if currentTour then
            local playerPed = PlayerPedId()
            -- Check if player died
            if IsPedDeadOrDying(playerPed, true) then
                debugLog("Player died during tour.")
                TriggerEvent('tourguide:client:forceEndTour', "You died.")
                Citizen.Wait(5000) -- Wait a bit after forcing end before checking again
                goto continue -- Skip rest of checks for this iteration
            end

            -- Check if the tour vehicle exists and is usable
            local vehicle = nil
            if currentTour.vehicleNetId and NetworkDoesNetworkIdExist(currentTour.vehicleNetId) then
                 vehicle = NetToVeh(currentTour.vehicleNetId)
            end

            if not vehicle or not DoesEntityExist(vehicle) or IsEntityDead(vehicle) then
                debugLog("Tour vehicle is missing or destroyed.")
                TriggerEvent('tourguide:client:forceEndTour', "The tour bus was lost or destroyed.")
                Citizen.Wait(5000)
                goto continue
            end

             -- Check if player is still in the driver's seat (optional, could be annoying)
             -- local currentVehicle = GetVehiclePedIsIn(playerPed, false)
             -- if currentVehicle ~= vehicle or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
             --     debugLog("Player is not driving the tour bus.")
             --     TriggerEvent('tourguide:client:forceEndTour', "You left the tour bus.")
             --     Citizen.Wait(5000)
             --    goto continue
             -- end

            -- Update UI state periodically
            UpdateTourUIState()
        end
        ::continue::
    end
end)

-- Helper Function to get current tour state (used in ui.lua check)
function GetTourState()
    return {
        onTour = (currentTour ~= nil)
    }
end

-- Initial Setup
Citizen.CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
    while not PlayerData.job do
        Citizen.Wait(500) -- Wait for player data to be loaded
        PlayerData = QBCore.Functions.GetPlayerData()
    end
    isOnDuty = PlayerData.job.onduty and PlayerData.job.name == Config.JobName
    debugLog(("Initial check. Job: %s, OnDuty: %s"):format(PlayerData.job.name, tostring(isOnDuty)))
    SetupTargets() -- Initial target setup
end)

-- Handle resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        debugLog("Resource stopping, running cleanup.")
        CleanupTour(false) -- Ensure cleanup runs when script stops/restarts
        SetNuiVisibility(false) -- Make sure NUI is hidden
        -- Remove targets explicitly on stop
        exports['qb-target']:RemoveZone("tourguide_duty_target")
        exports['qb-target']:RemoveZone("tourguide_vehicle_target")
        debugLog("Targets removed.")
    end
end)

debugLog("Client Main script loaded.")