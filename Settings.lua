-- luacheck: no max line length
-- luacheck: globals LibStub Settings SettingsPanel HideUIPanel CreateColor CreateColorFromHexString
-- luacheck: globals CreateFrame CreateFromMixins SettingsControlMixin SettingsListElementMixin
-- luacheck: globals SettingsColorSwatchControlMixin MinimalSliderWithSteppersMixin
-- luacheck: globals CreateSettingsListSectionHeaderInitializer CreateSettingsButtonInitializer
-- luacheck: globals OnFlightSettingsFontSizeMixin OnFlightSettingsColorMixin
-- luacheck: globals GameTooltip GameTooltip_Hide InCombatLockdown wipe
local addonName, addonCore = ...
local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local statusBarModuleCore = addonCore:GetModule("StatusBarModule")
local moduleName = "StatusBarModule"
local settings = {}
local gossipPage, diagnosticSetting

local function Register(category, key, kind, name, default, get, set)
    local setting = Settings.RegisterProxySetting(category, addonName .. "_" .. key, kind, name, default, get, set)
    settings[key] = setting
    return setting
end

function addonCore:RefreshSettings(...)
    local function Notify(setting)
        -- A native setter emits its own notification after releasing this lock.
        if setting and not setting:IsLocked() then
            setting:NotifyUpdate()
        end
    end
    if select("#", ...) == 0 then
        for _, setting in pairs(settings) do
            Notify(setting)
        end
    else
        for index = 1, select("#", ...) do
            local key = select(index, ...)
            Notify(settings[key])
            -- Short Names listens to Compact Mode as well as module enablement.
            if key == "StatusBarModule" then
                Notify(settings.bar_compactMode)
            end
        end
    end
end

function addonCore:RefreshDiagnostics()
    local owner = GameTooltip:GetOwner()
    if owner and owner.OnFlightGossipID and not (self.db.profile.showGossipConfig or self.db.profile.gossipdebug) then
        GameTooltip:Hide()
    end
    self:SendMessage("OnFlight_DiagnosticsChanged")
end

local function ResetBarSettings()
    statusBarModuleCore.db:ResetProfile(true)
    addonCore:RefreshSettings()
end

function addonCore:OpenSettings()
    Settings.OpenToCategory(self.settingsCategory:GetID())
end

function addonCore:ToggleSettings()
    local category = SettingsPanel:GetCurrentCategory()
    if SettingsPanel:IsShown() and category and
        (category == self.settingsCategory or category:GetParentCategory() == self.settingsCategory) then
        HideUIPanel(SettingsPanel)
        local browser = self:GetModule("NativeFlightListWindow")
        if browser:IsEnabled() and self:GetTaxiSession() then
            browser:Open()
        end
    else
        self:OpenSettings()
    end
end

-- The stock color picker edits RGB only. Keep alpha in AceDB, including on cancel.
local function ColorString(color)
    return CreateColor(color.r, color.g, color.b):GenerateHexColor()
end

-- Forever's stock swatch leaves SetButtonState unimplemented.
OnFlightSettingsColorMixin = CreateFromMixins(SettingsColorSwatchControlMixin)
function OnFlightSettingsColorMixin:SetButtonState(enabled)
    self.ColorSwatch:SetEnabled(enabled)
end

-- A single native text control preserves the font-size input's unrestricted range.
OnFlightSettingsFontSizeMixin = CreateFromMixins(SettingsControlMixin)

function OnFlightSettingsFontSizeMixin:OnLoad()
    SettingsControlMixin.OnLoad(self)
    self.input = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
    self.input:SetSize(80, 22)
    self.input:SetPoint("LEFT", self, "CENTER", -73, 0)
    self.input:SetAutoFocus(false)
    self.input:SetScript("OnTextChanged", function(input, userInput)
        if userInput then
            input.dirty = true
        end
    end)
    local function Commit(input)
        if not input.dirty then
            return
        end
        input.dirty = nil
        local value = tonumber(input:GetText())
        if value and value > 0 and value < math.huge then
            self:GetSetting():SetValue(value)
        end
        self:SetValue(self:GetSetting():GetValue())
    end
    self.input:SetScript("OnEnterPressed", function(input)
        Commit(input);
        input:ClearFocus()
    end)
    self.input:SetScript("OnEditFocusLost", Commit)
    self.input:SetScript("OnEscapePressed", function(input)
        input.dirty = nil
        self:SetValue(self:GetSetting():GetValue())
        input:ClearFocus()
    end)
end

function OnFlightSettingsFontSizeMixin:Init(initializer)
    SettingsControlMixin.Init(self, initializer)
    self:SetValue(self:GetSetting():GetValue())
    self:EvaluateState()
end

function OnFlightSettingsFontSizeMixin:SetValue(value)
    self.input.dirty = nil
    self.input:SetText(tostring(value))
end

function OnFlightSettingsFontSizeMixin:EvaluateState()
    SettingsListElementMixin.EvaluateState(self)
    self.input:SetEnabled(self:IsEnabled())
    self:DisplayEnabled(self:IsEnabled())
end

function OnFlightSettingsFontSizeMixin:Release()
    self.input.dirty = nil
    self.input:ClearFocus()
    SettingsControlMixin.Release(self)
end

local function MakeInput(parent, width)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width, 22)
    input:SetAutoFocus(false)
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return input
end

local function MakeButton(parent, text, width, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", click)
    return button
end

local function EndpointText(optionID, value)
    if type(value) == "number" then
        return tostring(value), addonCore:GetTaxiNodeName(value)
    end
    local _, label = addonCore:GetGossipEndpoint(optionID, value)
    return label or "", label
end

local function SetEndpointInput(input, optionID, value)
    local text, label = EndpointText(optionID, value)
    input.dirty = nil
    input:SetText(text)
    input.feedback:SetText(label or "")
    input.feedback:SetTextColor(1, 0.82, 0)
end

local function CommitEndpoint(input)
    if not input.dirty then
        return
    end
    input.dirty = nil
    local row = input:GetParent()
    local key, message = addonCore:ParseGossipEndpoint(row.optionID or 0, input:GetText())
    if not key then
        input:SetText("")
        input.feedback:SetText(message)
        input.feedback:SetTextColor(1, 0.3, 0.3)
        return
    end
    if row.optionID then
        addonCore.db.global.gossipTriggered[row.optionID][input.endpoint] = key
        LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    end
    -- New-row values remain in the form until Add supplies the real gossip ID.
    input:SetText(type(key) == "number" and tostring(key) or message)
    input.feedback:SetText(message)
    input.feedback:SetTextColor(1, 0.82, 0)
end

local function CreateGossipRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(114)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 0, -2)
    for index, name in ipairs({L["Source"], L["Destination"]}) do
        local input = MakeInput(row, 200)
        input.endpoint = index
        input:SetPoint("TOPLEFT", index == 1 and 8 or 270, -46)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 4)
        label:SetText(name)
        input.feedback = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        input.feedback:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -5)
        input.feedback:SetWidth(235)
        input.feedback:SetJustifyH("LEFT")
        input:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self.dirty = true
            end
        end)
        input:SetScript("OnEnterPressed", function(self)
            CommitEndpoint(self);
            self:ClearFocus()
        end)
        input:SetScript("OnEditFocusLost", CommitEndpoint)
        row[index] = input
    end
    return row
end

function addonCore:RefreshGossipEditor(optionID)
    if not gossipPage then
        return
    end
    local ids = {}
    for id in pairs(self.db.global.gossipTriggered) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for id, row in pairs(gossipPage.rows) do
        if not self.db.global.gossipTriggered[id] then
            -- Do not commit focused inputs after their configuration has been removed.
            for index = 1, 2 do
                row[index].dirty = nil;
                row[index]:ClearFocus()
            end
            row:Hide()
            gossipPage.rows[id] = nil
            gossipPage.freeRows[#gossipPage.freeRows + 1] = row
        end
    end
    for index, id in ipairs(ids) do
        local row = gossipPage.rows[id]
        if not row then
            row = table.remove(gossipPage.freeRows) or CreateGossipRow(gossipPage.content)
            row.optionID = id
            row.title:SetFormattedText(L["Gossip ID: %d"], id)
            if not row.remove then
                row.remove = MakeButton(row, L["Remove"], 80, function()
                    self.db.global.gossipTriggered[row.optionID] = nil
                    self:RefreshAdvOptions(row.optionID)
                end)
                row.remove:SetPoint("TOPRIGHT", -8, 0)
            end
            gossipPage.rows[id] = row
            for endpoint = 1, 2 do
                SetEndpointInput(row[endpoint], id, self.db.global.gossipTriggered[id][endpoint])
            end
        end
        if optionID == id then
            for endpoint = 1, 2 do
                SetEndpointInput(row[endpoint], id, self.db.global.gossipTriggered[id][endpoint])
            end
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 114)
        row:SetPoint("TOPRIGHT", 0, -(index - 1) * 114)
        row:Show()
    end
    gossipPage.content:SetHeight(math.max(1, #ids * 114))
end

local function CreateGossipPage(parentCategory)
    local page = CreateFrame("Frame")
    page:Hide()
    page.rows, page.freeRows = {}, {}
    gossipPage = page
    local category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, page, L["Gossip Configuration"])
    local help =
        L["Shows gossip option IDs in NPC dialogue tooltips and taxi-node IDs beside destinations in Flight Destinations. Use these IDs to configure gossip flights."]
    diagnosticSetting = Register(category, "showGossipConfig", "boolean", L["Show Diagnostic IDs"], false, function()
        return addonCore.db.profile.showGossipConfig
    end, function(value)
        addonCore.db.profile.showGossipConfig = value
        addonCore:RefreshDiagnostics()
    end)
    local checkbox = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 12, -8)
    checkbox.Text:SetText(L["Show Diagnostic IDs"])
    checkbox.Text:SetFontObject("GameFontNormal")
    checkbox:SetScript("OnClick", function(self)
        diagnosticSetting:SetValue(self:GetChecked())
    end)
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Show Diagnostic IDs"])
        GameTooltip:AddLine(help, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)
    diagnosticSetting:SetValueChangedCallback(function(_, value)
        checkbox:SetChecked(value)
    end)
    local diagnosticHelp = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    diagnosticHelp:SetPoint("TOPLEFT", 18, -44)
    diagnosticHelp:SetPoint("TOPRIGHT", -20, -44)
    diagnosticHelp:SetJustifyH("LEFT")
    diagnosticHelp:SetText(L["Enable this while configuring a gossip flight."])
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", diagnosticHelp, "BOTTOMLEFT", 0, -16)
    title:SetPoint("TOPRIGHT", diagnosticHelp, "BOTTOMRIGHT", 0, -16)
    title:SetJustifyH("LEFT")
    title:SetText(L["Gossip Flights"])
    local explanation = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    explanation:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    explanation:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    explanation:SetJustifyH("LEFT")
    explanation:SetText(
        L["Configure flights started through NPC dialogue. A Gossip ID identifies the dialogue option that starts a flight."])
    local endpointsTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    endpointsTitle:SetPoint("TOPLEFT", explanation, "BOTTOMLEFT", 0, -14)
    endpointsTitle:SetPoint("TOPRIGHT", explanation, "BOTTOMRIGHT", 0, -14)
    endpointsTitle:SetJustifyH("LEFT")
    endpointsTitle:SetText(L["Endpoints"])
    local endpointsHelp = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    endpointsHelp:SetPoint("TOPLEFT", endpointsTitle, "BOTTOMLEFT", 0, -8)
    endpointsHelp:SetPoint("TOPRIGHT", endpointsTitle, "BOTTOMRIGHT", 0, -8)
    endpointsHelp:SetJustifyH("LEFT")
    endpointsHelp:SetText(
        L["Enter a taxi-node ID or a custom location name for Source and Destination. Press Enter or click away to save."])

    local new = CreateGossipRow(page)
    new:SetPoint("TOPLEFT", endpointsHelp, "BOTTOMLEFT", 0, -20)
    new:SetPoint("TOPRIGHT", endpointsHelp, "BOTTOMRIGHT", -8, -20)
    new.title:SetText(L["New Gossip ID:"])
    new.id = MakeInput(new, 95)
    new.id:SetPoint("TOPLEFT", 140, 2)
    new.id:SetNumeric(true)
    new.id:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    new.add = MakeButton(new, L["Add"], 80, function()
        CommitEndpoint(new[1]);
        CommitEndpoint(new[2])
        local id = tonumber(new.id:GetText())
        if not id or id <= 0 or id % 1 ~= 0 then
            new[1].feedback:SetText(L["Enter a Gossip ID from a dialogue tooltip: digits only, greater than zero."])
            return
        end
        if addonCore.db.global.gossipTriggered[id] then
            new[1].feedback:SetText(L["This Gossip ID already exists. Edit its endpoints below."])
            return
        end
        local source, sourceMessage = addonCore:ParseGossipEndpoint(id, new[1]:GetText())
        local destination, destinationMessage = addonCore:ParseGossipEndpoint(id, new[2]:GetText())
        if not source or not destination then
            if not source then
                new[1].feedback:SetText(sourceMessage)
            end
            if not destination then
                new[2].feedback:SetText(destinationMessage)
            end
            return
        end
        addonCore.db.global.gossipTriggered[id] = {source, destination}
        new.id:SetText("");
        new.id:ClearFocus()
        for index = 1, 2 do
            new[index].dirty = nil
            new[index]:SetText("")
            new[index].feedback:SetText("")
            new[index]:ClearFocus()
        end
        addonCore:RefreshAdvOptions(id)
    end)
    new.add:SetPoint("TOPRIGHT", -8, 0)

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", new, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", -36, 12)
    page.content = CreateFrame("Frame", nil, scroll)
    page.content:SetSize(1, 1)
    scroll:SetScrollChild(page.content)
    scroll:SetScript("OnSizeChanged", function(_, width)
        page.content:SetWidth(width)
    end)
    page.OnRefresh = function()
        checkbox:SetChecked(diagnosticSetting:GetValue())
        addonCore:RefreshGossipEditor()
        for id, row in pairs(page.rows) do
            for index = 1, 2 do
                SetEndpointInput(row[index], id, addonCore.db.global.gossipTriggered[id][index])
            end
        end
    end
    page:SetScript("OnHide", function()
        new.id:ClearFocus()
        for index = 1, 2 do
            new[index]:ClearFocus()
        end
        for _, row in pairs(page.rows) do
            for index = 1, 2 do
                row[index]:ClearFocus()
            end
        end
    end)
end

function addonCore:InitializeSettings()
    if self.settingsCategory then
        return
    end
    local category = Settings.RegisterVerticalLayoutCategory("OnFlight")
    self.settingsCategory = category
    Settings.RegisterAddOnCategory(category)
    local showChat = Register(category, "showChat", "boolean", L["Show Chat Messages"], true, function()
        return self.db.profile.showChat
    end, function(value)
        self.db.profile.showChat = value
    end)
    Settings.CreateCheckbox(category, showChat,
        L["Reports when flights start, resume, finish, or end early. Includes timing information when available."])
    local minimap = Register(category, "showMinimapButton", "boolean", L["Show Minimap Button"], true, function()
        return not self.db.profile.minimap.hide
    end, function(value)
        self.db.profile.minimap.hide = not value
        self:GetModule("LDBLauncher"):RefreshMinimapIcon()
    end)
    Settings.CreateCheckbox(category, minimap,
        L["Shows the OnFlight minimap launcher. Left-click to open settings; drag to move it."])
    local bar = self:GetModule("StatusBarModule")
    local enabled = Register(category, "StatusBarModule", "boolean", L["Enable Flight Timer Bar"], true, function()
        return self.db.profile.moduleState.StatusBarModule
    end, function(value)
        self:SetModuleStatus({"StatusBarModule"}, value)
    end)
    local enableControl = Settings.CreateCheckbox(category, enabled,
        L["Shows OnFlight's built-in timer bar. Flight tracking and duration learning continue when disabled, and timing data remains available to other displays."])
    local barCategory, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Flight Timer Bar"])
    local function AddControl(initializer)
        initializer:SetParentInitializer(enableControl, function()
            return bar:IsEnabled()
        end)
        return initializer
    end
    local function BarSetting(key, kind, name, location, color)
        local defaults = location and bar.svDefaults.profile.barLocation or bar.svDefaults.profile
        local default = color and ColorString(defaults[key]) or defaults[key]
        return Register(barCategory, "bar_" .. key, kind, name, default, function()
            local profile = location and bar.db.profile.barLocation or bar.db.profile
            if color then
                return ColorString(profile[key])
            end
            return key == "fontSize" and tonumber(profile[key]) or profile[key]
        end, function(value)
            local profile = location and bar.db.profile.barLocation or bar.db.profile
            if color then
                local r, g, b = CreateColorFromHexString(value):GetRGB()
                local target = profile[key]
                target.r, target.g, target.b = r, g, b
            else
                profile[key] = value
            end
            bar:OnProfileUpdated()
        end)
    end
    local function Heading(name)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name))
    end
    local function Slider(key, name, min, max, step, location, tooltip)
        local setting = BarSetting(key, "number", name, location)
        local options = Settings.CreateSliderOptions(min, max, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        return AddControl(Settings.CreateSlider(barCategory, setting, options, tooltip))
    end
    local function Dropdown(key, name, getOptions, location, tooltip)
        return AddControl(Settings.CreateDropdown(barCategory, BarSetting(key, "string", name, location), getOptions,
            tooltip))
    end
    local function MediaOptions(kind)
        return function()
            local options = Settings.CreateControlTextContainer()
            for _, name in ipairs(LSM:List(kind)) do
                options:Add(name, name)
            end
            return options:GetData()
        end
    end
    local function Button(name, action, tooltip)
        layout:AddInitializer(AddControl(CreateSettingsButtonInitializer(name, name, action, tooltip, true)))
    end
    Heading(L["Layout and Position"])
    local function Anchors()
        local options = Settings.CreateControlTextContainer()
        for _, anchor in ipairs({"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM",
                                 "BOTTOMRIGHT"}) do
            options:Add(anchor, L[anchor])
        end
        return options:GetData()
    end
    Dropdown("anchorPoint", L["Bar Anchor"], Anchors, true, L["Point on the timer bar attached to the Relative Anchor."])
    Dropdown("relativePoint", L["Relative Anchor"], Anchors, true,
        L["Point on the screen's main UI frame (UIParent) that the bar attaches to. TOP for both anchors aligns their top centers before offsets."])
    Slider("offsetX", L["Horizontal Offset"], -1000, 1000, 1, true,
        L["Moves the bar from its anchor position. Positive values move right; negative values move left."])
    Slider("offsetY", L["Vertical Offset"], -1000, 1000, 1, true,
        L["Moves the bar from its anchor position. Positive values move up; negative values move down."])
    Slider("barWidth", L["Minimum Width"], 10, 1000, 10, false,
        L["The bar grows wider when needed to fit its text. This sets its minimum width."])
    Slider("barHeight", L["Height"], 10, 300, 1, false, L["Vertical size of the timer bar, including its border."])
    Heading(L["Display"])
    local compact = AddControl(Settings.CreateCheckbox(barCategory,
        BarSetting("compactMode", "boolean", L["Compact Mode"]),
        L["Shows only the remaining time for flights with a known duration. Unknown flights still show location names and elapsed time."]))
    local short = AddControl(Settings.CreateCheckbox(barCategory,
        BarSetting("shortNames", "boolean", L["Short Destination Names"]),
        L["Omits zone suffixes from source and destination names. Unavailable in Compact Mode because known flights show only the timer."]))
    short:SetParentInitializer(compact, function()
        return not bar.db.profile.compactMode
    end)
    Heading(L["Appearance"])
    Dropdown("barTexture", L["Bar Texture"], MediaOptions("statusbar"), false,
        L["Artwork used for the bar fill and background. Choices come from LibSharedMedia and may include textures supplied by other addons."])
    Dropdown("borderTexture", L["Border Texture"], MediaOptions("border"), false,
        L["Artwork around the edge of the timer bar. Choices come from LibSharedMedia and may include borders supplied by other addons."])
    Dropdown("fontName", L["Font"], MediaOptions("font"), false,
        L["Typeface for location names and the timer. Choices come from LibSharedMedia and may include fonts supplied by other addons."])
    local fontSize = BarSetting("fontSize", "number", L["Font Size"])
    layout:AddInitializer(AddControl(Settings.CreateControlInitializer("OnFlightSettingsFontSizeTemplate", fontSize,
        nil,
        L["Size of the location names and timer text. Enter a positive number, then press Enter or click away to apply."])))
    for _, entry in ipairs({{"backgroundColor", L["Background Color"],
                             L["Color behind the bar fill. Keeps the current transparency."]},
                            {"barColor", L["Known Flight Color"],
                             L["Bar fill used for the countdown when OnFlight has a measured flight duration."]},
                            {"unknownFlightColor", L["Unknown Flight Color"],
                             L["Bar fill used when no measured duration is saved for the flight's source and destination. The timer shows elapsed time instead of time remaining."]},
                            {"borderColor", L["Border Color"],
                             L["Color of the frame edge. Choose its artwork with Border Texture."]},
                            {"fontColor", L["Font Color"], L["Color shared by location names and the timer text."]}}) do
        local setting = BarSetting(entry[1], "string", entry[2], false, true)
        layout:AddInitializer(AddControl(Settings.CreateControlInitializer("OnFlightSettingsColorTemplate", setting,
            nil, entry[3])))
    end
    Heading(L["Preview and Reset"])
    Button(L["Preview Known Flight"], function()
        bar:StartTimerBar(L["City1, Zone1"], L["City2, Zone2"], 300)
    end,
        L["Shows a five-minute countdown with sample locations. Previews leave your travel and learned flight times unchanged."])
    Button(L["Preview Unknown Flight"], function()
        bar:StartTimerBar(L["Unknown1, Zone1"], L["Unknown2, Zone2"], nil, nil, true)
    end,
        L["Shows an elapsed-time display with sample locations. Previews leave your travel and learned flight times unchanged."])
    Button(L["Hide Timer Bar"], function()
        bar:StopTimerBar()
    end, L["Hides the preview or current flight display. Flight tracking and duration learning continue."])
    Button(L["Reset Bar Settings"], ResetBarSettings,
        L["Restores the current profile's timer-bar appearance and position defaults. Other OnFlight settings and learned flight times stay unchanged."])
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, L["Profiles"], category:GetID(), "profiles")
    CreateGossipPage(category)
    self:RefreshAdvOptions()
    self:RefreshSettings()
end

-- Text input validation is shared by the native and command editors.
function addonCore:ParseGossipEndpoint(optionID, text)
    local value = text:match("^%s*(.-)%s*$")
    if value == "" then
        return nil, L["Enter a taxi-node ID or a custom location name."]
    end
    if value:match("^%d+$") then
        local id = tonumber(value)
        local name = self:GetTaxiNodeName(id)
        if name then
            return id, name
        end
        return nil, L["Unknown taxi-node ID. Check the ID or use a name. Saved value unchanged."]
    end
    return tostring(optionID) .. ":" .. value, value
end

-- Retained command interface and embedded Profiles descriptions.
function addonCore.ChatCommand(_, input)
    if InCombatLockdown() then
        addonCore:Print(L["In Combat"])
        return
    end
    if not input or input:trim() == "" then
        addonCore:OpenSettings()
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(addonCore, "OnFlight", addonName, input)
    end
end

---Ace3 Config Table
function addonCore:GetOption(info)
    if info.type == "color" then
        if addonCore.db.profile[info[#info]] then
            local color = addonCore.db.profile[info[#info]]
            return color.r, color.g, color.b, color.a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100,
                math.random(0, 100) / 100
        end
    else
        return addonCore.db.profile[info[#info]]
    end
end

function addonCore:SetOption(info, ...)
    if info.type == "color" then
        local red, green, blue, alpha = ...
        addonCore.db.profile[info[#info]] = addonCore.db.profile[info[#info]] or {}
        addonCore.db.profile[info[#info]].r = red
        addonCore.db.profile[info[#info]].b = blue
        addonCore.db.profile[info[#info]].g = green
        addonCore.db.profile[info[#info]].a = alpha
    else
        addonCore.db.profile[info[#info]] = ...
    end
    self:RefreshSettings(info[#info])
end

local gossipOptionTemplate = {
    name = "",
    type = "group",
    inline = true,
    order = function(info)
        return tonumber(info[#info])
    end,
    args = {
        name = {
            order = 1,
            name = L["Gossip ID"],
            type = "input",
            get = function(info)
                return info[#info - 1]
            end,
            set = function()
            end,
            disabled = true
        },
        sourceID = {
            order = 2,
            type = "input",
            name = L["Source Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = function(info)
                local id = tonumber(info[#info - 1])
                local value = addonCore.db.global.gossipTriggered[id][1]
                return type(value) == "number" and tostring(value) or select(2, addonCore:GetGossipEndpoint(id, value))
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                addonCore.db.global.gossipTriggered[id][1] = addonCore:ParseGossipEndpoint(id, value)
                addonCore:RefreshGossipEditor(id)
            end
        },
        destinationID = {
            order = 3,
            type = "input",
            name = L["Destination Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = function(info)
                local id = tonumber(info[#info - 1])
                local value = addonCore.db.global.gossipTriggered[id][2]
                return type(value) == "number" and tostring(value) or select(2, addonCore:GetGossipEndpoint(id, value))
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                addonCore.db.global.gossipTriggered[id][2] = addonCore:ParseGossipEndpoint(id, value)
                addonCore:RefreshGossipEditor(id)
            end
        },
        remove = {
            order = 4,
            name = L["Remove"],
            type = "execute",
            func = function(info)
                local id = tonumber(info[#info - 1])
                ---@diagnostic disable-next-line: need-check-nil
                addonCore.db.global.gossipTriggered[id] = nil
                addonCore:RefreshAdvOptions(id)
            end
        }
    }
}

local addNew_Temp = {}
local addNew_Temp_get = function(info)
    return addNew_Temp[info[#info]]
end
local addNew_Temp_set = function(info, value)
    addNew_Temp[info[#info]] = value
end
local gossipOptionTemplate_AddNew = {
    name = "",
    type = "group",
    inline = true,
    order = -1,
    args = {
        name = {
            order = 1,
            name = L["Gossip ID"],
            type = "input",
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        sourceID = {
            order = 2,
            type = "input",
            name = L["Source Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        destinationID = {
            order = 3,
            type = "input",
            name = L["Destination Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        addNew = {
            order = 4,
            name = L["Add New"],
            type = "execute",
            func = function()
                local id = tonumber(addNew_Temp.name)
                if not id or not addNew_Temp.sourceID or not addNew_Temp.destinationID then
                    return
                end
                local source = addonCore:ParseGossipEndpoint(id, addNew_Temp.sourceID)
                local destination = addonCore:ParseGossipEndpoint(id, addNew_Temp.destinationID)
                if not source or not destination then
                    return
                end
                addonCore.db.global.gossipTriggered[id] = {source, destination}
                wipe(addNew_Temp)
                addonCore:RefreshAdvOptions(id)
            end
        }
    }
}

function addonCore:GetModuleStatus(info)
    return addonCore.db.profile.moduleState[info[#info]]
end

function addonCore:RefreshAdvOptions(optionID)
    local opt = wipe(self.configOptionsTable.args.gossipConfigTab.args)
    for k, _ in pairs(addonCore.db.global.gossipTriggered) do
        opt[tostring(k)] = gossipOptionTemplate
    end
    opt.AddNewGossipID = gossipOptionTemplate_AddNew
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    self:RefreshGossipEditor(optionID)
end

-- Keep the existing command paths; only Profiles is rendered by AceConfigDialog.
addonCore.configOptionsTable = {
    type = "group",
    name = L["OnFlight Options"],
    handler = addonCore,
    get = "GetOption",
    set = "SetOption",
    childGroups = "tab",
    args = {
        misc = {
            name = L["Main Options"],
            type = "group",
            order = 10,
            width = "full",
            args = {
                showChat = {
                    name = L["Show Chat Messages"],
                    desc = L["Show Flight Status Messages in Chat Window"],
                    type = "toggle",
                    order = 10
                },
                showGossipConfig = {
                    name = L["Show Diagnostic IDs"],
                    desc = L["Show gossip option IDs and taxi-node IDs."],
                    type = "toggle",
                    order = 20,
                    get = function(info)
                        return addonCore.db.profile.showGossipConfig
                    end,
                    set = function(_, option)
                        addonCore.db.profile.showGossipConfig = option
                        addonCore:RefreshSettings("showGossipConfig")
                        addonCore:RefreshDiagnostics()
                    end
                },
                moduleControl = {
                    name = L["Module Control"],
                    type = "group",
                    inline = true,
                    order = 100,
                    args = {
                        StatusBarModule = {
                            name = L["Flight Timer Bar"],
                            desc = L["The Built in Timer Bar that comes with OnFlight"],
                            type = "toggle",
                            get = "GetModuleStatus",
                            set = "SetModuleStatus"

                        }
                    }
                }
            }
        },
        gossipConfigTab = {
            name = L["Gossip Configuration"],
            type = "group",
            order = 900,
            args = {}
        }
    }
}

local optionsTable_SetPoint_Dictionary = {
    ["TOPLEFT"] = L["TOPLEFT"],
    ["TOP"] = L["TOP"],
    ["TOPRIGHT"] = L["TOPRIGHT"],
    ["LEFT"] = L["LEFT"],
    ["CENTER"] = L["CENTER"],
    ["RIGHT"] = L["RIGHT"],
    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
    ["BOTTOM"] = L["BOTTOM"],
    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"]

}
local optionsTable_SetPoint_SortedList = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT",
                                          "BOTTOM", "BOTTOMRIGHT"}
---

function statusBarModuleCore:GetOption(info)
    local profile = statusBarModuleCore.db.profile
    if info.type == "color" then
        local t = profile[info[#info]]
        if t then
            return t.r, t.g, t.b, t.a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100,
                math.random(0, 100) / 100
        end
    else
        return profile[info[#info]]
    end
end

function statusBarModuleCore:SetOption(info, ...)
    local profile = statusBarModuleCore.db.profile
    if info.type == "color" then
        local red, green, blue, alpha = ...
        profile[info[#info]] = profile[info[#info]] or {}
        profile[info[#info]].r = red
        profile[info[#info]].g = green
        profile[info[#info]].b = blue
        profile[info[#info]].a = alpha
    else
        profile[info[#info]] = ...
    end
    self:OnProfileUpdated()
    addonCore:RefreshSettings("bar_" .. info[#info])
end

function statusBarModuleCore:GetBarLocation(info, ...)
    return statusBarModuleCore.db.profile.barLocation[info[#info]]
end

function statusBarModuleCore:SetBarLocation(info, value)
    statusBarModuleCore.db.profile.barLocation[info[#info]] = value
    self:OnProfileUpdated()
    addonCore:RefreshSettings("bar_" .. info[#info])
end

-- These descriptions remain for AceConfigCmd, not the native settings page.
addonCore.configOptionsTable.plugins = addonCore.configOptionsTable.plugins or {}
addonCore.configOptionsTable.plugins[moduleName] = {
    barOptions = {
        handler = statusBarModuleCore,
        get = "GetOption",
        set = "SetOption",
        name = L["Flight Timer Bar"],
        type = "group",
        order = 100,
        disabled = function(info)
            return not statusBarModuleCore:IsEnabled()
        end,
        args = {
            desc = {
                type = "description",
                name = L[" Shift Click on the Status Bar to send flight info to chat.\n  Control Click & Drag to Move It."],
                order = 1
            },
            resetToDefaults = {
                type = "execute",
                name = L["Reset All Bar Options to Defaults"],
                width = "full",
                func = ResetBarSettings,
                order = 1000
            },
            barOptions = {
                type = "group",
                name = L["Bar Options"],
                inline = true,
                order = 100,
                args = {
                    barLocation = {
                        name = L["Bar Anchor"],
                        type = "group",
                        order = 9,
                        inline = true,
                        get = "GetBarLocation",
                        set = "SetBarLocation",
                        args = {
                            anchorPoint = {
                                type = "select",
                                name = L["Anchor Point"],
                                order = 20,
                                values = optionsTable_SetPoint_Dictionary,
                                sorting = optionsTable_SetPoint_SortedList
                            },
                            relativePoint = {
                                type = "select",
                                name = L["World Frame Anchor Point"],
                                order = 30,
                                desc = L["Status Bar is Always anchored to World Frame"],
                                values = optionsTable_SetPoint_Dictionary,
                                sorting = optionsTable_SetPoint_SortedList
                            },
                            breakFlow = {
                                type = "description",
                                name = " ",
                                order = 39
                            },
                            offsetX = {
                                type = "range",
                                name = L["X Offset"],
                                order = 40,
                                bigStep = 1,
                                min = -1000,
                                max = 1000,
                                softMin = -300,
                                softMax = 300
                            },
                            offsetY = {
                                type = "range",
                                name = L["Y Offset"],
                                order = 50,
                                bigStep = 1,
                                min = -1000,
                                max = 1000,
                                softMin = -300,
                                softMax = 300
                            }
                        }
                    },
                    size = {
                        name = L["Bar Size"],
                        type = "group",
                        order = 10,
                        inline = true,
                        args = {
                            barHeight = {
                                name = L["Height"],
                                type = "range",
                                order = 10,
                                min = 10,
                                max = 300,
                                step = 1
                            },
                            barWidth = {
                                name = L["Width"],
                                type = "range",
                                order = 20,
                                min = 10,
                                max = 1000,
                                step = 10
                            }
                        }
                    },
                    LookFeel = {
                        name = L["Look and Feel"],
                        type = "group",
                        order = 20,
                        inline = true,
                        width = "normal",
                        args = {
                            barTexture = {
                                name = L["Bar Texture"],
                                type = "select",
                                order = 10,
                                values = function()
                                    return LSM:HashTable("statusbar")
                                end
                            },
                            backgroundColor = {
                                name = L["Background Color"],
                                type = "color",
                                order = 20
                            },
                            barColor = {
                                name = L["Known Flight Color"],
                                type = "color",
                                order = 30
                            },
                            unknownFlightColor = {
                                name = L["Unknown Flight Color"],
                                type = "color",
                                order = 40
                            }
                        }
                    },
                    borderSettings = {
                        name = L["Border Settings"],
                        type = "group",
                        order = 30,
                        inline = true,
                        args = {
                            borderTexture = {
                                name = L["Border Texture"],
                                type = "select",
                                order = 10,
                                values = function()
                                    return LSM:HashTable("border")
                                end
                            },
                            borderColor = {
                                name = L["Border Color"],
                                type = "color",
                                order = 20
                            }
                        }
                    }
                }
            },
            textOptions = {
                name = L["Display"],
                type = "group",
                order = 200,
                inline = true,
                args = {
                    compactMode = {
                        name = L["Compact Mode"],
                        type = "toggle",
                        order = 9
                    },
                    shortNames = {
                        name = L["Short Names"],
                        type = "toggle",
                        order = 10,
                        disabled = function()
                            return statusBarModuleCore.db.profile.compactMode
                        end
                    },
                    fontOptions = {
                        name = L["Font Options"],
                        type = "group",
                        inline = true,
                        args = {
                            fontName = {
                                name = L["Font"],
                                type = "select",
                                values = function()
                                    return LSM:HashTable("font")
                                end,
                                order = 10
                            },
                            fontSize = {
                                name = L["Font Size"],
                                type = "input",
                                order = 20
                            },
                            fontColor = {
                                name = L["Font Color"],
                                type = "color",
                                order = 30
                            }
                        }
                    }
                }
            },
            testButtons = {
                type = "group",
                inline = true,
                name = L["Show/Test Flight Timer Bar"],
                order = 350,
                args = {
                    ["testKnown"] = {
                        type = "execute",
                        name = L["Start Known Flight"],
                        order = 1,
                        func = function()
                            statusBarModuleCore:StartTimerBar(L["City1, Zone1"], L["City2, Zone2"], 300)
                        end
                    },
                    ["testUnknown"] = {
                        type = "execute",
                        name = L["Start Unknown Flight"],
                        order = 2,
                        func = function()
                            statusBarModuleCore:StartTimerBar(L["Unknown1, Zone1"], L["Unknown2, Zone2"], nil, nil, true)
                        end
                    },
                    ["stopTest"] = {
                        type = "execute",
                        name = L["Stop Flight"],
                        order = 3,
                        func = function()
                            statusBarModuleCore:StopTimerBar()
                        end
                    }
                }
            }
        }
    }
}

function addonCore:InitializeConfig()
    self.configOptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.configOptionsTable.args.profiles.order = 800

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    self:RegisterChatCommand("OnFlight", "ChatCommand")
end
