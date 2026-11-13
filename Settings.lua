-- luacheck: no max line length
-- luacheck: globals LibStub Settings SettingsPanel HideUIPanel CreateColor CreateColorFromHexString
-- luacheck: globals CreateFrame CreateFromMixins SettingsControlMixin SettingsListElementMixin
-- luacheck: globals SettingsColorSwatchControlMixin MinimalSliderWithSteppersMixin
-- luacheck: globals CreateSettingsListSectionHeaderInitializer CreateSettingsButtonInitializer
-- luacheck: globals OnFlightSettingsFontSizeMixin OnFlightSettingsColorMixin
-- luacheck: globals GameTooltip GameTooltip_Hide InCombatLockdown wipe
local addonName, addonCore = ...
local LSMC = LibStub("LibSharedMediaControls-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3", true)
local timerBar = addonCore:GetModule("TimerBar")
local settings = {}

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
            if key == "TimerBar" then
                Notify(settings.flightDisplay)
                Notify(settings.bar_compactMode)
            end
        end
    end
end

function addonCore:GetFlightDisplay()
    local profile = self.db.profile
    -- Keep the existing bar preference until a display is explicitly selected.
    local display = profile.flightDisplay or (profile.moduleState.TimerBar and "builtin" or "none")
    return display == "quartz" and not Quartz3 and "builtin" or display
end

function addonCore:ApplyFlightDisplay()
    local display = self:GetFlightDisplay()
    local bar = self:GetModule("TimerBar")
    local enabled = display == "builtin"
    self.db.profile.moduleState.TimerBar = enabled
    if enabled and not bar:IsEnabled() then
        bar:Enable()
    elseif not enabled and bar:IsEnabled() then
        bar:Disable()
    end
    if Quartz3 then
        if display == "quartz" then
            Quartz3:SetModuleEnabled("Flight", false)
        end
        Quartz3:SetModuleEnabled("OnFlight", display == "quartz")
    end
    self:RefreshSettings("TimerBar")
end

function addonCore:SetFlightDisplay(display)
    if display == "quartz" then
        if not Quartz3 then return end
        if not Quartz3:GetModule("Player"):IsEnabled() then
            print(self.OnFlightPrefixText, L["Enable Quartz's Player module before selecting the Quartz flight timer."])
            return
        end
    end
    self.db.profile.flightDisplay = display
    self:ApplyFlightDisplay()
end

function addonCore:RefreshDiagnostics()
    local owner = GameTooltip:GetOwner()
    if owner and owner.OnFlightGossipID and not (self.db.profile.showGossipConfig or self.db.profile.gossipdebug) then
        GameTooltip:Hide()
    end
    self:TriggerEvent("OnFlight_DiagnosticsChanged")
end

function addonCore:ResetBarSettings()
    timerBar.db:ResetProfile(true)
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
        L["Show flight status and timing in chat."])
    local showUnknown = Register(category, "showUnknownFlightPoints", "boolean", L["Show Unknown Flight Points"], false,
        function() return self.db.profile.showUnknownFlightPoints end,
        function(value) self.db.profile.showUnknownFlightPoints = value end)
    Settings.CreateCheckbox(category, showUnknown,
        L["Show unreachable destinations and mark them red on the flight map."])
    local worldMaps = Register(category, "useWorldMapFlightMaps", "boolean",
        L["Use World Map Style Flight Maps"], true,
        function() return self.db.profile.useWorldMapFlightMaps end,
        function(value) self.db.profile.useWorldMapFlightMaps = value end)
    Settings.CreateCheckbox(category, worldMaps,
        L["Use detailed continent artwork for flight maps."])
    local minimap = Register(category, "showMinimapButton", "boolean", L["Show Minimap Button"], true, function()
        return not self.db.profile.minimap.hide
    end, function(value)
        self.db.profile.minimap.hide = not value
        self:GetModule("LDBLauncher"):RefreshMinimapIcon()
    end)
    Settings.CreateCheckbox(category, minimap,
        L["Left-click to resend your flight. Right-click for settings. Drag to move."])
    local bar = self:GetModule("TimerBar")
    local display = Register(category, "flightDisplay", "string", L["Flight Timer Display"], "builtin", function()
        return self:GetFlightDisplay()
    end, function(value)
        self:SetFlightDisplay(value)
    end)
    local enableControl = Settings.CreateDropdown(category, display, function()
        local options = Settings.CreateControlTextContainer()
        options:Add("none", L["None"])
        options:Add("builtin", L["Built-in Timer Bar"])
        if Quartz3 then
            options:Add("quartz", L["Quartz"],
                L["Show known flights on Quartz's Player bar. Replaces Quartz's Flight module."])
        end
        return options:GetData()
    end, L["Choose a timer display. None hides the timer without stopping flight tracking."])
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
    Dropdown("anchorPoint", L["Bar Anchor"], Anchors, true, L["Bar point attached to the Relative Anchor."])
    Dropdown("relativePoint", L["Relative Anchor"], Anchors, true,
        L["Screen point the bar attaches to."])
    Slider("offsetX", L["Horizontal Offset"], -1000, 1000, 1, true,
        L["Positive values move right; negative values move left."])
    Slider("offsetY", L["Vertical Offset"], -1000, 1000, 1, true,
        L["Positive values move up; negative values move down."])
    Slider("barWidth", L["Minimum Width"], 10, 1000, 10, false,
        L["Minimum bar width. Expands to fit the text."])
    Slider("barHeight", L["Height"], 20, 300, 1, false, L["Timer bar height, including its border."])
    Heading(L["Display"])
    local compact = AddControl(Settings.CreateCheckbox(barCategory,
        BarSetting("compactMode", "boolean", L["Compact Mode"]),
        L["Show only the countdown on known flights."]))
    local short = AddControl(Settings.CreateCheckbox(barCategory,
        BarSetting("shortNames", "boolean", L["Short Destination Names"]),
        L["Hide zones in location names. Unavailable in Compact Mode."]))
    short:SetParentInitializer(compact, function()
        return not bar.db.profile.compactMode
    end)
    Heading(L["Appearance"])
    local function ColorControl(setting, tooltip)
        layout:AddInitializer(AddControl(Settings.CreateControlInitializer("OnFlightSettingsColorTemplate", setting,
            nil, tooltip)))
    end
    Heading(L["Bar"])
    local barColor = BarSetting("barColor", "string", L["Known Flight Color"], false, true)
    AddControl(LSMC:CreateStatusbarDropdown(barCategory,
        BarSetting("barTexture", "string", L["Bar Texture"]),
        L["Timer bar texture."],
        barColor))
    ColorControl(barColor, L["Bar color for known flight times."])
    ColorControl(BarSetting("unknownFlightColor", "string", L["Unknown Flight Color"], false, true),
        L["Bar color for unknown flight times."])
    ColorControl(BarSetting("backgroundColor", "string", L["Background Color"], false, true),
        L["Color behind the bar fill."])

    Heading(L["Border"])
    local borderColor = BarSetting("borderColor", "string", L["Border Color"], false, true)
    AddControl(LSMC:CreateBorderDropdown(barCategory,
        BarSetting("borderTexture", "string", L["Border Texture"]),
        L["Timer bar border texture."],
        borderColor))
    ColorControl(borderColor, L["Timer bar border color."])

    Heading(L["Text"])
    local fontSize = BarSetting("fontSize", "number", L["Font Size"])
    local fontColor = BarSetting("fontColor", "string", L["Font Color"], false, true)
    local fontOutline = BarSetting("fontOutline", "string", L["Font Outline"])
    AddControl(LSMC:CreateFontDropdown(barCategory, BarSetting("fontName", "string", L["Font"]),
        L["Timer bar font."],
        fontSize, fontColor, fontOutline))
    layout:AddInitializer(AddControl(Settings.CreateControlInitializer("OnFlightSettingsFontSizeTemplate", fontSize,
        nil,
        L["Timer bar font size."])))
    ColorControl(fontColor, L["Timer bar text color."])
    AddControl(Settings.CreateDropdown(barCategory, fontOutline, function()
        local options = Settings.CreateControlTextContainer()
        options:Add("", L["None"])
        options:Add("OUTLINE", L["Outline"])
        options:Add("THICKOUTLINE", L["Thick Outline"])
        return options:GetData()
    end, L["Timer bar text outline."]))
    Heading(L["Preview and Reset"])
    Button(L["Preview Known Flight"], function()
        bar:TogglePreview(false)
    end,
        L["Shows a five-minute countdown with sample locations.\n/onflight test known"])
    Button(L["Preview Unknown Flight"], function()
        bar:TogglePreview(true)
    end,
        L["Shows an elapsed-time display with sample locations.\n/onflight test unknown"])
    Button(L["Hide Timer Bar"], function()
        bar:StopTimerBar()
    end, L["Hide the timer bar.\n/onflight test stop stops only the preview."])
    Button(L["Reset Bar Settings"], function() self:ResetBarSettings() end,
        L["Reset this profile's bar appearance and position."])
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, L["Profiles"], category:GetID(), "profiles")
    self:CreateGossipSettings(category, Register)
    self:RefreshGossipEditor()
    self:ApplyFlightDisplay()
    self:RefreshSettings()
end
