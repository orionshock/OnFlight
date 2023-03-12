local addonName, addonCore = ...
local svDefaults = addonCore.svDefaults

--[[
Stats:
Horde Stats:
--Flight Count: 355
--Total Duration: 78793sec 21hrs 53min
Alliance Stats:
--Flight Count: 4
--Total Duration: 573sec 9mins 33 Sec
Gossip Total: 15
]]

svDefaults.global["gossipTriggered"] = {
	-- [gossipOptionID] = {startingPoint, endingPoint},
	-- Gossip Triggered Flights get integrated in to main Horde/Alliance DB as they occur as any other flight
	-- we set a start locatoin name and end location name here as it's not provided otherwise and is needed to work.

	[93177] = {
		"Voltarus",
		"Zul' Drak Tour"
	},
	[93568] = {
		"Middle, Wyrmrest Temple",
		"Bottom, Wyrmrest Temple"
	},
	[93569] = {
		"Middle, Wyrmrest Temple",
		"Top, Wyrmrest Temple"
	},
	[94294] = {
		"Dalaran",
		"Orgrim's Hammer"
	},
	[91907] = {
		"Tanaris",
		"Caverns of Time"
	},
	[93033] = {
		"Sun's Reach Harbor",
		"The Sin'loren"
	},
	[93559] = {
		"Bottom, Wyrmrest Temple",
		"Middle, Wyrmrest Temple"
	},
	[93560] = {
		"Bottom, Wyrmrest Temple",
		"Top, Wyrmrest Temple"
	},
	[93564] = {
		"Warsong Hold",
		"Garrosh's Landing"
	},
	[92213] = {
		"Skyguard Outpost",
		"Blackwind Landing"
	},
	[92694] = {
		"The Sin'loren",
		"Sun's Reach Harbor"
	},
	[92215] = {
		"Blackwind Landing",
		"Skyguard Outpost"
	},
	[93073] = {
		"Top, Wyrmrest Temple",
		"Middle, Wyrmrest Temple"
	},
	[93074] = {
		"Top, Wyrmrest Temple",
		"Bottom, Wyrmrest Temple"
	}
}

svDefaults.global["Horde"] = {
	["Transitus Shield, Coldarra"] = {
		["Warsong Hold, Borean Tundra"] = 57,
		["Camp Oneqwah, Grizzly Hills"] = 300,
		["Apothecary Camp, Howling Fjord"] = 259,
		["Conquest Hold, Grizzly Hills"] = 232,
		["Taunka'le Village, Borean Tundra"] = 77,
		["Venomspite, Dragonblight"] = 194,
		["Vengeance Landing, Howling Fjord"] = 338,
		["Bor'gorok Outpost, Borean Tundra"] = 52,
		["Camp Winterhoof, Howling Fjord"] = 288,
		["New Agamand, Howling Fjord"] = 317,
		["Wyrmrest Temple, Dragonblight"] = 170,
		["Dalaran"] = 215,
		["Kor'koron Vanguard, Dragonblight"] = 178,
		["Agmar's Hammer, Dragonblight"] = 137
	},
	["Moa'ki, Dragonblight"] = {
		["Dalaran"] = 122
	},
	["Zoram'gar Outpost, Ashenvale"] = {
		["Thunder Bluff, Mulgore"] = 247,
		["Orgrimmar, Durotar"] = 261
	},
	["Revantusk Village, The Hinterlands"] = {
		["Undercity, Tirisfal"] = 285
	},
	["Camp Taurajo, The Barrens"] = {
		["Thunder Bluff, Mulgore"] = 114
	},
	["Area 52, Netherstorm"] = {
		["Thunderlord Stronghold, Blade's Edge Mountains"] = 108
	},
	["Stonebreaker Hold, Terokkar Forest"] = {
		["Shattrath, Terokkar Forest"] = 56
	},
	["Kor'koron Vanguard, Dragonblight"] = {
		["Wyrmrest Temple, Dragonblight"] = 67,
		["Dalaran"] = 55
	},
	["The Sepulcher, Silverpine Forest"] = {
		["Undercity, Tirisfal"] = 111
	},
	["Warsong Hold"] = {
		["Garrosh's Landing"] = 56
	},
	["Gadgetzan, Tanaris"] = {
		["Thunder Bluff, Mulgore"] = 303,
		["Orgrimmar, Durotar"] = 350
	},
	["Tanaris"] = {
		["Caverns of Time"] = 59
	},
	["Stonard, Swamp of Sorrows"] = {
		["Flame Crest, Burning Steppes"] = 176,
		["Undercity, Tirisfal"] = 728
	},
	["New Agamand, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 533,
		["Warsong Hold, Borean Tundra"] = 488,
		["Kamagua, Howling Fjord"] = 76,
		["Venomspite, Dragonblight"] = 194,
		["Conquest Hold, Grizzly Hills"] = 150,
		["Taunka'le Village, Borean Tundra"] = 423,
		["Camp Oneqwah, Grizzly Hills"] = 135,
		["Vengeance Landing, Howling Fjord"] = 79,
		["Camp Winterhoof, Howling Fjord"] = 79,
		["Bor'gorok Outpost, Borean Tundra"] = 495,
		["Wyrmrest Temple, Dragonblight"] = 245,
		["Dalaran"] = 335,
		["Apothecary Camp, Howling Fjord"] = 103,
		["Agmar's Hammer, Dragonblight"] = 315
	},
	["Hellfire Peninsula, The Dark Portal, Horde"] = {
		["Zabra'jin, Zangarmarsh"] = 271
	},
	["Wyrmrest Temple, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 193,
		["Vengeance Landing, Howling Fjord"] = 177,
		["Venomspite, Dragonblight"] = 33,
		["Conquest Hold, Grizzly Hills"] = 72,
		["Ulduar, The Storm Peaks"] = 181,
		["Camp Winterhoof, Howling Fjord"] = 128,
		["Dalaran"] = 64,
		["Dun Nifflelem, The Storm Peaks"] = 164,
		["New Agamand, Howling Fjord"] = 157
	},
	["Amber Ledge, Borean Tundra"] = {
		["Dalaran"] = 186
	},
	["Valormok, Azshara"] = {
		["Thunder Bluff, Mulgore"] = 250,
		["Orgrimmar, Durotar"] = 101
	},
	["Flame Crest, Burning Steppes"] = {
		["Undercity, Tirisfal"] = 578
	},
	["Freewind Post, Thousand Needles"] = {
		["Orgrimmar, Durotar"] = 278,
		["Thunder Bluff, Mulgore"] = 222
	},
	["Grom'arsh Crash-Site, The Storm Peaks"] = {
		["Bouldercrag's Refuge, The Storm Peaks"] = 37,
		["Argent Tournament Grounds, Icecrown"] = 97,
		["New Agamand, Howling Fjord"] = 397,
		["Unu'pe, Borean Tundra"] = 372
	},
	["Splintertree Post, Ashenvale"] = {
		["Thunder Bluff, Mulgore"] = 267,
		["Orgrimmar, Durotar"] = 95
	},
	["Bottom, Wyrmrest Temple"] = {
		["Top, Wyrmrest Temple"] = 18,
		["Middle, Wyrmrest Temple"] = 15
	},
	["Top, Wyrmrest Temple"] = {
		["Middle, Wyrmrest Temple"] = 25,
		["Bottom, Wyrmrest Temple"] = 18
	},
	["Dalaran"] = {
		["Transitus Shield, Coldarra"] = 346,
		["Warsong Hold, Borean Tundra"] = 319,
		["Camp Oneqwah, Grizzly Hills"] = 230,
		["Moa'ki, Dragonblight"] = 159,
		["Camp Tunka'lo, The Storm Peaks"] = 145,
		["Death's Rise, Icecrown"] = 206,
		["Unu'pe, Borean Tundra"] = 265,
		["K3, The Storm Peaks"] = 52,
		["Argent Tournament Grounds, Icecrown"] = 122,
		["Bouldercrag's Refuge, The Storm Peaks"] = 166,
		["Conquest Hold, Grizzly Hills"] = 199,
		["Orgrim's Hammer"] = 126,
		["The Argent Stand, Zul'Drak"] = 145,
		["New Agamand, Howling Fjord"] = 348,
		["Wyrmrest Temple, Dragonblight"] = 121,
		["Amber Ledge, Borean Tundra"] = 310,
		["River's Heart, Sholazar Basin"] = 211,
		["Ebon Watch, Zul'Drak"] = 81,
		["Crusaders' Pinnacle, Icecrown"] = 39,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 129,
		["Bor'gorok Outpost, Borean Tundra"] = 307,
		["Light's Breach, Zul'Drak"] = 126,
		["Taunka'le Village, Borean Tundra"] = 235,
		["Sunreaver's Command, Crystalsong Forest"] = 57,
		["Vengeance Landing, Howling Fjord"] = 335,
		["Apothecary Camp, Howling Fjord"] = 255,
		["Venomspite, Dragonblight"] = 163,
		["Nesingwary Base Camp, Sholazar Basin"] = 246,
		["Ulduar, The Storm Peaks"] = 181,
		["The Shadow Vault, Icecrown"] = 162,
		["Gundrak, Zul'Drak"] = 238,
		["Dun Nifflelem, The Storm Peaks"] = 155,
		["Kamagua, Howling Fjord"] = 310,
		["Camp Winterhoof, Howling Fjord"] = 278,
		["The Argent Vanguard, Icecrown"] = 32,
		["Zim'Torga, Zul'Drak"] = 185,
		["Kor'koron Vanguard, Dragonblight"] = 73,
		["Warsong Camp, Wintergrasp"] = 161,
		["Agmar's Hammer, Dragonblight"] = 125
	},
	["Blackwind Landing"] = {
		["Skyguard Outpost"] = 244
	},
	["Taunka'le Village, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 111,
		["Dalaran"] = 207,
		["New Agamand, Howling Fjord"] = 361,
		["Vengeance Landing, Howling Fjord"] = 391
	},
	["Venomspite, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 342,
		["Vengeance Landing, Howling Fjord"] = 216,
		["New Agamand, Howling Fjord"] = 185,
		["Apothecary Camp, Howling Fjord"] = 97,
		["Conquest Hold, Grizzly Hills"] = 59,
		["Dalaran"] = 148,
		["Wyrmrest Temple, Dragonblight"] = 51,
		["Camp Winterhoof, Howling Fjord"] = 143
	},
	["Nighthaven"] = {
		["Thunder Bluff"] = 399
	},
	["Hammerfall, Arathi"] = {
		["Undercity, Tirisfal"] = 259
	},
	["Camp Winterhoof, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 515,
		["Warsong Hold, Borean Tundra"] = 474,
		["Camp Oneqwah, Grizzly Hills"] = 58,
		["Apothecary Camp, Howling Fjord"] = 56,
		["Conquest Hold, Grizzly Hills"] = 93,
		["Argent Tournament Grounds, Icecrown"] = 368,
		["K3, The Storm Peaks"] = 229,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 305,
		["New Agamand, Howling Fjord"] = 80,
		["Vengeance Landing, Howling Fjord"] = 74,
		["Wyrmrest Temple, Dragonblight"] = 225,
		["Dalaran"] = 256,
		["Venomspite, Dragonblight"] = 174,
		["Agmar's Hammer, Dragonblight"] = 294
	},
	["The Argent Vanguard, Icecrown"] = {
		["Dalaran"] = 31,
		["Argent Tournament Grounds, Icecrown"] = 124,
		["Dun Nifflelem, The Storm Peaks"] = 177
	},
	["Zim'Torga, Zul'Drak"] = {
		["Dalaran"] = 171
	},
	["Sun's Reach Harbor"] = {
		["The Sin'loren"] = 59
	},
	["Sunreaver's Command, Crystalsong Forest"] = {
		["Camp Winterhoof, Howling Fjord"] = 235,
		["Dalaran"] = 55
	},
	["Warsong Hold, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 72,
		["Vengeance Landing, Howling Fjord"] = 477,
		["New Agamand, Howling Fjord"] = 447,
		["Camp Winterhoof, Howling Fjord"] = 403,
		["Dalaran"] = 294,
		["Argent Tournament Grounds, Icecrown"] = 375,
		["Unu'pe, Borean Tundra"] = 92
	},
	["Kamagua, Howling Fjord"] = {
		["New Agamand, Howling Fjord"] = 63,
		["Dalaran"] = 287
	},
	["Kargath, Badlands"] = {
		["Undercity, Tirisfal"] = 497
	},
	["Thrallmar, Hellfire Peninsula"] = {
		["Shattrath, Terokkar Forest"] = 122
	},
	["Falcon Watch, Hellfire Peninsula"] = {
		["Shattrath, Terokkar Forest"] = 71
	},
	["Camp Tunka'lo, The Storm Peaks"] = {
		["Dalaran"] = 185
	},
	["The Bulwark, Tirisfal"] = {
		["Undercity, Tirisfal"] = 89
	},
	["Grom'gol, Stranglethorn"] = {
		["Flame Crest, Burning Steppes"] = 198,
		["Booty Bay, Stranglethorn"] = 78,
		["Undercity, Tirisfal"] = 742
	},
	["Voltarus"] = {
		["Zul' Drak Tour"] = 216
	},
	["Zabra'jin, Zangarmarsh"] = {
		["Shattrath, Terokkar Forest"] = 151
	},
	["Ulduar, The Storm Peaks"] = {
		["The Argent Stand, Zul'Drak"] = 205
	},
	["Death's Rise, Icecrown"] = {
		["Argent Tournament Grounds, Icecrown"] = 170,
		["Dalaran"] = 238
	},
	["Camp Mojache, Feralas"] = {
		["Thunder Bluff, Mulgore"] = 259,
		["Orgrimmar, Durotar"] = 380
	},
	["K3, The Storm Peaks"] = {
		["Argent Tournament Grounds, Icecrown"] = 172,
		["Dalaran"] = 71
	},
	["The Shadow Vault"] = {
		["Seeds Of Chaos"] = 259
	},
	["Argent Tournament Grounds, Icecrown"] = {
		["K3, The Storm Peaks"] = 178,
		["Transitus Shield, Coldarra"] = 414,
		["The Shadow Vault, Icecrown"] = 88,
		["Warsong Camp, Wintergrasp"] = 224,
		["Ulduar, The Storm Peaks"] = 95,
		["Dalaran"] = 140,
		["Crusaders' Pinnacle, Icecrown"] = 73,
		["Unu'pe, Borean Tundra"] = 333
	},
	["Bouldercrag's Refuge, The Storm Peaks"] = {
		["Argent Tournament Grounds, Icecrown"] = 60,
		["Dalaran"] = 150
	},
	["Conquest Hold, Grizzly Hills"] = {
		["Transitus Shield, Coldarra"] = 428,
		["Vengeance Landing, Howling Fjord"] = 158,
		["New Agamand, Howling Fjord"] = 148,
		["Apothecary Camp, Howling Fjord"] = 57,
		["Venomspite, Dragonblight"] = 88,
		["Dalaran"] = 185,
		["Camp Oneqwah, Grizzly Hills"] = 101,
		["Camp Winterhoof, Howling Fjord"] = 84
	},
	["Silvermoon City"] = {
		["Revantusk Village, The Hinterlands"] = 122
	},
	["Nesingwary Base Camp, Sholazar Basin"] = {
		["Dalaran"] = 363
	},
	["Shadowprey Village, Desolace"] = {
		["Orgrimmar, Durotar"] = 385,
		["Thunder Bluff, Mulgore"] = 178
	},
	["Booty Bay, Stranglethorn"] = {
		["Grom'gol, Stranglethorn"] = 75,
		["Undercity, Tirisfal"] = 811
	},
	["Orgrimmar, Durotar"] = {
		["Brackenwall Village, Dustwallow Marsh"] = 228,
		["Cenarion Hold, Silithus"] = 489,
		["Moonglade"] = 357,
		["Marshal's Refuge, Un'Goro Crater"] = 451,
		["Freewind Post, Thousand Needles"] = 292,
		["Crossroads, The Barrens"] = 108,
		["Camp Taurajo, The Barrens"] = 181,
		["Everlook, Winterspring"] = 240,
		["Thunder Bluff, Mulgore"] = 225,
		["Sun Rock Retreat, Stonetalon Mountains"] = 257,
		["Camp Mojache, Feralas"] = 359,
		["Gadgetzan, Tanaris"] = 417,
		["Shadowprey Village, Desolace"] = 373,
		["Ratchet, The Barrens"] = 108,
		["Bloodvenom Post, Felwood"] = 252,
		["Splintertree Post, Ashenvale"] = 89,
		["Zoram'gar Outpost, Ashenvale"] = 249,
		["Mudsprocket, Dustwallow Marsh"] = 265,
		["Emerald Sanctuary, Felwood"] = 168,
		["Valormok, Azshara"] = 95
	},
	["Marshal's Refuge, Un'Goro Crater"] = {
		["Orgrimmar, Durotar"] = 450,
		["Thunder Bluff, Mulgore"] = 416
	},
	["Cenarion Hold, Silithus"] = {
		["Thunder Bluff, Mulgore"] = 389,
		["Orgrimmar, Durotar"] = 510
	},
	["Skyguard Outpost"] = {
		["Blackwind Landing"] = 243
	},
	["Thorium Point, Searing Gorge"] = {
		["Undercity, Tirisfal"] = 566
	},
	["Moonglade"] = {
		["Thunder Bluff, Mulgore"] = 458,
		["Orgrimmar, Durotar"] = 376
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
	["Brackenwall Village, Dustwallow Marsh"] = {
		["Thunder Bluff, Mulgore"] = 224,
		["Orgrimmar, Durotar"] = 215
	},
	["Garadar, Nagrand"] = {
		["Shattrath, Terokkar Forest"] = 77
	},
	["Middle, Wyrmrest Temple"] = {
		["Top, Wyrmrest Temple"] = 23,
		["Bottom, Wyrmrest Temple"] = 13
	},
	["Thondoril River, Western Plaguelands"] = {
		["Undercity, Tirisfal"] = 160
	},
	["Swamprat Post, Zangarmarsh"] = {
		["Shattrath, Terokkar Forest"] = 86
	},
	["Tarren Mill, Hillsbrad"] = {
		["The Bulwark, Tirisfal"] = 69,
		["Undercity, Tirisfal"] = 139
	},
	["Ebon Watch, Zul'Drak"] = {
		["K3, The Storm Peaks"] = 40,
		["Dalaran"] = 67,
		["Camp Winterhoof, Howling Fjord"] = 198,
		["Argent Tournament Grounds, Icecrown"] = 180
	},
	["Undercity, Tirisfal"] = {
		["Booty Bay, Stranglethorn"] = 784,
		["Kargath, Badlands"] = 488,
		["Flame Crest, Burning Steppes"] = 554,
		["Tarren Mill, Hillsbrad"] = 144,
		["Stonard, Swamp of Sorrows"] = 711,
		["Thorium Point, Searing Gorge"] = 543,
		["Hammerfall, Arathi"] = 300,
		["Revantusk Village, The Hinterlands"] = 284,
		["Grom'gol, Stranglethorn"] = 726,
		["Light's Hope Chapel, Eastern Plaguelands"] = 261,
		["The Sepulcher, Silverpine Forest"] = 106,
		["The Bulwark, Tirisfal"] = 88,
		["Thondoril River, Western Plaguelands"] = 152
	},
	["Crusaders' Pinnacle, Icecrown"] = {
		["Wyrmrest Temple, Dragonblight"] = 174,
		["Dalaran"] = 71,
		["The Shadow Vault, Icecrown"] = 123
	},
	["The Sin'loren"] = {
		["Sun's Reach Harbor"] = 12
	},
	["Crossroads, The Barrens"] = {
		["Orgrimmar, Durotar"] = 116,
		["Thunder Bluff, Mulgore"] = 107
	},
	["Mudsprocket, Dustwallow Marsh"] = {
		["Orgrimmar, Durotar"] = 245,
		["Thunder Bluff, Mulgore"] = 223
	},
	["Bor'gorok Outpost, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 92,
		["Dalaran"] = 250,
		["New Agamand, Howling Fjord"] = 438,
		["Vengeance Landing, Howling Fjord"] = 468
	},
	["Light's Breach, Zul'Drak"] = {
		["Wyrmrest Temple, Dragonblight"] = 130,
		["Dalaran"] = 107,
		["Argent Tournament Grounds, Icecrown"] = 220,
		["Moa'ki, Dragonblight"] = 182
	},
	["River's Heart, Sholazar Basin"] = {
		["Dalaran"] = 301
	},
	["Sun Rock Retreat, Stonetalon Mountains"] = {
		["Orgrimmar, Durotar"] = 266,
		["Thunder Bluff, Mulgore"] = 174
	},
	["Unu'pe, Borean Tundra"] = {
		["Camp Winterhoof, Howling Fjord"] = 321,
		["Dalaran"] = 229,
		["Camp Oneqwah, Grizzly Hills"] = 338,
		["Argent Tournament Grounds, Icecrown"] = 331
	},
	["Vengeance Landing, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 588,
		["Warsong Hold, Borean Tundra"] = 547,
		["Camp Oneqwah, Grizzly Hills"] = 104,
		["Apothecary Camp, Howling Fjord"] = 130,
		["Conquest Hold, Grizzly Hills"] = 165,
		["Death's Rise, Icecrown"] = 495,
		["Taunka'le Village, Borean Tundra"] = 478,
		["Venomspite, Dragonblight"] = 247,
		["New Agamand, Howling Fjord"] = 87,
		["Camp Winterhoof, Howling Fjord"] = 73,
		["Bor'gorok Outpost, Borean Tundra"] = 550,
		["Wyrmrest Temple, Dragonblight"] = 298,
		["Dalaran"] = 303,
		["Kor'koron Vanguard, Dragonblight"] = 343,
		["Agmar's Hammer, Dragonblight"] = 368
	},
	["Warsong Camp, Wintergrasp"] = {
		["River's Heart, Sholazar Basin"] = 77,
		["Dalaran"] = 141,
		["Argent Tournament Grounds, Icecrown"] = 240
	},
	["Apothecary Camp, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 459,
		["Vengeance Landing, Howling Fjord"] = 132,
		["New Agamand, Howling Fjord"] = 92,
		["Venomspite, Dragonblight"] = 117,
		["Conquest Hold, Grizzly Hills"] = 47,
		["Dalaran"] = 232,
		["Camp Winterhoof, Howling Fjord"] = 60
	},
	["Everlook, Winterspring"] = {
		["Thunder Bluff, Mulgore"] = 385,
		["Orgrimmar, Durotar"] = 243
	},
	["Camp Oneqwah, Grizzly Hills"] = {
		["K3, The Storm Peaks"] = 172,
		["Vengeance Landing, Howling Fjord"] = 105,
		["Argent Tournament Grounds, Icecrown"] = 311,
		["Conquest Hold, Grizzly Hills"] = 96,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 247,
		["Camp Winterhoof, Howling Fjord"] = 48,
		["Dalaran"] = 199,
		["Transitus Shield, Coldarra"] = 511,
		["New Agamand, Howling Fjord"] = 128
	},
	["Shattrath, Terokkar Forest"] = {
		["Garadar, Nagrand"] = 82,
		["Area 52, Netherstorm"] = 205,
		["Zabra'jin, Zangarmarsh"] = 136,
		["Thrallmar, Hellfire Peninsula"] = 131,
		["Stonebreaker Hold, Terokkar Forest"] = 69,
		["Falcon Watch, Hellfire Peninsula"] = 76,
		["Swamprat Post, Zangarmarsh"] = 79
	},
	["Gundrak, Zul'Drak"] = {
		["Dalaran"] = 227
	},
	["Ratchet, The Barrens"] = {
		["Orgrimmar, Durotar"] = 101,
		["Crossroads, The Barrens"] = 68,
		["Thunder Bluff, Mulgore"] = 174
	},
	["Light's Hope Chapel, Eastern Plaguelands"] = {
		["Undercity, Tirisfal"] = 260
	},
	["Dun Nifflelem, The Storm Peaks"] = {
		["Argent Tournament Grounds, Icecrown"] = 193,
		["Dalaran"] = 158
	},
	["Bloodvenom Post, Felwood"] = {
		["Thunder Bluff, Mulgore"] = 347,
		["Orgrimmar, Durotar"] = 259
	},
	["The Argent Stand, Zul'Drak"] = {
		["Dalaran"] = 119
	},
	["The Shadow Vault, Icecrown"] = {
		["Death's Rise, Icecrown"] = 77,
		["Argent Tournament Grounds, Icecrown"] = 77
	},
	["Emerald Sanctuary, Felwood"] = {
		["Orgrimmar, Durotar"] = 172,
		["Thunder Bluff, Mulgore"] = 343
	},
	["Agmar's Hammer, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 224,
		["Vengeance Landing, Howling Fjord"] = 302,
		["New Agamand, Howling Fjord"] = 272,
		["Dalaran"] = 120,
		["Camp Winterhoof, Howling Fjord"] = 229
	}
}

svDefaults.global["Alliance"] = {
	["Thelsamar, Loch Modan"] = {
		["Ironforge, Dun Morogh"] = 110,
		["Stormwind, Elwynn"] = 276
	},
	["Sentinel Hill, Westfall"] = {
		["Stormwind, Elwynn"] = 86
	},
	["Ironforge, Dun Morogh"] = {
		["Thelsamar, Loch Modan"] = 101
	}
}
