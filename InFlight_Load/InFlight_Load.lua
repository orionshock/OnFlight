local InFlight = CreateFrame("Frame", "InFlight")  -- no parent is intentional
local self = InFlight
InFlight:SetScript("OnEvent", function(this, event, ...) this[event](this, ...) end)
InFlight:RegisterEvent("ADDON_LOADED")

-- LOCAL FUNCTIONS
local function LoadInFlight()
	if not InFlight.ShowOptions then
		LoadAddOn("InFlight")
	end

	return GetAddOnEnableState(UnitName("player"), "InFlight") == 2 and InFlight.ShowOptions and true or nil
end

-----------------------------------------
function InFlight:ADDON_LOADED(addonName)
-----------------------------------------
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
	end
end

-------------------------------------
function InFlight:TAXIMAP_OPENED(...)
-------------------------------------
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

	local t
	do
	t = {
		[L["Nighthaven"]]					= {{ find = L["NighthavenGossipA"],			s = "Nighthaven", 					d = "Rut'theran Village" },
											   { find = L["NighthavenGossipH"],			s = "Nighthaven", 					d = "Thunder Bluff" }},
	}
	end

	-- support for flightpaths that are started by gossip options
	hooksecurefunc("GossipTitleButton_OnClick", function(this, button)
		if this.type ~= "Gossip" then
			return
		end

		local subzone = GetMinimapZoneText()
		local tsz = t[subzone]
		if not tsz then
--			print("|cff00ff40In|cff00aaffFlight|r: zone - ", L[GetMinimapZoneText()], GetMinimapZoneText())
--			print("|cff00ff40In|cff00aaffFlight|r: gossip - ", this:GetText())
			return
		end

		local text = this:GetText()
		if not text or text == "" then
			return
		end
--		print("|cff00ff40In|cff00aaffFlight|r: gossip - ", text)

		local source, destination
		for _, sz in ipairs(tsz) do
			if strfind(text, sz.find, 1, true) then
				source = sz.s
				destination = sz.d
				break
			end
		end

		if source and destination and LoadInFlight() then
			self:StartMiscFlight(source, destination)
		end
	end)

	---------------------------------
	function InFlight:SetupInFlight()
	---------------------------------
		SlashCmdList.INFLIGHT = function()
			if LoadInFlight() then
				self:ShowOptions()
			end
		end
		SLASH_INFLIGHT1 = "/inflight"

		local panel = CreateFrame("Frame")
		panel.name = "InFlight"
		panel:SetScript("OnShow", function(this)
			if LoadInFlight() and InFlight.SetLayout then
				InFlight:SetLayout(this)
			end
		end)
		panel:Hide()
		InterfaceOptions_AddCategory(panel)
		InFlight.SetupInFlight = nil
	end
end
