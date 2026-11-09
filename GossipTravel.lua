-- Forever NPC-dialogue travel. The flight engine and editor use these existing methods.
--luacheck: no max line length
--luacheck: globals LibStub C_GossipInfo GossipOptionButtonMixin GameTooltip hooksecurefunc
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Custom gossip endpoints never resolve by name to a taxi node.
function addonCore:GetGossipEndpoint(optionID, value)
    if type(value) == "number" then return value, self:GetTaxiNodeName(value) end
    if type(value) ~= "string" then return end
    local prefix = tostring(optionID) .. ":"
    local label = value:sub(1, #prefix) == prefix and value:sub(#prefix + 1) or value
    label = label:match("^%s*(.-)%s*$")
    if label ~= "" then return prefix .. label, label end
end

function addonCore:StartGossipFlight(optionID)
    local endpoints = addonCore.db.global.gossipTriggered[optionID]
    if not endpoints then return end
    local source, sourceName = self:GetGossipEndpoint(optionID, endpoints[1])
    local destination, destinationName = self:GetGossipEndpoint(optionID, endpoints[2])
    if not sourceName or not destinationName then
        self:Print(L["Configure both gossip-flight endpoints in settings: %s"]:format(optionID))
        return
    end
    self:StartAFlight(source, destination)
end

do
    hooksecurefunc(
        C_GossipInfo,
        "SelectOption",
        function(option, ...)
            if addonCore.db.global.gossipTriggered[option] then
                addonCore:StartGossipFlight(option)
            end
        end
    )

    local original_C_GossipInfo_SelectOptionByIndex = C_GossipInfo.SelectOptionByIndex

    ---@diagnostic disable-next-line: duplicate-set-field
    function C_GossipInfo.SelectOptionByIndex(...)
        local selectedIndex = tonumber(...)
        local gossipOptions = C_GossipInfo.GetOptions()
        for _, optionData in ipairs(gossipOptions) do
            if optionData.orderIndex == selectedIndex then
                local selectedGossipID = optionData.gossipOptionID
                if addonCore.db.global.gossipTriggered[selectedGossipID] then
                    addonCore:StartGossipFlight(selectedGossipID)
                    break
                end
            end
        end
        original_C_GossipInfo_SelectOptionByIndex(...)
    end

    hooksecurefunc(
        GossipOptionButtonMixin,
        "Setup",
        function(self, optionInfo)
            self.OnFlightGossipID = optionInfo.gossipOptionID
            if self.OnFlightTooltipHooked then return end
            self.OnFlightTooltipHooked = true
            self:HookScript("OnEnter", function(frame)
                if addonCore.db and (addonCore.db.profile.showGossipConfig or addonCore.db.profile.gossipdebug) then
                    if GameTooltip:GetOwner() ~= frame then
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                    end
                    GameTooltip:AddLine(L["gossipOptionID: %s"]:format(frame.OnFlightGossipID or "??"))
                    GameTooltip:Show()
                end
            end)
            self:HookScript("OnLeave", function(frame)
                if GameTooltip:GetOwner() == frame then
                    GameTooltip:Hide()
                end
            end)
        end
    )
end
