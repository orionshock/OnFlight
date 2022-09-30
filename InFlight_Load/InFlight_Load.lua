local InFlight = CreateFrame("Frame", "InFlight") -- no parent is intentional
local self = InFlight
InFlight:SetScript(
	"OnEvent",
	function(this, event, ...)
		this[event](this, ...)
	end
)
InFlight:RegisterEvent("ADDON_LOADED")

-- LOCAL FUNCTIONS
local function LoadInFlight()
	if not InFlight.ShowOptions then
		LoadAddOn("InFlight")
	end

	return GetAddOnEnableState(UnitName("player"), "InFlight") == 2 and InFlight.ShowOptions and true or nil
end

function InFlight:ADDON_LOADED(addonName)
	if addonName == "InFlight_Load" then
		self:RegisterEvent("TAXIMAP_OPENED")
		if self.SetupInFlight then
			self:SetupInFlight()
		else
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif addonName == "InFlight" then
		self:UnregisterEvent("ADDON_LOADED")
		self:LoadBulk()
		local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3", true)
		if Quartz3 then
			local Quartz3_Flight = Quartz3:GetModule("Flight")
			if Quartz3_Flight then
				Quartz3_Flight:TAXIMAP_OPENED()
			end
		end
	end
end

function InFlight:TAXIMAP_OPENED(...)
	if LoadInFlight() then
		local uiMapSystem = ...
		local isTaxiMap = uiMapSystem == Enum.UIMapSystem.Taxi
		self:InitSource(isTaxiMap)
	end
end

-- maybe this stuff gets garbage collected if InFlight isn't loadable
if GetAddOnEnableState(UnitName("player"), "InFlight") == 2 then
	-- GLOBALS -> LOCAL
	local ipairs, strfind = ipairs, strfind

	-- LOCALIZATION
	local L = LibStub("AceLocale-3.0"):GetLocale("InFlight", true)
	InFlight.L = L

	local gossipFlightData = {
		[L["Nighthaven"]] = {
			{find = L["NighthavenGossipA"], s = "Nighthaven", d = "Rut'theran Village"},
			{find = L["NighthavenGossipH"], s = "Nighthaven", d = "Thunder Bluff"}
		},
		[L["Skyguard Outpost"]] = {
			{find = L["BEM-Skettis"], s = "Skyguard Outpost", d = "Blackwind Landing"}
		},
		[L["Blackwind Landing"]] = {
			{find = L["Skettis-BEM"], s = "Blackwind Landing", d = "Skyguard Outpost"}
		},
		[L["Caverns of Time"]] = {
			{find = L["CoT-Flight"], s = "Tanaris", d = "Caverns of Time"}
		},
		[L["Old Hillsbrad Foothills"]] = {
			{find = L["OHB-Flight"], s = "Old Hillsbrad Foothills Entrance", d = "Durnholde Keep"}
		},
		[L["Area 52"]] = {
			{find = L["Scryer-ManaForgeC"], s = "Area 52", d = L["ManaForgeC"]}
		},
		[L["Sun's Reach Harbor"]] = {
			{find = L["SSO_BombRun"], s = "Sun's Reach Harbor", d = "Dead Scar"},
			{find = L["SSO_Boats"], s = "Sun's Reach Harbor", d = "The Sin'loren"}
		},
		[L["The Sin'loren"]] = {
			{find = L["ReturnFromBoats"], s = "The Sin'loren", d = "Sun's Reach Harbor"}
		},
		["Wyrmrest Temple"] = {
			--Top to Bottom, Top to Middle
			{find = "Yes, please, I would like to return to the ground level of the temple.", s = "Wyrmrest Temple Top", d = "Wyrmrest Temple Ground"},
			{find = "I would like to go to Lord Devrestrasz in the middle of the temple.", s = "Wyrmrest Temple Top", d = "Wyrmrest Temple Middle"},
			--Middle to Top, Middle to Bottom
			{find = "My lord, I need to get to the top of the temple.", s = "Wyrmrest Temple Middle", d = "Wyrmrest Temple Top"},
			{find = "Can I get a ride back to ground level, Lord Devrestrasz?", s = "Wyrmrest Temple Middle", d = "Wyrmrest Temple Ground"},
			--Bottom to Top, Bottom to Middle
			{find = "Steward, please allow me to ride one of the drakes to the queen's chamber at the top of the temple.", s = "Wyrmrest Temple Ground", d = "Wyrmrest Temple Top"},
			{find = "Can you spare a drake to take me to Lord Devrestrasz in the middle of the temple?", s = "Wyrmrest Temple Ground", d = "Wyrmrest Temple Middle"}
		},
		["Voltarus"] = {
			{find = "Uhh, can you send me on the tour of Zul'Drak?", s = "Voltaris - Dark Horizon Start", d = "Voltaris - Dark Horizon End"}
		},
		["Altar of Har'koa"] = {
			{
				find = "Great and powerful Har'koa, please call for one of your children that it might stealthily carry me into the Altar of Quetz'lun.",
				s = "Altar of Har'koa",
				d = "Altar of Quetz'lun"
			}
		},
		["Krasus' Landing"] = {
			{ find = "I'm ready to fly to Sholazar Basin.", s = "Krasus' Landing", d ="Wildgrowth Mangal"}
		}
	}

	-- Support flights that are started by gossip options properly so automation addons don't futz it.
	do
		local orig_SelectGossipOption = SelectGossipOption
		function SelectGossipOption(option, ...)
			--print("SelectGossipOption", option, ...)
			local gossipText, gossipType = select(((option * 2) - 1), GetGossipOptions())
			--print(gossipText, gossipType)
			if (gossipText and gossipText ~= "") and (gossipType == "gossip") then
				local gossipZoneData = gossipFlightData[GetMinimapZoneText()]
				--print(gossipText, GetMinimapZoneText(), gossipZoneData)
				if gossipZoneData then
					for index, gossipFlightOption in ipairs(gossipZoneData) do
						if strfind(gossipText, gossipFlightOption.find, 1, true) then
							if gossipFlightOption.s and gossipFlightOption.d and LoadInFlight() then
								print("|cff00ff40In|cff00aaffFlight|r: Special Flight - ", gossipFlightOption.s, "->", gossipFlightOption.d)
								self:StartMiscFlight(gossipFlightOption.s, gossipFlightOption.d)
							end
						end
					end
				end
			end
			orig_SelectGossipOption(option, ...)
		end
	end

	function InFlight:SetupInFlight()
		SlashCmdList.INFLIGHT = function()
			if LoadInFlight() then
				self:ShowOptions()
			end
		end
		SLASH_INFLIGHT1 = "/inflight"

		local panel = CreateFrame("Frame")
		panel.name = "InFlight"
		panel:SetScript(
			"OnShow",
			function(this)
				if LoadInFlight() and InFlight.SetLayout then
					InFlight:SetLayout(this)
				end
			end
		)
		panel:Hide()
		InterfaceOptions_AddCategory(panel)
		InFlight.SetupInFlight = nil
	end
end
