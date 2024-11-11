local addonName, addonCore = ...
local svDefaults = addonCore.svDefaults

--[[
Stats:
Horde Stats:
--Flight Count: 759
--Total Duration: 155007 1 |4Day:Days; 19 |4Hr:Hr;
Alliance Stats:
--Flight Count: 61
--Total Duration: 10170 2 |4Hr:Hr; 49 |4Min:Min;
]]
svDefaults.global["gossipTriggered"] = {
	-- [gossipOptionID] = {startingPoint, endingPoint},
	-- Gossip Triggered Flights get integrated in to main Horde/Alliance DB as they occur as any other flight.
	-- Only Non-Quest Flights Included
	-- we set a start locatoin name and end location name here as it's not provided otherwise and is needed to work.

	--Old World
	[89449] = { "Moonglade", "Thunder Bluff, Mulgore" }, --Druid Flight
	[91907] = { "Tanaris", "Caverns of Time" },
	--TBC
	[92213] = { "Skyguard Outpost", "Blackwind Landing" },
	[92215] = { "Blackwind Landing", "Skyguard Outpost" },
	[92694] = { "The Sin'loren", "Sun's Reach Harbor" },
	[93033] = { "Sun's Reach Harbor", "The Sin'loren" },
	--Wrath
	[93559] = { "Bottom, Wyrmrest Temple", "Middle, Wyrmrest Temple" },
	[93560] = { "Bottom, Wyrmrest Temple", "Top, Wyrmrest Temple" },
	[93568] = { "Middle, Wyrmrest Temple", "Bottom, Wyrmrest Temple" },
	[93569] = { "Middle, Wyrmrest Temple", "Top, Wyrmrest Temple" },
	[93074] = { "Top, Wyrmrest Temple", "Bottom, Wyrmrest Temple" },
	[93073] = { "Top, Wyrmrest Temple", "Middle, Wyrmrest Temple" },
	[93707] = { "Argent Tournament Grounds, Icecrown", "Get Kraken!" },
	[94294] = { "Dalaran", "Orgrim's Hammer, Icecrown" },
	[94293] = { "Dalaran", "Skybreaker, Icecrown" },
	--Cata
	[112430] = { "Orgrimmar Exchange", "Southern Terminus" },
	[112431] = { "Orgrimmar Exchange", "Gallywix Exchange" },
	[112432] = { "Orgrimmar Exchange", "Northern Exchange" },
	[112433] = { "Orgrimmar Exchange", "North Terminus" },
	[112434] = { "Southern Terminus", "Orgrimmar Exchange" },
	[112435] = { "Southern Terminus", "Gallywix Exchange" },
	[112436] = { "Southern Terminus", "Northern Exchange" },
	[112437] = { "Southern Terminus", "North Terminus" },
	[112439] = { "Gallywix Exchange", "Orgrimmar Exchange" },
	[112440] = { "Gallywix Exchange", "Northern Exchange" },
	[112441] = { "Gallywix Exchange", "Southern Terminus" },
	[112442] = { "Gallywix Exchange", "North Terminus" },
	[112443] = { "Northern Exchange", "North Terminus" },
	[112444] = { "Northern Exchange", "Gallywix Exchange" },
	[112445] = { "Northern Exchange", "Orgrimmar Exchange" },
	[112446] = { "Northern Exchange", "Southern Terminus" },
	[112447] = { "Southern Terminus", "Northern Exchange" },
	[112448] = { "Southern Terminus", "Gallywix Exchange" },
	[112449] = { "Southern Terminus", "Orgrimmar Exchange" },
	[112450] = { "Southern Terminus", "Southern Terminus" },

}

svDefaults.global["Horde"] = {
	["Transitus Shield, Coldarra"] = {
		["Warsong Hold, Borean Tundra"] = 57,
		["Camp Oneqwah, Grizzly Hills"] = 300,
		["Moa'ki, Dragonblight"] = 175,
		["Bor'gorok Outpost, Borean Tundra"] = 52,
		["Dalaran"] = 215,
		["Kor'koron Vanguard, Dragonblight"] = 178,
		["Taunka'le Village, Borean Tundra"] = 77,
		["Vengeance Landing, Howling Fjord"] = 338,
		["Apothecary Camp, Howling Fjord"] = 259,
		["Conquest Hold, Grizzly Hills"] = 232,
		["Unu'pe, Borean Tundra"] = 96,
		["Kamagua, Howling Fjord"] = 295,
		["New Agamand, Howling Fjord"] = 317,
		["Camp Winterhoof, Howling Fjord"] = 288,
		["Wyrmrest Temple, Dragonblight"] = 170,
		["Venomspite, Dragonblight"] = 194,
		["Amber Ledge, Borean Tundra"] = 30,
		["Agmar's Hammer, Dragonblight"] = 137
	},
	["Moa'ki, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 263,
		["Vengeance Landing, Howling Fjord"] = 278,
		["Kamagua, Howling Fjord"] = 184,
		["Venomspite, Dragonblight"] = 61,
		["New Agamand, Howling Fjord"] = 247,
		["Agmar's Hammer, Dragonblight"] = 64,
		["Wyrmrest Temple, Dragonblight"] = 48,
		["Dalaran"] = 122,
		["Camp Winterhoof, Howling Fjord"] = 205,
		["Unu'pe, Borean Tundra"] = 131
	},
	["Zoram'gar Outpost, Ashenvale"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 121,
		["Orgrimmar, Durotar"] = 261,
		["Crossroads, The Barrens"] = 235,
		["Thunder Bluff, Mulgore"] = 247
	},
	["Thunderlord Stronghold, Blade's Edge Mountains"] = {
		["Garadar, Nagrand"] = 226,
		["Thrallmar, Hellfire Peninsula"] = 251,
		["Falcon Watch, Hellfire Peninsula"] = 178,
		["Shadowmoon Village, Shadowmoon Valley"] = 335,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 321,
		["Zabra'jin, Zangarmarsh"] = 148,
		["Shattrath, Terokkar Forest"] = 202,
		["Area 52, Netherstorm"] = 97,
		["Stonebreaker Hold, Terokkar Forest"] = 270
	},
	["Revantusk Village, The Hinterlands"] = {
		["Hammerfall, Arathi"] = 93,
		["Undercity, Tirisfal"] = 285
	},
	["Camp Taurajo, The Barrens"] = {
		["Marshal's Refuge, Un'Goro Crater"] = 318,
		["Thunder Bluff, Mulgore"] = 114,
		["Crossroads, The Barrens"] = 79,
		["Freewind Post, Thousand Needles"] = 125
	},
	["Area 52, Netherstorm"] = {
		["Garadar, Nagrand"] = 305,
		["The Stormspire, Netherstorm"] = 48,
		["Falcon Watch, Hellfire Peninsula"] = 200,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 108,
		["Zabra'jin, Zangarmarsh"] = 247,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 342,
		["Shadowmoon Village, Shadowmoon Valley"] = 356,
		["Stonebreaker Hold, Terokkar Forest"] = 292,
		["Shattrath, Terokkar Forest"] = 223,
		["Thrallmar, Hellfire Peninsula"] = 272
	},
	["Shattrath, Terokkar Forest"] = {
		["Garadar, Nagrand"] = 82,
		["Evergrove, Blade's Edge Mountains"] = 210,
		["Thrallmar, Hellfire Peninsula"] = 131,
		["Spinebreaker Ridge, Hellfire Peninsula"] = 197,
		["Falcon Watch, Hellfire Peninsula"] = 76,
		["Cosmowrench, Netherstorm"] = 270,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 185,
		["Shadowmoon Village, Shadowmoon Valley"] = 133,
		["The Stormspire, Netherstorm"] = 253,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 201,
		["Area 52, Netherstorm"] = 205,
		["Stonebreaker Hold, Terokkar Forest"] = 69,
		["Zabra'jin, Zangarmarsh"] = 136,
		["Swamprat Post, Zangarmarsh"] = 79
	},
	["Kor'koron Vanguard, Dragonblight"] = {
		["Vengeance Landing, Howling Fjord"] = 306,
		["Argent Tournament Grounds, Icecrown"] = 170,
		["Venomspite, Dragonblight"] = 90,
		["Ebon Watch, Zul'Drak"] = 107,
		["New Agamand, Howling Fjord"] = 275,
		["Wyrmrest Temple, Dragonblight"] = 67,
		["Dalaran"] = 55,
		["Camp Winterhoof, Howling Fjord"] = 233,
		["Agmar's Hammer, Dragonblight"] = 52
	},
	["The Sepulcher, Silverpine Forest"] = {
		["Hammerfall, Arathi"] = 213,
		["Undercity, Tirisfal"] = 111
	},
	["Warsong Hold"] = {
		["Garrosh's Landing"] = 56
	},
	["Gadgetzan, Tanaris"] = {
		["Brackenwall Village, Dustwallow Marsh"] = 194,
		["Cenarion Hold, Silithus"] = 232,
		["Camp Mojache, Feralas"] = 199,
		["Marshal's Refuge, Un'Goro Crater"] = 107,
		["Freewind Post, Thousand Needles"] = 87,
		["Ratchet, The Barrens"] = 243,
		["Orgrimmar, Durotar"] = 350,
		["Crossroads, The Barrens"] = 301,
		["Sun Rock Retreat, Stonetalon Mountains"] = 427,
		["Thunder Bluff, Mulgore"] = 304,
		["Shadowprey Village, Desolace"] = 399,
		["Valormok, Azshara"] = 434
	},
	["Tanaris"] = {
		["Caverns of Time"] = 59
	},
	["The Argent Stand, Zul'Drak"] = {
		["Vengeance Landing, Howling Fjord"] = 204,
		["Camp Oneqwah, Grizzly Hills"] = 99,
		["Light's Breach, Zul'Drak"] = 24,
		["Zim'Torga, Zul'Drak"] = 41,
		["Dalaran"] = 120,
		["Ebon Watch, Zul'Drak"] = 52,
		["New Agamand, Howling Fjord"] = 226
	},
	["The Shadow Vault, Icecrown"] = {
		["Argent Tournament Grounds, Icecrown"] = 77,
		["Bouldercrag's Refuge, The Storm Peaks"] = 121,
		["River's Heart, Sholazar Basin"] = 193,
		["Death's Rise, Icecrown"] = 77,
		["Unu'pe, Borean Tundra"] = 245
	},
	["Hellfire Peninsula, The Dark Portal, Horde"] = {
		["Garadar, Nagrand"] = 253,
		["Thrallmar, Hellfire Peninsula"] = 60,
		["Falcon Watch, Hellfire Peninsula"] = 122,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 296,
		["Area 52, Netherstorm"] = 316,
		["Shadowmoon Village, Shadowmoon Valley"] = 251,
		["Shattrath, Terokkar Forest"] = 182,
		["Stonebreaker Hold, Terokkar Forest"] = 187,
		["Zabra'jin, Zangarmarsh"] = 271
	},
	["Wyrmrest Temple, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 193,
		["Moa'ki, Dragonblight"] = 35,
		["Ebon Watch, Zul'Drak"] = 70,
		["Crusaders' Pinnacle, Icecrown"] = 83,
		["Bor'gorok Outpost, Borean Tundra"] = 168,
		["Dalaran"] = 64,
		["Kor'koron Vanguard, Dragonblight"] = 44,
		["Vengeance Landing, Howling Fjord"] = 177,
		["Argent Tournament Grounds, Icecrown"] = 140,
		["Venomspite, Dragonblight"] = 34,
		["Conquest Hold, Grizzly Hills"] = 73,
		["Ulduar, The Storm Peaks"] = 181,
		["Camp Winterhoof, Howling Fjord"] = 128,
		["New Agamand, Howling Fjord"] = 157,
		["Dun Nifflelem, The Storm Peaks"] = 164,
		["Amber Ledge, Borean Tundra"] = 170,
		["Agmar's Hammer, Dragonblight"] = 46
	},
	["Amber Ledge, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 25,
		["Warsong Hold, Borean Tundra"] = 28,
		["New Agamand, Howling Fjord"] = 289,
		["Camp Winterhoof, Howling Fjord"] = 260,
		["Bor'gorok Outpost, Borean Tundra"] = 22,
		["Dalaran"] = 186,
		["Vengeance Landing, Howling Fjord"] = 309,
		["Taunka'le Village, Borean Tundra"] = 48
	},
	["Skyguard Outpost"] = {
		["Blackwind Landing"] = 243
	},
	["Acherus: The Ebon Hold"] = {
		["Undercity, Tirisfal"] = 309
	},
	["Flame Crest, Burning Steppes"] = {
		["Undercity, Tirisfal"] = 578
	},
	["Freewind Post, Thousand Needles"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 341,
		["Camp Mojache, Feralas"] = 123,
		["Gadgetzan, Tanaris"] = 93,
		["Orgrimmar, Durotar"] = 278,
		["Crossroads, The Barrens"] = 191,
		["Camp Taurajo, The Barrens"] = 137,
		["Thunder Bluff, Mulgore"] = 222,
		["Mudsprocket, Dustwallow Marsh"] = 69,
		["Brackenwall Village, Dustwallow Marsh"] = 95
	},
	["Altar of Har'koa"] = {
		["Altar of Quetz'lun"] = 130
	},
	["Grom'arsh Crash-Site, The Storm Peaks"] = {
		["K3, The Storm Peaks"] = 87,
		["Argent Tournament Grounds, Icecrown"] = 97,
		["Bouldercrag's Refuge, The Storm Peaks"] = 37,
		["Ulduar, The Storm Peaks"] = 51,
		["Camp Tunka'lo, The Storm Peaks"] = 95,
		["New Agamand, Howling Fjord"] = 397,
		["The Argent Vanguard, Icecrown"] = 80,
		["Dun Nifflelem, The Storm Peaks"] = 141,
		["Unu'pe, Borean Tundra"] = 372
	},
	["Splintertree Post, Ashenvale"] = {
		["Ratchet, The Barrens"] = 203,
		["Orgrimmar, Durotar"] = 95,
		["Crossroads, The Barrens"] = 160,
		["Thunder Bluff, Mulgore"] = 267
	},
	["Bottom, Wyrmrest Temple"] = {
		["Top, Wyrmrest Temple"] = 19,
		["Middle, Wyrmrest Temple"] = 15
	},
	["Top, Wyrmrest Temple"] = {
		["Middle, Wyrmrest Temple"] = 25,
		["Bottom, Wyrmrest Temple"] = 18
	},
	["Voltarus"] = {
		["Zul' Drak Tour"] = 217
	},
	["Blackwind Landing"] = {
		["Skyguard Outpost"] = 244
	},
	["Taunka'le Village, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 111,
		["Warsong Hold, Borean Tundra"] = 85,
		["Warsong Camp, Wintergrasp"] = 71,
		["Unu'pe, Borean Tundra"] = 30,
		["Vengeance Landing, Howling Fjord"] = 391,
		["Camp Winterhoof, Howling Fjord"] = 318,
		["New Agamand, Howling Fjord"] = 361,
		["Bor'gorok Outpost, Borean Tundra"] = 72,
		["Dalaran"] = 207,
		["Amber Ledge, Borean Tundra"] = 75,
		["Agmar's Hammer, Dragonblight"] = 91
	},
	["Tranquillien, Ghostlands"] = {
		["Silvermoon City"] = 73
	},
	["Scalawag Point"] = {
		["Bael'gun's"] = 89
	},
	["Apothecary Camp, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 459,
		["Vengeance Landing, Howling Fjord"] = 132,
		["Camp Oneqwah, Grizzly Hills"] = 117,
		["Venomspite, Dragonblight"] = 117,
		["Conquest Hold, Grizzly Hills"] = 47,
		["Camp Winterhoof, Howling Fjord"] = 59,
		["Wyrmrest Temple, Dragonblight"] = 168,
		["Dalaran"] = 232,
		["Kamagua, Howling Fjord"] = 54,
		["New Agamand, Howling Fjord"] = 92
	},
	["Venomspite, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 342,
		["Vengeance Landing, Howling Fjord"] = 216,
		["Apothecary Camp, Howling Fjord"] = 97,
		["Conquest Hold, Grizzly Hills"] = 59,
		["Moa'ki, Dragonblight"] = 83,
		["Ebon Watch, Zul'Drak"] = 83,
		["New Agamand, Howling Fjord"] = 186,
		["Camp Winterhoof, Howling Fjord"] = 143,
		["Light's Breach, Zul'Drak"] = 106,
		["Wyrmrest Temple, Dragonblight"] = 51,
		["Dalaran"] = 148,
		["Kor'koron Vanguard, Dragonblight"] = 120,
		["Agmar's Hammer, Dragonblight"] = 133
	},
	["Frenzyheart Hill, Sholazar Basin"] = {
		["Mistwhisper Refuge, Sholazar Basin"] = 109
	},
	["Ulduar, The Storm Peaks"] = {
		["Argent Tournament Grounds, Icecrown"] = 108,
		["Bouldercrag's Refuge, The Storm Peaks"] = 48,
		["The Argent Stand, Zul'Drak"] = 205,
		["Camp Tunka'lo, The Storm Peaks"] = 88,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 44,
		["Dun Nifflelem, The Storm Peaks"] = 104,
		["Zim'Torga, Zul'Drak"] = 153,
		["Dalaran"] = 154,
		["New Agamand, Howling Fjord"] = 362
	},
	["Krasus' Landing, Dalaran"] = {
		["Wildgrowth Mangal, Sholazar Basin"] = 47
	},
	["Evergrove, Blade's Edge Mountains"] = {
		["Thrallmar, Hellfire Peninsula"] = 287
	},
	["Cosmowrench, Netherstorm"] = {
		["Thrallmar, Hellfire Peninsula"] = 336
	},
	["Hammerfall, Arathi"] = {
		["Revantusk Village, The Hinterlands"] = 90,
		["Undercity, Tirisfal"] = 259
	},
	["Camp Winterhoof, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 515,
		["Warsong Hold, Borean Tundra"] = 474,
		["Kamagua, Howling Fjord"] = 110,
		["Moa'ki, Dragonblight"] = 256,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 304,
		["Bor'gorok Outpost, Borean Tundra"] = 476,
		["Dalaran"] = 256,
		["Kor'koron Vanguard, Dragonblight"] = 291,
		["Taunka'le Village, Borean Tundra"] = 405,
		["K3, The Storm Peaks"] = 229,
		["Vengeance Landing, Howling Fjord"] = 74,
		["Argent Tournament Grounds, Icecrown"] = 368,
		["Apothecary Camp, Howling Fjord"] = 56,
		["Conquest Hold, Grizzly Hills"] = 93,
		["New Agamand, Howling Fjord"] = 80,
		["Venomspite, Dragonblight"] = 174,
		["Wyrmrest Temple, Dragonblight"] = 225,
		["Camp Oneqwah, Grizzly Hills"] = 58,
		["Amber Ledge, Borean Tundra"] = 479,
		["Agmar's Hammer, Dragonblight"] = 294
	},
	["The Argent Vanguard, Icecrown"] = {
		["Grom'arsh Crash-Site, The Storm Peaks"] = 103,
		["Dalaran"] = 32,
		["Argent Tournament Grounds, Icecrown"] = 124,
		["Dun Nifflelem, The Storm Peaks"] = 177
	},
	["Zim'Torga, Zul'Drak"] = {
		["Camp Tunka'lo, The Storm Peaks"] = 86,
		["Dun Nifflelem, The Storm Peaks"] = 85,
		["New Agamand, Howling Fjord"] = 210,
		["Gundrak, Zul'Drak"] = 53,
		["Ulduar, The Storm Peaks"] = 154,
		["Dalaran"] = 171,
		["The Argent Stand, Zul'Drak"] = 53,
		["Camp Oneqwah, Grizzly Hills"] = 82
	},
	["Sun's Reach Harbor"] = {
		["The Sin'loren"] = 59
	},
	["Bloodvenom Post, Felwood"] = {
		["Orgrimmar, Durotar"] = 259,
		["Crossroads, The Barrens"] = 241,
		["Thunder Bluff, Mulgore"] = 347
	},
	["Sunreaver's Command, Crystalsong Forest"] = {
		["Ebon Watch, Zul'Drak"] = 38,
		["Dalaran"] = 55,
		["Camp Winterhoof, Howling Fjord"] = 235,
		["Apothecary Camp, Howling Fjord"] = 212
	},
	["Kamagua"] = {
		["Scalawag Points"] = 149,
		["Scalawag Point"] = 90
	},
	["Warsong Hold, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 72,
		["Vengeance Landing, Howling Fjord"] = 477,
		["Argent Tournament Grounds, Icecrown"] = 375,
		["Garrosh's Landing"] = 56,
		["Taunka'le Village, Borean Tundra"] = 86,
		["Camp Winterhoof, Howling Fjord"] = 403,
		["Apothecary Camp, Howling Fjord"] = 359,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 415,
		["New Agamand, Howling Fjord"] = 447,
		["Ride to Taunka'le Village"] = 119,
		["Bor'gorok Outpost, Borean Tundra"] = 69,
		["Dalaran"] = 293,
		["Amber Ledge, Borean Tundra"] = 35,
		["Unu'pe, Borean Tundra"] = 93
	},
	["Camp Oneqwah, Grizzly Hills"] = {
		["K3, The Storm Peaks"] = 172,
		["Vengeance Landing, Howling Fjord"] = 105,
		["Argent Tournament Grounds, Icecrown"] = 311,
		["Apothecary Camp, Howling Fjord"] = 105,
		["Conquest Hold, Grizzly Hills"] = 96,
		["The Argent Stand, Zul'Drak"] = 100,
		["Zim'Torga, Zul'Drak"] = 92,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 247,
		["Camp Winterhoof, Howling Fjord"] = 48,
		["Light's Breach, Zul'Drak"] = 92,
		["Wyrmrest Temple, Dragonblight"] = 222,
		["Dalaran"] = 199,
		["Transitus Shield, Coldarra"] = 511,
		["New Agamand, Howling Fjord"] = 128
	},
	["Moonglade"] = {
		["Orgrimmar, Durotar"] = 376,
		["Emerald Sanctuary, Felwood"] = 186,
		["Thunder Bluff, Mulgore"] = 458
	},
	["Thrallmar, Hellfire Peninsula"] = {
		["Garadar, Nagrand"] = 199,
		["The Stormspire, Netherstorm"] = 309,
		["Spinebreaker Ridge, Hellfire Peninsula"] = 65,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 241,
		["Shadowmoon Village, Shadowmoon Valley"] = 192,
		["Area 52, Netherstorm"] = 261,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 70,
		["Zabra'jin, Zangarmarsh"] = 216,
		["Shattrath, Terokkar Forest"] = 122,
		["Stonebreaker Hold, Terokkar Forest"] = 129,
		["Falcon Watch, Hellfire Peninsula"] = 67
	},
	["Shadowmoon Village, Shadowmoon Valley"] = {
		["Garadar, Nagrand"] = 208,
		["The Stormspire, Netherstorm"] = 379,
		["Falcon Watch, Hellfire Peninsula"] = 202,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 311,
		["Zabra'jin, Zangarmarsh"] = 262,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 266,
		["Area 52, Netherstorm"] = 331,
		["Stonebreaker Hold, Terokkar Forest"] = 73,
		["Shattrath, Terokkar Forest"] = 126,
		["Thrallmar, Hellfire Peninsula"] = 196
	},
	["Falcon Watch, Hellfire Peninsula"] = {
		["Garadar, Nagrand"] = 132,
		["The Stormspire, Netherstorm"] = 242,
		["Spinebreaker Ridge, Hellfire Peninsula"] = 138,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 175,
		["Area 52, Netherstorm"] = 194,
		["Shadowmoon Village, Shadowmoon Valley"] = 204,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 143,
		["Zabra'jin, Zangarmarsh"] = 149,
		["Shattrath, Terokkar Forest"] = 71,
		["Stonebreaker Hold, Terokkar Forest"] = 139,
		["Thrallmar, Hellfire Peninsula"] = 72
	},
	["The Stormspire, Netherstorm"] = {
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 146,
		["Garadar, Nagrand"] = 358,
		["Thrallmar, Hellfire Peninsula"] = 325,
		["Shadowmoon Village, Shadowmoon Valley"] = 409,
		["Area 52, Netherstorm"] = 53,
		["Falcon Watch, Hellfire Peninsula"] = 253,
		["Zabra'jin, Zangarmarsh"] = 294
	},
	["Camp Tunka'lo, The Storm Peaks"] = {
		["K3, The Storm Peaks"] = 114,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 100,
		["Dun Nifflelem, The Storm Peaks"] = 45,
		["Zim'Torga, Zul'Drak"] = 98,
		["Dalaran"] = 185,
		["Ulduar, The Storm Peaks"] = 73
	},
	["Nighthaven"] = {
		["Thunder Bluff"] = 399
	},
	["Grom'gol, Stranglethorn"] = {
		["Booty Bay, Stranglethorn"] = 77,
		["Flame Crest, Burning Steppes"] = 198,
		["Undercity, Tirisfal"] = 742
	},
	["Dalaran"] = {
		["Transitus Shield, Coldarra"] = 346,
		["Warsong Hold, Borean Tundra"] = 319,
		["Camp Oneqwah, Grizzly Hills"] = 230,
		["Moa'ki, Dragonblight"] = 159,
		["Camp Tunka'lo, The Storm Peaks"] = 145,
		["Kor'koron Vanguard, Dragonblight"] = 73,
		["Unu'pe, Borean Tundra"] = 265,
		["K3, The Storm Peaks"] = 54,
		["Argent Tournament Grounds, Icecrown"] = 123,
		["Bouldercrag's Refuge, The Storm Peaks"] = 167,
		["Conquest Hold, Grizzly Hills"] = 200,
		["Orgrim's Hammer"] = 62,
		["The Argent Stand, Zul'Drak"] = 145,
		["New Agamand, Howling Fjord"] = 348,
		["Wyrmrest Temple, Dragonblight"] = 121,
		["Amber Ledge, Borean Tundra"] = 310,
		["River's Heart, Sholazar Basin"] = 211,
		["Ebon Watch, Zul'Drak"] = 81,
		["Crusaders' Pinnacle, Icecrown"] = 39,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 130,
		["Bor'gorok Outpost, Borean Tundra"] = 307,
		["Light's Breach, Zul'Drak"] = 125,
		["Taunka'le Village, Borean Tundra"] = 236,
		["Sunreaver's Command, Crystalsong Forest"] = 57,
		["Vengeance Landing, Howling Fjord"] = 335,
		["Venomspite, Dragonblight"] = 163,
		["Warsong Camp, Wintergrasp"] = 160,
		["Nesingwary Base Camp, Sholazar Basin"] = 246,
		["Ulduar, The Storm Peaks"] = 181,
		["The Shadow Vault, Icecrown"] = 162,
		["Gundrak, Zul'Drak"] = 238,
		["Dun Nifflelem, The Storm Peaks"] = 154,
		["Kamagua, Howling Fjord"] = 310,
		["Camp Winterhoof, Howling Fjord"] = 278,
		["The Argent Vanguard, Icecrown"] = 32,
		["Zim'Torga, Zul'Drak"] = 185,
		["Death's Rise, Icecrown"] = 206,
		["Apothecary Camp, Howling Fjord"] = 256,
		["Agmar's Hammer, Dragonblight"] = 125
	},
	["Zabra'jin, Zangarmarsh"] = {
		["Garadar, Nagrand"] = 81,
		["Thrallmar, Hellfire Peninsula"] = 220,
		["Falcon Watch, Hellfire Peninsula"] = 147,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 113,
		["Area 52, Netherstorm"] = 209,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 290,
		["Shadowmoon Village, Shadowmoon Valley"] = 284,
		["Shattrath, Terokkar Forest"] = 151,
		["The Stormspire, Netherstorm"] = 256,
		["Stonebreaker Hold, Terokkar Forest"] = 219
	},
	["Camp Mojache, Feralas"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 399,
		["Cenarion Hold, Silithus"] = 130,
		["Crossroads, The Barrens"] = 264,
		["Shadowprey Village, Desolace"] = 200,
		["Gadgetzan, Tanaris"] = 201,
		["Thunder Bluff, Mulgore"] = 259,
		["Orgrimmar, Durotar"] = 380,
		["Freewind Post, Thousand Needles"] = 107
	},
	["Death's Rise, Icecrown"] = {
		["Camp Oneqwah, Grizzly Hills"] = 458,
		["River's Heart, Sholazar Basin"] = 117,
		["Dalaran"] = 238,
		["Nesingwary Base Camp, Sholazar Basin"] = 117,
		["Argent Tournament Grounds, Icecrown"] = 170
	},
	["Silvermoon City"] = {
		["Light's Hope Chapel, Eastern Plaguelands"] = 180,
		["Tranquillien, Ghostlands"] = 66,
		["Revantusk Village, The Hinterlands"] = 122,
		["Undercity, Tirisfal"] = 312
	},
	["K3, The Storm Peaks"] = {
		["Camp Tunka'lo, The Storm Peaks"] = 90,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 75,
		["Argent Tournament Grounds, Icecrown"] = 172,
		["Dun Nifflelem, The Storm Peaks"] = 101,
		["The Shadow Vault, Icecrown"] = 225,
		["Dalaran"] = 71,
		["Ebon Watch, Zul'Drak"] = 43,
		["Unu'pe, Borean Tundra"] = 317
	},
	["Booty Bay, Stranglethorn"] = {
		["Grom'gol, Stranglethorn"] = 75,
		["Undercity, Tirisfal"] = 811
	},
	["Argent Tournament Grounds, Icecrown"] = {
		["Transitus Shield, Coldarra"] = 414,
		["Bouldercrag's Refuge, The Storm Peaks"] = 51,
		["Camp Oneqwah, Grizzly Hills"] = 353,
		["Warsong Camp, Wintergrasp"] = 224,
		["River's Heart, Sholazar Basin"] = 281,
		["Ulduar, The Storm Peaks"] = 95,
		["Camp Winterhoof, Howling Fjord"] = 378,
		["Get Kraken!"] = 152,
		["Crusaders' Pinnacle, Icecrown"] = 73,
		["Apothecary Camp, Howling Fjord"] = 380,
		["The Shadow Vault, Icecrown"] = 88,
		["New Agamand, Howling Fjord"] = 458,
		["Wyrmrest Temple, Dragonblight"] = 246,
		["Dalaran"] = 140,
		["K3, The Storm Peaks"] = 178,
		["Unu'pe, Borean Tundra"] = 333
	},
	["Bouldercrag's Refuge, The Storm Peaks"] = {
		["Grom'arsh Crash-Site, The Storm Peaks"] = 41,
		["Argent Tournament Grounds, Icecrown"] = 60,
		["Dalaran"] = 150,
		["Ulduar, The Storm Peaks"] = 44,
		["The Shadow Vault, Icecrown"] = 113
	},
	["Conquest Hold, Grizzly Hills"] = {
		["Transitus Shield, Coldarra"] = 428,
		["Vengeance Landing, Howling Fjord"] = 158,
		["Camp Oneqwah, Grizzly Hills"] = 101,
		["Venomspite, Dragonblight"] = 88,
		["The Argent Stand, Zul'Drak"] = 123,
		["Camp Winterhoof, Howling Fjord"] = 84,
		["Argent Tournament Grounds, Icecrown"] = 298,
		["Light's Breach, Zul'Drak"] = 80,
		["Dalaran"] = 185,
		["New Agamand, Howling Fjord"] = 148,
		["Apothecary Camp, Howling Fjord"] = 57
	},
	["Bael'gun's"] = {
		["Scalawag Point"] = 70
	},
	["Nesingwary Base Camp, Sholazar Basin"] = {
		["Argent Tournament Grounds, Icecrown"] = 390,
		["Bor'gorok Outpost, Borean Tundra"] = 91,
		["River's Heart, Sholazar Basin"] = 76,
		["Dalaran"] = 363,
		["Death's Rise, Icecrown"] = 137,
		["New Agamand, Howling Fjord"] = 747
	},
	["Shadowprey Village, Desolace"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 199,
		["Orgrimmar, Durotar"] = 385,
		["Crossroads, The Barrens"] = 280,
		["Camp Mojache, Feralas"] = 196,
		["Gadgetzan, Tanaris"] = 395,
		["Thunder Bluff, Mulgore"] = 178,
		["Freewind Post, Thousand Needles"] = 303
	},
	["Thorium Point, Searing Gorge"] = {
		["Undercity, Tirisfal"] = 566
	},
	["Orgrimmar, Durotar"] = {
		["Brackenwall Village, Dustwallow Marsh"] = 229,
		["Cenarion Hold, Silithus"] = 489,
		["Moonglade"] = 357,
		["Marshal's Refuge, Un'Goro Crater"] = 451,
		["Freewind Post, Thousand Needles"] = 292,
		["Crossroads, The Barrens"] = 107,
		["Camp Taurajo, The Barrens"] = 181,
		["Everlook, Winterspring"] = 239,
		["Thunder Bluff, Mulgore"] = 225,
		["Sun Rock Retreat, Stonetalon Mountains"] = 257,
		["Camp Mojache, Feralas"] = 359,
		["Gadgetzan, Tanaris"] = 417,
		["Shadowprey Village, Desolace"] = 373,
		["Ratchet, The Barrens"] = 107,
		["Bloodvenom Post, Felwood"] = 252,
		["Splintertree Post, Ashenvale"] = 89,
		["Zoram'gar Outpost, Ashenvale"] = 249,
		["Mudsprocket, Dustwallow Marsh"] = 266,
		["Emerald Sanctuary, Felwood"] = 168,
		["Valormok, Azshara"] = 95
	},
	["Stonebreaker Hold, Terokkar Forest"] = {
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 240,
		["Garadar, Nagrand"] = 138,
		["Thrallmar, Hellfire Peninsula"] = 125,
		["Shadowmoon Village, Shadowmoon Valley"] = 68,
		["Area 52, Netherstorm"] = 261,
		["Shattrath, Terokkar Forest"] = 56,
		["Falcon Watch, Hellfire Peninsula"] = 133,
		["Zabra'jin, Zangarmarsh"] = 192
	},
	["Thunder Bluff, Mulgore"] = {
		["Brackenwall Village, Dustwallow Marsh"] = 239,
		["Cenarion Hold, Silithus"] = 382,
		["Moonglade"] = 513,
		["Zoram'gar Outpost, Ashenvale"] = 264,
		["Freewind Post, Thousand Needles"] = 204,
		["Splintertree Post, Ashenvale"] = 264,
		["Camp Taurajo, The Barrens"] = 87,
		["Everlook, Winterspring"] = 379,
		["Sun Rock Retreat, Stonetalon Mountains"] = 181,
		["Camp Mojache, Feralas"] = 252,
		["Gadgetzan, Tanaris"] = 290,
		["Shadowprey Village, Desolace"] = 159,
		["Ratchet, The Barrens"] = 153,
		["Orgrimmar, Durotar"] = 207,
		["Crossroads, The Barrens"] = 102,
		["Bloodvenom Post, Felwood"] = 356,
		["Marshal's Refuge, Un'Goro Crater"] = 394,
		["Mudsprocket, Dustwallow Marsh"] = 205,
		["Emerald Sanctuary, Felwood"] = 343,
		["Valormok, Azshara"] = 251
	},
	["Garadar, Nagrand"] = {
		["The Stormspire, Netherstorm"] = 321,
		["Falcon Watch, Hellfire Peninsula"] = 125,
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 178,
		["Shadowmoon Village, Shadowmoon Valley"] = 209,
		["Zabra'jin, Zangarmarsh"] = 66,
		["Hellfire Peninsula, The Dark Portal, Horde"] = 269,
		["Area 52, Netherstorm"] = 274,
		["Shattrath, Terokkar Forest"] = 77,
		["Stonebreaker Hold, Terokkar Forest"] = 145,
		["Thrallmar, Hellfire Peninsula"] = 198
	},
	["Middle, Wyrmrest Temple"] = {
		["Top, Wyrmrest Temple"] = 23,
		["Bottom, Wyrmrest Temple"] = 13
	},
	["Thondoril River, Western Plaguelands"] = {
		["The Bulwark, Tirisfal"] = 76,
		["Light's Hope Chapel, Eastern Plaguelands"] = 96,
		["Undercity, Tirisfal"] = 160
	},
	["Warsong Camp, Wintergrasp"] = {
		["Camp Oneqwah, Grizzly Hills"] = 344,
		["River's Heart, Sholazar Basin"] = 77,
		["Dalaran"] = 141,
		["Argent Tournament Grounds, Icecrown"] = 239,
		["Unu'pe, Borean Tundra"] = 109
	},
	["Brackenwall Village, Dustwallow Marsh"] = {
		["Orgrimmar, Durotar"] = 215,
		["Crossroads, The Barrens"] = 162,
		["Gadgetzan, Tanaris"] = 205,
		["Thunder Bluff, Mulgore"] = 224,
		["Freewind Post, Thousand Needles"] = 104
	},
	["Cenarion Hold, Silithus"] = {
		["Gadgetzan, Tanaris"] = 241,
		["Orgrimmar, Durotar"] = 510,
		["Everlook, Winterspring"] = 686,
		["Thunder Bluff, Mulgore"] = 389
	},
	["Undercity, Tirisfal"] = {
		["Booty Bay, Stranglethorn"] = 784,
		["Kargath, Badlands"] = 488,
		["Flame Crest, Burning Steppes"] = 554,
		["Tarren Mill, Hillsbrad"] = 145,
		["Stonard, Swamp of Sorrows"] = 711,
		["Silvermoon City"] = 454,
		["The Sepulcher, Silverpine Forest"] = 106,
		["Hammerfall, Arathi"] = 300,
		["Revantusk Village, The Hinterlands"] = 284,
		["Grom'gol, Stranglethorn"] = 726,
		["The Bulwark, Tirisfal"] = 88,
		["Thorium Point, Searing Gorge"] = 543,
		["Light's Hope Chapel, Eastern Plaguelands"] = 262,
		["Thondoril River, Western Plaguelands"] = 152
	},
	["The Shadow Vault"] = {
		["Seeds Of Chaos"] = 259
	},
	["Swamprat Post, Zangarmarsh"] = {
		["Garadar, Nagrand"] = 168,
		["Shattrath, Terokkar Forest"] = 86
	},
	["Tarren Mill, Hillsbrad"] = {
		["The Bulwark, Tirisfal"] = 68,
		["The Sepulcher, Silverpine Forest"] = 103,
		["Light's Hope Chapel, Eastern Plaguelands"] = 195,
		["Undercity, Tirisfal"] = 139
	},
	["Ebon Watch, Zul'Drak"] = {
		["Transitus Shield, Coldarra"] = 380,
		["Vengeance Landing, Howling Fjord"] = 254,
		["Argent Tournament Grounds, Icecrown"] = 180,
		["Venomspite, Dragonblight"] = 99,
		["The Argent Stand, Zul'Drak"] = 64,
		["K3, The Storm Peaks"] = 40,
		["New Agamand, Howling Fjord"] = 267,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 115,
		["Camp Winterhoof, Howling Fjord"] = 198,
		["Light's Breach, Zul'Drak"] = 45,
		["Wyrmrest Temple, Dragonblight"] = 91,
		["Dalaran"] = 68,
		["Kor'koron Vanguard, Dragonblight"] = 107,
		["Sunreaver's Command, Crystalsong Forest"] = 27
	},
	["The Sin'loren"] = {
		["Sun's Reach Harbor"] = 12
	},
	["Crusaders' Pinnacle, Icecrown"] = {
		["Wyrmrest Temple, Dragonblight"] = 174,
		["Dalaran"] = 71,
		["The Shadow Vault, Icecrown"] = 123
	},
	["Bor'gorok Outpost, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 92,
		["Warsong Hold, Borean Tundra"] = 72,
		["Camp Oneqwah, Grizzly Hills"] = 411,
		["River's Heart, Sholazar Basin"] = 56,
		["Nesingwary Base Camp, Sholazar Basin"] = 48,
		["New Agamand, Howling Fjord"] = 438,
		["Camp Winterhoof, Howling Fjord"] = 394,
		["Vengeance Landing, Howling Fjord"] = 468,
		["Wyrmrest Temple, Dragonblight"] = 216,
		["Dalaran"] = 250,
		["Amber Ledge, Borean Tundra"] = 57,
		["Taunka'le Village, Borean Tundra"] = 78
	},
	["Crossroads, The Barrens"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 149,
		["Camp Mojache, Feralas"] = 252,
		["Gadgetzan, Tanaris"] = 303,
		["Bloodvenom Post, Felwood"] = 253,
		["Zoram'gar Outpost, Ashenvale"] = 230,
		["Shadowprey Village, Desolace"] = 265,
		["Ratchet, The Barrens"] = 52,
		["Orgrimmar, Durotar"] = 116,
		["Splintertree Post, Ashenvale"] = 163,
		["Camp Taurajo, The Barrens"] = 74,
		["Brackenwall Village, Dustwallow Marsh"] = 163,
		["Thunder Bluff, Mulgore"] = 107,
		["Freewind Post, Thousand Needles"] = 185,
		["Valormok, Azshara"] = 163
	},
	["Mudsprocket, Dustwallow Marsh"] = {
		["Orgrimmar, Durotar"] = 245,
		["Thunder Bluff, Mulgore"] = 223
	},
	["The Bulwark, Tirisfal"] = {
		["Undercity, Tirisfal"] = 89
	},
	["Light's Breach, Zul'Drak"] = {
		["Argent Tournament Grounds, Icecrown"] = 220,
		["Venomspite, Dragonblight"] = 121,
		["Conquest Hold, Grizzly Hills"] = 74,
		["Moa'ki, Dragonblight"] = 182,
		["Ebon Watch, Zul'Drak"] = 39,
		["New Agamand, Howling Fjord"] = 223,
		["Wyrmrest Temple, Dragonblight"] = 130,
		["Dalaran"] = 107,
		["The Argent Stand, Zul'Drak"] = 43,
		["Camp Oneqwah, Grizzly Hills"] = 105
	},
	["River's Heart, Sholazar Basin"] = {
		["Argent Tournament Grounds, Icecrown"] = 393,
		["Death's Rise, Icecrown"] = 139,
		["Camp Oneqwah, Grizzly Hills"] = 625,
		["Camp Winterhoof, Howling Fjord"] = 618,
		["Bor'gorok Outpost, Borean Tundra"] = 93,
		["Dalaran"] = 302,
		["Nesingwary Base Camp, Sholazar Basin"] = 64,
		["Agmar's Hammer, Dragonblight"] = 278
	},
	["Sun Rock Retreat, Stonetalon Mountains"] = {
		["Freewind Post, Thousand Needles"] = 334,
		["Orgrimmar, Durotar"] = 266,
		["Crossroads, The Barrens"] = 149,
		["Camp Mojache, Feralas"] = 339,
		["Gadgetzan, Tanaris"] = 426,
		["Thunder Bluff, Mulgore"] = 174,
		["Zoram'gar Outpost, Ashenvale"] = 120,
		["Shadowprey Village, Desolace"] = 143
	},
	["Unu'pe, Borean Tundra"] = {
		["Vengeance Landing, Howling Fjord"] = 394,
		["Argent Tournament Grounds, Icecrown"] = 331,
		["River's Heart, Sholazar Basin"] = 149,
		["Moa'ki, Dragonblight"] = 118,
		["Ebon Watch, Zul'Drak"] = 261,
		["Camp Winterhoof, Howling Fjord"] = 321,
		["New Agamand, Howling Fjord"] = 364,
		["Camp Oneqwah, Grizzly Hills"] = 338,
		["Warsong Hold, Borean Tundra"] = 87,
		["Dalaran"] = 229,
		["Amber Ledge, Borean Tundra"] = 96,
		["Taunka'le Village, Borean Tundra"] = 22
	},
	["Vengeance Landing, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 588,
		["Warsong Hold, Borean Tundra"] = 547,
		["Camp Oneqwah, Grizzly Hills"] = 104,
		["Moa'ki, Dragonblight"] = 329,
		["Ebon Watch, Zul'Drak"] = 235,
		["Bor'gorok Outpost, Borean Tundra"] = 550,
		["Dalaran"] = 302,
		["Kor'koron Vanguard, Dragonblight"] = 343,
		["Taunka'le Village, Borean Tundra"] = 478,
		["Apothecary Camp, Howling Fjord"] = 130,
		["Conquest Hold, Grizzly Hills"] = 165,
		["Ulduar, The Storm Peaks"] = 350,
		["The Argent Stand, Zul'Drak"] = 203,
		["Unu'pe, Borean Tundra"] = 460,
		["Kamagua, Howling Fjord"] = 162,
		["Venomspite, Dragonblight"] = 247,
		["Camp Winterhoof, Howling Fjord"] = 73,
		["New Agamand, Howling Fjord"] = 87,
		["Wyrmrest Temple, Dragonblight"] = 298,
		["Death's Rise, Icecrown"] = 495,
		["Amber Ledge, Borean Tundra"] = 553,
		["Agmar's Hammer, Dragonblight"] = 368
	},
	["Marshal's Refuge, Un'Goro Crater"] = {
		["Orgrimmar, Durotar"] = 450,
		["Thunder Bluff, Mulgore"] = 417
	},
	["Gundrak, Zul'Drak"] = {
		["Zim'Torga, Zul'Drak"] = 55,
		["Dalaran"] = 227
	},
	["Kamagua, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 458,
		["Vengeance Landing, Howling Fjord"] = 142,
		["New Agamand, Howling Fjord"] = 63,
		["Apothecary Camp, Howling Fjord"] = 55,
		["Venomspite, Dragonblight"] = 173,
		["Dalaran"] = 287,
		["Moa'ki, Dragonblight"] = 195,
		["Camp Winterhoof, Howling Fjord"] = 115
	},
	["Kargath, Badlands"] = {
		["Flame Crest, Burning Steppes"] = 68,
		["Grom'gol, Stranglethorn"] = 238,
		["Undercity, Tirisfal"] = 497
	},
	["Spinebreaker Ridge, Hellfire Peninsula"] = {
		["Thrallmar, Hellfire Peninsula"] = 62,
		["Falcon Watch, Hellfire Peninsula"] = 129,
		["Zabra'jin, Zangarmarsh"] = 278
	},
	["Everlook, Winterspring"] = {
		["Orgrimmar, Durotar"] = 243,
		["Splintertree Post, Ashenvale"] = 228,
		["Thunder Bluff, Mulgore"] = 385
	},
	["Ratchet, The Barrens"] = {
		["Gadgetzan, Tanaris"] = 241,
		["Orgrimmar, Durotar"] = 101,
		["Crossroads, The Barrens"] = 68,
		["Thunder Bluff, Mulgore"] = 174
	},
	["Stonard, Swamp of Sorrows"] = {
		["Booty Bay, Stranglethorn"] = 230,
		["Grom'gol, Stranglethorn"] = 178,
		["Kargath, Badlands"] = 231,
		["Flame Crest, Burning Steppes"] = 176,
		["Undercity, Tirisfal"] = 728
	},
	["Dun Nifflelem, The Storm Peaks"] = {
		["Camp Tunka'lo, The Storm Peaks"] = 32,
		["Vengeance Landing, Howling Fjord"] = 275,
		["Argent Tournament Grounds, Icecrown"] = 192,
		["K3, The Storm Peaks"] = 87,
		["Zim'Torga, Zul'Drak"] = 89,
		["Dalaran"] = 158,
		["Ulduar, The Storm Peaks"] = 84,
		["New Agamand, Howling Fjord"] = 298
	},
	["New Agamand, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 533,
		["Warsong Hold, Borean Tundra"] = 488,
		["Camp Oneqwah, Grizzly Hills"] = 135,
		["River's Heart, Sholazar Basin"] = 505,
		["Moa'ki, Dragonblight"] = 270,
		["Ebon Watch, Zul'Drak"] = 268,
		["Bor'gorok Outpost, Borean Tundra"] = 495,
		["Dalaran"] = 335,
		["Kor'koron Vanguard, Dragonblight"] = 311,
		["Taunka'le Village, Borean Tundra"] = 423,
		["K3, The Storm Peaks"] = 308,
		["Vengeance Landing, Howling Fjord"] = 79,
		["Unu'pe, Borean Tundra"] = 402,
		["Venomspite, Dragonblight"] = 194,
		["Conquest Hold, Grizzly Hills"] = 150,
		["Light's Breach, Zul'Drak"] = 229,
		["Nesingwary Base Camp, Sholazar Basin"] = 542,
		["Zim'Torga, Zul'Drak"] = 227,
		["The Argent Stand, Zul'Drak"] = 234,
		["Dun Nifflelem, The Storm Peaks"] = 312,
		["Camp Winterhoof, Howling Fjord"] = 79,
		["Apothecary Camp, Howling Fjord"] = 103,
		["Wyrmrest Temple, Dragonblight"] = 245,
		["Kamagua, Howling Fjord"] = 76,
		["Amber Ledge, Borean Tundra"] = 498,
		["Agmar's Hammer, Dragonblight"] = 315
	},
	["Valormok, Azshara"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 313,
		["Orgrimmar, Durotar"] = 101,
		["Crossroads, The Barrens"] = 164,
		["Thunder Bluff, Mulgore"] = 250
	},
	["Light's Hope Chapel, Eastern Plaguelands"] = {
		["Thondoril River, Western Plaguelands"] = 99,
		["Undercity, Tirisfal"] = 260
	},
	["Emerald Sanctuary, Felwood"] = {
		["Thunder Bluff, Mulgore"] = 343,
		["Bloodvenom Post, Felwood"] = 79,
		["Orgrimmar, Durotar"] = 172
	},
	["Agmar's Hammer, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 224,
		["Vengeance Landing, Howling Fjord"] = 302,
		["Venomspite, Dragonblight"] = 87,
		["Conquest Hold, Grizzly Hills"] = 145,
		["Moa'ki, Dragonblight"] = 63,
		["Camp Winterhoof, Howling Fjord"] = 229,
		["New Agamand, Howling Fjord"] = 272,
		["Wyrmrest Temple, Dragonblight"] = 50,
		["Dalaran"] = 120,
		["Kor'koron Vanguard, Dragonblight"] = 65,
		["Taunka'le Village, Borean Tundra"] = 113
	}
}

svDefaults.global["Alliance"] = {
	["Southshore, Hillsbrad"] = {
		["Chillwind Camp, Western Plaguelands"] = 81,
		["Menethil Harbor, Wetlands"] = 110,
		["Refuge Pointe, Arathi"] = 74
	},
	["Sentinel Hill, Westfall"] = {
		["Thelsamar, Loch Modan"] = 345,
		["Lakeshire, Redridge"] = 130,
		["Stormwind, Elwynn"] = 86
	},
	["Theramore, Dustwallow Marsh"] = {
		["Ratchet, The Barrens"] = 115,
		["Nijel's Point, Desolace"] = 333,
		["Gadgetzan, Tanaris"] = 156
	},
	["Auberdine, Darkshore"] = {
		["Rut'theran Village, Teldrassil"] = 84,
		["Astranaar, Ashenvale"] = 167
	},
	["Darkshire, Duskwood"] = {
		["Nethergarde Keep, Blasted Lands"] = 96,
		["Sentinel Hill, Westfall"] = 93,
		["Stormwind, Elwynn"] = 88,
		["Rebel Camp, Stranglethorn Vale"] = 48
	},
	["Astranaar, Ashenvale"] = {
		["Rut'theran Village, Teldrassil"] = 232,
		["Forest Song, Ashenvale"] = 134,
		["Auberdine, Darkshore"] = 148,
		["Ratchet, The Barrens"] = 193
	},
	["Nijel's Point, Desolace"] = {
		["Theramore, Dustwallow Marsh"] = 307,
		["Stonetalon Peak, Stonetalon Mountains"] = 120
	},
	["Aerie Peak, The Hinterlands"] = {
		["Refuge Pointe, Arathi"] = 76
	},
	["Stormwind, Elwynn"] = {
		["Booty Bay, Stranglethorn"] = 199,
		["Sentinel Hill, Westfall"] = 78,
		["Lakeshire, Redridge"] = 112,
		["Darkshire, Duskwood"] = 116,
		["Ironforge, Dun Morogh"] = 216,
		["Rebel Camp, Stranglethorn Vale"] = 92,
		["Southshore, Hillsbrad"] = 388,
		["Thelsamar, Loch Modan"] = 274,
		["Menethil Harbor, Wetlands"] = 285,
		["Refuge Pointe, Arathi"] = 376
	},
	["Booty Bay, Stranglethorn"] = {
		["Sentinel Hill, Westfall"] = 147,
		["Rebel Camp, Stranglethorn Vale"] = 117,
		["Stormwind, Elwynn"] = 199
	},
	["Stonetalon Peak, Stonetalon Mountains"] = {
		["Astranaar, Ashenvale"] = 155
	},
	["Thelsamar, Loch Modan"] = {
		["Ironforge, Dun Morogh"] = 109,
		["Stormwind, Elwynn"] = 276
	},
	["Gadgetzan, Tanaris"] = {
		["Theramore, Dustwallow Marsh"] = 154
	},
	["Nethergarde Keep, Blasted Lands"] = {
		["Booty Bay, Stranglethorn"] = 251,
		["Stormwind, Elwynn"] = 189
	},
	["Lakeshire, Redridge"] = {
		["Darkshire, Duskwood"] = 61,
		["Sentinel Hill, Westfall"] = 134,
		["Stormwind, Elwynn"] = 112
	},
	["Feathermoon, Feralas"] = {
		["Nijel's Point, Desolace"] = 227
	},
	["Ratchet, The Barrens"] = {
		["Gadgetzan, Tanaris"] = 245,
		["Theramore, Dustwallow Marsh"] = 105
	},
	["Rut'theran Village, Teldrassil"] = {
		["Auberdine, Darkshore"] = 85,
		["Astranaar, Ashenvale"] = 252
	},
	["Ironforge, Dun Morogh"] = {
		["Southshore, Hillsbrad"] = 215,
		["Menethil Harbor, Wetlands"] = 114,
		["Thelsamar, Loch Modan"] = 101
	},
	["Rebel Camp, Stranglethorn Vale"] = {
		["Darkshire, Duskwood"] = 48,
		["Booty Bay, Stranglethorn"] = 116
	},
	["Forest Song, Ashenvale"] = {
		["Astranaar, Ashenvale"] = 142
	},
	["Menethil Harbor, Wetlands"] = {
		["Ironforge, Dun Morogh"] = 89,
		["Stormwind, Elwynn"] = 259
	},
	["Chillwind Camp, Western Plaguelands"] = {
		["Southshore, Hillsbrad"] = 86,
		["Stormwind, Elwynn"] = 432
	},
	["Refuge Pointe, Arathi"] = {
		["Menethil Harbor, Wetlands"] = 126,
		["Ironforge, Dun Morogh"] = 271
	}
}
