-- One-time construction of the native destination pane.
-- luacheck: globals LibStub CreateFrame TaxiFrame GameTooltip GameTooltip_Hide
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addonCore:RefreshFlightNotificationCheckbox()
    local checkbox = self.destinationFrame and self.destinationFrame.notifications
    if not checkbox then return end

    local enabled = self.db.profile.flightNotifications
    checkbox:SetChecked(self:GetNextFlightNotifications())
    -- Desaturate the native gold artwork before tinting it blue.
    local textures = {checkbox:GetNormalTexture(), checkbox:GetPushedTexture(), checkbox:GetCheckedTexture()}
    for _, texture in ipairs(textures) do
        texture:SetDesaturated(enabled)
        texture:SetVertexColor(enabled and 0.35 or 1, enabled and 0.65 or 1, 1)
    end
end

function addonCore:CreateDestinationFrame()
    if self.destinationFrame then return self.destinationFrame end

    local window = CreateFrame("Frame", "OnFlightDestinationWindow", TaxiFrame)
    self.destinationFrame = window
    window:Hide()
    window:SetPoint("TOPLEFT", TaxiFrame.InsetBg, "TOPRIGHT", 0, 24)
    window:SetPoint("BOTTOMRIGHT", TaxiFrame, "BOTTOMRIGHT", 0, 0)
    window:EnableMouse(true)

    local background = window:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-General-BG")
    background:SetPoint("TOPLEFT", 0, -24)
    background:SetPoint("BOTTOMRIGHT", -2, 2)

    window.back = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    window.back:SetSize(85, 22)
    window.back:SetPoint("TOPLEFT", 16, -35)
    window.back:SetText(L["< Back"])

    window.header = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    window.header:SetJustifyH("LEFT")
    window.header:SetWordWrap(false)

    window.search = CreateFrame("EditBox", nil, window, "SearchBoxTemplate")
    window.search:SetSize(115, 20)
    window.search:SetPoint("RIGHT", window, "TOPRIGHT", -18, -46)

    window.scroll = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
    window.scroll:SetPoint("TOPLEFT", 16, -68)
    window.scroll:SetPoint("BOTTOMRIGHT", -35, 48)
    window.scroll:EnableMouseWheel(true)
    window.content = CreateFrame("Frame", nil, window.scroll)
    window.content:SetSize(window.scroll:GetWidth(), 1)
    window.scroll:SetScrollChild(window.content)
    window.scroll:HookScript("OnSizeChanged", function(scroll, width, height)
        window.content:SetWidth(width)
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(), math.max(0, window.content:GetHeight() - height)))
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

    local notifications = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    window.notifications = notifications
    notifications:SetSize(24, 24)
    notifications:SetPoint("BOTTOMRIGHT", -16, 20)
    notifications.Text:ClearAllPoints()
    notifications.Text:SetPoint("RIGHT", notifications, "LEFT", 2, 0)
    notifications.Text:SetText(L["End of Flight Notification"])
    notifications:SetHitRectInsets(-notifications.Text:GetStringWidth(), 0, 0, 0)
    notifications:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    notifications:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            self:SetFlightNotifications(not self.db.profile.flightNotifications, true)
        else
            self:SetNextFlightNotifications(not self:GetNextFlightNotifications())
        end
    end)
    notifications:SetScript("OnEnter", function(checkbox)
        GameTooltip:SetOwner(checkbox, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine(L["Landing warning and arrival notifications."], 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Left-click: Next flight"], 1, 1, 1)
        GameTooltip:AddLine(L["Right-click: Profile default"], 1, 1, 1)
        GameTooltip:AddLine(L["Blue: Profile default enabled"], 1, 1, 1)
        GameTooltip:Show()
    end)
    notifications:SetScript("OnLeave", GameTooltip_Hide)
    self:RefreshFlightNotificationCheckbox()

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
        window.tabs[data[1]] = tab
    end
    return window
end

function addonCore.CreateDestinationRow(window, index, height)
    local row = CreateFrame("Button", nil, window.content)
    row:SetHeight(height)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * height)
    row:SetPoint("TOPRIGHT", 0, -(index - 1) * height)
    row:SetMotionScriptsWhileDisabled(true)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("UI-Character-Info-Line-Bounce")
    background:SetAllPoints()
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", 6, -3)
    row.favorite = row:CreateTexture(nil, "OVERLAY")
    row.favorite:SetAtlas("PetJournal-FavoritesIcon")
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
    return row
end
