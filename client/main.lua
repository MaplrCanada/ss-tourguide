local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local tourActive = false
local currentTour = nil
local currentTourists = {}
local tourVehicle = nil
local tourBlip = nil
local destinationBlip = nil
local currentDestination = nil
local currentCheckpoint = nil
local currentTourPoints = nil
local currentTourPointIndex = 1
local knowledgePoints = 0
local safetyPoints = 0
local maxSpeed = 0
local tourStartTime = 0
local touristSatisfaction = 0

-- Initialize
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.job.name == "tourguide" then
        CreateTourBlips()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    if JobInfo.name == "tourguide" then
        CreateTourBlips()
    else
        RemoveTourBlips()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveTourBlips()
    EndTour("cancelled")
end)

-- Function to create tour starting point blips
function CreateTourBlips()
    RemoveTourBlips() -- Remove existing blips first
    
    for tourType, tourData in pairs(Config.TourLocations) do
        local blip = AddBlipForCoord(tourData.startPoint.x, tourData.startPoint.y, tourData.startPoint.z)
        SetBlipSprite(blip, 409) -- Tour bus icon
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 2) -- Green
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(tourData.name .. " Start")
        EndTextCommandSetBlipName(blip)
        
        -- Store the blip
        if not tourBlip then tourBlip = {} end
        table.insert(tourBlip, blip)
    end
end

-- Function to remove blips
function RemoveTourBlips()
    if tourBlip then
        for _, blip in pairs(tourBlip) do
            RemoveBlip(blip)
        end
        tourBlip = nil
    end
    
    if destinationBlip then
        RemoveBlip(destinationBlip)
        destinationBlip = nil
    end
    
    if currentCheckpoint then
        DeleteCheckpoint(currentCheckpoint)
        currentCheckpoint = nil
    end
end

-- Function to start a tour
function StartTour(tourType)
    if tourActive then
        QBCore.Functions.Notify("You are already on a tour!", "error")
        return
    end
    
    if not Config.TourLocations[tourType] then
        QBCore.Functions.Notify("Invalid tour type!", "error")
        return
    end
    
    currentTour = tourType
    currentTourPoints = Config.TourLocations[tourType].tourPoints
    currentTourPointIndex = 1
    knowledgePoints = 0
    safetyPoints = 300 -- Start with some safety points that get reduced for bad driving
    maxSpeed = 0
    touristSatisfaction = 50 -- Start at neutral satisfaction
    
    -- Spawn the tour vehicle
    local nearestSpawn = GetNearestVehicleSpawn()
    SpawnTourVehicle(nearestSpawn)
    
    -- Spawn the tourists
    SpawnTourists()
    
    -- Create the first destination point
    CreateDestinationPoint(currentTourPoints[currentTourPointIndex].location)
    
    -- Start tracking time
    tourStartTime = GetGameTimer()
    
    -- Set tour as active
    tourActive = true
    
    -- Notify player
    QBCore.Functions.Notify("Tour started! Drive to the first destination.", "success")
    
    -- Trigger UI
    SendNUIMessage({
        type = "TOUR_START",
        tourName = Config.TourLocations[tourType].name,
        tourDuration = Config.TourLocations[tourType].duration,
        destination = currentTourPoints[currentTourPointIndex].name
    })
    
    -- Start monitoring driving
    StartDrivingMonitor()
end

-- Function to get the nearest vehicle spawn point
function GetNearestVehicleSpawn()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestSpawn = nil
    local shortestDistance = 99999.0
    
    for _, spawn in pairs(Config.VehicleSpawns) do
        local distance = #(playerCoords - vector3(spawn.x, spawn.y, spawn.z))
        if distance < shortestDistance then
            shortestDistance = distance
            nearestSpawn = spawn
        end
    end
    
    return nearestSpawn
end

-- Function to spawn the tour vehicle
function SpawnTourVehicle(spawnPoint)
    -- Get the first vehicle from config
    local vehicleInfo = Config.TourGuideVehicles[1]
    
    -- Request the model
    local modelHash = GetHashKey(vehicleInfo.model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end
    
    -- Spawn the vehicle
    tourVehicle = CreateVehicle(modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)
    
    -- Set as mission entity so it doesn't disappear
    SetEntityAsMissionEntity(tourVehicle, true, true)
    
    -- Set some properties
    SetVehicleOnGroundProperly(tourVehicle)
    SetModelAsNoLongerNeeded(modelHash)
    SetVehicleNumberPlateText(tourVehicle, "TOUR" .. math.random(100, 999))
    
    -- Give keys to player
    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(tourVehicle))
    
    -- Add a blip for the vehicle
    local vehicleBlip = AddBlipForEntity(tourVehicle)
    SetBlipSprite(vehicleBlip, 427) -- Tour bus icon
    SetBlipColour(vehicleBlip, 26) -- Light blue
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Tour Vehicle")
    EndTextCommandSetBlipName(vehicleBlip)
end

-- Function to spawn tourists
function SpawnTourists()
    -- Get number of tourists (random between 1 and max)
    local numTourists = math.random(1, Config.MaxTourists)
    
    -- Get vehicle seating capacity
    local seats = GetVehicleMaxNumberOfPassengers(tourVehicle)
    
    -- Limit tourists to available seats
    if numTourists > seats then
        numTourists = seats
    end
    
    -- Get the start location
    local startPoint = Config.TourLocations[currentTour].startPoint
    
    -- Spawn each tourist
    for i = 1, numTourists do
        -- Select random model
        local modelName = Config.TouristModels[math.random(1, #Config.TouristModels)]
        local modelHash = GetHashKey(modelName)
        
        -- Request the model
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
        
        -- Create the tourist NPC
        local tourist = CreatePed(4, modelHash, 
            startPoint.x + math.random(-3, 3), 
            startPoint.y + math.random(-3, 3), 
            startPoint.z, 
            startPoint.w, true, false)
        
        -- Set as mission entity
        SetEntityAsMissionEntity(tourist, true, true)
        
        -- Set some properties
        SetPedCanRagdoll(tourist, false)
        SetPedConfigFlag(tourist, 185, true) -- Disable collisions
        SetPedConfigFlag(tourist, 32, false) -- Can't be knocked off vehicle
        SetPedConfigFlag(tourist, 281, true) -- Disable melee
        SetBlockingOfNonTemporaryEvents(tourist, true)
        
        -- Set random walking style
        local walkingStyles = {"move_m@brave", "move_m@confident", "move_m@casual@d", "move_f@sexy@a"}
        RequestAnimSet(walkingStyles[math.random(1, #walkingStyles)])
        SetPedMovementClipset(tourist, walkingStyles[math.random(1, #walkingStyles)], 1.0)
        
        -- Task to get in the tour vehicle
        TaskEnterVehicle(tourist, tourVehicle, -1, i, 1.0, 1, 0)
        
        -- Store tourist data
        table.insert(currentTourists, {
            ped = tourist,
            id = i,
            satisfaction = 50, -- Start at neutral satisfaction
            knowledgeAnswer = nil -- To store answer during knowledge checks
        })
        
        -- Set model as no longer needed
        SetModelAsNoLongerNeeded(modelHash)
        
        -- Random greeting
        local randomGreeting = Config.TouristPhrases.greeting[math.random(1, #Config.TouristPhrases.greeting)]
        TriggerTouristSpeech(tourist, randomGreeting)
    end
    
    -- Notify player about tourists
    QBCore.Functions.Notify(numTourists .. " tourists have joined your tour!", "success")
end

-- Function to create destination point
function CreateDestinationPoint(location)
    -- Create/update blip
    if destinationBlip then
        RemoveBlip(destinationBlip)
    end
    destinationBlip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(destinationBlip, 162) -- Waypoint icon
    SetBlipDisplay(destinationBlip, 4)
    SetBlipScale(destinationBlip, 1.0)
    SetBlipColour(destinationBlip, 5) -- Yellow
    SetBlipRoute(destinationBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Tour Destination")
    EndTextCommandSetBlipName(destinationBlip)
    
    -- Create checkpoint
    if currentCheckpoint then
        DeleteCheckpoint(currentCheckpoint)
    end
    currentCheckpoint = CreateCheckpoint(45, location.x, location.y, location.z - 1.0, 0, 0, 0, 5.0, 255, 255, 0, 100, 0)
    
    -- Set current destination
    currentDestination = location
    
    -- Update UI
    SendNUIMessage({
        type = "UPDATE_DESTINATION",
        destination = currentTourPoints[currentTourPointIndex].name
    })
end

-- Function to trigger tourist speech
function TriggerTouristSpeech(ped, text)
    if not DoesEntityExist(ped) then return end
    
    -- Create text above head
    SetDrawOrigin(GetEntityCoords(ped))
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
    
    -- Play speech animation
    RequestAnimDict("mp_facial")
    while not HasAnimDictLoaded("mp_facial") do
        Wait(0)
    end
    TaskPlayAnim(ped, "mp_facial", "mic_chatter", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Create subtitle
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local pedCoords = GetEntityCoords(ped)
    if #(playerCoords - pedCoords) < 10.0 then
        PlayAmbientSpeech1(ped, "GENERIC_HI", "SPEECH_PARAMS_FORCE_NORMAL")
        SendNUIMessage({
            type = "TOURIST_SPEECH",
            text = text
        })
    end
end

-- Function to handle destination arrival
function HandleDestinationArrival()
    -- Stop the vehicle
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        SetVehicleHandbrake(GetVehiclePedIsIn(playerPed, false), true)
    end
    
    -- Update UI
    local currentPoint = currentTourPoints[currentTourPointIndex]
    SendNUIMessage({
        type = "SHOW_LANDMARK_INFO",
        name = currentPoint.name,
        description = currentPoint.description,
        facts = currentPoint.facts
    })
    
    -- Notify the player
    QBCore.Functions.Notify("You have arrived at " .. currentPoint.name .. ". Share information with your tourists!", "success")
    
    -- Tourist reactions
    for _, tourist in ipairs(currentTourists) do
        local randomDelay = math.random(2000, 5000)
        Wait(randomDelay)
        
        -- Random positive reaction
        local randomReaction = Config.TouristPhrases.positive[math.random(1, #Config.TouristPhrases.positive)]
        TriggerTouristSpeech(tourist.ped, randomReaction)
        
        -- Random question after a delay
        randomDelay = math.random(5000, 10000)
        Wait(randomDelay)
        local randomQuestion = Config.TouristPhrases.question[math.random(1, #Config.TouristPhrases.question)]
        TriggerTouristSpeech(tourist.ped, randomQuestion)
    end
    
    -- Start knowledge check after delay
    Wait(currentPoint.waitTime * 500) -- Half the wait time
    StartKnowledgeCheck(currentPoint)
    
    -- Wait for the rest of the time
    Wait(currentPoint.waitTime * 500) -- Other half of wait time
    
    -- Move to next destination
    MoveToNextDestination()
end

-- Function to start knowledge check
function StartKnowledgeCheck(currentPoint)
    -- Show the quiz question and options
    SendNUIMessage({
        type = "SHOW_KNOWLEDGE_CHECK",
        question = currentPoint.quizQuestion,
        options = currentPoint.quizOptions
    })
    
    -- Set up NUI callback to receive answer
    RegisterNUICallback("knowledgeCheckAnswer", function(data, cb)
        -- Check if answer is correct
        if tonumber(data.answer) == currentPoint.quizAnswer then
            -- Correct answer
            QBCore.Functions.Notify("Correct answer! Your tourists are impressed.", "success")
            knowledgePoints = knowledgePoints + 1
            
            -- Improve tourist satisfaction
            for _, tourist in ipairs(currentTourists) do
                tourist.satisfaction = tourist.satisfaction + 10
                if tourist.satisfaction > 100 then
                    tourist.satisfaction = 100
                end
                
                -- Positive reaction
                local randomReaction = Config.TouristPhrases.positive[math.random(1, #Config.TouristPhrases.positive)]
                TriggerTouristSpeech(tourist.ped, randomReaction)
            end
        else
            -- Incorrect answer
            QBCore.Functions.Notify("Incorrect answer. Your tourists are disappointed.", "error")
            
            -- Decrease tourist satisfaction
            for _, tourist in ipairs(currentTourists) do
                tourist.satisfaction = tourist.satisfaction - 10
                if tourist.satisfaction < 0 then
                    tourist.satisfaction = 0
                end
                
                -- Negative reaction
                local randomReaction = Config.TouristPhrases.negative[math.random(1, #Config.TouristPhrases.negative)]
                TriggerTouristSpeech(tourist.ped, randomReaction)
            end
        end
        
        cb({success = true})
    end)
end

-- Function to move to the next destination
function MoveToNextDestination()
    currentTourPointIndex = currentTourPointIndex + 1
    
    -- Check if tour is complete
    if currentTourPointIndex > #currentTourPoints then
        EndTour("completed")
        return
    end
    
    -- Create the next destination point
    CreateDestinationPoint(currentTourPoints[currentTourPointIndex].location)
    
    -- Notify player
    QBCore.Functions.Notify("Please proceed to the next destination: " .. currentTourPoints[currentTourPointIndex].name, "primary")
end

-- Function to start driving monitor
function StartDrivingMonitor()
    -- Create a thread to monitor driving
    Citizen.CreateThread(function()
        while tourActive do
            Wait(1000)
            
            local playerPed = PlayerPedId()
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if vehicle == tourVehicle then
                    -- Monitor speed
                    local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                    
                    -- Record max speed
                    if speed > maxSpeed then
                        maxSpeed = speed
                    end
                    
                    -- Reduce safety points for speeding
                    if speed > 80 then -- Over 80 km/h is too fast for a tour
                        safetyPoints = safetyPoints - 5
                        QBCore.Functions.Notify("You're driving too fast! Slow down for tourist safety.", "error")
                        
                        -- Reduce tourist satisfaction
                        for _, tourist in ipairs(currentTourists) do
                            tourist.satisfaction = tourist.satisfaction - 2
                            if tourist.satisfaction < 0 then
                                tourist.satisfaction = 0
                            end
                        end
                    end
                    
                    -- Reduce safety points for reckless driving
                    if HasEntityCollidedWithAnything(vehicle) then
                        safetyPoints = safetyPoints - 20
                        QBCore.Functions.Notify("You've hit something! Be more careful with your tourists!", "error")
                        
                        -- Reduce tourist satisfaction
                        for _, tourist in ipairs(currentTourists) do
                            tourist.satisfaction = tourist.satisfaction - 5
                            if tourist.satisfaction < 0 then
                                tourist.satisfaction = 0
                            end
                        end
                    end
                    
                    -- Limit safety points
                    if safetyPoints < 0 then
                        safetyPoints = 0
                    end
                    
                    -- Check for destination arrival
                    if currentDestination then
                        local vehicleCoords = GetEntityCoords(vehicle)
                        local destCoords = vector3(currentDestination.x, currentDestination.y, currentDestination.z)
                        
                        if #(vehicleCoords - destCoords) < 5.0 then
                            -- We've reached the destination
                            HandleDestinationArrival()
                            
                            -- Reset destination to prevent multiple triggers
                            currentDestination = nil
                        end
                    end
                end
            end
        end
    end)
end

-- Function to end the tour
function EndTour(reason)
    if not tourActive then return end
    
    -- Calculate tour ratings
    local knowledgeRating = math.floor((knowledgePoints / #currentTourPoints) * 5)
    if knowledgeRating < 1 then knowledgeRating = 1 end
    if knowledgeRating > 5 then knowledgeRating = 5 end
    
    local safetyRating = math.floor((safetyPoints / 300) * 5)
    if safetyRating < 1 then safetyRating = 1 end
    if safetyRating > 5 then safetyRating = 5 end
    
    -- Calculate entertainment rating based on tourist satisfaction
    local totalSatisfaction = 0
    for _, tourist in ipairs(currentTourists) do
        totalSatisfaction = totalSatisfaction + tourist.satisfaction
    end
    local averageSatisfaction = totalSatisfaction / #currentTourists
    local entertainmentRating = math.floor((averageSatisfaction / 100) * 5)
    if entertainmentRating < 1 then entertainmentRating = 1 end
    if entertainmentRating > 5 then entertainmentRating = 5 end
    
    -- Calculate timeliness
    local tourDuration = (GetGameTimer() - tourStartTime) / 60000 -- Convert to minutes
    local expectedDuration = Config.TourLocations[currentTour].duration
    local timelinessRating = 5 - math.abs(tourDuration - expectedDuration)
    if timelinessRating < 1 then timelinessRating = 1 end
    if timelinessRating > 5 then timelinessRating = 5 end
    
    -- Calculate overall rating
    local overallRating = math.floor((knowledgeRating + safetyRating + entertainmentRating + timelinessRating) / 4)
    
    -- Calculate payment and tip
    local basePay = Config.TourLocations[currentTour].price
    local tipPercentage = Config.TipMultipliers[overallRating]
    local tipAmount = math.floor(basePay * tipPercentage)
    local totalPay = basePay + tipAmount
    
    -- Only pay if tour was completed
    if reason == "completed" then
        -- Send payment data to server
        TriggerServerEvent("qb-tourguide:server:PayTourGuide", totalPay, basePay, tipAmount, overallRating)
        
        -- Tourist goodbye phrases
        for _, tourist in ipairs(currentTourists) do
            local randomGoodbye = Config.TouristPhrases.goodbye[math.random(1, #Config.TouristPhrases.goodbye)]
            TriggerTouristSpeech(tourist.ped, randomGoodbye)
            
            -- Delete the tourist ped after a delay
            Wait(math.random(1000, 3000))
            DeletePed(tourist.ped)
        end
    else
        -- Tour was cancelled
        QBCore.Functions.Notify("Tour cancelled. No payment received.", "error")
        
        -- Delete tourists
        for _, tourist in ipairs(currentTourists) do
            DeletePed(tourist.ped)
        end
    end
    
    -- Show tour results UI
    if reason == "completed" then
        SendNUIMessage({
            type = "SHOW_TOUR_RESULTS",
            ratings = {
                knowledge = knowledgeRating,
                safety = safetyRating,
                entertainment = entertainmentRating,
                timeliness = timelinessRating,
                overall = overallRating
            },
            payment = {
                base = basePay,
                tip = tipAmount,
                total = totalPay
            }
        })
    end
    
    -- Clean up tour data
    currentTourists = {}
    
    -- Delete vehicle after a delay
    Wait(10000) -- 10 seconds
    if DoesEntityExist(tourVehicle) then
        DeleteVehicle(tourVehicle)
    end
    
    -- Remove blips
    RemoveTourBlips()
    
    -- Reset tour state
    tourActive = false
    currentTour = nil
    currentTourPoints = nil
    currentTourPointIndex = 1
    knowledgePoints = 0
    
    -- Recreate tour starting blips
    CreateTourBlips()
end

-- NUI Callbacks
RegisterNUICallback("startTour", function(data, cb)
    StartTour(data.tourType)
    cb({success = true})
end)

RegisterNUICallback("endTour", function(data, cb)
    EndTour("cancelled")
    cb({success = true})
end)

RegisterNUICallback("closeUI", function(data, cb)
    SetNuiFocus(false, false)
    cb({success = true})
end)

-- Command to open tour menu
RegisterCommand("tourmenu", function()
    if PlayerData.job and PlayerData.job.name == "tourguide" then
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "OPEN_MENU",
            tours = Config.TourLocations
        })
    else
        QBCore.Functions.Notify("You are not a tour guide!", "error")
    end
end)

-- Create target for job locations
CreateThread(function()
    for tourType, tourData in pairs(Config.TourLocations) do
        exports['qb-target']:AddBoxZone("tourguide-" .. tourType, 
            vector3(tourData.startPoint.x, tourData.startPoint.y, tourData.startPoint.z), 2.0, 2.0, {
            name = "tourguide-" .. tourType,
            heading = tourData.startPoint.w,
            debugPoly = false,
            minZ = tourData.startPoint.z - 1.0,
            maxZ = tourData.startPoint.z + 1.0,
        }, {
            options = {
                {
                    type = "client",
                    event = "qb-tourguide:client:OpenTourMenu",
                    icon = "fas fa-map-marked",
                    label = "Start " .. tourData.name,
                    job = "tourguide",
                    tourType = tourType
                },
            },
            distance = 2.5
        })
    end
end)

-- Event for target interaction
RegisterNetEvent('qb-tourguide:client:OpenTourMenu', function(data)
    if data.tourType then
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "OPEN_SPECIFIC_TOUR",
            tourType = data.tourType,
            tour = Config.TourLocations[data.tourType]
        })
    else
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "OPEN_MENU",
            tours = Config.TourLocations
        })
    end
end)