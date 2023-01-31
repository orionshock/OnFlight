local addonName, addonCore = ...
local svDefaults = addonCore.svDefaults

svDefaults.global["gossipTriggered"] = {
	-- [gossipOptionID] = {startingPoint, endingPoint},
	-- Gossip Triggered Flights get integrated in to main Horde/Alliance DB as they occur as any other flight
	-- we set a start locatoin name and end location name here as it's not provided otherwise and is needed for the rest of it to work.
	-- likely will be editable in the future via ADV Options pannel so people can add in more as desired / found.
	[93033] = {"Sun's Reach Harbor", "The Sin'loren"},
	[92694] = {"The Sin'loren", "Sun's Reach Harbor"}
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
