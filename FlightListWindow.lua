local addonName, addonCore = ...
local module = addonCore:NewModule("NativeFlightListWindow", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local window, hoveredButton, hoveredRow
local rows = {}
local selectedTab, selectedZone = "favorites", nil
local ROW_HEIGHT = 40
local favoriteIcon = CreateSimpleTextureMarkup(134411, 16, 16)
local currentIcon = CreateSimpleTextureMarkup(137033, 16, 16)
local unknownIcon = CreateSimpleTextureMarkup(134400, 16, 16)
local specialIcon = CreateSimpleTextureMarkup(132172, 16, 16)

-- Temporary presentation grouping only. Never used to identify a destination.
local function GetDisplayZone(name)
    local suffix = name:match("^[^,]+,%s*([^,]*)")
    local zone = suffix and suffix:match("^%s*(.-)%s*$")
    return zone and zone ~= "" and zone or L["Special"]
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

local function RowOnEnter(self)
    ClearHover()
    local session = addonCore:GetTaxiSession()
    if not session then return end
    if self.zone then
        for id, node in pairs(session.nodes) do
            if GetDisplayZone(node.name) == self.zone then
                local button = _G["TaxiButton" .. session.idToSlot[id]]
                if button then button:LockHighlight() end
            end
        end
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

local function RowOnClick(self)
    local session = addonCore:GetTaxiSession()
    if not session then return end
    if self.zone then
        selectedZone = self.zone
        module:Refresh(true)
        return
    end
    local id = self.nodeID
    local slot = session.idToSlot[id]
    if not slot or TaxiNodeGetType(slot) ~= "REACHABLE" then return end
    if IsShiftKeyDown() then
        local favorites = addonCore.db.profile.favorites
        favorites[id] = not favorites[id] or nil
        module:Refresh(false)
    else
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
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("TOPLEFT", 6, -3)
    row.label:SetPoint("TOPRIGHT", -6, -3)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.detail:SetPoint("BOTTOMLEFT", 6, 4)
    row.detail:SetPoint("BOTTOMRIGHT", -6, 4)
    row.detail:SetJustifyH("LEFT")
    row.detail:SetWordWrap(false)
    row:SetScript("OnClick", RowOnClick)
    row:SetScript("OnEnter", RowOnEnter)
    row:SetScript("OnLeave", ClearHover)
    rows[index] = row
    return row
end

local function GetDurationText(sourceID, destinationID)
    local duration = addonCore:GetFlightDuration(sourceID, destinationID)
    if duration then return SecondsToTime(duration) end
    local estimate = OnFlight_GetEstimatedTime(destinationID)
    return estimate and "~" .. SecondsToTime(estimate) or L["Unknown"]
end

function module:Refresh(resetScroll)
    local session = addonCore:GetTaxiSession()
    if not session then self:TAXIMAP_CLOSED() return end
    ClearHover()
    local favorites = addonCore.db.profile.favorites
    local destinations, zones, zoneNames = {}, {}, {}
    local total, unknown = 0, 0
    for slot = 1, NumTaxiNodes() do
        local id = session.slotToID[slot]
        local node = id and session.nodes[id]
        local nodeType = TaxiNodeGetType(slot)
        if node and nodeType ~= "NONE" then
            local zone = GetDisplayZone(node.name)
            if not zones[zone] then
                zones[zone] = { count = 0 }
                zoneNames[#zoneNames + 1] = zone
            end
            local group = zones[zone]
            group.count = group.count + 1
            if nodeType == "CURRENT" then group.current = true end
            if nodeType == "DISTANT" then group.unknown = true; unknown = unknown + 1 end
            total = total + 1
            if (selectedTab == "favorites" and favorites[id])
                or (selectedTab == "zones" and selectedZone == zone) then
                destinations[#destinations + 1] = { id = id, name = node.name, type = nodeType }
            end
        end
    end
    table.sort(zoneNames)
    -- A new map/session may no longer contain the zone that was being viewed.
    if selectedZone and not zones[selectedZone] then selectedZone = nil end
    window.back:SetShown(selectedTab == "zones" and selectedZone ~= nil)
    window.header:ClearAllPoints()
    if window.back:IsShown() then
        window.header:SetPoint("LEFT", window.back, "RIGHT", 8, 0)
    else
        window.header:SetPoint("LEFT", window, "TOPLEFT", 16, -46)
    end
    window.header:SetPoint("RIGHT", window, "TOPRIGHT", -18, -46)
    window.header:SetText(selectedTab == "favorites" and L["Favorite Destinations"] or selectedZone or L["By Zone"])
    for key, tab in pairs(window.tabs) do tab:SetChecked(key == selectedTab) end

    local zoneList = selectedTab == "zones" and not selectedZone
    local count = zoneList and #zoneNames or #destinations
    for index = 1, count do
        local row = GetRow(index)
        row.nodeID, row.zone = nil, nil
        if zoneList then
            local zone = zoneNames[index]
            local group = zones[zone]
            local icon = group.current and currentIcon or group.unknown and unknownIcon
                or zone == L["Special"] and specialIcon or ""
            row.zone = zone
            row:SetEnabled(true)
            row.label:SetText(icon .. " " .. zone)
            row.label:SetTextColor(1, 1, 1)
            row.detail:SetFormattedText("%d %s", group.count, L["destinations"])
        else
            local node = destinations[index]
            row.nodeID = node.id
            row:SetEnabled(node.type == "REACHABLE")
            local icon = node.type == "CURRENT" and currentIcon or node.type == "DISTANT" and unknownIcon or ""
            row.label:SetText(icon .. (favorites[node.id] and favoriteIcon .. " " or "") .. node.name)
            local shade = node.type == "REACHABLE" or node.type == "CURRENT"
            row.label:SetTextColor(shade and 1 or 0.5, shade and 1 or 0.5, shade and 1 or 0.5)
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
    window.empty:SetText(selectedTab == "favorites" and L["No favorite destinations in this taxi session.\nShift-click an available destination in By Zone to add it."] or L["No destinations in this taxi session."])
    window.footer:SetFormattedText(L["Total: %d -- Unknown: %d"], total, unknown)
    local offset = resetScroll and 0 or window.scroll:GetVerticalScroll()
    window.content:SetHeight(math.max(1, count * ROW_HEIGHT))
    window.scroll:SetVerticalScroll(math.min(offset, math.max(0, count * ROW_HEIGHT - window.scroll:GetHeight())))
end

local function CreateWindow()
    window = CreateFrame("Frame", "OnFlightDestinationWindow", UIParent, "PortraitFrameTemplate")
    window:Hide()
    window:SetSize(420, 450)
    window:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", 10, -5)
    window:SetFrameStrata("HIGH")
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
        for _, row in ipairs(rows) do
            row.nodeID, row.zone = nil, nil
            row:Hide()
        end
    end)
    window.back = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.back:SetSize(85, 22)
    window.back:SetPoint("TOPLEFT", 14, -35)
    window.back:SetText("< " .. L["Back"])
    window.back:SetScript("OnClick", function() selectedZone = nil; module:Refresh(true) end)
    window.header = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    window.header:SetJustifyH("LEFT")
    window.header:SetWordWrap(false)
    window.scroll = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
    window.scroll:SetPoint("TOPLEFT", 16, -68)
    window.scroll:SetPoint("BOTTOMRIGHT", -35, 48)
    window.scroll:EnableMouseWheel(true)
    window.scroll:SetPanExtent(ROW_HEIGHT)
    window.content = CreateFrame("Frame", nil, window.scroll)
    window.content:SetSize(369, 1)
    window.scroll:SetScrollChild(window.content)
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
                module:Refresh(true)
            end
        end)
        window.tabs[key] = tab
    end
end

function module:Open()
    if not addonCore:GetTaxiSession() then return end
    if not window then CreateWindow() end
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
        local settings = LibStub("AceConfigDialog-3.0")
        if settings.OpenFrames[addonName] then
            settings:Close(addonName)
            if module:IsEnabled() then module:Open() end
        else
            if window then window:Hide() end
            settings:Open(addonName)
        end
    end
end)
