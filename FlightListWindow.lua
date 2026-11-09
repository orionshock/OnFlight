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
local favoriteAtlas = "PetJournal-FavoritesIcon"
local otherLocationsIcon = 132172 -- Original Special-group icon.

-- Temporary presentation grouping only. Never used to identify a destination.
local function GetDisplayZone(name, nodeID)
    -- These verified Moonglade nodes have the zone name but no comma suffix.
    if nodeID == 49 or nodeID == 69 then return name end
    local suffix = name:match("^[^,]+,%s*([^,]*)")
    local zone = suffix and suffix:match("^%s*(.-)%s*$")
    return zone and zone ~= "" and zone or L["Other Locations"]
end

local function ClearHover()
    if hoveredButton and addonCore:GetTaxiSession() then TaxiNodeOnButtonLeave(hoveredButton) end
    if hoveredRow then hoveredRow:SetID(0) end
    hoveredButton = nil
    hoveredRow = nil
    GameTooltip:Hide()
    for slot = 1, NUM_TAXI_BUTTONS do
        _G["TaxiButton" .. slot]:UnlockHighlight()
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
    if not zone or not session or not window:IsShown() then return end
    for id, node in pairs(session.nodes) do
        if GetDisplayZone(node.name, id) == zone then
            local button = _G["TaxiButton" .. session.idToSlot[id]]
            if button then button:LockHighlight() end
        end
    end
end

local function RowOnEnter(self)
    ClearHover()
    local session = addonCore:GetTaxiSession()
    if not session then return end
    if self.zone then
        HighlightZone(self.zone)
        return
    end
    local slot = session.idToSlot[self.nodeID]
    local button = slot and _G["TaxiButton" .. slot]
    if not button then return end
    hoveredButton = button
    -- Let Blizzard draw the map route, then own the tooltip on the visible row.
    -- DISTANT map buttons can be hidden, so they cannot own our row's tooltip.
    TaxiNodeOnButtonEnter(button)
    button:LockHighlight()
    hoveredRow = self
    self:SetID(slot) -- Temporary handle for the existing duration-tooltip hook only.
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(session.nodes[self.nodeID].name, 1, 1, 1, true)
    local nodeType = TaxiNodeGetType(slot)
    if nodeType == "REACHABLE" then
        GameTooltip_AddMoneyLine(GameTooltip, TaxiNodeCost(slot))
    elseif nodeType == "CURRENT" then
        GameTooltip:AddLine(TAXINODEYOUAREHERE, 1, 1, 1, true)
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
    if not session then return end
    if self.zone then
        selectedZone = self.zone
        ClearSearch()
        module:Refresh(true)
        return
    end
    local id = self.nodeID
    local slot = session.idToSlot[id]
    if not slot then return end
    local nodeType = TaxiNodeGetType(slot)
    if nodeType ~= "REACHABLE" and nodeType ~= "CURRENT" then return end
    if IsShiftKeyDown() then
        local favorites = addonCore.db.profile.favorites
        favorites[id] = not favorites[id] or nil
        module:Refresh(false)
    elseif nodeType == "REACHABLE" then
        -- The core's existing pre-call hook captures IDs and starts tracking.
        TakeTaxiNode(slot)
    end
end

local function GetRow(index)
    if rows[index] then return rows[index] end
    local row = CreateFrame("Button", nil, window.content)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetMotionScriptsWhileDisabled(true)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-Line-Bounce")
    background:SetAllPoints()
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", 6, -3)
    row.favorite = row:CreateTexture(nil, "OVERLAY")
    row.favorite:SetAtlas(favoriteAtlas)
    row.favorite:SetSize(16, 16)
    row.favorite:SetPoint("TOPRIGHT", -6, -3)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("TOPLEFT", 28, -3)
    row.label:SetPoint("TOPRIGHT", -28, -3)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.detail:SetPoint("BOTTOMLEFT", 28, 4)
    row.detail:SetPoint("BOTTOMRIGHT", -6, 4)
    row.detail:SetJustifyH("LEFT")
    row.detail:SetWordWrap(false)
    row.nodeNumber = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.nodeNumber:SetPoint("BOTTOMRIGHT", -6, 4)
    row.nodeNumber:SetJustifyH("RIGHT")
    row:SetScript("OnClick", RowOnClick)
    row:SetScript("OnEnter", RowOnEnter)
    row:SetScript("OnLeave", RowOnLeave)
    rows[index] = row
    return row
end

local function GetDurationText(sourceID, destinationID)
    local duration = addonCore:GetFlightDuration(sourceID, destinationID)
    if duration then return SecondsToTime(duration) end
    local estimate = OnFlight_GetEstimatedTime(destinationID)
    return estimate and "~" .. SecondsToTime(estimate) or L["Unknown"]
end

function module:Refresh(resetScroll, focusCurrentZone)
    local session = addonCore:GetTaxiSession()
    if not session then self:TAXIMAP_CLOSED() return end
    ClearHover()
    local query = window.search:GetText():lower()
    local favorites = addonCore.db.profile.favorites
    local destinations, zones, zoneNames = {}, {}, {}
    local total, unknown = 0, 0
    for slot = 1, NumTaxiNodes() do
        local id = session.slotToID[slot]
        local node = id and session.nodes[id]
        local nodeType = TaxiNodeGetType(slot)
        if node and nodeType ~= "NONE" then
            local zone = GetDisplayZone(node.name, id)
            if not zones[zone] then
                zones[zone] = { count = 0 }
            end
            local group = zones[zone]
            group.count = group.count + 1
            local nameMatches = node.name:lower():find(query, 1, true)
            group.matches = group.matches or nameMatches or zone:lower():find(query, 1, true)
            if nodeType == "CURRENT" then group.current = true end
            if nodeType == "DISTANT" then unknown = unknown + 1 end
            total = total + 1
            if nameMatches and ((selectedTab == "favorites" and favorites[id])
                or (selectedTab == "zones" and selectedZone == zone)) then
                destinations[#destinations + 1] = { id = id, name = node.name, type = nodeType }
            end
        end
    end
    for zone, group in pairs(zones) do
        if group.matches then zoneNames[#zoneNames + 1] = zone end
    end
    table.sort(zoneNames)
    -- A new map/session may no longer contain the zone that was being viewed.
    if selectedZone and not zones[selectedZone] then selectedZone = nil end
    window.back:SetShown(selectedTab == "zones" and selectedZone ~= nil)
    window.header:ClearAllPoints()
    if window.back:IsShown() then
        window.header:SetPoint("LEFT", window.back, "RIGHT", 8, 0)
    else
        window.header:SetPoint("LEFT", window, "TOPLEFT", 74, -46)
    end
    window.header:SetPoint("RIGHT", window.search, "LEFT", -10, 0)
    window.header:SetText(selectedTab == "favorites" and L["Favorite Destinations"] or selectedZone or L["By Zone"])
    for key, tab in pairs(window.tabs) do tab:SetChecked(key == selectedTab) end

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
            row.zone = zone
            row:SetEnabled(true)
            if group.current then
                row.icon:SetTexture(currentIcon)
                row.icon:SetTexCoord(0, 1, 0, 1)
                if focusCurrentZone then
                    focusIndex = index
                    row:LockHighlight()
                end
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
            row.detail:SetFormattedText("%d %s", group.count, L["destinations"])
        else
            local node = destinations[index]
            row.nodeID = node.id
            if addonCore.db.profile.showGossipConfig then
                row.nodeNumber:SetText(tostring(node.id))
                row.nodeNumber:Show()
                row.detail:SetPoint("BOTTOMRIGHT", -row.nodeNumber:GetStringWidth() - 14, 4)
            end
            row:SetEnabled(node.type == "REACHABLE" or node.type == "CURRENT")
            local available = node.type == "REACHABLE" or node.type == "CURRENT"
            row.icon:SetTexture(node.type == "CURRENT" and currentIcon or node.type == "REACHABLE" and reachableIcon or unavailableIcon)
            row.icon:SetTexCoord(0, 1, 0, 1)
            row.icon:SetDesaturated(not available)
            local tint = available and 1 or 0.5
            row.icon:SetVertexColor(tint, tint, tint)
            row.favorite:SetShown(favorites[node.id] == true)
            row.label:SetText(node.name)
            row.label:SetTextColor(tint, tint, tint)
            if node.type == "REACHABLE" then
                row.detail:SetText(L["Duration:"] .. " " .. GetDurationText(session.sourceID, node.id))
            else
                row.detail:SetText(node.type == "CURRENT" and TAXINODEYOUAREHERE or L["Unavailable"])
            end
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
        window.empty:SetText(selectedTab == "favorites" and L["No favorite destinations in this taxi session.\nShift-click an available destination in By Zone to add it."] or L["No destinations in this taxi session."])
    end
    window.footer:SetFormattedText(L["Total: %d -- Unknown: %d"], total, unknown)
    local offset = resetScroll and 0 or window.scroll:GetVerticalScroll()
    if focusIndex then
        offset = math.max(0, (focusIndex - 1) * ROW_HEIGHT - (window.scroll:GetHeight() - ROW_HEIGHT) / 2)
    end
    window.content:SetHeight(math.max(1, count * ROW_HEIGHT))
    -- Update the scroll range before positioning after a short Favorites list.
    window.scroll:UpdateScrollChildRect()
    window.scroll:SetVerticalScroll(math.min(offset, math.max(0, count * ROW_HEIGHT - window.scroll:GetHeight())))
    window.focusedZone = focusIndex and zoneNames[focusIndex]
    HighlightZone(selectedTab == "zones" and (selectedZone or window.focusedZone))
end

local function CreateWindow()
    window = CreateFrame("Frame", "OnFlightDestinationWindow", UIParent, "PortraitFrameTemplate")
    window:Hide()
    window:SetWidth(420)
    window:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", 10, 0)
    window:SetPoint("BOTTOMLEFT", TaxiFrame, "BOTTOMRIGHT", 10, 0)
    window:SetFrameStrata("HIGH")
    window:EnableMouse(true)
    window:SetClampedToScreen(true)
    window:SetTitle(L["Flight Destinations"])
    window:SetPortraitToAsset(132172)
    window:SetBorder("PortraitFrameTemplate")
    -- CharacterFrame artwork; no CharacterFrame mixins or global registrations.
    local background = window:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-General-BG")
    background:SetPoint("TOPLEFT", 2, -22)
    background:SetPoint("BOTTOMRIGHT", -2, 2)
    window.CloseButton:SetScript("OnClick", function() window:Hide() end)
    window:SetScript("OnHide", function()
        ClearHover()
        window.search:ClearFocus()
        for _, row in ipairs(rows) do
            row.nodeID, row.zone = nil, nil
            row:Hide()
        end
    end)
    window.back = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.back:SetSize(85, 22)
    window.back:SetPoint("TOPLEFT", 74, -35)
    window.back:SetText("< " .. L["Back"])
    window.back:SetScript("OnClick", function()
        selectedZone = nil
        ClearSearch()
        module:Refresh(true)
    end)
    window.header = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    window.header:SetJustifyH("LEFT")
    window.header:SetWordWrap(false)
    window.search = CreateFrame("EditBox", nil, window, "SearchBoxTemplate")
    window.search:SetSize(115, 20)
    window.search:SetPoint("RIGHT", window, "TOPRIGHT", -18, -46)
    -- Keep the native magnifier, instructions, clear button, and focus scripts.
    window.search:HookScript("OnTextChanged", function(self)
        if not self.clearing and window:IsShown() then module:Refresh(true) end
    end)
    window.scroll = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
    window.scroll:SetPoint("TOPLEFT", 16, -68)
    window.scroll:SetPoint("BOTTOMRIGHT", -35, 48)
    window.scroll:EnableMouseWheel(true)
    window.scroll:SetPanExtent(ROW_HEIGHT)
    window.content = CreateFrame("Frame", nil, window.scroll)
    window.content:SetSize(window.scroll:GetWidth(), 1)
    window.scroll:SetScrollChild(window.content)
    window.scroll:HookScript("OnSizeChanged", function(self, width, height)
        window.content:SetWidth(width)
        self:SetVerticalScroll(math.min(self:GetVerticalScroll(), math.max(0, window.content:GetHeight() - height)))
    end)
    window.empty = window.scroll:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.empty:SetPoint("TOPLEFT", 12, -20)
    window.empty:SetPoint("TOPRIGHT", -12, -20)
    window.empty:SetJustifyH("CENTER")
    window.footer = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    window.footer:SetPoint("BOTTOM", 0, 28)
    local hint = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", 0, 12)
    hint:SetText(L["Shift-click a destination to toggle favorites."])
    window.tabs = {}
    for index, data in ipairs({ { "favorites", L["Favorites"], 134411 }, { "zones", L["By Zone"], 132172 } }) do
        local tab = CreateFrame("Frame", nil, window, "LargeSideTabButtonTemplate")
        tab:EnableMouse(true)
        tab:SetPoint("TOPLEFT", window, "TOPRIGHT", 0, -30 - (index - 1) * (tab:GetHeight() + 2))
        tab.Icon:SetTexture(data[3])
        tab:SetFillToInterior(true)
        tab.tooltipText = data[2]
        local key = data[1]
        tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
            if button == "LeftButton" and upInside then
                selectedTab, selectedZone = key, nil
                ClearSearch()
                module:Refresh(true, key == "zones")
            end
        end)
        window.tabs[key] = tab
    end
end

function module:Open()
    if not addonCore:GetTaxiSession() then return end
    if not window then CreateWindow() end
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
    selectedZone = nil
    if window then window:Hide() end
end

function module:OnEnable()
    self:RegisterMessage("OnFlight_TaxiMapReady", "TAXIMAP_OPENED")
    self:RegisterMessage("OnFlight_DiagnosticsChanged", function()
        if window and window:IsShown() then self:Refresh(false) end
    end)
    self:RegisterEvent("TAXIMAP_CLOSED")
    if addonCore:GetTaxiSession() then self:Open() end
end

function module:OnDisable()
    self:UnregisterAllMessages()
    self:UnregisterAllEvents()
    self:TAXIMAP_CLOSED()
end

local toggle = CreateFrame("Button", "OnFlight_TaxiFrameToggleButton", TaxiFrame)
toggle:SetSize(32, 32)
toggle:SetPoint("CENTER", TaxiFrame, "TOPRIGHT", -60, -45)
toggle:SetFrameLevel(TaxiFrame:GetFrameLevel() + 5)
toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
local icon = toggle:CreateTexture(nil, "BACKGROUND")
icon:SetTexture(132172)
icon:SetSize(20, 20)
icon:SetPoint("CENTER")
local border = toggle:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")
toggle:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:AddLine(L["Left Click to Toggle Flight Destinations View"], 1, 1, 1)
    GameTooltip:AddLine(L["Right Click to Toggle OnFlight Settings"], 1, 1, 1)
    GameTooltip:Show()
end)
toggle:SetScript("OnLeave", GameTooltip_Hide)
toggle:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
        if not module:IsEnabled() then return end
        if window and window:IsShown() then window:Hide() else module:Open() end
    else
        if window then window:Hide() end
        addonCore:ToggleSettings()
    end
end)
