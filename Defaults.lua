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
		["Dalaran"] = 215
	},
	["Moa'ki, Dragonblight"] = {
		["Dalaran"] = 122
	},
	["Revantusk Village, The Hinterlands"] = {
		["Undercity, Tirisfal"] = 285
	},
	["Shattrath, Terokkar Forest"] = {
		["Garadar, Nagrand"] = 82,
		["Zabra'jin, Zangarmarsh"] = 136,
		["Thrallmar, Hellfire Peninsula"] = 131,
		["Stonebreaker Hold, Terokkar Forest"] = 69,
		["Falcon Watch, Hellfire Peninsula"] = 76,
		["Swamprat Post, Zangarmarsh"] = 79
	},
	["Kor'koron Vanguard, Dragonblight"] = {
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
		["Dalaran"] = 335
	},
	["Wyrmrest Temple, Dragonblight"] = {
		["Dalaran"] = 64
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
		["Dalaran"] = 207
	},
	["Venomspite, Dragonblight"] = {
		["Dalaran"] = 148
	},
	["Nighthaven"] = {
		["Thunder Bluff"] = 399
	},
	["Hammerfall, Arathi"] = {
		["Undercity, Tirisfal"] = 259
	},
	["Camp Winterhoof, Howling Fjord"] = {
		["Dalaran"] = 256
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
		["Dalaran"] = 294
	},
	["Kamagua, Howling Fjord"] = {
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
	["Everlook, Winterspring"] = {
		["Orgrimmar, Durotar"] = 243
	},
	["Death's Rise, Icecrown"] = {
		["Argent Tournament Grounds, Icecrown"] = 170
	},
	["Sun Rock Retreat, Stonetalon Mountains"] = {
		["Orgrimmar, Durotar"] = 266,
		["Thunder Bluff, Mulgore"] = 174
	},
	["Argent Tournament Grounds, Icecrown"] = {
		["K3, The Storm Peaks"] = 178,
		["Dalaran"] = 140,
		["The Shadow Vault, Icecrown"] = 88,
		["Unu'pe, Borean Tundra"] = 333
	},
	["Conquest Hold, Grizzly Hills"] = {
		["Dalaran"] = 185
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
		["Crossroads, The Barrens"] = 108,
		["Splintertree Post, Ashenvale"] = 89,
		["Everlook, Winterspring"] = 240,
		["Thunder Bluff, Mulgore"] = 225,
		["Brackenwall Village, Dustwallow Marsh"] = 228,
		["Valormok, Azshara"] = 95
	},
	["Brackenwall Village, Dustwallow Marsh"] = {
		["Orgrimmar, Durotar"] = 215
	},
	["Garadar, Nagrand"] = {
		["Shattrath, Terokkar Forest"] = 77
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
	["Dalaran"] = {
		["Transitus Shield, Coldarra"] = 346,
		["Warsong Hold, Borean Tundra"] = 319,
		["Camp Oneqwah, Grizzly Hills"] = 230,
		["River's Heart, Sholazar Basin"] = 211,
		["Moa'ki, Dragonblight"] = 159,
		["Ebon Watch, Zul'Drak"] = 81,
		["Sunreaver's Command, Crystalsong Forest"] = 57,
		["Bor'gorok Outpost, Borean Tundra"] = 264,
		["Light's Breach, Zul'Drak"] = 125,
		["Kor'koron Vanguard, Dragonblight"] = 73,
		["Taunka'le Village, Borean Tundra"] = 235,
		["Nesingwary Base Camp, Sholazar Basin"] = 246,
		["Vengeance Landing, Howling Fjord"] = 335,
		["Argent Tournament Grounds, Icecrown"] = 122,
		["Venomspite, Dragonblight"] = 162,
		["Conquest Hold, Grizzly Hills"] = 199,
		["Ulduar, The Storm Peaks"] = 181,
		["The Argent Stand, Zul'Drak"] = 144,
		["Unu'pe, Borean Tundra"] = 265,
		["Wyrmrest Temple, Dragonblight"] = 121,
		["Apothecary Camp, Howling Fjord"] = 255,
		["New Agamand, Howling Fjord"] = 348,
		["Camp Winterhoof, Howling Fjord"] = 278,
		["Zim'Torga, Zul'Drak"] = 185,
		["Kamagua, Howling Fjord"] = 310,
		["Amber Ledge, Borean Tundra"] = 310,
		["Agmar's Hammer, Dragonblight"] = 125
	},
	["Undercity, Tirisfal"] = {
		["Booty Bay, Stranglethorn"] = 784,
		["Kargath, Badlands"] = 488,
		["Tarren Mill, Hillsbrad"] = 144,
		["Hammerfall, Arathi"] = 300,
		["Revantusk Village, The Hinterlands"] = 284,
		["Light's Hope Chapel, Eastern Plaguelands"] = 261,
		["The Sepulcher, Silverpine Forest"] = 106,
		["The Bulwark, Tirisfal"] = 88,
		["Thondoril River, Western Plaguelands"] = 152
	},
	["Crossroads, The Barrens"] = {
		["Orgrimmar, Durotar"] = 117,
		["Thunder Bluff, Mulgore"] = 107
	},
	["The Sin'loren"] = {
		["Sun's Reach Harbor"] = 12
	},
	["Bor'gorok Outpost, Borean Tundra"] = {
		["Dalaran"] = 250
	},
	["Light's Breach, Zul'Drak"] = {
		["Dalaran"] = 107
	},
	["River's Heart, Sholazar Basin"] = {
		["Dalaran"] = 301
	},
	["The Shadow Vault, Icecrown"] = {
		["Death's Rise, Icecrown"] = 77
	},
	["Unu'pe, Borean Tundra"] = {
		["Dalaran"] = 229
	},
	["Vengeance Landing, Howling Fjord"] = {
		["Dalaran"] = 303
	},
	["Apothecary Camp, Howling Fjord"] = {
		["Dalaran"] = 232
	},
	["Warsong Camp, Wintergrasp"] = {
		["Argent Tournament Grounds, Icecrown"] = 240
	},
	["Bloodvenom Post, Felwood"] = {
		["Orgrimmar, Durotar"] = 259
	},
	["Stonard, Swamp of Sorrows"] = {
		["Flame Crest, Burning Steppes"] = 175
	},
	["Middle, Wyrmrest Temple"] = {
		["Top, Wyrmrest Temple"] = 23,
		["Bottom, Wyrmrest Temple"] = 13
	},
	["K3, The Storm Peaks"] = {
		["Argent Tournament Grounds, Icecrown"] = 172
	},
	["Ratchet, The Barrens"] = {
		["Orgrimmar, Durotar"] = 101
	},
	["Zabra'jin, Zangarmarsh"] = {
		["Shattrath, Terokkar Forest"] = 151
	},
	["Booty Bay, Stranglethorn"] = {
		["Undercity, Tirisfal"] = 811,
		["Grom'gol, Stranglethorn"] = 75
	},
	["Stonebreaker Hold, Terokkar Forest"] = {
		["Shattrath, Terokkar Forest"] = 56
	},
	["The Bulwark, Tirisfal"] = {
		["Undercity, Tirisfal"] = 89
	},
	["Camp Oneqwah, Grizzly Hills"] = {
		["K3, The Storm Peaks"] = 172,
		["Dalaran"] = 199
	},
	["Light's Hope Chapel, Eastern Plaguelands"] = {
		["Undercity, Tirisfal"] = 260
	},
	["Agmar's Hammer, Dragonblight"] = {
		["Dalaran"] = 120
	},
	["Grom'gol, Stranglethorn"] = {
		["Booty Bay, Stranglethorn"] = 78
	}
}
svDefaults.global["Alliance"] = {}
