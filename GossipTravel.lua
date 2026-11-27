-- Forever NPC-dialogue travel. The flight engine and editor use these existing methods.
-- luacheck: no max line length
-- luacheck: globals LibStub C_GossipInfo GossipOptionButtonMixin GameTooltip hooksecurefunc
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addonCore.MakeGossipEndpointKey(optionID, label)
    label = label:gsub("[:|]", "")
    if label ~= "" then
        return tostring(optionID) .. ":" .. label
    end
end

-- Custom gossip endpoints never resolve by name to a taxi node.
function addonCore:GetGossipEndpoint(optionID, value, isSource)
    if type(value) == "number" then
        local key = isSource and self.MakeGossipEndpointKey(optionID, tostring(value)) or value
        return key, self:GetTaxiNodeName(value)
    end
    if type(value) ~= "string" then
        return
    end
    local prefix = tostring(optionID) .. ":"
    -- The editor already trims stored labels. Preserve spaces exposed by sanitization.
    local label = value:sub(1, #prefix) == prefix and value:sub(#prefix + 1) or value:match("^%s*(.-)%s*$")
    local key = self.MakeGossipEndpointKey(optionID, label)
    if key then
        return key, label
    end
end

function addonCore:StartGossipFlight(optionID)
    local endpoints = addonCore.db.global.gossipTriggered[optionID]
    if not endpoints then
        return
    end
    local source, sourceName = self:GetGossipEndpoint(optionID, endpoints[1], true)
    local destination, destinationName = self:GetGossipEndpoint(optionID, endpoints[2])
    if not sourceName or not destinationName then
        print(self.OnFlightPrefixText, L["Configure both gossip-flight endpoints in settings: %s"]:format(optionID))
        return
    end
    local flight = self:StartAFlight(source, destination)
    if flight then
        flight.gossip = true
        if type(endpoints[1]) == "number" then
            flight.sourceName = sourceName
            flight.sourceNodeID = endpoints[1]
        end
    end
end

do
    hooksecurefunc(C_GossipInfo, "SelectOption", function(option, ...)
        if addonCore.db.global.gossipTriggered[option] then
            addonCore:StartGossipFlight(option)
        end
    end)

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

    hooksecurefunc(GossipOptionButtonMixin, "Setup", function(self, optionInfo)
        self.OnFlightGossipID = optionInfo.gossipOptionID
        if self.OnFlightTooltipHooked then
            return
        end
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
    end)
end
