local addonName, addonCore = ...
local module = addonCore:NewModule("NativeFlightListWindow", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local window, hoveredButton, hoveredRow
local rows = {}
local selectedTab, selectedZone = "favorites", nil
local ROW_HEIGHT = 40
-- Shared taxi art from TaxiFrame.lua; the green location marker is unchanged.
local currentIcon = 137033
local reachableIcon = "Interface\\TaxiFrame\\UI-Taxi-Icon-White"
local unavailableIcon = "Interface\\TaxiFrame\\UI-Taxi-Icon-Nub"
local zoneAtlas = "poi-traveldirections-arrow"
local otherLocationsIcon = 132172 -- Original Special-group icon.

-- Temporary presentation grouping only. Never used to identify a destination.
local function GetDisplayZone(name, nodeID)
    -- These verified Moonglade nodes have the zone name but no comma suffix.
    if nodeID == 49 or nodeID == 69 then
        return name
    end
    local suffix = name:match("^[^,]+,%s*([^,]*)")
    local zone = suffix and suffix:match("^%s*(.-)%s*$")
    return zone and zone ~= "" and zone or L["Other Locations"]
end

local function ClearHover()
    if hoveredButton and addonCore:GetTaxiSession() then
        TaxiNodeOnButtonLeave(hoveredButton)
    end
    if hoveredRow then
        hoveredRow:SetID(0)
    end
    hoveredButton = nil
    hoveredRow = nil
    GameTooltip:Hide()
    for slot = 1, NUM_TAXI_BUTTONS do
        local button = _G["TaxiButton" .. slot]
        button:UnlockHighlight()
        if button.OnFlightUnknownClick then
            button:GetNormalTexture():SetVertexColor(0.85, 0.1, 0.1)
        end
    end
end

local function UpdateUnknownButtons()
    local session = addonCore:GetTaxiSession()
    local show = window and window:IsShown() and session and
        addonCore.db.profile.showUnknownFlightPoints
    local count = NumTaxiNodes()
    for slot = 1, NUM_TAXI_BUTTONS do
        local button = _G["TaxiButton" .. slot]
        local nodeType = slot <= count and TaxiNodeGetType(slot) or "NONE"
        local id = session and session.slotToID[slot]
        local node = id and session.nodes[id]
        if show and nodeType == "DISTANT" and node and not node.name:match("^zz") then
            if not button.OnFlightUnknownClick then
                -- Keep native hover/highlighting, but remove only the taxi-selection action.
                button.OnFlightUnknownClick = button:GetScript("OnClick")
                button:SetScript("OnClick", nil)
            end
            button:SetNormalTexture(reachableIcon)
            button:GetNormalTexture():SetVertexColor(0.85, 0.1, 0.1)
            local highlight = button:GetHighlightTexture()
            highlight:SetVertexColor(1, 0.2, 0.2)
            highlight:SetAlpha(1)
            button:Show()
        elseif button.OnFlightUnknownClick then
            button:SetScript("OnClick", button.OnFlightUnknownClick)
            button.OnFlightUnknownClick = nil
            button:UnlockHighlight()
            button:GetNormalTexture():SetVertexColor(1, 1, 1)
            button:GetHighlightTexture():SetVertexColor(1, 1, 1)
            if TaxiButtonTypes[nodeType] then
                button:SetNormalTexture(TaxiButtonTypes[nodeType].file)
                button:GetHighlightTexture():SetAlpha(TaxiButtonTypes[nodeType].highlightBrightness)
            end
            if nodeType == "DISTANT" or nodeType == "NONE" then
                button:Hide()
            end
        end
    end
end

local function GetDurationText(sourceID, destinationID)
    local duration = addonCore:GetFlightDuration(sourceID, destinationID)
    if duration then
        return SecondsToTime(duration)
    end
    local estimate = OnFlight_GetEstimatedTime(destinationID)
    return estimate and "~" .. SecondsToTime(estimate) or L["Unknown"]
end

local function AddUnknownFlightInfo(slot)
    local session = addonCore:GetTaxiSession()
    if not session then return end
    local id = session.slotToID[slot]
    GameTooltip:AddLine(L["Unavailable"], 1, 1, 1, true)
    GameTooltip:AddDoubleLine(L["Duration:"], GetDurationText(session.sourceID, id))
    if addonCore.db.profile.showGossipConfig then
        GameTooltip:AddLine(tostring(id), 0.6, 0.6, 0.6)
    end
end

local function ClearSearch()
    window.search.clearing = true
    window.search:SetText("")
    window.search:ClearFocus()
    window.search.clearing = nil
end

local function HighlightZone(zone)
    local session = addonCore:GetTaxiSession()
    if not zone or not session or not window:IsShown() then
        return
    end
    for id, node in pairs(session.nodes) do
        if GetDisplayZone(node.name, id) == zone then
            local slot = session.idToSlot[id]
            local nodeType = TaxiNodeGetType(slot)
            local button = _G["TaxiButton" .. slot]
            if nodeType == "DISTANT" then
                if button and button.OnFlightUnknownClick and button:IsShown() then
                    button:GetNormalTexture():SetVertexColor(1, 0.35, 0.35)
                    button:LockHighlight()
                end
            elseif nodeType == "CURRENT" or nodeType == "REACHABLE" then
                if button then
                    button:LockHighlight()
                end
            end
        end
    end
end

-- Blizzard hides DISTANT buttons during route updates. Restore only the requested points.
hooksecurefunc("DrawOneHopLines", UpdateUnknownButtons)
hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
    if addonCore:GetTaxiSession() then
        UpdateUnknownButtons()
        if TaxiNodeGetType(button:GetID()) == "DISTANT" then
            if button.OnFlightUnknownClick then
                button:GetNormalTexture():SetVertexColor(1, 0.35, 0.35)
            end
            AddUnknownFlightInfo(button:GetID())
            GameTooltip:Show()
        end
    end
end)

-- Both native taxi buttons and browser rows use this leave handler.
hooksecurefunc("TaxiNodeOnButtonLeave", function(button)
    if TaxiFrame:IsShown() and addonCore:GetTaxiSession() then
        button:UnlockHighlight()
        DrawOneHopLines()
        if window and window:IsShown() then
            HighlightZone(selectedTab == "zones" and (selectedZone or window.focusedZone))
        end
    end
end)

local function RowOnEnter(self)
    ClearHover()
    local session = addonCore:GetTaxiSession()
    if not session then
        return
    end
    if self.zone then
        HighlightZone(self.zone)
        return
    end
    local slot = session.idToSlot[self.nodeID]
    if not slot then return end
    local nodeType = TaxiNodeGetType(slot)
    local button = _G["TaxiButton" .. slot]
    if not button then
        return
    end
    hoveredButton = button
    -- Let Blizzard draw the map route, then own the tooltip on the visible row.
    TaxiNodeOnButtonEnter(button)
    button:LockHighlight()
    hoveredRow = self
    self:SetID(slot) -- Temporary handle for the existing duration-tooltip hook only.
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(session.nodes[self.nodeID].name, 1, 1, 1, true)
    if nodeType == "REACHABLE" then
        GameTooltip_AddMoneyLine(GameTooltip, TaxiNodeCost(slot))
    elseif nodeType == "CURRENT" then
        GameTooltip:AddLine(TAXINODEYOUAREHERE, 1, 1, 1, true)
    elseif nodeType == "DISTANT" then
        AddUnknownFlightInfo(slot)
    end
    OnFlight_TaxiFrame_TooltipHook(self)
    GameTooltip:Show()
end

local function RowOnLeave()
    ClearHover()
    HighlightZone(selectedTab == "zones" and (selectedZone or window.focusedZone))
end

local function RowOnClick(self)
    local session = addonCore:GetTaxiSession()
    if not session then
        return
    end
    if self.zone then
        selectedZone = self.zone
        ClearSearch()
        module:Refresh(true)
        return
    end
    local id = self.nodeID
    local slot = session.idToSlot[id]
    if not slot then
        return
    end
    local nodeType = TaxiNodeGetType(slot)
    if nodeType ~= "REACHABLE" and nodeType ~= "CURRENT" then
        return
    end
    if IsShiftKeyDown() then
        local favorites = addonCore.db.profile.favorites
        -- False overrides AceDB's default favorites across reloads and profile changes.
        favorites[id] = not favorites[id]
        module:Refresh(false)
    elseif nodeType == "REACHABLE" then
        -- The core's existing pre-call hook captures IDs and starts tracking.
        TakeTaxiNode(slot)
    end
end

local function GetRow(index)
    if rows[index] then
        return rows[index]
    end
    local row = addonCore.CreateDestinationRow(window, index, ROW_HEIGHT)
    row:SetScript("OnClick", RowOnClick)
    row:SetScript("OnEnter", RowOnEnter)
    row:SetScript("OnLeave", RowOnLeave)
    rows[index] = row
    return row
end

local function GetVisibleRows(session, profile, query)
    local destinations, zones, zoneNames = {}, {}, {}
    for slot = 1, NumTaxiNodes() do
        local id = session.slotToID[slot]
        local node = id and session.nodes[id]
        local nodeType = TaxiNodeGetType(slot)
        if node and (nodeType == "CURRENT" or nodeType == "REACHABLE" or
            (profile.showUnknownFlightPoints and nodeType == "DISTANT" and not node.name:match("^zz"))) then
            local zone = GetDisplayZone(node.name, id)
            if not zones[zone] then
                zones[zone] = {
                    count = 0
                }
            end
            local group = zones[zone]
            group.count = group.count + 1
            local nameMatches = node.name:lower():find(query, 1, true)
            group.matches = group.matches or nameMatches or zone:lower():find(query, 1, true)
            if nodeType == "CURRENT" then
                group.current = true
            end
            if nameMatches and
                ((selectedTab == "favorites" and profile.favorites[id]) or (selectedTab == "zones" and selectedZone == zone)) then
                destinations[#destinations + 1] = {
                    id = id,
                    name = node.name,
                    type = nodeType
                }
            end
        end
    end
    for zone, group in pairs(zones) do
        if group.matches then
            zoneNames[#zoneNames + 1] = zone
        end
    end
    table.sort(zoneNames)
    return destinations, zones, zoneNames
end

local function SetZoneRow(row, zone, group)
    row.zone = zone
    row:SetEnabled(true)
    if group.current then
        row.icon:SetTexture(currentIcon)
        row.icon:SetTexCoord(0, 1, 0, 1)
    elseif zone == L["Other Locations"] then
        row.icon:SetTexture(otherLocationsIcon)
        row.icon:SetTexCoord(0, 1, 0, 1)
    else
        row.icon:SetAtlas(zoneAtlas)
    end
    row.icon:SetDesaturated(false)
    row.icon:SetVertexColor(1, 1, 1)
    row.favorite:Hide()
    row.label:SetText(zone)
    row.label:SetTextColor(1, 1, 1)
    row.detail:SetFormattedText(L["%d destinations"], group.count)
end

local function SetDestinationRow(row, node, session, profile)
    row.nodeID = node.id
    if profile.showGossipConfig then
        row.nodeNumber:SetText(tostring(node.id))
        row.nodeNumber:Show()
        row.detail:SetPoint("BOTTOMRIGHT", -row.nodeNumber:GetStringWidth() - 14, 4)
    end
    local available = node.type == "REACHABLE" or node.type == "CURRENT"
    row:SetEnabled(available)
    row.icon:SetTexture(node.type == "CURRENT" and currentIcon or node.type == "REACHABLE" and reachableIcon or
                            unavailableIcon)
    row.icon:SetTexCoord(0, 1, 0, 1)
    row.icon:SetDesaturated(not available)
    local tint = available and 1 or 0.5
    row.icon:SetVertexColor(tint, tint, tint)
    row.favorite:SetShown(profile.favorites[node.id] == true)
    row.label:SetText(node.name)
    row.label:SetTextColor(tint, tint, tint)
    if node.type == "REACHABLE" then
        local durationText = GetDurationText(session.sourceID, node.id)
        local slot = session.idToSlot[node.id]
        local cost = slot and TaxiNodeCost(slot)
        row.detail:SetText(cost and durationText .. " · " .. C_CurrencyInfo.GetCoinTextureString(cost) or durationText)
    else
        row.detail:SetText(node.type == "CURRENT" and TAXINODEYOUAREHERE or L["Unavailable"])
    end
end

function module:Refresh(resetScroll, focusCurrentZone)
    local session = addonCore:GetTaxiSession()
    if not session then
        self:TAXIMAP_CLOSED()
        return
    end
    ClearHover()
    UpdateUnknownButtons()
    local profile = addonCore.db.profile
    window.showUnknown:SetChecked(profile.showUnknownFlightPoints)
    local query = window.search:GetText():lower()
    local destinations, zones, zoneNames = GetVisibleRows(session, profile, query)
    -- A new map/session may no longer contain the zone that was being viewed.
    if selectedZone and not zones[selectedZone] then
        selectedZone = nil
    end
    window.back:SetShown(selectedTab == "zones" and selectedZone ~= nil)
    window.header:ClearAllPoints()
    if window.back:IsShown() then
        window.header:SetPoint("LEFT", window.back, "RIGHT", 8, 0)
    else
        window.header:SetPoint("LEFT", window, "TOPLEFT", 16, -46)
    end
    window.header:SetPoint("RIGHT", window.search, "LEFT", -10, 0)
    window.header:SetText(selectedTab == "favorites" and L["Favorite Destinations"] or selectedZone or L["By Zone"])
    for key, tab in pairs(window.tabs) do
        tab:SetChecked(key == selectedTab)
    end

    local zoneList = selectedTab == "zones" and not selectedZone
    local count = zoneList and #zoneNames or #destinations
    local focusIndex
    for index = 1, count do
        local row = GetRow(index)
        row:UnlockHighlight()
        row.nodeID, row.zone = nil, nil
        row.nodeNumber:Hide()
        row.detail:SetPoint("BOTTOMRIGHT", -6, 4)
        if zoneList then
            local zone = zoneNames[index]
            local group = zones[zone]
            SetZoneRow(row, zone, group)
            if group.current and focusCurrentZone then
                focusIndex = index
                row:LockHighlight()
            end
        else
            SetDestinationRow(row, destinations[index], session, profile)
        end
        row:Show()
    end
    for index = count + 1, #rows do
        rows[index].nodeID, rows[index].zone = nil, nil
        rows[index]:Hide()
    end
    window.empty:SetShown(count == 0)
    if query ~= "" then
        window.empty:SetText(zoneList and L["No zones match your search."] or L["No destinations match your search."])
    else
        window.empty:SetText(selectedTab == "favorites" and
                                 L["No favorite destinations in this taxi session.\nShift-click an available destination in By Zone to add it."] or
                                 L["No destinations in this taxi session."])
    end
    local offset = resetScroll and 0 or window.scroll:GetVerticalScroll()
    if focusIndex then
        offset = math.max(0, (focusIndex - 1) * ROW_HEIGHT - (window.scroll:GetHeight() - ROW_HEIGHT) / 2)
    end
    window.content:SetHeight(math.max(1, count * ROW_HEIGHT))
    -- Update the scroll range before positioning after a short Favorites list.
    window.scroll:UpdateScrollChildRect()
    window.scroll:SetVerticalScroll(math.min(offset, math.max(0, count * ROW_HEIGHT - window.scroll:GetHeight())))
    if resetScroll then
        window.focusedZone = nil
    end
    if focusIndex then
        window.focusedZone = zoneNames[focusIndex]
    end
    HighlightZone(selectedTab == "zones" and (selectedZone or window.focusedZone))
end

local function CreateWindow()
    window = addonCore:CreateDestinationFrame()
    window:SetScript("OnHide", function()
        ClearHover()
        UpdateUnknownButtons()
        window.search:ClearFocus()
        for _, row in ipairs(rows) do
            row.nodeID, row.zone = nil, nil
            row:Hide()
        end
    end)
    window.back:SetScript("OnClick", function()
        selectedZone = nil
        ClearSearch()
        module:Refresh(true)
    end)
    window.search:HookScript("OnTextChanged", function(self)
        if not self.clearing and window:IsShown() then
            module:Refresh(true)
        end
    end)
    window.scroll:SetPanExtent(ROW_HEIGHT)
    window.showUnknown:SetScript("OnClick", function(self)
        addonCore.db.profile.showUnknownFlightPoints = self:GetChecked()
        module:Refresh(false)
    end)
    for key, tab in pairs(window.tabs) do
        tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
            if button == "LeftButton" and upInside then
                selectedTab, selectedZone = key, nil
                ClearSearch()
                module:Refresh(true, key == "zones")
            end
        end)
    end
end

function module:Open()
    if not addonCore:GetTaxiSession() then
        return
    end
    if not window then
        CreateWindow()
    end
    selectedTab, selectedZone = "favorites", nil
    ClearSearch()
    window:Show()
    self:Refresh(true)
end

function module:TAXIMAP_OPENED()
    selectedZone = nil
    self:Open()
end

function module:TAXIMAP_CLOSED()
    UpdateUnknownButtons()
    selectedZone = nil
    if window then
        window:Hide()
    end
end

function module:OnEnable()
    addonCore.ExpandTaxiFrame()
    addonCore:RegisterCallback("OnFlight_TaxiMapReady", self.TAXIMAP_OPENED, self)
    addonCore:RegisterCallback("OnFlight_DiagnosticsChanged", function(owner)
        if window and window:IsShown() then
            owner:Refresh(false)
        end
    end, self)
    self:RegisterEvent("TAXIMAP_CLOSED")
end

local toggle = addonCore:CreateTaxiFrameToggle()
toggle:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine(L["Left Click to Toggle Flight Destinations View"], 1, 1, 1)
    GameTooltip:AddLine(L["Right Click to Toggle OnFlight Settings"], 1, 1, 1)
    GameTooltip:Show()
end)
toggle:SetScript("OnLeave", GameTooltip_Hide)
toggle:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
        if window and window:IsShown() then
            window:Hide()
        else
            module:Open()
        end
    else
        if window then
            window:Hide()
        end
        addonCore:ToggleSettings()
    end
end)
