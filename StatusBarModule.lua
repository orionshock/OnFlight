--[[
    This Module's Entire Job is to handle the Status Bar
]]
local addonName, addonCore = ...
local moduleName = "StatusBarModule"
local statusBarModuleCore = addonCore:NewModule(moduleName, "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LSM = LibStub("LibSharedMedia-3.0")

local db
local svDefaults = {
    profile = {
        --Basic Bar Options
        countUp = false,
        fillUp = false,
        --Bar Background Color
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.6 },
        --Bar Size Settings
        barHeight = 30,
        barWidth = 300,
        --Bar Settings
        barTexture = "Blizzard",
        barColor = { r = 0.5, g = 0.5, b = 0.8, a = 1.0 },
        unknownFlightColor = { r = 0.2, g = 0.2, b = 0.4, a = 1.0 },
        --Border Settings
        borderTexture = "Blizzard Dialog",
        borderColor = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
        --Basic Text Options
        compactMode = false,
        shortNames = true,
        --Font Options
        fontName = "2002 Bold",
        fontSize = 15,
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        --Bar Location
        barLocation = {
            offsetX = 0,
            offsetY = -170,
            anchorPoint = "TOP",
            relativePoint = "TOP"
        }
    }
}
statusBarModuleCore.svDefaults = svDefaults

function statusBarModuleCore:OnInitialize()
    self.db = addonCore.db:RegisterNamespace(moduleName, svDefaults)
    db = self.db
    self:SetEnabledState(addonCore.db.profile.moduleState[moduleName])

    db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdated")
    db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdated")
    db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdated")
end

function statusBarModuleCore:OnEnable()
    if not self.OnFlightTimerFrame then
        self:SetupTimerBar()
    end
    self:RegisterMessage("OnFlight_Taxi_Start")
    self:RegisterMessage("OnFlight_Taxi_Stop")
    self:RegisterMessage("OnFlight_Taxi_EarlyExit", "OnFlight_Taxi_Stop")
    self:RegisterMessage("OnFlight_Taxi_FAILED_ENTRY", "OnFlight_Taxi_Stop")
    self:RegisterMessage("OnFlight_Taxi_RESUME")
    self:RegisterMessage("OnFlight_Taxi_Suspend", function()
        self.OnFlightTimerFrame:Hide()
    end)
    self:ShowCurrentFlight()
end

function statusBarModuleCore:OnDisable()
    self:UnregisterAllMessages()
    self:StopTimerBar("Module disabled")
end

-- Rebuild presentation from the core if enabled after a lifecycle notification.
function statusBarModuleCore:ShowCurrentFlight()
    local current = addonCore:GetCurrentFlight()
    local elapsed, remaining, duration = addonCore:GetCurrentFlightProgress()
    if not current or elapsed == nil then return end
    self:StartTimerBar(current.sourceName, current.destinationName, duration, remaining, not duration, true)
end

function statusBarModuleCore:OnFlight_Taxi_Start(event, taxiSrcName, taxiDestName, taxiDuration, unknownFlight)
    if taxiDuration ~= 0 then
        self:StartTimerBar(taxiSrcName, taxiDestName, taxiDuration, nil, nil, true)
    elseif unknownFlight then
        self:StartTimerBar(taxiSrcName, taxiDestName, nil, nil, unknownFlight, true)
    end
end

function statusBarModuleCore:OnFlight_Taxi_Stop(event, ...)
    self:StopTimerBar(event)
end

function statusBarModuleCore:OnFlight_Taxi_RESUME(event, taxiSrcName, taxiDestName, taxiDuration, timeRemaining,
                                                  unknownFlight, timeOnFlight)
    self:StartTimerBar(taxiSrcName, taxiDestName, taxiDuration, timeRemaining, unknownFlight, true)
end

local function disp_time(time)
    local minutes = floor(mod(time, 3600) / 60)
    local seconds = floor(mod(time, 60))
    return format("%d:%02d", minutes, seconds)
end

local function timerBarOnUpdate(self, elapsed)
    local timeOnFlight
    if self.isFlightDisplay then
        -- These are render values, not a second clock or authoritative flight state.
        timeOnFlight, self.timeRemaining, self.duration = addonCore:GetCurrentFlightProgress()
        if timeOnFlight == nil then
            statusBarModuleCore:StopTimerBar("No active flight progress")
            return
        end
        local current = addonCore:GetCurrentFlight()
        if self.timeRemaining and current.resumeRemaining then
            self.timeRemaining = current.resumeRemaining - timeOnFlight
        end
    end
    local profile = db.profile
    local displayedTime
    if self.unknownFlight then
        if not self.isFlightDisplay then
            -- Appearance previews have no core flight and keep their own display timer.
            self.countingUpwards = (self.countingUpwards or 0) + elapsed
        end
        displayedTime = timeOnFlight or self.countingUpwards
    else
        if not self.isFlightDisplay then self.timeRemaining = self.timeRemaining - elapsed end
        if self.timeRemaining <= 0 then
            statusBarModuleCore:StopTimerBar("timerBarOnUpdate timedout")
            return
        end
        displayedTime = self.timeRemaining
    end

    local second = floor(displayedTime)
    if self.displayedSecond ~= second then
        self.displayedSecond = second
        if profile.compactMode and not self.unknownFlight then
            self.textObj:SetText(disp_time(displayedTime))
        else
            local label = profile.shortNames and self.shortText or self.text
            self.textObj:SetFormattedText(L["%s - %s"], label, disp_time(displayedTime))
        end
        local currentWidth = self:GetWidth()
        local width = math.max(self.textObj:GetStringWidth() + 30, profile.barWidth)
        if not self.unknownFlight then width = math.max(width, currentWidth) end
        if width ~= currentWidth then self:SetWidth(width) end
    end

    if not self.unknownFlight then
        self.statusBar:SetValue(self.timeRemaining)
        local sparkPosition = (self.timeRemaining / self.duration) * self.statusBar:GetWidth()
        self.spark:SetPoint("CENTER", self.statusBar, "LEFT", sparkPosition, 0)
    end
end

local bdrop = { edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }
local function ApplyLookAndFeel(self)
    local profile = db.profile
    local barTexture = LSM:Fetch("statusbar", profile.barTexture)
    bdrop.bgFile = barTexture
    bdrop.edgeFile = LSM:Fetch("border", profile.borderTexture)

    -- Invalidate text and width after any appearance or profile change.
    self.displayedSecond = nil
    if self:GetWidth() ~= profile.barWidth then self:SetWidth(profile.barWidth) end
    self:SetHeight(profile.barHeight)
    local location = profile.barLocation
    self:ClearAllPoints()
    self:SetPoint(location.anchorPoint, UIParent, location.relativePoint, location.offsetX, location.offsetY)
    -- Forever skips SetBackdrop for the same table unless it is cleared first.
    self:ClearBackdrop()
    self:SetBackdrop(bdrop)
    local background, border = profile.backgroundColor, profile.borderColor
    self:SetBackdropColor(background.r, background.g, background.b, background.a)
    self:SetBackdropBorderColor(border.r, border.g, border.b, border.a)

    self.statusBar:SetStatusBarTexture(barTexture)
    local color = self.unknownFlight and profile.unknownFlightColor or profile.barColor
    self.statusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
    self.spark:SetHeight(profile.barHeight)
    self.textObj:SetFont(LSM:Fetch("font", profile.fontName), tonumber(profile.fontSize) or svDefaults.profile.fontSize)
    local font = profile.fontColor
    self.textObj:SetTextColor(font.r, font.g, font.b, font.a)
end

function statusBarModuleCore:SetupTimerBar()
    local OnFlightTimerFrame = CreateFrame("Frame", "OnFlightTimerFrame", UIParent, "BackdropTemplate")
    local statusBar = CreateFrame("StatusBar", "OnFlightTimerFrameStatusBar", OnFlightTimerFrame)
    LowerFrameLevel(statusBar)
    statusBar:SetPoint("TOPLEFT", OnFlightTimerFrame, "TOPLEFT", 6, -6)
    statusBar:SetPoint("BOTTOMRIGHT", OnFlightTimerFrame, "BOTTOMRIGHT", -6, 6)
    local textObj = OnFlightTimerFrame:CreateFontString("OnFlightTimerFrameText", nil, "GameFontHighlight")
    textObj:SetPoint("CENTER", OnFlightTimerFrame, "CENTER")
    OnFlightTimerFrame:SetScript("OnUpdate", timerBarOnUpdate)
    OnFlightTimerFrame:Hide()
    OnFlightTimerFrame:SetMovable(true)
    OnFlightTimerFrame:EnableMouse(true)
    OnFlightTimerFrame:SetClampedToScreen(true)
    OnFlightTimerFrame:RegisterForDrag("LeftButton")

    OnFlightTimerFrame.statusBar = statusBar
    OnFlightTimerFrame.textObj = textObj

    local spark = statusBar:CreateTexture(nil, "OVERLAY", nil, 7)
    OnFlightTimerFrame.spark = spark
    spark:Hide()
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetBlendMode("ADD")

    ApplyLookAndFeel(OnFlightTimerFrame)

    OnFlightTimerFrame:SetScript(
        "OnMouseDown",
        function(frame)
            if IsShiftKeyDown() then
                if frame.timeRemaining then
                    ChatFrameUtil.ActivateChat(DEFAULT_CHAT_FRAME.editBox)
                    ChatFrameUtil.InsertLink(L["[%s]: %s - %s"]:format(L["OnFlight"], frame.shortText,
                        disp_time(frame.timeRemaining)))
                end
            end
        end
    )

    OnFlightTimerFrame:SetScript(
        "OnDragStart",
        function(frame)
            if IsControlKeyDown() then
                frame:StartMoving()
            end
        end
    )

    OnFlightTimerFrame:SetScript(
        "OnDragStop",
        function(frame)
            frame:StopMovingOrSizing()
            local anchorPoint, _, relativePoint, offsetX, offsetY = frame:GetPoint()
            local location = db.profile.barLocation
            location.anchorPoint, location.relativePoint = anchorPoint, relativePoint
            location.offsetX, location.offsetY = offsetX, offsetY
            addonCore:RefreshSettings("bar_anchorPoint", "bar_relativePoint", "bar_offsetX", "bar_offsetY")
        end
    )
    self.OnFlightTimerFrame = OnFlightTimerFrame
end

function statusBarModuleCore:StartTimerBar(taxiSrcName, taxiDestName, duration, timeRemaining, unknownFlight, isFlightDisplay) --Bar Text and Duration in seconds--
    if not self:IsEnabled() then return end
    if not self.OnFlightTimerFrame then
        return
    end
    if ((not taxiSrcName) or (not taxiDestName)) then
        return
    end

    local timerFrame = self.OnFlightTimerFrame

    timerFrame.isFlightDisplay = isFlightDisplay or false
    timerFrame.duration = duration
    timerFrame.timeRemaining = timeRemaining or duration
    timerFrame.unknownFlight = unknownFlight or false

    timerFrame.text = L["%s --> %s"]:format(taxiSrcName, taxiDestName)

    local taxiSrcNameShort = taxiSrcName:gsub(L["DestParse"], "")
    local taxiDestNameShort = taxiDestName:gsub(L["DestParse"], "")
    timerFrame.shortText = L["%s --> %s"]:format(taxiSrcNameShort, taxiDestNameShort)

    local statusBar = timerFrame.statusBar
    if unknownFlight then
        statusBar:SetMinMaxValues(0, 1)
        statusBar:SetValue(1)
        timerFrame.spark:Hide()
        timerFrame.countingUpwards = 0
    else
        statusBar:SetMinMaxValues(0, duration)
        statusBar:SetValue(duration)
        timerFrame.spark:Show()
    end
    ApplyLookAndFeel(self.OnFlightTimerFrame)

    timerFrame:Show()
end

function statusBarModuleCore:StopTimerBar(reason)
    if not self.OnFlightTimerFrame then return end
    self.OnFlightTimerFrame:Hide()
    self.OnFlightTimerFrame.isFlightDisplay = false
    self.OnFlightTimerFrame.countingUpwards = 0
    self.OnFlightTimerFrame.timeRemaining = 0
    self.OnFlightTimerFrame.duration = 0
    self.OnFlightTimerFrame.text = nil
    self.OnFlightTimerFrame.shortText = nil
    self.OnFlightTimerFrame.unknownFlight = false
    self.OnFlightTimerFrame.textObj:SetText("")
end

---
function statusBarModuleCore:OnProfileUpdated()
    if self.OnFlightTimerFrame then ApplyLookAndFeel(self.OnFlightTimerFrame) end
end
