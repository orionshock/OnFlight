local addonName, addonCore = ...
local module = addonCore:NewModule("NativeFlightListWindow", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local window, hoveredButton, hoveredRow
local rows = {}
local selectedTab, selectedZone = "favorites", nil
local ROW_HEIGHT = 40
local taxiWidth = TaxiFrame:GetWidth()
local taxiPanelWidth = GetUIPanelWidthUnscaled(TaxiFrame)
-- Reserve 430 pixels for the destination pane and its outer border.
local browserExtent = 430
local expandedWidth = taxiWidth + browserExtent
local expandedPanelWidth = taxiPanelWidth + browserExtent + C_Texture.GetAtlasInfo("common-sidetab").width

local taxiBorder = {
    TopLeftCorner = TaxiFrame.TopLeftCorner,
    TopRightCorner = TaxiFrame.TopRightCorner,
    BottomLeftCorner = TaxiFrame.BotLeftCorner,
    BottomRightCorner = TaxiFrame.BotRightCorner,
    TopEdge = TaxiFrame.TopBorder,
    BottomEdge = TaxiFrame.BottomBorder,
    LeftEdge = TaxiFrame.LeftBorder,
    RightEdge = TaxiFrame.RightBorder,
    Center = TaxiFrame.Bg,
}
local leftBorderLayer

local function StyleTaxiFrame()
    -- NineSlice's legacy lookup lets the modern border reuse TaxiFrame's existing regions.
    TaxiFrame.GetNineSlicePiece = function(_, piece)
        return taxiBorder[piece]
    end
    for piece, texture in pairs(taxiBorder) do
        if piece ~= "Center" then
            texture:SetDrawLayer("OVERLAY")
        end
    end
    NineSliceUtil.ApplyLayoutByName(TaxiFrame, "ButtonFrameTemplateNoPortrait")
    TaxiFrame.GetNineSlicePiece = nil
    TaxiFrame.TitleBg:Hide()

    -- The detailed map is a child frame, so its textures otherwise cover the left edge.
    if not leftBorderLayer then
        leftBorderLayer = CreateFrame("Frame", nil, TaxiFrame)
        leftBorderLayer:SetAllPoints(TaxiFrame)
        leftBorderLayer:EnableMouse(false)
        TaxiFrame.TopLeftCorner:SetParent(leftBorderLayer)
        TaxiFrame.BotLeftCorner:SetParent(leftBorderLayer)
        TaxiFrame.LeftBorder:SetParent(leftBorderLayer)
    end
    leftBorderLayer:SetFrameLevel(TaxiRouteMap:GetFrameLevel() + 2)
end
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
    local show = module:IsEnabled() and window and window:IsShown() and session and
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
hooksecurefunc("DrawOneHopLines", function()
    if module:IsEnabled() then UpdateUnknownButtons() end
end)
hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
    if module:IsEnabled() and addonCore:GetTaxiSession() then
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
    if module:IsEnabled() and TaxiFrame:IsShown() and addonCore:GetTaxiSession() then
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
    local favorites = profile.favorites
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
                ((selectedTab == "favorites" and favorites[id]) or (selectedTab == "zones" and selectedZone == zone)) then
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
            row.detail:SetFormattedText(L["%d destinations"], group.count)
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
            row.icon:SetTexture(node.type == "CURRENT" and currentIcon or node.type == "REACHABLE" and reachableIcon or
                                    unavailableIcon)
            row.icon:SetTexCoord(0, 1, 0, 1)
            row.icon:SetDesaturated(not available)
            local tint = available and 1 or 0.5
            row.icon:SetVertexColor(tint, tint, tint)
            row.favorite:SetShown(favorites[node.id] == true)
            row.label:SetText(node.name)
            row.label:SetTextColor(tint, tint, tint)
            if node.type == "REACHABLE" then
                row.detail:SetFormattedText(L["Duration: %s"], GetDurationText(session.sourceID, node.id))
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
    window = CreateFrame("Frame", "OnFlightDestinationWindow", TaxiFrame)
    window:Hide()
    window:SetPoint("TOPLEFT", TaxiFrame.InsetBg, "TOPRIGHT", 0, 24)
    window:SetPoint("BOTTOMRIGHT", TaxiFrame, "BOTTOMRIGHT", 0, 0)
    window:EnableMouse(true)
    -- The existing CharacterFrame artwork remains behind the destination list.
    local background = window:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-General-BG")
    background:SetPoint("TOPLEFT", 0, -24)
    background:SetPoint("BOTTOMRIGHT", -2, 2)
    window:SetScript("OnHide", function()
        ClearHover()
        UpdateUnknownButtons()
        window.search:ClearFocus()
        for _, row in ipairs(rows) do
            row.nodeID, row.zone = nil, nil
            row:Hide()
        end
    end)
    window.back = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.back:SetSize(85, 22)
    window.back:SetPoint("TOPLEFT", 16, -35)
    window.back:SetText(L["< Back"])
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
        if not self.clearing and window:IsShown() then
            module:Refresh(true)
        end
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
    window.showUnknown = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    window.showUnknown:SetSize(24, 24)
    window.showUnknown:SetPoint("BOTTOMLEFT", 16, 20)
    window.showUnknown.Text:SetText(L["Show Unknown Flight Points"])
    window.showUnknown:SetHitRectInsets(0, -window.showUnknown.Text:GetStringWidth(), 0, 0)
    window.showUnknown:SetScript("OnClick", function(self)
        addonCore.db.profile.showUnknownFlightPoints = self:GetChecked()
        module:Refresh(false)
    end)
    local hint = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", 0, 12)
    hint:SetText(L["Shift-click a destination to toggle favorites."])
    window.tabs = {}
    for index, data in ipairs({{"favorites", L["Favorites"], 134411}, {"zones", L["By Zone"], 132172}}) do
        local tab = CreateFrame("Frame", nil, window, "LargeSideTabButtonTemplate")
        tab:EnableMouse(true)
        tab:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", 0, -30 - (index - 1) * (tab:GetHeight() + 2))
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
    StyleTaxiFrame()
    -- Keep Blizzard's 580x580 taxi map fixed while its outer frame grows.
    TaxiFrame.InsetBg:ClearAllPoints()
    TaxiFrame.InsetBg:SetPoint("TOPLEFT", TaxiFrame, "TOPLEFT", 4, -24)
    TaxiFrame.InsetBg:SetPoint("BOTTOMRIGHT", TaxiFrame, "TOPLEFT", 584, -604)
    TaxiFrame:SetWidth(expandedWidth)
    SetUIPanelAttribute(TaxiFrame, "width", expandedPanelWidth)
    if TaxiFrame:IsShown() then
        UpdateUIPanelPositions(TaxiFrame)
    end
    self:RegisterMessage("OnFlight_TaxiMapReady", "TAXIMAP_OPENED")
    self:RegisterMessage("OnFlight_DiagnosticsChanged", function()
        if window and window:IsShown() then
            self:Refresh(false)
        end
    end)
    self:RegisterEvent("TAXIMAP_CLOSED")
    if addonCore:GetTaxiSession() then
        self:Open()
    end
end

function module:OnDisable()
    self:UnregisterAllMessages()
    self:UnregisterAllEvents()
    self:TAXIMAP_CLOSED()
    TaxiFrame.InsetBg:ClearAllPoints()
    TaxiFrame.InsetBg:SetPoint("TOPLEFT", TaxiFrame, "TOPLEFT", 4, -24)
    TaxiFrame.InsetBg:SetPoint("BOTTOMRIGHT", TaxiFrame, "BOTTOMRIGHT", -6, 4)
    TaxiFrame:SetWidth(taxiWidth)
    SetUIPanelAttribute(TaxiFrame, "width", taxiPanelWidth)
    if TaxiFrame:IsShown() then
        UpdateUIPanelPositions(TaxiFrame)
    end
end

local toggle = CreateFrame("Button", "OnFlight_TaxiFrameToggleButton", TaxiFrame)
toggle:SetSize(32, 32)
toggle:SetPoint("CENTER", TaxiFrame, "TOPLEFT", taxiWidth - 60, -45)
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
        if not module:IsEnabled() then
            return
        end
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
