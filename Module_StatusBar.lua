--[[
    This Module's Entire Job is to handle the Status Bar
]]
local Debug = LibEdrik_GetDebugFunction and LibEdrik_GetDebugFunction("|cff0040ffIn|cff00aaffFlight-SB|r|r:", nil, nil, false) or function()
    end

local addonName, addonCore = ...
local statusBarModuleCore = addonCore:NewModule("StatusBarModule", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("InFlight")
local LSM = LibStub("LibSharedMedia-3.0")

local db
local svDefaults = {
    profile = {
        --Basic Bar Options
        countUp = false,
        fillUp = false,
        --Bar Background Color
        backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.6},
        --Bar Size Settings
        barHeight = 30,
        barWidth = 300,
        --Bar Settings
        barTexture = "Blizzard",
        barColor = {r = 0.5, g = 0.5, b = 0.8, a = 1.0},
        unknownFlightColor = {r = 0.2, g = 0.2, b = 0.4, a = 1.0},
        --Border Settings
        borderTexture = "Blizzard Dialog",
        borderColor = {r = 0.6, g = 0.6, b = 0.6, a = 1},
        --Basic Text Options
        compactMode = false,
        shortNames = true,
        --Font Options
        fontName = "2002 Bold",
        fontSize = "15",
        fontColor = {r = 1, g = 1, b = 1, a = 1},
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
    self.db = addonCore.db:RegisterNamespace("StatusBarModule", svDefaults)
    db = self.db
end
function statusBarModuleCore:OnEnable()
    self:SetupTimerBar()
    self:RegisterMessage("InFlight_Taxi_Start")
    self:RegisterMessage("InFlight_Taxi_Stop")
    self:RegisterMessage("InFlight_Taxi_FAILED_ENTRY", "InFlight_Taxi_Stop")
end

function statusBarModuleCore:InFlight_Taxi_Start(event, taxiSrcName, taxiDestName, taxiDuration, unknownFlight)
    Debug(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- Duration:", SecondsToTime(taxiDuration))
    if taxiDuration ~= 0 then
        Debug("Star Timer Bar:", taxiSrcName, taxiDestName, "--Duration:", taxiDuration)
        self:StartTimerBar(taxiSrcName, taxiDestName, taxiDuration)
    elseif unknownFlight then
        Debug("Star Timer Bar", taxiSrcName, taxiDestName, "--Unknown Duration.")
        self:StartTimerBar(taxiSrcName, taxiDestName, 0, unknownFlight)
    end
end

function statusBarModuleCore:InFlight_Taxi_Stop(event, taxiSrcName, taxiDestName, taxiDuration)
    Debug(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- Completed, Duration: ", SecondsToTime(taxiDuration))
    self:StopTimerBar()
end

function statusBarModuleCore:InFlight_Taxi_EarlyExit(event, taxiSrcName, taxiDestName, exitReason)
    Debug(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- ExitReason: ", exitReason)
    self:StopTimerBar()
end

local function disp_time(time)
    local minutes = floor(mod(time, 3600) / 60)
    local seconds = floor(mod(time, 60))
    return format("%d:%02d", minutes, seconds)
end

local onUpdateThrottle = 0
local onUpdateInterval = 1
local function timerBarOnUpdate(self, elapsed)
    if (self.unknownFlight) then
        if db.profile.shortNames then
            self.textObj:SetText(self.shortText)
        else
            self.textObj:SetText(self.text)
        end
        self.spark:Hide()
        local ajdBarWidth = math.max(self.textObj:GetStringWidth() + 30, db.profile.barWidth)
        self:SetWidth(ajdBarWidth)
        return
    end

    self.timeRemaining = self.timeRemaining - elapsed
    if self.timeRemaining > 0 then
        if db.profile.compactMode then
            self.textObj:SetText(disp_time(self.timeRemaining))
        else
            if db.profile.shortNames then
                self.textObj:SetFormattedText("%s - %s", self.shortText, disp_time(self.timeRemaining))
            else
                self.textObj:SetFormattedText("%s - %s", self.text, disp_time(self.timeRemaining))
            end
        end

        local ajdBarWidth = math.max(self.textObj:GetStringWidth() + 30, db.profile.barWidth)
        self:SetWidth(ajdBarWidth)

        self.statusBar:SetValue(self.timeRemaining)
        self.spark:Show()
        local sparkPosition = (self.timeRemaining / self.duration) * self.statusBar:GetWidth()
        self.spark:SetPoint("CENTER", self.statusBar, "LEFT", sparkPosition, 0)
    elseif self.timeRemaining <= 0 then
        self:Hide()
        self.timeRemaining = 0
        self.duration = 0
        self.text = ""
        self.textObj:SetText("")
    end
end

local bdrop = {edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}}
local function ApplyLookAndFeel(self) --self is the baseFrame
    local barTexture = LSM:Fetch("statusbar", db.profile.barTexture)
    bdrop.bgFile = barTexture
    bdrop.edgeFile = LSM:Fetch("border", db.profile.borderTexture)

    --Set Frame Settings
    self:SetWidth(db.profile.barWidth)
    self:SetHeight(db.profile.barHeight)
    self:ClearBackdrop()
    self:SetBackdrop(bdrop)
    self:SetBackdropColor(db.profile.backgroundColor.r, db.profile.backgroundColor.g, db.profile.backgroundColor.b, db.profile.backgroundColor.a)
    self:SetBackdropBorderColor(db.profile.borderColor.r, db.profile.borderColor.g, db.profile.borderColor.b, db.profile.borderColor.a)

    --Set Status Bar Settings
    local statusBar = self.statusBar
    statusBar:SetStatusBarTexture(barTexture)
    statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b, db.profile.barColor.a)
    statusBar:ClearAllPoints()
    statusBar:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -6)
    statusBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 6)
    local spark = self.spark
    spark:ClearAllPoints()
    spark:SetHeight(db.profile.barHeight)
    spark:SetWidth(16)

    --Text Object
    local textObj = self.textObj
    textObj:ClearAllPoints()
    textObj:SetPoint("CENTER", self, "CENTER")
    textObj:SetFont(LSM:Fetch("font", db.profile.fontName), db.profile.fontSize)
    textObj:SetTextColor(db.profile.fontColor.r, db.profile.fontColor.g, db.profile.fontColor.b, db.profile.fontColor.a)

    if self.unknownFlight then
        statusBar:SetStatusBarColor(db.profile.unknownFlightColor.r, db.profile.unknownFlightColor.g, db.profile.unknownFlightColor.b, db.profile.unknownFlightColor.a)
    else
        statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b, db.profile.barColor.a)
    end
end

function statusBarModuleCore:SetupTimerBar()
    local barLocation = db.profile.barLocation
    local InFlightTimerFrame = CreateFrame("Frame", "InFlightTimerFrame", UIParent, "BackdropTemplate")
    local statusBar = CreateFrame("StatusBar", "InFlightTimerFrameStatusBar", InFlightTimerFrame)
    LowerFrameLevel(statusBar)
    local textObj = InFlightTimerFrame:CreateFontString("InFlightTimerFrameText", nil, "GameFontHighlight")
    InFlightTimerFrame:SetScript("OnUpdate", timerBarOnUpdate)
    InFlightTimerFrame:Hide()
    InFlightTimerFrame:SetWidth(db.profile.barWidth)
    InFlightTimerFrame:SetHeight(db.profile.barHeight)
    InFlightTimerFrame:SetPoint(barLocation.anchorPoint, UIParent, barLocation.relativePoint, barLocation.offsetX, barLocation.offsetY)
    InFlightTimerFrame:SetMovable(true)
    InFlightTimerFrame:EnableMouse(true)
    InFlightTimerFrame:SetClampedToScreen(true)
    InFlightTimerFrame:RegisterForDrag("LeftButton")

    InFlightTimerFrame.statusBar = statusBar
    InFlightTimerFrame.textObj = textObj

    local spark = statusBar:CreateTexture(nil, "OVERLAY", nil, 7)
    InFlightTimerFrame.spark = spark
    spark:Hide()
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetHeight(16)
    spark:SetBlendMode("ADD")

    ApplyLookAndFeel(InFlightTimerFrame)

    -- InFlightTimerFrame:SetScript(
    --     "OnMouseUp",
    --     function(frame, button)
    --         --I want to add a Shift Click here to announce... do it later tho
    --     end
    -- )

    InFlightTimerFrame:SetScript(
        "OnDragStart",
        function(frame)
            if IsShiftKeyDown() then
                frame:StartMoving()
            end
        end
    )
    InFlightTimerFrame:SetScript(
        "OnDragStop",
        function(frame)
            frame:StopMovingOrSizing()
            local anchorPoint, relativeToFrame, relativePoint, offsetX, offsetY = frame:GetPoint()
            db.profile.barLocation.anchorPoint = anchorPoint
            db.profile.barLocation.relativePoint = relativePoint
            db.profile.barLocation.offsetX = offsetX
            db.profile.barLocation.offsetY = offsetY
        end
    )
    self.InFlightTimerFrame = InFlightTimerFrame
end

function statusBarModuleCore:StartTimerBar(taxiSrcName, taxiDestName, duration, unknownFlight) --Bar Text and Duration in seconds--
    Debug("StartTimerBar:", taxiSrcName, taxiDestName, duration, unknownFlight)
    if not self.InFlightTimerFrame then
        Debug("No Timer Bar?")
        return
    end
    if ((not taxiSrcName) or (not taxiDestName)) then
        Debug("No Src or Dest? ", taxiSrcName, taxiDestName)
        return
    end

    local timerFrame = self.InFlightTimerFrame

    timerFrame.duration = duration
    timerFrame.timeRemaining = duration
    timerFrame.text = ("%s --> %s"):format(taxiSrcName, taxiDestName)

    local taxiSrcNameShort = taxiSrcName:gsub(L["DestParse"], "")
    local taxiDestNameShort = taxiDestName:gsub(L["DestParse"], "")
    timerFrame.shortText = ("%s --> %s"):format(taxiSrcNameShort, taxiDestNameShort)

    local statusBar = timerFrame.statusBar
    if unknownFlight then
        statusBar:SetMinMaxValues(0, 1)
        statusBar:SetValue(1)
        timerFrame.unknownFlight = unknownFlight
    else
        statusBar:SetMinMaxValues(0, duration)
        statusBar:SetValue(duration)
    end
    ApplyLookAndFeel(self.InFlightTimerFrame)

    timerFrame:Show()
end

function statusBarModuleCore:StopTimerBar()
    Debug("StopTimerBar")
    self.InFlightTimerFrame:Hide()
    self.InFlightTimerFrame.timeRemaining = 0
    self.InFlightTimerFrame.duration = 0
    self.InFlightTimerFrame.text = nil
    self.InFlightTimerFrame.shortText = nil
    self.InFlightTimerFrame.unknownFlight = false
    self.InFlightTimerFrame.textObj:SetText("")
end

function statusBarModuleCore:GetOption(info)
    if info.type == "color" then
        local t = db.profile[info[#info]]
        if t then
            return t.r, t.g, t.b, t.a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100
        end
    else
        return db.profile[info[#info]]
    end
end
function statusBarModuleCore:SetOption(info, ...)
    if info.type == "color" then
        local red, green, blue, alpha = ...
        db.profile[info[#info]] = db.profile[info[#info]] or {}
        db.profile[info[#info]].r = red
        db.profile[info[#info]].g = green
        db.profile[info[#info]].b = blue
        db.profile[info[#info]].a = alpha
        Debug("SetColorOption:", info[#info], "to:", red, blue, green, alpha)
    else
        db.profile[info[#info]] = ...
        Debug("SetOption:", info[#info], "to:", ...)
    end
    ApplyLookAndFeel(self.InFlightTimerFrame)
end

addonCore.configOptionsTable.plugins = addonCore.configOptionsTable.plugins or {}
addonCore.configOptionsTable.plugins["StatusBarModule"] = {
    barOptions = {
        handler = statusBarModuleCore,
        get = "GetOption",
        set = "SetOption",
        name = L["Bar Options"],
        type = "group",
        order = 100,
        args = {
            countUp = {
                hidden = true,
                desc = "Not Implemented",
                name = L["Count Upwards"],
                type = "toggle",
                order = 10
            },
            fillUp = {
                hidden = true,
                desc = "Not Implemented",
                name = L["Fill Upwards"],
                type = "toggle",
                order = 20
            },
            size = {
                name = L["Bar Size"],
                type = "group",
                order = 60,
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
            barSettings = {
                name = L["Look and Feel"],
                type = "group",
                order = 70,
                inline = true,
                width = "normal",
                args = {
                    barTexture = {
                        name = L["Bar Texture"],
                        type = "select",
                        order = 10,
                        dialogControl = "LSM30_Statusbar",
                        values = AceGUIWidgetLSMlists.statusbar
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
                order = 80,
                inline = true,
                width = "normal",
                args = {
                    borderTexture = {
                        name = L["Border Texture"],
                        type = "select",
                        order = 10,
                        dialogControl = "LSM30_Border",
                        values = AceGUIWidgetLSMlists.border
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
        handler = statusBarModuleCore,
        get = "GetOption",
        set = "SetOption",
        name = "Text Options",
        type = "group",
        order = 200,
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
                    return db.profile.compactMode
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
                        dialogControl = "LSM30_Font",
                        values = AceGUIWidgetLSMlists.font,
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
    }
}
