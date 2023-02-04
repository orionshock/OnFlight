local addonName, addonCore = ...
local svDefaults = addonCore.svDefaults

svDefaults.global["gossipTriggered"] = {
	-- [gossipOptionID] = {startingPoint, endingPoint},
	-- Gossip Triggered Flights get integrated in to main Horde/Alliance DB as they occur as any other flight
	-- we set a start locatoin name and end location name here as it's not provided otherwise and is needed to work.

	[93033] = {"Sun's Reach Harbor", "The Sin'loren"},
	[92694] = {"The Sin'loren", "Sun's Reach Harbor"},
	--Wyrmrest Temple Gossip
	[93559] = {"Bottom, Wyrmrest Temple", "Middle, Wyrmrest Temple"},
	[93560] = {"Bottom, Wyrmrest Temple", "Top, Wyrmrest Temple"},
	[93568] = {"Middle, Wyrmrest Temple", "Bottom, Wyrmrest Temple"},
	[93569] = {"Middle, Wyrmrest Temple", "Top, Wyrmrest Temple"},
	[93073] = {"Top, Wyrmrest Temple", "Middle, Wyrmrest Temple"},
	[93074] = {"Top, Wyrmrest Temple", "Bottom, Wyrmrest Temple"}
}

svDefaults.global["Horde"] = {
	["Transitus Shield, Coldarra"] = {
		["Vengeance Landing, Howling Fjord"] = 338,
		["Camp Oneqwah, Grizzly Hills"] = 300,
		["Venomspite, Dragonblight"] = 194,
		["Conquest Hold, Grizzly Hills"] = 232,
		["Taunka'le Village, Borean Tundra"] = 77,
		["Apothecary Camp, Howling Fjord"] = 259,
		["Warsong Hold, Borean Tundra"] = 57,
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
	["Revantusk Village, The Hinterlands"] = {
		["Undercity, Tirisfal"] = 285
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
	["Gadgetzan, Tanaris"] = {
		["Orgrimmar, Durotar"] = 350
	},
	["The Argent Stand, Zul'Drak"] = {
		["Dalaran"] = 119
	},
	["New Agamand, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 533,
		["Vengeance Landing, Howling Fjord"] = 79,
		["Kamagua, Howling Fjord"] = 76,
		["Apothecary Camp, Howling Fjord"] = 103,
		["Conquest Hold, Grizzly Hills"] = 150,
		["Taunka'le Village, Borean Tundra"] = 423,
		["Camp Oneqwah, Grizzly Hills"] = 135,
		["Warsong Hold, Borean Tundra"] = 488,
		["Camp Winterhoof, Howling Fjord"] = 79,
		["Bor'gorok Outpost, Borean Tundra"] = 495,
		["Wyrmrest Temple, Dragonblight"] = 245,
		["Dalaran"] = 335,
		["Venomspite, Dragonblight"] = 194,
		["Agmar's Hammer, Dragonblight"] = 315
	},
	["Wyrmrest Temple, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 193,
		["Vengeance Landing, Howling Fjord"] = 177,
		["New Agamand, Howling Fjord"] = 157,
		["Venomspite, Dragonblight"] = 33,
		["Dalaran"] = 64,
		["Camp Winterhoof, Howling Fjord"] = 128
	},
	["Amber Ledge, Borean Tundra"] = {
		["Dalaran"] = 186
	},
	["Valormok, Azshara"] = {
		["Orgrimmar, Durotar"] = 101
	},
	["Freewind Post, Thousand Needles"] = {
		["Thunder Bluff, Mulgore"] = 222
	},
	["Grom'arsh Crash-Site, The Storm Peaks"] = {
		["New Agamand, Howling Fjord"] = 397
	},
	["Splintertree Post, Ashenvale"] = {
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
	["Thunder Bluff, Mulgore"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 181,
		["Orgrimmar, Durotar"] = 207,
		["Crossroads, The Barrens"] = 102
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
		["Vengeance Landing, Howling Fjord"] = 74,
		["Camp Oneqwah, Grizzly Hills"] = 58,
		["Apothecary Camp, Howling Fjord"] = 56,
		["Conquest Hold, Grizzly Hills"] = 93,
		["New Agamand, Howling Fjord"] = 80,
		["Warsong Hold, Borean Tundra"] = 474,
		["Wyrmrest Temple, Dragonblight"] = 225,
		["Dalaran"] = 256,
		["Venomspite, Dragonblight"] = 174,
		["Agmar's Hammer, Dragonblight"] = 294
	},
	["The Argent Vanguard, Icecrown"] = {
		["Dalaran"] = 31
	},
	["Zim'Torga, Zul'Drak"] = {
		["Dalaran"] = 171
	},
	["Sun's Reach Harbor"] = {
		["The Sin'loren"] = 59
	},
	["Sunreaver's Command, Crystalsong Forest"] = {
		["Dalaran"] = 55
	},
	["Warsong Hold, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 72,
		["Vengeance Landing, Howling Fjord"] = 477,
		["New Agamand, Howling Fjord"] = 447,
		["Dalaran"] = 294,
		["Camp Winterhoof, Howling Fjord"] = 403
	},
	["Camp Oneqwah, Grizzly Hills"] = {
		["Transitus Shield, Coldarra"] = 511,
		["Vengeance Landing, Howling Fjord"] = 105,
		["New Agamand, Howling Fjord"] = 128,
		["Conquest Hold, Grizzly Hills"] = 95,
		["Dalaran"] = 199,
		["Camp Winterhoof, Howling Fjord"] = 48,
		["K3, The Storm Peaks"] = 172
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
	["Grom'gol, Stranglethorn"] = {
		["Booty Bay, Stranglethorn"] = 78
	},
	["Light's Hope Chapel, Eastern Plaguelands"] = {
		["Undercity, Tirisfal"] = 260
	},
	["Death's Rise, Icecrown"] = {
		["Argent Tournament Grounds, Icecrown"] = 170,
		["Dalaran"] = 238
	},
	["Booty Bay, Stranglethorn"] = {
		["Grom'gol, Stranglethorn"] = 75,
		["Undercity, Tirisfal"] = 811
	},
	["Argent Tournament Grounds, Icecrown"] = {
		["K3, The Storm Peaks"] = 178,
		["Dalaran"] = 140,
		["The Shadow Vault, Icecrown"] = 88,
		["Unu'pe, Borean Tundra"] = 333
	},
	["Bouldercrag's Refuge, The Storm Peaks"] = {
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
	["Nesingwary Base Camp, Sholazar Basin"] = {
		["Dalaran"] = 363
	},
	["Orgrimmar, Durotar"] = {
		["Sun Rock Retreat, Stonetalon Mountains"] = 257,
		["Gadgetzan, Tanaris"] = 417,
		["Freewind Post, Thousand Needles"] = 292,
		["Ratchet, The Barrens"] = 107,
		["Bloodvenom Post, Felwood"] = 252,
		["Splintertree Post, Ashenvale"] = 89,
		["Crossroads, The Barrens"] = 108,
		["Everlook, Winterspring"] = 240,
		["Thunder Bluff, Mulgore"] = 225,
		["Brackenwall Village, Dustwallow Marsh"] = 228,
		["Valormok, Azshara"] = 95
	},
	["Dalaran"] = {
		["Transitus Shield, Coldarra"] = 346,
		["Warsong Hold, Borean Tundra"] = 319,
		["Kamagua, Howling Fjord"] = 310,
		["Moa'ki, Dragonblight"] = 159,
		["Camp Tunka'lo, The Storm Peaks"] = 145,
		["Kor'koron Vanguard, Dragonblight"] = 73,
		["Unu'pe, Borean Tundra"] = 265,
		["K3, The Storm Peaks"] = 55,
		["Argent Tournament Grounds, Icecrown"] = 122,
		["Bouldercrag's Refuge, The Storm Peaks"] = 166,
		["Conquest Hold, Grizzly Hills"] = 199,
		["The Argent Stand, Zul'Drak"] = 144,
		["New Agamand, Howling Fjord"] = 348,
		["Wyrmrest Temple, Dragonblight"] = 121,
		["Amber Ledge, Borean Tundra"] = 310,
		["River's Heart, Sholazar Basin"] = 211,
		["Ebon Watch, Zul'Drak"] = 81,
		["Crusaders' Pinnacle, Icecrown"] = 39,
		["Grom'arsh Crash-Site, The Storm Peaks"] = 129,
		["Bor'gorok Outpost, Borean Tundra"] = 264,
		["Light's Breach, Zul'Drak"] = 125,
		["Taunka'le Village, Borean Tundra"] = 235,
		["Death's Rise, Icecrown"] = 206,
		["Vengeance Landing, Howling Fjord"] = 335,
		["Warsong Camp, Wintergrasp"] = 161,
		["Apothecary Camp, Howling Fjord"] = 255,
		["Dun Nifflelem, The Storm Peaks"] = 154,
		["Ulduar, The Storm Peaks"] = 181,
		["Nesingwary Base Camp, Sholazar Basin"] = 246,
		["The Shadow Vault, Icecrown"] = 179,
		["Camp Oneqwah, Grizzly Hills"] = 230,
		["Gundrak, Zul'Drak"] = 238,
		["Camp Winterhoof, Howling Fjord"] = 278,
		["The Argent Vanguard, Icecrown"] = 32,
		["Zim'Torga, Zul'Drak"] = 185,
		["Sunreaver's Command, Crystalsong Forest"] = 57,
		["Venomspite, Dragonblight"] = 162,
		["Agmar's Hammer, Dragonblight"] = 125
	},
	["Brackenwall Village, Dustwallow Marsh"] = {
		["Orgrimmar, Durotar"] = 215
	},
	["Garadar, Nagrand"] = {
		["Shattrath, Terokkar Forest"] = 77
	},
	["Gundrak, Zul'Drak"] = {
		["Dalaran"] = 227
	},
	["Middle, Wyrmrest Temple"] = {
		["Top, Wyrmrest Temple"] = 23,
		["Bottom, Wyrmrest Temple"] = 13
	},
	["Swamprat Post, Zangarmarsh"] = {
		["Shattrath, Terokkar Forest"] = 86
	},
	["Tarren Mill, Hillsbrad"] = {
		["Undercity, Tirisfal"] = 139
	},
	["Ebon Watch, Zul'Drak"] = {
		["Dalaran"] = 67
	},
	["Thondoril River, Western Plaguelands"] = {
		["Undercity, Tirisfal"] = 160
	},
	["Crusaders' Pinnacle, Icecrown"] = {
		["Dalaran"] = 71
	},
	["Undercity, Tirisfal"] = {
		["Booty Bay, Stranglethorn"] = 784,
		["Kargath, Badlands"] = 488,
		["Tarren Mill, Hillsbrad"] = 144,
		["Hammerfall, Arathi"] = 300,
		["Revantusk Village, The Hinterlands"] = 284,
		["The Bulwark, Tirisfal"] = 88,
		["The Sepulcher, Silverpine Forest"] = 106,
		["Light's Hope Chapel, Eastern Plaguelands"] = 261,
		["Thondoril River, Western Plaguelands"] = 152
	},
	["Crossroads, The Barrens"] = {
		["Orgrimmar, Durotar"] = 117,
		["Thunder Bluff, Mulgore"] = 107
	},
	["The Sin'loren"] = {
		["Sun's Reach Harbor"] = 12
	},
	["The Bulwark, Tirisfal"] = {
		["Undercity, Tirisfal"] = 89
	},
	["Light's Breach, Zul'Drak"] = {
		["Dalaran"] = 107
	},
	["Kamagua, Howling Fjord"] = {
		["New Agamand, Howling Fjord"] = 63,
		["Dalaran"] = 287
	},
	["River's Heart, Sholazar Basin"] = {
		["Dalaran"] = 301
	},
	["The Shadow Vault, Icecrown"] = {
		["Death's Rise, Icecrown"] = 77,
		["Argent Tournament Grounds, Icecrown"] = 77
	},
	["Vengeance Landing, Howling Fjord"] = {
		["Transitus Shield, Coldarra"] = 588,
		["Warsong Hold, Borean Tundra"] = 547,
		["Camp Oneqwah, Grizzly Hills"] = 104,
		["Venomspite, Dragonblight"] = 247,
		["Conquest Hold, Grizzly Hills"] = 165,
		["Taunka'le Village, Borean Tundra"] = 478,
		["Apothecary Camp, Howling Fjord"] = 130,
		["New Agamand, Howling Fjord"] = 87,
		["Camp Winterhoof, Howling Fjord"] = 73,
		["Bor'gorok Outpost, Borean Tundra"] = 550,
		["Wyrmrest Temple, Dragonblight"] = 298,
		["Dalaran"] = 303,
		["Kor'koron Vanguard, Dragonblight"] = 343,
		["Agmar's Hammer, Dragonblight"] = 368
	},
	["Unu'pe, Borean Tundra"] = {
		["Dalaran"] = 229
	},
	["Warsong Camp, Wintergrasp"] = {
		["Argent Tournament Grounds, Icecrown"] = 240,
		["Dalaran"] = 141
	},
	["Everlook, Winterspring"] = {
		["Orgrimmar, Durotar"] = 243
	},
	["Shattrath, Terokkar Forest"] = {
		["Garadar, Nagrand"] = 82,
		["Thrallmar, Hellfire Peninsula"] = 131,
		["Zabra'jin, Zangarmarsh"] = 136,
		["Stonebreaker Hold, Terokkar Forest"] = 69,
		["Falcon Watch, Hellfire Peninsula"] = 76,
		["Swamprat Post, Zangarmarsh"] = 79
	},
	["Sun Rock Retreat, Stonetalon Mountains"] = {
		["Orgrimmar, Durotar"] = 266,
		["Thunder Bluff, Mulgore"] = 174
	},
	["Bloodvenom Post, Felwood"] = {
		["Orgrimmar, Durotar"] = 259
	},
	["Ratchet, The Barrens"] = {
		["Orgrimmar, Durotar"] = 101
	},
	["Stonard, Swamp of Sorrows"] = {
		["Flame Crest, Burning Steppes"] = 175
	},
	["Dun Nifflelem, The Storm Peaks"] = {
		["Dalaran"] = 158
	},
	["K3, The Storm Peaks"] = {
		["Argent Tournament Grounds, Icecrown"] = 172,
		["Dalaran"] = 71
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
	["Zabra'jin, Zangarmarsh"] = {
		["Shattrath, Terokkar Forest"] = 151
	},
	["Bor'gorok Outpost, Borean Tundra"] = {
		["Transitus Shield, Coldarra"] = 92,
		["Dalaran"] = 250,
		["New Agamand, Howling Fjord"] = 438,
		["Vengeance Landing, Howling Fjord"] = 468
	},
	["Agmar's Hammer, Dragonblight"] = {
		["Transitus Shield, Coldarra"] = 224,
		["Vengeance Landing, Howling Fjord"] = 302,
		["New Agamand, Howling Fjord"] = 272,
		["Dalaran"] = 120,
		["Camp Winterhoof, Howling Fjord"] = 229
	}
}
svDefaults.global["Alliance"] = {}
