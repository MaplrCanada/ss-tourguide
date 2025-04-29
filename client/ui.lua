-- This file handles communication with the NUI (HTML/CSS/JS)

local isNuiVisible = false

-- Helper function for debugging client-side
local function debugLog(msg)
    if Config.Debug then
        print(("^5[DEBUG | %s | CLIENT UI] %s^0"):format(GetCurrentResourceName(), msg))
    end
end

function SendNUIMessage(action, data)
    if not isNuiVisible and action ~= 'setVisible' then return end -- Don't send if not visible unless specifically showing it
    debugLog(("Sending NUI message: action=%s, data=%s"):format(action, json.encode(data or {})))
    SendNUIMessage({
        action = action,
        data = data or {}
    })
end

function SetNuiVisibility(visible)
    isNuiVisible = visible
    SetNuiFocus(visible, visible) -- Give focus when visible, remove when hidden
    SendNUIMessage('setVisible', { visible = visible })
    debugLog(("NUI visibility set to: %s"):format(tostring(visible)))
end

-- NUI Callback Handlers
RegisterNUICallback('closeNui', function(data, cb)
    SetNuiVisibility(false)
    cb({ ok = true }) -- Acknowledge the callback
    debugLog("NUI close requested.")
    -- Potentially trigger other cleanup if needed
end)

RegisterNUICallback('startSelectedTour', function(data, cb)
    local tourKey = data.tourKey
    if tourKey and Config.Tours[tourKey] then
        SetNuiVisibility(false) -- Hide selection UI
        TriggerEvent('tourguide:client:startTour', tourKey)
        cb({ ok = true })
        debugLog(("NUI requested start of tour: %s"):format(tourKey))
    else
        cb({ ok = false, message = "Invalid tour selected" })
         debugLog(("NUI requested invalid tour key: %s"):format(tostring(tourKey)))
    end
end)

RegisterNUICallback('nextPOI', function(data, cb)
    TriggerEvent('tourguide:client:proceedToNextPOI')
    cb({ ok = true })
    debugLog("NUI requested next POI.")
end)

RegisterNUICallback('submitQuizAnswer', function(data, cb)
    local answer = data.answer
    if answer then
        TriggerEvent('tourguide:client:processQuizAnswer', answer)
        cb({ ok = true })
        debugLog(("NUI submitted quiz answer: %s"):format(answer))
    else
        cb({ ok = false, message = "No answer provided"})
        debugLog("NUI submitted empty quiz answer.")
    end
end)

RegisterNUICallback('endTourEarly', function(data, cb) -- Allow player to end tour from UI
    SetNuiVisibility(false)
    TriggerEvent('tourguide:client:forceEndTour', "Ended early by guide.")
    cb({ ok = true })
    debugLog("NUI requested early tour end.")
end)


-- Functions called from client/main.lua to update the UI
function UpdateUIState(stateData)
    -- stateData could include: { onTour=true, currentPOI=1, totalPOIs=5, poiName="Legion Square", distance=120.5, npcCount=6, avgRating=0.8, quizActive=false, etc. }
    SendNUIMessage('updateState', stateData)
end

function ShowTourSelection(toursData)
    -- toursData = { { key="downtown", label="Downtown Delights", time=10 }, { key="paleto", label="Paleto Cruise", time=15 } }
    SendNUIMessage('showTourSelection', toursData)
    SetNuiVisibility(true)
end

function ShowPOIInfo(poiData)
     -- poiData = { name="Legion Square", info="Blah blah blah..." }
     SendNUIMessage('showPOIInfo', poiData)
     SetNuiVisibility(true) -- Ensure UI is visible when POI info/quiz shows
end

function ShowQuiz(quizData)
    -- quizData = { q="What is this?", options={"A", "B", "C", "D"} }
    SendNUIMessage('showQuiz', quizData)
    SetNuiVisibility(true) -- Keep UI visible for quiz
end

function HideQuiz()
    SendNUIMessage('hideQuiz')
    -- Don't necessarily hide the whole NUI here, just the quiz part
end

-- Event listener to hide NUI if player goes off duty during tour selection etc.
RegisterNetEvent('tourguide:client:updateDutyState', function(onDuty)
    if not onDuty and isNuiVisible then
        local state = GetTourState() -- Assuming GetTourState() exists in main.lua
        if not state.onTour then -- Only hide if not actively on a tour
             SetNuiVisibility(false)
             debugLog("Hiding NUI because player went off duty (not on tour).")
        end
    end
end)


debugLog("Client UI script loaded.")