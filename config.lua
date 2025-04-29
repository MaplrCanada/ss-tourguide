Config = {}

Config.JobName = "tourguide" -- The job name as defined in qb-core/shared/jobs.lua

Config.Locations = {
    duty = vector3(-555.5, -605.0, 34.0), -- Example: Near Vinewood Tours building
    vehicleSpawn = vector4(-560.0, -608.0, 33.8, 180.0), -- Where the bus spawns (x,y,z, heading)
    npcLoadZone = vector3(-558.0, -606.0, 34.0), -- Zone where NPCs appear and walk to the bus
    npcDespawnZone = vector3(-558.0, -606.0, 34.0), -- Zone where NPCs get off and despawn (can be same as load)
}

Config.DutyBlip = { -- qb-blips integration (optional)
    coords = Config.Locations.duty,
    sprite = 489, -- Tourbus blip sprite
    color = 47,  -- Light Blue
    scale = 0.8,
    label = "Tour Guide Duty",
    display = 4, -- Show for everyone
}

Config.Vehicles = {
    ["tourbus"] = { label = "Tour Bus", model = "tourbus", price = 0 }, -- Price is 0 as it's a job vehicle
    ["coach"] = { label = "Coach Bus", model = "coach", price = 0 },
    -- Add more vehicle options if desired
}

Config.MaxNPCs = 6 -- How many NPCs join the tour
Config.NPCModels = { -- List of ped models for tourists
    "a_f_y_tourist_01",
    "a_f_y_tourist_02",
    "a_m_y_tourist_01",
    "a_m_y_vinewood_01",
    "a_f_y_vinewood_01",
    "g_m_y_strpunk_01", -- Add variety
}

Config.Tours = {
    ["downtown"] = {
        label = "Downtown Delights Tour",
        estimatedTime = 10, -- Minutes (approximate)
        pointsOfInterest = {
            { coords = vector3(130.5, -755.0, 45.8), name = "Legion Square", info = "This is the heart of downtown, known for its vibrant atmosphere and gatherings.", quiz = { q = "What is this central square called?", a = "Legion Square", options = {"City Hall Plaza", "Legion Square", "Pershing Square", "Maze Bank Plaza"} } },
            { coords = vector3(-140.0, -625.0, 168.8), name = "Maze Bank Tower", info = "The tallest building in Los Santos, offering breathtaking views.", quiz = { q = "Which bank's name is on the tallest building?", a = "Maze Bank", options = {"Fleeca Bank", "Bank of Liberty", "Maze Bank", "Lombank"} } },
            { coords = vector3(-540.0, -210.0, 37.6), name = "Rockford Hills City Hall", info = "An iconic government building featured in many films.", quiz = { q = "This building represents which affluent area's governance?", a = "Rockford Hills", options = {"Vinewood", "Rockford Hills", "Vespucci", "Downtown LS"} } },
            -- Add more POIs for this tour
        },
    },
    ["paleto"] = {
        label = "Paleto Bay Coastal Cruise",
        estimatedTime = 15,
        pointsOfInterest = {
            { coords = vector3(-145.5, 6335.0, 31.5), name = "Paleto Bay Sheriff's Office", info = "The local law enforcement headquarters, keeping the peace in this seaside town.", quiz = { q = "What type of building is this?", a = "Sheriff's Office", options = {"Fire Station", "Bank", "Sheriff's Office", "Post Office"} } },
            { coords = vector3(235.0, 6500.0, 29.8), name = "Cluckin' Bell Farms", info = "A major poultry processing plant on the outskirts of Paleto.", quiz = { q = "What fast-food brand is associated with this farm?", a = "Cluckin' Bell", options = {"Burger Shot", "Up-n-Atom", "Cluckin' Bell", "Pizza This"} } },
            { coords = vector3(490.0, 6490.0, 28.5), name = "Beeker's Garage", info = "The primary mechanic and mod shop serving the Paleto Bay area.", quiz = { q = "What service does Beeker's primarily offer?", a = "Vehicle Repair", options = {"Grocery Store", "Gun Shop", "Vehicle Repair", "Clothing Store"} } },
            -- Add more POIs
        },
    },
    ["grapeseed"] = {
        label = "Grapeseed Countryside Jaunt",
        estimatedTime = 12,
        pointsOfInterest = {
             { coords = vector3(1695.0, 4825.0, 42.0), name = "McKenzie Field Hangar", info = "An airfield primarily used for smuggling and crop-dusting.", quiz = { q = "What is this location mainly used for?", a = "Airfield", options = {"Race Track", "Airfield", "Farm Market", "Train Depot"} } },
             { coords = vector3(1480.0, 4920.0, 43.5), name = "Grapeseed Main Street", info = "The quiet central street of this agricultural town.", quiz = { q = "Grapeseed is known for what industry?", a = "Agriculture", options = {"Tourism", "Finance", "Agriculture", "Manufacturing"} } },
             { coords = vector3(2440.0, 4970.0, 46.7), name = "Sandy Shores Airfield", info = "Technically closer to Sandy, but a landmark near Grapeseed often visited.", quiz = { q = "What town is this airfield officially part of?", a = "Sandy Shores", options = {"Grapeseed", "Paleto Bay", "Sandy Shores", "Harmony"} } },
            -- Add more POIs
        },
    },
    -- Add more tour types (e.g., Vinewood Stars, Vespucci Beach)
}

Config.Payment = {
    base = 50, -- Base pay regardless of rating
    ratingMultiplier = 150, -- Max bonus pay = ratingMultiplier * 1.0 (e.g., 150 * 1.0 = $150 bonus for perfect rating)
    ratingTiers = { -- Feedback text based on average rating (0.0 to 1.0)
        { threshold = 0.0, text = "Terrible! The tourists learned nothing." },
        { threshold = 0.3, text = "Poor. The tourists were mostly confused." },
        { threshold = 0.6, text = "Okay. Some tourists enjoyed it, some didn't." },
        { threshold = 0.8, text = "Good! Most tourists had a positive experience." },
        { threshold = 0.95, text = "Excellent! The tourists loved your tour!" },
    }
}

Config.Target = { -- qb-target settings
    duty = {
        icon = "fas fa-sign-in-alt", -- Font Awesome icon
        label = "Toggle Tour Guide Duty",
        job = Config.JobName,
    },
    vehicle = {
        icon = "fas fa-bus",
        label = "Select Tour Vehicle",
        job = Config.JobName,
        onDuty = true, -- Requires player to be on duty
    },
    -- Add target options for NPCs if needed (e.g., manual boarding trigger)
}

Config.CooldownSeconds = 300 -- 5 minutes cooldown between tours

Config.Debug = true -- Set to true to print debug messages in console