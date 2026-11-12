--[[
MIT License

Copyright (c) 2026 Orionshock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- Native Settings media selectors for WoW Forever. Full API and examples: README.md.
-- Load after LibStub, LibSharedMedia-3.0, and Blizzard Settings. Construct once
-- per selector in a vertical-layout category; returns an initializer already added
-- to its layout. The addon owns Settings objects, persistence, and applying values.
-- Primary settings store LSM names. Use SetValue() for notifications. Companions
-- update selected previews live; reopen menus to refresh all rows. The library owns
-- the initializer lifecycle and option/selection handlers; do not replace them.
local MAJOR, MINOR = "LibSharedMediaControls-1.0", 14
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local media = LibStub("LibSharedMedia-3.0")

--- Font names themselves preview the chosen font.
-- CreateFontDropdown(category, setting, tooltip[, sizeSetting, colorSetting, outlineSetting])
-- setting: string Settings object holding an LSM "font" name; tooltip: string or nil.
-- Optional Settings companions: number size (default 14), AARRGGBB string color
-- (default white), string outline ("", "OUTLINE", "THICKOUTLINE"; default "").
-- Preview-only size limits: menu 8-32, selected 8-18. Fonts are assumed usable.
-- Returns the native initializer. Selecting a font writes only the primary setting.
function lib:CreateFontDropdown(category, setting, tooltip, sizeSetting, colorSetting, outlineSetting)
    local function NewPreviewFont()
        lib.fontSerial = (lib.fontSerial or 0) + 1
        return CreateFont("LibSharedMediaControlsPreviewFont" .. lib.fontSerial)
    end
    assert(setting and setting:GetVariableType() == "string", "Font settings must store a media name")
    if sizeSetting then assert(sizeSetting:GetVariableType() == "number", "Font size must be numeric") end
    if colorSetting then assert(colorSetting:GetVariableType() == "string", "Font color must be AARRGGBB") end
    if outlineSetting then assert(outlineSetting:GetVariableType() == "string", "Font outline must be a string") end

    local menuFonts = {}
    local selectedFont = NewPreviewFont()
    local function PreviewName(name)
        if colorSetting then
            -- Inline color survives native hover/selection SetTextColor calls.
            return CreateColorFromHexString(colorSetting:GetValue()):WrapTextInColorCode(name)
        end
        return name
    end
    local function UpdateSample(sample, name, maxSize, fontObject)
        local size = sizeSetting and sizeSetting:GetValue() or 14
        size = math.max(8, math.min(maxSize, size))
        local outline = outlineSetting and outlineSetting:GetValue() or ""
        if outline ~= "OUTLINE" and outline ~= "THICKOUTLINE" then outline = "" end
        -- Compositor FontStrings prohibit SetFont; SetFontObject is supported.
        local path = media:Fetch("font", name)
        if path then
            fontObject:SetFont(path, size, outline)
            sample:SetFontObject(fontObject)
        else
            -- No registered/default font: keep the saved name visible in native text.
            sample:SetFontObject("GameFontHighlight")
        end
        sample:SetText(PreviewName(name))
        sample:SetTextColor(1, 1, 1, 1)
    end

    local initializer = Settings.CreateDropdown(category, setting, function() return {} end, tooltip)
    initializer.data.forceSteppersHidden = true
    local activeSample, savedFont, savedColor
    local function RefreshSample()
        if activeSample then UpdateSample(activeSample, setting:GetValue(), 18, selectedFont) end
    end

    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        RefreshSample()
        for _, name in ipairs(media:List("font")) do
            -- Reuse font objects on reopening; refetch their paths in UpdateSample.
            menuFonts[name] = menuFonts[name] or NewPreviewFont()
            local entry = Settings.CreateDropdownButton(rootDescription,
                {value = name, label = name, text = name},
                function(data) return setting:GetValue() == data.value end,
                function(data) setting:SetValue(data.value) end)
            entry:AddInitializer(function(button)
                local text = button.Text
                UpdateSample(text, name, 32, menuFonts[name])
                local width = math.min(400, text:GetUnboundedStringWidth())
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(width)
                return math.max(220, width + 28), 40
            end)
        end
    end

    local initFrame, resetter = initializer.InitFrame, initializer.Resetter
    initializer.InitFrame = function(owner, frame)
        assert(not activeSample, "Create a separate font initializer for each Settings row")
        local dropdown = frame.Control.Dropdown
        activeSample = dropdown.Text
        savedFont = activeSample:GetFontObject()
        savedColor = {activeSample:GetTextColor()}
        RefreshSample()
        initFrame(owner, frame)
        for _, companion in pairs({sizeSetting, colorSetting, outlineSetting}) do
            frame.cbrHandles:SetOnValueChangedCallback(companion:GetVariable(), RefreshSample)
        end
    end
    initializer.Resetter = function(owner, frame)
        local text = frame.Control.Dropdown.Text
        text:SetFontObject(savedFont)
        text:SetTextColor(unpack(savedColor))
        activeSample, savedFont, savedColor = nil, nil, nil
        resetter(owner, frame)
    end
    initializer.getSelectionTextFunc = function()
        RefreshSample()
        return PreviewName(setting:GetValue())
    end
    return initializer
end

--- CreateStatusbarDropdown(category, setting, tooltip[, colorSetting])
-- Native string setting stores an LSM "statusbar" name. Optional color companion
-- stores AARRGGBB. Preview RGB is dimmed to 45%; alpha is unchanged. Default: gray.
-- Returns the registered native initializer; only the primary setting is written.
function lib:CreateStatusbarDropdown(category, setting, tooltip, colorSetting)
    assert(setting and setting:GetVariableType() == "string", "Status-bar settings must store a media name")
    if colorSetting then
        assert(colorSetting:GetVariableType() == "string", "Color settings must store an AARRGGBB string")
    end

    local function TintPreview(preview)
        local r, g, b, a = 1, 1, 1, 1
        if colorSetting then
            r, g, b, a = CreateColorFromHexString(colorSetting:GetValue()):GetRGBA()
        end
        preview:SetVertexColor(r * 0.45, g * 0.45, b * 0.45, a)
    end

    local initializer = Settings.CreateDropdown(category, setting, function() return {} end, tooltip)
    initializer.data.forceSteppersHidden = true

    local function IsSelected(name)
        return setting:GetValue() == name
    end

    local function SetSelected(name)
        setting:SetValue(name)
    end

    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        -- List is LSM's maintained, sorted list; never retain or mutate it.
        for _, name in ipairs(media:List("statusbar")) do
            local option = {value = name, label = name, text = name}
            local entry = Settings.CreateDropdownButton(rootDescription, option,
                function(data) return IsSelected(data.value) end,
                function(data) SetSelected(data.value) end)

            entry:AddInitializer(function(button)
                -- Compositor attachments are reset and released by Blizzard.
                -- Fetch here so reused rows always receive the current texture.
                local preview = button:AttachTexture()
                preview:SetDrawLayer("BACKGROUND", -1)
                preview:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -2)
                preview:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 2)
                preview:SetTexture(media:Fetch("statusbar", name))
                TintPreview(preview)

                local text = button.Text
                local textWidth = math.min(400, text:GetUnboundedStringWidth())
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(textWidth)
                text:SetShadowColor(0, 0, 0, 1)
                text:SetShadowOffset(1, -1)
                return math.max(220, textWidth + 28), 24
            end)
        end
    end

    local activePreview
    local initFrame = initializer.InitFrame
    local resetter = initializer.Resetter

    -- Use the initializer lifecycle so artwork is hidden before a pooled
    -- Settings row is handed to another setting, including a stock dropdown.
    initializer.InitFrame = function(owner, frame)
        assert(not activePreview, "Create a separate status-bar initializer for each Settings row")
        local dropdown = frame.Control.Dropdown
        if not dropdown.LSMCStatusbarPreview then
            local preview = dropdown:CreateTexture(nil, "ARTWORK")
            preview:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 4, -4)
            preview:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -4, 4)
            dropdown.LSMCStatusbarPreview = preview
        end
        activePreview = dropdown.LSMCStatusbarPreview
        activePreview:SetTexture(media:Fetch("statusbar", setting:GetValue(), true))
        TintPreview(activePreview)
        activePreview:Show()
        initFrame(owner, frame)
        if colorSetting then
            -- The native control unregisters these handles on Release().
            frame.cbrHandles:SetOnValueChangedCallback(colorSetting:GetVariable(), function()
                if activePreview then
                    TintPreview(activePreview)
                end
            end)
        end
    end

    initializer.Resetter = function(owner, frame)
        frame.Control.Dropdown.LSMCStatusbarPreview:Hide()
        activePreview = nil
        resetter(owner, frame)
    end

    initializer.getSelectionTextFunc = function()
        local name = setting:GetValue()
        if activePreview then
            activePreview:SetTexture(media:Fetch("statusbar", name, true))
            TintPreview(activePreview)
        end
        -- Preserve missing names rather than silently changing the setting.
        return name
    end

    return initializer
end

--- CreateBackgroundDropdown(category, setting, tooltip[, colorSetting])
-- category: native vertical-layout category; setting: string Settings object
-- holding an LSM "background" name; tooltip: string or nil. Optional colorSetting
-- is a native AARRGGBB string setting. Omit it for original texture colors;
-- otherwise RGBA tints the ordinary texture without dimming, tiling, or a backdrop.
-- Returns the initializer already added to the layout. Selection writes only the
-- primary setting. The addon owns persistence, color controls, and applying values.
-- Selected tint updates live; reopen menus for new media and current entry tints.
-- Hover previews fill the menu behind all labels without selecting the entry.
-- Opening starts with the selected texture; the last hover remains until close.
-- "None" clears the artwork. Menu artwork belongs to Blizzard's compositor.
function lib:CreateBackgroundDropdown(category, setting, tooltip, colorSetting)
    assert(setting and setting:GetVariableType() == "string", "Background settings must store a media name")
    if colorSetting then
        assert(colorSetting:GetVariableType() == "string", "Color settings must store an AARRGGBB string")
    end

    local function TintPreview(preview)
        local r, g, b, a = 1, 1, 1, 1
        if colorSetting then
            r, g, b, a = CreateColorFromHexString(colorSetting:GetValue()):GetRGBA()
        end
        preview:SetVertexColor(r, g, b, a)
    end

    local initializer = Settings.CreateDropdown(category, setting, function() return {} end, tooltip)
    initializer.data.forceSteppersHidden = true

    local function IsSelected(name)
        return setting:GetValue() == name
    end

    local function SetSelected(name)
        setting:SetValue(name)
    end

    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        local menuPreview
        rootDescription:AddMenuAcquiredCallback(function(menu)
            menuPreview = menu:AttachTexture()
            menuPreview:SetDrawLayer("ARTWORK", 7)
            menuPreview:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -6)
            menuPreview:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -3, 7)
            menuPreview:SetTexture(media:Fetch("background", setting:GetValue(), true))
            TintPreview(menuPreview)
        end)
        rootDescription:AddMenuReleasedCallback(function()
            menuPreview = nil
        end)
        -- List is LSM's maintained, sorted list; never retain or mutate it.
        for _, name in ipairs(media:List("background")) do
            local option = {value = name, label = name, text = name}
            option.onEnter = function()
                if menuPreview then
                    menuPreview:SetTexture(media:Fetch("background", name))
                    TintPreview(menuPreview)
                end
            end
            local entry = Settings.CreateDropdownButton(rootDescription, option,
                function(data) return IsSelected(data.value) end,
                function(data) SetSelected(data.value) end)

            entry:AddInitializer(function(button)
                local text = button.Text
                local textWidth = math.min(400, text:GetUnboundedStringWidth())
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(textWidth)
                text:SetShadowColor(0, 0, 0, 1)
                text:SetShadowOffset(1, -1)
                return math.max(220, textWidth + 28), 24
            end)
        end
    end

    local activePreview
    local initFrame = initializer.InitFrame
    local resetter = initializer.Resetter

    -- Use the initializer lifecycle so artwork is hidden before a pooled
    -- Settings row is handed to another setting, including a stock dropdown.
    initializer.InitFrame = function(owner, frame)
        assert(not activePreview, "Create a separate background initializer for each Settings row")
        local dropdown = frame.Control.Dropdown
        if not dropdown.LSMCBackgroundPreview then
            local preview = dropdown:CreateTexture(nil, "ARTWORK")
            preview:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 4, -4)
            preview:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -4, 4)
            dropdown.LSMCBackgroundPreview = preview
        end
        activePreview = dropdown.LSMCBackgroundPreview
        activePreview:SetTexture(media:Fetch("background", setting:GetValue(), true))
        TintPreview(activePreview)
        activePreview:Show()
        initFrame(owner, frame)
        if colorSetting then
            -- The native control unregisters these handles on Release().
            frame.cbrHandles:SetOnValueChangedCallback(colorSetting:GetVariable(), function()
                if activePreview then
                    TintPreview(activePreview)
                end
            end)
        end
    end

    initializer.Resetter = function(owner, frame)
        frame.Control.Dropdown.LSMCBackgroundPreview:Hide()
        activePreview = nil
        resetter(owner, frame)
    end

    initializer.getSelectionTextFunc = function()
        local name = setting:GetValue()
        if activePreview then
            activePreview:SetTexture(media:Fetch("background", name, true))
            TintPreview(activePreview)
        end
        -- Preserve missing names rather than silently changing the setting.
        return name
    end

    return initializer
end

--- CreateBorderDropdown(category, setting, tooltip[, colorSetting, edgeSizeSetting])
-- Native string setting holds an LSM "border" name; optional companions are
-- AARRGGBB color (default white) and numeric edge size (default 8).
-- Menu edge size is limited to 1-32; selected control to 1-8, for its short height.
-- Hover changes only the menu preview; selection writes the primary setting.
-- Returns the registered initializer. Selected companions refresh live; menu
-- opening starts with the current selection. "None" clears the preview border.
function lib:CreateBorderDropdown(category, setting, tooltip, colorSetting, edgeSizeSetting)
    assert(setting and setting:GetVariableType() == "string", "Border settings must store a media name")
    if colorSetting then assert(colorSetting:GetVariableType() == "string", "Border color must be AARRGGBB") end
    if edgeSizeSetting then
        assert(edgeSizeSetting:GetVariableType() == "number", "Border edge size must be numeric")
    end

    local function UpdateBorder(preview, name, maxEdge)
        local size = edgeSizeSetting and edgeSizeSetting:GetValue() or 8
        size = math.max(1, math.min(maxEdge, size))
        local path = media:Fetch("border", name)
        -- A fresh backdrop table reapplies size even when the media is unchanged.
        preview:SetBackdrop(path and {edgeFile = path, edgeSize = size} or nil)
        local r, g, b, a = 1, 1, 1, 1
        if colorSetting then
            r, g, b, a = CreateColorFromHexString(colorSetting:GetValue()):GetRGBA()
        end
        preview:SetBackdropBorderColor(r, g, b, a)
    end

    local initializer = Settings.CreateDropdown(category, setting, function() return {} end, tooltip)
    initializer.data.forceSteppersHidden = true
    local activePreview
    local function RefreshSelected()
        if activePreview then UpdateBorder(activePreview, setting:GetValue(), 8) end
    end

    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        local menuPreview
        rootDescription:AddMenuAcquiredCallback(function(menu)
            -- AttachTemplate permits the backdrop mixin to create its own pieces;
            -- AttachFrame's compositor restrictions would prohibit CreateTexture.
            menuPreview = menu:AttachTemplate("BackdropTemplate")
            menuPreview:ClearBackdrop()
            menuPreview:ClearAllPoints()
            menuPreview:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -8)
            menuPreview:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -6, 9)
            menuPreview:SetFrameLevel(menu:GetFrameLevel() + 1)
            menuPreview:EnableMouse(false)
            -- Template scripts are not restored automatically after pool reset.
            menuPreview:SetScript("OnSizeChanged", menuPreview.OnBackdropSizeChanged)
            UpdateBorder(menuPreview, setting:GetValue(), 32)
            menuPreview:Show()
        end)
        rootDescription:AddMenuReleasedCallback(function()
            if menuPreview then
                menuPreview:ClearBackdrop()
                menuPreview:SetScript("OnSizeChanged", nil)
                menuPreview:Hide()
                menuPreview = nil
            end
        end)
        for _, name in ipairs(media:List("border")) do
            local option = {value = name, label = name, text = name}
            option.onEnter = function()
                if menuPreview then UpdateBorder(menuPreview, name, 32) end
            end
            local entry = Settings.CreateDropdownButton(rootDescription, option,
                function(data) return setting:GetValue() == data.value end,
                function(data) setting:SetValue(data.value) end)
            entry:AddInitializer(function(button)
                local text = button.Text
                local width = math.min(400, text:GetUnboundedStringWidth())
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(width)
                text:SetShadowColor(0, 0, 0, 1)
                text:SetShadowOffset(1, -1)
                return math.max(220, width + 28), 24
            end)
        end
    end

    local initFrame, resetter = initializer.InitFrame, initializer.Resetter
    initializer.InitFrame = function(owner, frame)
        assert(not activePreview, "Create a separate border initializer for each Settings row")
        local dropdown = frame.Control.Dropdown
        if not dropdown.LSMCBorderPreview then
            local preview = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
            preview:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 3, -3)
            preview:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -3, 3)
            preview:SetFrameLevel(dropdown:GetFrameLevel())
            preview:EnableMouse(false)
            dropdown.LSMCBorderPreview = preview
        end
        activePreview = dropdown.LSMCBorderPreview
        RefreshSelected()
        activePreview:Show()
        initFrame(owner, frame)
        for _, companion in pairs({colorSetting, edgeSizeSetting}) do
            frame.cbrHandles:SetOnValueChangedCallback(companion:GetVariable(), RefreshSelected)
        end
    end
    initializer.Resetter = function(owner, frame)
        local preview = frame.Control.Dropdown.LSMCBorderPreview
        preview:ClearBackdrop()
        preview:Hide()
        activePreview = nil
        resetter(owner, frame)
    end
    initializer.getSelectionTextFunc = function()
        RefreshSelected()
        return setting:GetValue()
    end
    return initializer
end

--- CreateSoundDropdown(category, setting, tooltip[, channelSetting])
-- Primary string setting stores an LSM "sound" name. Optional string companion
-- supplies Master/SFX/Music/Ambience/Dialog at click time; default SFX.
-- Speaker clicks preview only; radio clicks select without previewing.
-- A speaker beside the closed dropdown previews its current selection.
-- One preview at a time, stopped on menu release or control hide. "None" is silent.
-- Returns the initializer already added to the native category layout.
function lib:CreateSoundDropdown(category, setting, tooltip, channelSetting)
    assert(setting and setting:GetVariableType() == "string", "Sound settings must store a media name")
    if channelSetting then
        assert(channelSetting:GetVariableType() == "string", "Sound channel must be a string")
    end

    local soundHandle
    local function StopPreview()
        if soundHandle then
            StopSound(soundHandle)
            soundHandle = nil
        end
    end
    local function PlayPreview(name)
        StopPreview()
        local file = media:Fetch("sound", name)
        -- LSM's "None" uses file ID 1.
        if not file or file == 1 then return end
        local channel = channelSetting and channelSetting:GetValue() or "SFX"
        local played, handle = PlaySoundFile(file, channel)
        if played then soundHandle = handle end
    end

    local initializer = Settings.CreateDropdown(category, setting, function() return {} end, tooltip)
    initializer.data.forceSteppersHidden = true
    initializer.customOptionHandler = function(rootDescription)
        rootDescription:SetScrollMode(400)
        rootDescription:AddMenuReleasedCallback(StopPreview)

        for _, name in ipairs(media:List("sound")) do
            local entry = Settings.CreateDropdownButton(rootDescription,
                {value = name, label = name, text = name},
                function(data) return setting:GetValue() == data.value end,
                function(data) setting:SetValue(data.value) end)
            entry:AddInitializer(function(button)
                local text = button.Text
                local width = math.min(400, text:GetUnboundedStringWidth())
                text:ClearAllPoints()
                text:SetPoint("LEFT", button, "LEFT", 14, 0)
                text:SetWidth(width)

                local play = MenuTemplates.AttachBasicButton(button, 20, 20)
                play:SetPoint("RIGHT", button, "RIGHT", -6, 0)
                play:SetPropagateMouseClicks(false)
                play:RegisterForClicks("LeftButtonUp")
                local icon = play:AttachTexture()
                icon:SetAllPoints(play)
                icon:SetTexture([[Interface\Common\VoiceChat-Speaker]])
                play:SetNormalTexture(icon)
                local highlight = play:AttachTexture()
                highlight:SetAllPoints(play)
                highlight:SetTexture([[Interface\Common\VoiceChat-On]])
                play:SetHighlightTexture(highlight)
                MenuTemplates.SetUtilityButtonClickHandler(play, function()
                    PlayPreview(name)
                end)
                MenuTemplates.SetUtilityButtonTooltipText(play, "Preview sound")
                return math.max(220, width + 52), 24
            end)
        end
    end
    local initialized
    local initFrame, resetter = initializer.InitFrame, initializer.Resetter
    initializer.InitFrame = function(owner, frame)
        assert(not initialized, "Create a separate sound initializer for each Settings row")
        initialized = true
        initFrame(owner, frame)
        local control = frame.Control
        if not control.LSMCSoundPreview then
            local play = CreateFrame("Button", nil, control)
            play:SetSize(20, 20)
            play:SetPoint("LEFT", control.Dropdown, "RIGHT", 6, 0)
            play:SetNormalTexture([[Interface\Common\VoiceChat-Speaker]])
            play:SetHighlightTexture([[Interface\Common\VoiceChat-On]])
            play:RegisterForClicks("LeftButtonUp")
            play:SetPropagateMouseClicks(false)
            MenuTemplates.SetUtilityButtonTooltipText(play, "Preview selected sound")
            control.LSMCSoundPreview = play
        end
        local play = control.LSMCSoundPreview
        play:SetScript("OnClick", function() PlayPreview(setting:GetValue()) end)
        play:SetScript("OnHide", StopPreview)
        play:Show()
    end
    initializer.Resetter = function(owner, frame)
        local play = frame.Control.LSMCSoundPreview
        StopPreview()
        play:SetScript("OnClick", nil)
        play:SetScript("OnHide", nil)
        play:Hide()
        initialized = nil
        resetter(owner, frame)
    end
    initializer.getSelectionTextFunc = function()
        return setting:GetValue()
    end
    return initializer
end
