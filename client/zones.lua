-- This uses ox_lib zones, which are efficient.
-- If you don't use ox_lib, you'd need to implement PolyZone or standard distance checks.

local loadedZones = {}

-- Helper function for debugging client-side
local function debugLog(msg)
    if Config.Debug then
        print(("^5[DEBUG | %s | CLIENT] %s^0"):format(GetCurrentResourceName(), msg))
    end
end

function CreateTourZones()
    debugLog("Creating tour zones...")
    -- Duty Zone
    loadedZones.dutyZone = lib.zones.box({
        coords = Config.Locations.duty,
        size = vec3(3.0, 3.0, 2.0), -- Adjust size as needed
        debug = Config.Debug,
        onEnter = function()
            debugLog("Entered duty zone")
            -- Logic handled by qb-target now, this is just for potential extra triggers
        end,
        onExit = function()
             debugLog("Exited duty zone")
             -- Potentially hide target options if needed, though qb-target distance check usually handles this
        end
    })

    -- NPC Loading Zone
    loadedZones.npcLoadZone = lib.zones.box({
        coords = Config.Locations.npcLoadZone,
        size = vec3(5.0, 5.0, 3.0),
        debug = Config.Debug,
        -- onEnter/onExit handled dynamically when tour is active
    })

    -- NPC Despawn Zone
    loadedZones.npcDespawnZone = lib.zones.box({
        coords = Config.Locations.npcDespawnZone,
        size = vec3(5.0, 5.0, 3.0),
        debug = Config.Debug,
        -- onEnter/onExit handled dynamically when tour is active
    })

    debugLog("Base zones created.")
end

function CreatePOIZones(poiCoords)
    debugLog("Creating POI zone...")
    if loadedZones.poiZone then
        loadedZones.poiZone:remove() -- Remove previous POI zone if exists
        loadedZones.poiZone = nil
        debugLog("Removed existing POI zone.")
    end

    if poiCoords then
        loadedZones.poiZone = lib.zones.sphere({
            coords = poiCoords,
            radius = 15.0, -- How close player needs to be to trigger POI
            debug = Config.Debug,
            onEnter = function()
                debugLog("Entered POI zone")
                TriggerEvent('tourguide:client:enteredPOI')
            end,
            onExit = function()
                debugLog("Exited POI zone")
                TriggerEvent('tourguide:client:exitedPOI')
            end
        })
        debugLog(("POI zone created at %s"):format(tostring(poiCoords)))
    end
end

function RemovePOIZone()
    if loadedZones.poiZone then
        loadedZones.poiZone:remove()
        loadedZones.poiZone = nil
        debugLog("Removed POI zone.")
    end
end

function RemoveAllZones()
    debugLog("Removing all zones...")
    for k, zone in pairs(loadedZones) do
        if zone and zone.remove then
           zone:remove()
        end
    end
    loadedZones = {}
    debugLog("All zones removed.")
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveAllZones()
    end
end)

-- Initial creation
CreateTourZones()
debugLog("Client zones script loaded.")