--luacheck: no max line length
--luacheck: globals LibStub Settings SettingsPanel HideUIPanel CreateColor CreateColorFromHexString
--luacheck: globals CreateFrame CreateFromMixins SettingsControlMixin SettingsListElementMixin
--luacheck: globals SettingsColorSwatchControlMixin MinimalSliderWithSteppersMixin
--luacheck: globals CreateSettingsListSectionHeaderInitializer CreateSettingsButtonInitializer
--luacheck: globals OnFlightSettingsFontSizeMixin OnFlightSettingsColorMixin
--luacheck: globals GameTooltip GameTooltip_Hide
local addonName, addonCore = ...
local LSM = LibStub("LibSharedMedia-3.0")
local settings = {}
local gossipPage, diagnosticSetting

local function Register(category, key, kind, name, default, get, set)
    local setting = Settings.RegisterProxySetting(category, addonName .. "_" .. key,
        kind, name, default, get, set)
    settings[#settings + 1] = setting
    return setting
end

function addonCore:RefreshSettings()
    for _, setting in ipairs(settings) do setting:NotifyUpdate() end
end

function addonCore:OpenSettings()
    Settings.OpenToCategory(self.settingsCategory:GetID())
end

function addonCore:ToggleSettings()
    local category = SettingsPanel:GetCurrentCategory()
    if SettingsPanel:IsShown() and category
        and (category == self.settingsCategory or category:GetParentCategory() == self.settingsCategory) then
        HideUIPanel(SettingsPanel)
        local browser = self:GetModule("NativeFlightListWindow")
        if browser:IsEnabled() and self:GetTaxiSession() then browser:Open() end
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
        if userInput then input.dirty = true end
    end)
    local function Commit(input)
        if not input.dirty then return end
        input.dirty = nil
        local value = tonumber(input:GetText())
        if value and value > 0 and value < math.huge then self:GetSetting():SetValue(value) end
        self:SetValue(self:GetSetting():GetValue())
    end
    self.input:SetScript("OnEnterPressed", function(input) Commit(input); input:ClearFocus() end)
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
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
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
    if type(value) == "number" then return tostring(value), addonCore:GetTaxiNodeName(value) end
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
    if not input.dirty then return end
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
    for index, name in ipairs({ "Source", "Destination" }) do
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
            if userInput then self.dirty = true end
        end)
        input:SetScript("OnEnterPressed", function(self) CommitEndpoint(self); self:ClearFocus() end)
        input:SetScript("OnEditFocusLost", CommitEndpoint)
        row[index] = input
    end
    return row
end

function addonCore:RefreshGossipEditor(optionID)
    if not gossipPage then return end
    local ids = {}
    for id in pairs(self.db.global.gossipTriggered) do ids[#ids + 1] = id end
    table.sort(ids)
    for id, row in pairs(gossipPage.rows) do
        if not self.db.global.gossipTriggered[id] then
            -- Do not commit focused inputs after their configuration has been removed.
            for index = 1, 2 do row[index].dirty = nil; row[index]:ClearFocus() end
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
            row.title:SetText("Gossip ID: " .. id)
            if not row.remove then
                row.remove = MakeButton(row, "Remove", 80, function()
                    self.db.global.gossipTriggered[row.optionID] = nil
                    self:RefreshAdvOptions()
                end)
                row.remove:SetPoint("TOPRIGHT", -8, 0)
            end
            gossipPage.rows[id] = row
            for endpoint = 1, 2 do SetEndpointInput(row[endpoint], id, self.db.global.gossipTriggered[id][endpoint]) end
        end
        if optionID == id then
            for endpoint = 1, 2 do SetEndpointInput(row[endpoint], id, self.db.global.gossipTriggered[id][endpoint]) end
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
    local category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, page, "Gossip Configuration")
    local help = "Shows gossip option IDs in NPC dialogue tooltips and taxi-node IDs beside destinations in Flight Destinations. Use these IDs to configure gossip flights."
    diagnosticSetting = Register(category, "showGossipConfig", "boolean", "Show Diagnostic IDs", false,
        function() return addonCore.db.profile.showGossipConfig end,
        function(value)
            addonCore.db.profile.showGossipConfig = value
            addonCore:SendMessage("OnFlight_DiagnosticsChanged")
        end)
    local checkbox = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 12, -8)
    checkbox.Text:SetText("Show Diagnostic IDs")
    checkbox.Text:SetFontObject("GameFontNormal")
    checkbox:SetScript("OnClick", function(self) diagnosticSetting:SetValue(self:GetChecked()) end)
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show Diagnostic IDs")
        GameTooltip:AddLine(help, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)
    diagnosticSetting:SetValueChangedCallback(function(_, value) checkbox:SetChecked(value) end)
    local diagnosticHelp = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    diagnosticHelp:SetPoint("TOPLEFT", 18, -44)
    diagnosticHelp:SetPoint("TOPRIGHT", -20, -44)
    diagnosticHelp:SetJustifyH("LEFT")
    diagnosticHelp:SetText("Enable this while configuring a gossip flight.")
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", diagnosticHelp, "BOTTOMLEFT", 0, -16)
    title:SetPoint("TOPRIGHT", diagnosticHelp, "BOTTOMRIGHT", 0, -16)
    title:SetJustifyH("LEFT")
    title:SetText("Gossip Flights")
    local explanation = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    explanation:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    explanation:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    explanation:SetJustifyH("LEFT")
    explanation:SetText("Configure flights started through NPC dialogue. A Gossip ID identifies the dialogue option that starts a flight.")
    local endpointsTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    endpointsTitle:SetPoint("TOPLEFT", explanation, "BOTTOMLEFT", 0, -14)
    endpointsTitle:SetPoint("TOPRIGHT", explanation, "BOTTOMRIGHT", 0, -14)
    endpointsTitle:SetJustifyH("LEFT")
    endpointsTitle:SetText("Endpoints")
    local endpointsHelp = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    endpointsHelp:SetPoint("TOPLEFT", endpointsTitle, "BOTTOMLEFT", 0, -8)
    endpointsHelp:SetPoint("TOPRIGHT", endpointsTitle, "BOTTOMRIGHT", 0, -8)
    endpointsHelp:SetJustifyH("LEFT")
    endpointsHelp:SetText("Enter a taxi-node ID or a custom location name for Source and Destination. Press Enter or click away to save.")

    local new = CreateGossipRow(page)
    new:SetPoint("TOPLEFT", endpointsHelp, "BOTTOMLEFT", 0, -20)
    new:SetPoint("TOPRIGHT", endpointsHelp, "BOTTOMRIGHT", -8, -20)
    new.title:SetText("New Gossip ID:")
    new.id = MakeInput(new, 95)
    new.id:SetPoint("TOPLEFT", 140, 2)
    new.id:SetNumeric(true)
    new.id:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    new.add = MakeButton(new, "Add", 80, function()
        CommitEndpoint(new[1]); CommitEndpoint(new[2])
        local id = tonumber(new.id:GetText())
        if not id or id <= 0 or id % 1 ~= 0 then
            new[1].feedback:SetText("Enter a Gossip ID from a dialogue tooltip: digits only, greater than zero.")
            return
        end
        if addonCore.db.global.gossipTriggered[id] then
            new[1].feedback:SetText("This Gossip ID already exists. Edit its endpoints below.")
            return
        end
        local source, sourceMessage = addonCore:ParseGossipEndpoint(id, new[1]:GetText())
        local destination, destinationMessage = addonCore:ParseGossipEndpoint(id, new[2]:GetText())
        if not source or not destination then
            if not source then new[1].feedback:SetText(sourceMessage) end
            if not destination then new[2].feedback:SetText(destinationMessage) end
            return
        end
        addonCore.db.global.gossipTriggered[id] = { source, destination }
        new.id:SetText(""); new.id:ClearFocus()
        for index = 1, 2 do
            new[index].dirty = nil
            new[index]:SetText("")
            new[index].feedback:SetText("")
            new[index]:ClearFocus()
        end
        addonCore:RefreshAdvOptions()
    end)
    new.add:SetPoint("TOPRIGHT", -8, 0)

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", new, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", -36, 12)
    page.content = CreateFrame("Frame", nil, scroll)
    page.content:SetSize(1, 1)
    scroll:SetScrollChild(page.content)
    scroll:SetScript("OnSizeChanged", function(_, width) page.content:SetWidth(width) end)
    page.OnRefresh = function()
        checkbox:SetChecked(diagnosticSetting:GetValue())
        addonCore:RefreshGossipEditor()
        for id, row in pairs(page.rows) do
            for index = 1, 2 do SetEndpointInput(row[index], id, addonCore.db.global.gossipTriggered[id][index]) end
        end
    end
    page:SetScript("OnHide", function()
        new.id:ClearFocus()
        for index = 1, 2 do new[index]:ClearFocus() end
        for _, row in pairs(page.rows) do
            for index = 1, 2 do row[index]:ClearFocus() end
        end
    end)
end

function addonCore:InitializeSettings()
    if self.settingsCategory then return end
    local category = Settings.RegisterVerticalLayoutCategory("OnFlight")
    self.settingsCategory = category
    Settings.RegisterAddOnCategory(category)
    local showChat = Register(category, "showChat", "boolean", "Show Chat Messages", true,
        function() return self.db.profile.showChat end,
        function(value) self.db.profile.showChat = value end)
    Settings.CreateCheckbox(category, showChat, "Reports when flights start, resume, finish, or end early. Includes timing information when available.")
    local bar = self:GetModule("StatusBarModule")
    local enabled = Register(category, "StatusBarModule", "boolean", "Enable Flight Timer Bar", true,
        function() return self.db.profile.moduleState.StatusBarModule end,
        function(value) self:SetModuleStatus({ "StatusBarModule" }, value) end)
    local enableControl = Settings.CreateCheckbox(category, enabled,
        "Shows OnFlight's built-in timer bar. Flight tracking and duration learning continue when disabled, and timing data remains available to other displays.")
    local barCategory, layout = Settings.RegisterVerticalLayoutSubcategory(category, "Flight Timer Bar")
    local function AddControl(initializer)
        initializer:SetParentInitializer(enableControl, function() return bar:IsEnabled() end)
        return initializer
    end
    local function BarSetting(key, kind, name, location, color)
        local defaults = location and bar.svDefaults.profile.barLocation or bar.svDefaults.profile
        local default = color and ColorString(defaults[key]) or defaults[key]
        return Register(barCategory, "bar_" .. key, kind, name, default,
            function()
                local profile = location and bar.db.profile.barLocation or bar.db.profile
                if color then return ColorString(profile[key]) end
                return key == "fontSize" and tonumber(profile[key]) or profile[key]
            end,
            function(value)
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
        return AddControl(Settings.CreateDropdown(barCategory,
            BarSetting(key, "string", name, location), getOptions, tooltip))
    end
    local function MediaOptions(kind)
        return function()
            local options = Settings.CreateControlTextContainer()
            for _, name in ipairs(LSM:List(kind)) do options:Add(name, name) end
            return options:GetData()
        end
    end
    local function Button(name, action, tooltip)
        layout:AddInitializer(AddControl(CreateSettingsButtonInitializer(name, name, action, tooltip, true)))
    end
    Heading("Layout and Position")
    local function Anchors()
        local options = Settings.CreateControlTextContainer()
        for _, anchor in ipairs({ "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }) do
            options:Add(anchor, anchor)
        end
        return options:GetData()
    end
    Dropdown("anchorPoint", "Bar Anchor", Anchors, true,
        "Point on the timer bar attached to the Relative Anchor.")
    Dropdown("relativePoint", "Relative Anchor", Anchors, true,
        "Point on the screen's main UI frame (UIParent) that the bar attaches to. TOP for both anchors aligns their top centers before offsets.")
    Slider("offsetX", "Horizontal Offset", -1000, 1000, 1, true,
        "Moves the bar from its anchor position. Positive values move right; negative values move left.")
    Slider("offsetY", "Vertical Offset", -1000, 1000, 1, true,
        "Moves the bar from its anchor position. Positive values move up; negative values move down.")
    Slider("barWidth", "Minimum Width", 10, 1000, 10, false,
        "The bar grows wider when needed to fit its text. This sets its minimum width.")
    Slider("barHeight", "Height", 10, 300, 1, false,
        "Vertical size of the timer bar, including its border.")
    Heading("Display")
    local compact = AddControl(Settings.CreateCheckbox(barCategory, BarSetting("compactMode", "boolean", "Compact Mode"),
        "Shows only the remaining time for flights with a known duration. Unknown flights still show location names and elapsed time."))
    local short = AddControl(Settings.CreateCheckbox(barCategory, BarSetting("shortNames", "boolean", "Short Destination Names"),
        "Omits zone suffixes from source and destination names. Unavailable in Compact Mode because known flights show only the timer."))
    short:SetParentInitializer(compact, function() return not bar.db.profile.compactMode end)
    Heading("Appearance")
    Dropdown("barTexture", "Bar Texture", MediaOptions("statusbar"), false,
        "Artwork used for the bar fill and background. Choices come from LibSharedMedia and may include textures supplied by other addons.")
    Dropdown("borderTexture", "Border Texture", MediaOptions("border"), false,
        "Artwork around the edge of the timer bar. Choices come from LibSharedMedia and may include borders supplied by other addons.")
    Dropdown("fontName", "Font", MediaOptions("font"), false,
        "Typeface for location names and the timer. Choices come from LibSharedMedia and may include fonts supplied by other addons.")
    local fontSize = BarSetting("fontSize", "number", "Font Size")
    layout:AddInitializer(AddControl(Settings.CreateControlInitializer("OnFlightSettingsFontSizeTemplate", fontSize, nil,
        "Size of the location names and timer text. Enter a positive number, then press Enter or click away to apply.")))
    for _, entry in ipairs({
        { "backgroundColor", "Background Color", "Color behind the bar fill. Keeps the current transparency." },
        { "barColor", "Known Flight Color", "Bar fill used for the countdown when OnFlight has a measured flight duration." },
        { "unknownFlightColor", "Unknown Flight Color", "Bar fill used when no measured duration is saved for the flight's source and destination. The timer shows elapsed time instead of time remaining." },
        { "borderColor", "Border Color", "Color of the frame edge. Choose its artwork with Border Texture." },
        { "fontColor", "Font Color", "Color shared by location names and the timer text." },
    }) do
        local setting = BarSetting(entry[1], "string", entry[2], false, true)
        layout:AddInitializer(AddControl(Settings.CreateControlInitializer("OnFlightSettingsColorTemplate", setting, nil, entry[3])))
    end
    Heading("Preview and Reset")
    Button("Preview Known Flight", function() bar:StartTimerBar("City1, Zone1", "City2, Zone2", 300) end,
        "Shows a five-minute countdown with sample locations. Previews leave your travel and learned flight times unchanged.")
    Button("Preview Unknown Flight", function() bar:StartTimerBar("Unknown1, Zone1", "Unknown2, Zone2", nil, nil, true) end,
        "Shows an elapsed-time display with sample locations. Previews leave your travel and learned flight times unchanged.")
    Button("Hide Timer Bar", function() bar:StopTimerBar() end,
        "Hides the preview or current flight display. Flight tracking and duration learning continue.")
    Button("Reset Bar Settings", function() bar.db:ResetProfile(true) end,
        "Restores the current profile's timer-bar appearance and position defaults. Other OnFlight settings and learned flight times stay unchanged.")
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "Profiles", category:GetID(), "profiles")
    CreateGossipPage(category)
    self:RefreshAdvOptions()
    self:RefreshSettings()
end
