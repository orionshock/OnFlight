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
		local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3")
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
		}
	}

	-- Support flights that are started by gossip options properly so automation addons don't futz it.
	do
		local orig_SelectGossipOption = SelectGossipOption
		function SelectGossipOption(option, ...)
			local gossipText, gossipType = select(option, GetGossipOptions())
			if (gossipText and gossipText ~= "") and (gossipType == "gossip") then
				local gossipZoneData = gossipFlightData[GetMinimapZoneText()]
				if gossipZoneData then
					for index, gossipFlightOption in ipairs(gossipZoneData) do
						if strfind(gossipText, gossipFlightOption.find, 1, true) then
							if gossipFlightOption.s and gossipFlightOption.d and LoadInFlight() then
								--print("|cff00ff40In|cff00aaffFlight|r: Special Flight - ", gossipFlightOption.s, "->", gossipFlightOption.d)
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
