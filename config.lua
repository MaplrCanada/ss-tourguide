Config = {}

Config.TourLocations = {
    -- Los Santos City Tour
    ["city"] = {
        name = "Los Santos City Tour",
        description = "Experience the urban wonders of Los Santos with our comprehensive city tour!",
        price = 350, -- How much tourists pay for a complete tour
        duration = 30, -- Total minutes for the full tour
        image = "city_tour.png",
        startPoint = vector4(-517.73, -257.49, 35.93, 24.31), -- Arcadius Business Center
        tourPoints = {
            {
                location = vector4(-517.73, -257.49, 35.93, 24.31),
                name = "Arcadius Business Center",
                description = "One of Los Santos' premier office buildings, home to numerous corporations.",
                facts = {
                    "Arcadius Business Center stands at 320 meters tall, making it one of the tallest buildings in Los Santos.",
                    "The building features a unique design with a garden atrium in its center.",
                    "It was completed in 2013 at a cost of $850 million."
                },
                quizQuestion = "How tall is the Arcadius Business Center?",
                quizOptions = {"220 meters", "320 meters", "420 meters", "520 meters"},
                quizAnswer = 2,
                waitTime = 60 -- seconds to wait at this location
            },
            {
                location = vector4(-75.71, -819.52, 326.18, 50.68),
                name = "Maze Bank Tower",
                description = "The tallest skyscraper in Los Santos, housing the headquarters of Maze Bank.",
                facts = {
                    "Maze Bank Tower is the tallest building in the state of San Andreas.",
                    "The observation deck offers panoramic views of the entire city.",
                    "Its distinctive design was inspired by US Bank Tower in Los Angeles."
                },
                quizQuestion = "What is housed in the Maze Bank Tower?",
                quizOptions = {"FIB Headquarters", "Maze Bank Headquarters", "Life Invader Offices", "Union Depository"},
                quizAnswer = 2,
                waitTime = 60
            },
            {
                location = vector4(188.46, -579.34, 43.12, 287.84),
                name = "Pillbox Medical Center",
                description = "The main hospital serving downtown Los Santos.",
                facts = {
                    "Pillbox Medical Center is the largest hospital in Los Santos.",
                    "The hospital has state-of-the-art trauma facilities.",
                    "It employs over 500 medical professionals around the clock."
                },
                quizQuestion = "What type of facility is Pillbox?",
                quizOptions = {"Police Station", "Hospital", "Fire Station", "Government Office"},
                quizAnswer = 2,
                waitTime = 60
            },
            {
                location = vector4(100.78, -933.55, 29.82, 161.56),
                name = "Legion Square",
                description = "The central public space of Los Santos, surrounded by skyscrapers.",
                facts = {
                    "Legion Square is modeled after Pershing Square in Los Angeles.",
                    "It serves as a gathering place for many public events and protests.",
                    "The square was renovated in 2010 at a cost of $30 million."
                },
                quizQuestion = "What real-life location is Legion Square modeled after?",
                quizOptions = {"Times Square", "Central Park", "Pershing Square", "Union Square"},
                quizAnswer = 3,
                waitTime = 60
            },
            {
                location = vector4(233.18, -410.35, 48.11, 159.37),
                name = "City Hall",
                description = "The center of Los Santos government and municipal services.",
                facts = {
                    "Los Santos City Hall was built in 1928.",
                    "The building features a distinctive Art Deco style.",
                    "It houses the mayor's office and city council chambers."
                },
                quizQuestion = "In what year was Los Santos City Hall built?",
                quizOptions = {"1908", "1928", "1948", "1968"},
                quizAnswer = 2,
                waitTime = 60
            }
        }
    },
    
    -- Vinewood Tour
    ["vinewood"] = {
        name = "Vinewood Star Tour",
        description = "See where the stars live, work and play in glamorous Vinewood!",
        price = 500,
        duration = 25,
        image = "vinewood_tour.png",
        startPoint = vector4(311.58, 218.62, 104.9, 164.92), -- Vinewood Boulevard
        tourPoints = {
            {
                location = vector4(311.58, 218.62, 104.9, 164.92),
                name = "Vinewood Boulevard",
                description = "The most famous street in Los Santos, lined with theaters and boutiques.",
                facts = {
                    "Vinewood Boulevard is based on the real-life Hollywood Boulevard.",
                    "The Walk of Fame features over 200 stars dedicated to Vinewood celebrities.",
                    "The first star was placed in 1953 for actress Leonora Johnson."
                },
                quizQuestion = "What real-life street is Vinewood Boulevard based on?",
                quizOptions = {"Rodeo Drive", "Sunset Boulevard", "Hollywood Boulevard", "Melrose Avenue"},
                quizAnswer = 3,
                waitTime = 60
            },
            {
                location = vector4(719.12, 1204.47, 325.98, 320.78),
                name = "Vinewood Sign",
                description = "The iconic landmark overlooking the city of Los Santos.",
                facts = {
                    "The Vinewood Sign was originally erected in 1923 as an advertisement.",
                    "Each letter stands approximately 45 feet tall.",
                    "The sign has been featured in countless movies and TV shows."
                },
                quizQuestion = "When was the Vinewood Sign originally erected?",
                quizOptions = {"1903", "1923", "1943", "1963"},
                quizAnswer = 2,
                waitTime = 60
            },
            {
                location = vector4(-785.45, 315.67, 85.66, 280.15),
                name = "Richman Mansion",
                description = "One of the most expensive residential properties in Los Santos.",
                facts = {
                    "Richman Mansion spans over 20,000 square feet of living space.",
                    "The property includes a private tennis court, swimming pool, and helipad.",
                    "It was previously owned by movie producer Solomon Richards."
                },
                quizQuestion = "What feature does Richman Mansion NOT have?",
                quizOptions = {"Tennis Court", "Swimming Pool", "Underwater Theater", "Helipad"},
                quizAnswer = 3,
                waitTime = 60
            },
            {
                location = vector4(-810.18, -210.75, 37.09, 295.56),
                name = "Oriental Theater",
                description = "Historic movie palace where many film premieres are held.",
                facts = {
                    "The Oriental Theater opened in 1927.",
                    "It can seat over 900 people for premieres and special events.",
                    "The theater's design is inspired by Chinese architecture."
                },
                quizQuestion = "When did the Oriental Theater open?",
                quizOptions = {"1907", "1927", "1947", "1967"},
                quizAnswer = 2,
                waitTime = 60
            },
            {
                location = vector4(7.76, 543.7, 176.02, 238.5),
                name = "Rockford Hills",
                description = "The most affluent neighborhood in Los Santos.",
                facts = {
                    "Rockford Hills is based on Beverly Hills in Los Angeles.",
                    "The area has the highest property values in the entire state.",
                    "Many Vinewood celebrities and executives live in this exclusive enclave."
                },
                quizQuestion = "What real-life neighborhood is Rockford Hills based on?",
                quizOptions = {"Bel Air", "Beverly Hills", "Hollywood Hills", "Malibu"},
                quizAnswer = 2,
                waitTime = 60
            }
        }
    },
    
    -- Natural Wonders Tour
    ["nature"] = {
        name = "San Andreas Natural Wonders",
        description = "Explore the breathtaking natural beauty of San Andreas!",
        price = 450,
        duration = 35,
        image = "nature_tour.png",
        startPoint = vector4(-1603.64, 5252.91, 3.97, 297.76), -- Paleto Bay
        tourPoints = {
            {
                location = vector4(-1603.64, 5252.91, 3.97, 297.76),
                name = "Paleto Bay",
                description = "A charming coastal town on the northern edge of San Andreas.",
                facts = {
                    "Paleto Bay is known for its fishing industry and coastal charm.",
                    "The area was first settled by fishermen in the late 1800s.",
                    "The nearby mountains create a unique microclimate for the region."
                },
                quizQuestion = "What industry is Paleto Bay known for?",
                quizOptions = {"Technology", "Fishing", "Mining", "Automotive"},
                quizAnswer = 2,
                waitTime = 60
            },
            {
                location = vector4(501.35, 5603.6, 795.91, 184.33),
                name = "Mount Chiliad",
                description = "The highest peak in San Andreas, offering spectacular views.",
                facts = {
                    "Mount Chiliad stands at 798 meters above sea level.",
                    "The mountain is a popular destination for hikers and mountain bikers.",
                    "Ancient rock carvings can be found in caves throughout the mountain."
                },
                quizQuestion = "How tall is Mount Chiliad?",
                quizOptions = {"598 meters", "698 meters", "798 meters", "898 meters"},
                quizAnswer = 3,
                waitTime = 60
            },
            {
                location = vector4(-501.74, 4195.33, 41.56, 175.12),
                name = "Cassidy Creek",
                description = "A picturesque river running through the San Andreas wilderness.",
                facts = {
                    "Cassidy Creek is fed by snowmelt from the mountains.",
                    "The creek is home to several endangered fish species.",
                    "The Raton Canyon was carved by the creek over millions of years."
                },
                quizQuestion = "What formed the Raton Canyon?",
                quizOptions = {"Volcanic activity", "Tectonic shifting", "Cassidy Creek erosion", "Meteor impact"},
                quizAnswer = 3,
                waitTime = 60
            },
            {
                location = vector4(2802.12, 5985.1, 350.82, 270.45),
                name = "Grapeseed Farms",
                description = "The agricultural heartland of San Andreas.",
                facts = {
                    "Grapeseed produces over 40% of the state's agricultural output.",
                    "The fertile soil is the result of ancient volcanic activity.",
                    "The area specializes in vineyards and organic produce."
                },
                quizQuestion = "What percentage of the state's agricultural output comes from Grapeseed?",
                quizOptions = {"20%", "30%", "40%", "50%"},
                quizAnswer = 3,
                waitTime = 60
            },
            {
                location = vector4(-1938.82, 4623.92, 38.67, 45.04),
                name = "Alamo Sea",
                description = "The largest inland body of water in San Andreas.",
                facts = {
                    "The Alamo Sea was once much larger during prehistoric times.",
                    "Environmental concerns have been raised due to pollution from nearby industries.",
                    "It's a popular spot for fishing despite environmental warnings."
                },
                quizQuestion = "What environmental issue affects the Alamo Sea?",
                quizOptions = {"Overfishing", "Pollution", "Drought", "Invasive species"},
                quizAnswer = 2,
                waitTime = 60
            }
        }
    }
}

Config.TourGuideVehicles = {
    {model = "tourbus", label = "Tour Bus", seats = 8},
    {model = "stretch", label = "Stretch Limousine", seats = 4},
    {model = "pbus2", label = "Festival Bus", seats = 10}
}

Config.VehicleSpawns = {
    vector4(-494.78, -255.09, 35.58, 29.72),
    vector4(280.62, 200.85, 104.37, 160.0),
    vector4(-1591.64, 5258.53, 3.97, 302.64)
}

Config.MaxTourists = 4 -- Maximum number of NPCs per tour

Config.TouristModels = {
    "a_f_m_beach_01",
    "a_f_m_bevhills_01",
    "a_f_m_bevhills_02",
    "a_f_m_bodybuild_01",
    "a_f_m_business_02",
    "a_f_m_downtown_01",
    "a_f_m_eastsa_01",
    "a_f_m_eastsa_02",
    "a_f_m_fatbla_01",
    "a_f_m_fatwhite_01",
    "a_f_m_ktown_01",
    "a_f_m_ktown_02",
    "a_f_m_prolhost_01",
    "a_f_m_salton_01",
    "a_f_m_skidrow_01",
    "a_f_m_soucent_01",
    "a_f_m_soucent_02",
    "a_f_m_soucentmc_01",
    "a_f_m_tourist_01",
    "a_f_o_genstreet_01",
    "a_f_o_indian_01",
    "a_f_o_ktown_01",
    "a_f_o_salton_01",
    "a_f_y_beach_01",
    "a_f_y_bevhills_01",
    "a_f_y_bevhills_02",
    "a_f_y_bevhills_03",
    "a_f_y_bevhills_04",
    "a_f_y_business_01",
    "a_f_y_business_02",
    "a_f_y_business_03",
    "a_f_y_business_04",
    "a_f_y_eastsa_01",
    "a_f_y_eastsa_02",
    "a_f_y_eastsa_03",
    "a_f_y_epsilon_01",
    "a_f_y_fitness_01",
    "a_f_y_fitness_02",
    "a_f_y_genhot_01",
    "a_f_y_golfer_01",
    "a_f_y_hiker_01",
    "a_f_y_hippie_01",
    "a_f_y_hipster_01",
    "a_f_y_hipster_02",
    "a_f_y_hipster_03",
    "a_f_y_hipster_04",
    "a_f_y_indian_01",
    "a_f_y_juggalo_01",
    "a_f_y_runner_01",
    "a_f_y_rurmeth_01",
    "a_f_y_scdressy_01",
    "a_f_y_skater_01",
    "a_f_y_soucent_01",
    "a_f_y_soucent_02",
    "a_f_y_soucent_03",
    "a_f_y_tennis_01",
    "a_f_y_tourist_01",
    "a_f_y_tourist_02",
    "a_f_y_vinewood_01",
    "a_f_y_vinewood_02",
    "a_f_y_vinewood_03",
    "a_f_y_vinewood_04",
    "a_f_y_yoga_01",
    "a_m_m_afriamer_01",
    "a_m_m_beach_01",
    "a_m_m_beach_02",
    "a_m_m_bevhills_01",
    "a_m_m_bevhills_02",
    "a_m_m_business_01",
    "a_m_m_eastsa_01",
    "a_m_m_eastsa_02",
    "a_m_m_farmer_01",
    "a_m_m_fatlatin_01",
    "a_m_m_genfat_01",
    "a_m_m_genfat_02",
    "a_m_m_golfer_01",
    "a_m_m_hasjew_01",
    "a_m_m_hillbilly_01",
    "a_m_m_hillbilly_02",
    "a_m_m_indian_01",
    "a_m_m_ktown_01",
    "a_m_m_malibu_01",
    "a_m_m_mexcntry_01",
    "a_m_m_mexlabor_01",
    "a_m_m_og_boss_01",
    "a_m_m_paparazzi_01",
    "a_m_m_polynesian_01",
    "a_m_m_prolhost_01",
    "a_m_m_rurmeth_01",
    "a_m_m_salton_01",
    "a_m_m_salton_02",
    "a_m_m_salton_03",
    "a_m_m_salton_04",
    "a_m_m_skater_01",
    "a_m_m_skidrow_01",
    "a_m_m_socenlat_01",
    "a_m_m_soucent_01",
    "a_m_m_soucent_02",
    "a_m_m_soucent_03",
    "a_m_m_soucent_04",
    "a_m_m_stlat_02",
    "a_m_m_tennis_01",
    "a_m_m_tourist_01",
    "a_m_m_tramp_01",
    "a_m_m_trampbeac_01",
    "a_m_m_tourist_01",
    "a_m_y_beachvesp_01",
    "a_m_y_beachvesp_02",
    "a_m_y_beach_01",
    "a_m_y_beach_02",
    "a_m_y_beach_03"
}

Config.TouristPhrases = {
    greeting = {
        "Hi there! Looking forward to the tour!",
        "Hello! I'm excited to see the sights!",
        "Good day! I've heard great things about your tours!",
        "Hey! I can't wait to explore Los Santos!",
        "Greetings! This is my first time in San Andreas!"
    },
    goodbye = {
        "Thanks for the tour! It was wonderful!",
        "That was so informative! I'll recommend you to my friends!",
        "What a great experience! Five stars!",
        "I learned so much today! Thank you!",
        "Bye! I'll never forget this tour!"
    },
    positive = {
        "This is amazing!",
        "Wow, I never knew that!",
        "That's fascinating information!",
        "Oh, what a beautiful sight!",
        "I'm so glad we came to this spot!"
    },
    negative = {
        "Are we just going to stand here all day?",
        "I thought this tour would be more exciting...",
        "My feet are getting tired.",
        "Is this really worth the money?",
        "I could have looked this up online..."
    },
    question = {
        "How long has this landmark been here?",
        "What's the history behind this place?",
        "Can you tell us an interesting fact about this spot?",
        "Is there a famous story connected to this location?",
        "Do many locals visit this area or mostly tourists?"
    }
}

Config.RatingCriteria = {
    knowledge = {
        name = "Knowledge",
        description = "How well you knew information about tour locations"
    },
    safety = {
        name = "Safety",
        description = "How safely you drove and conducted the tour"
    },
    entertainment = {
        name = "Entertainment",
        description = "How engaging and entertaining the tour was"
    },
    timeliness = {
        name = "Timeliness",
        description = "How well you managed the tour time"
    }
}

Config.TipMultipliers = {
    [1] = 0.0,   -- 1 star rating gets no tip
    [2] = 0.1,   -- 2 star rating gets 10% tip
    [3] = 0.15,  -- 3 star rating gets 15% tip
    [4] = 0.25,  -- 4 star rating gets 25% tip
    [5] = 0.4    -- 5 star rating gets 40% tip
}