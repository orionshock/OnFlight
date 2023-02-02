local addonName, addonCore = ...
local svDefaults = addonCore.svDefaults

svDefaults.global["gossipTriggered"] = {
	-- [gossipOptionID] = {startingPoint, endingPoint},
	-- Gossip Triggered Flights get integrated in to main Horde/Alliance DB as they occur as any other flight
	-- we set a start locatoin name and end location name here as it's not provided otherwise and is needed for the rest of it to work.

	[93033] = {"Sun's Reach Harbor", "The Sin'loren"},
	[92694] = {"The Sin'loren", "Sun's Reach Harbor"},

	--Wyrmrest Temple Gossip
	[93559] = {"Bottom, Wyrmrest Temple", "Middle, Wyrmrest Temple"},
	[93560] = {"Bottom, Wyrmrest Temple", "Top, Wyrmrest Temple"},
	[93568] = {"Middle, Wyrmrest Temple", "Bottom, Wyrmrest Temple"},
	[93569] = {"Middle, Wyrmrest Temple", "Top, Wyrmrest Temple"},
	[93073] = {"Top, Wyrmrest Temple", "Middle, Wyrmrest Temple"},
	[93074] = {"Top, Wyrmrest Temple", "Bottom, Wyrmrest Temple"},
}

svDefaults.global["Horde"] = {
	["Booty Bay, Stranglethorn"] = {
		["Grom'gol, Stranglethorn"] = 75
	},
	["Grom'gol, Stranglethorn"] = {
		["Booty Bay, Stranglethorn"] = 78
	}
}
svDefaults.global["Alliance"] = {}
