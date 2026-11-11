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
local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3", true)
local statusBarModuleCore = addonCore:GetModule("StatusBarModule")
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
            if key == "StatusBarModule" then
                Notify(settings.flightDisplay)
                Notify(settings.bar_compactMode)
            end
        end
    end
end

function addonCore:GetFlightDisplay()
    local profile = self.db.profile
    -- Keep the existing bar preference until a display is explicitly selected.
    local display = profile.flightDisplay or (profile.moduleState.StatusBarModule and "builtin" or "none")
    return display == "quartz" and not Quartz3 and "builtin" or display
end

function addonCore:ApplyFlightDisplay()
    local display = self:GetFlightDisplay()
    local bar = self:GetModule("StatusBarModule")
    local enabled = display == "builtin"
    self.db.profile.moduleState.StatusBarModule = enabled
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
    self:RefreshSettings("StatusBarModule")
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
    self:SendMessage("OnFlight_DiagnosticsChanged")
end

function addonCore:ResetBarSettings()
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
    local showUnknown = Register(category, "showUnknownFlightPoints", "boolean", L["Show Unknown Flight Points"], false,
        function() return self.db.profile.showUnknownFlightPoints end,
        function(value) self.db.profile.showUnknownFlightPoints = value end)
    Settings.CreateCheckbox(category, showUnknown,
        L["Show unreachable flight points in the destination browser and mark their locations in red on the flight map. These destinations cannot be selected."])
    local worldMaps = Register(category, "useWorldMapFlightMaps", "boolean",
        L["Use World Map Style Flight Maps"], true,
        function() return self.db.profile.useWorldMapFlightMaps end,
        function(value) self.db.profile.useWorldMapFlightMaps = value end)
    Settings.CreateCheckbox(category, worldMaps,
        L["Use detailed continent artwork on the flight map instead of Blizzard's simplified taxi-map background."])
    local minimap = Register(category, "showMinimapButton", "boolean", L["Show Minimap Button"], true, function()
        return not self.db.profile.minimap.hide
    end, function(value)
        self.db.profile.minimap.hide = not value
        self:GetModule("LDBLauncher"):RefreshMinimapIcon()
    end)
    Settings.CreateCheckbox(category, minimap,
        L["Shows the OnFlight minimap launcher. Left-click to resend your flight; right-click to open settings. Drag to move it."])
    local bar = self:GetModule("StatusBarModule")
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
                L["Shows known flights on Quartz's Player bar and disables Quartz's original Flight module."])
        end
        return options:GetData()
    end, L["Choose a flight timer display. Quartz is available when installed. None hides OnFlight's timer bars; flight tracking, learning, and the broker display continue."])
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
    Button(L["Reset Bar Settings"], function() self:ResetBarSettings() end,
        L["Restores the current profile's timer-bar appearance and position defaults. Other OnFlight settings and learned flight times stay unchanged."])
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, L["Profiles"], category:GetID(), "profiles")
    self:CreateGossipSettings(category, Register)
    self:RefreshGossipEditor()
    self:ApplyFlightDisplay()
    self:RefreshSettings()
end
