--[[
    This Module's Entire Job is to handle the Status Bar
]]
local addonName, addonCore = ...
local statusBarModuleCore = addonCore:NewModule("StatusBarModule", "AceEvent-3.0")

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
        fontSize = "15",
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
    self.db = addonCore.db:RegisterNamespace("StatusBarModule", svDefaults)
    db = self.db
end

function statusBarModuleCore:OnEnable()
    self:SetupTimerBar()
    self:RegisterMessage("OnFlight_Taxi_Start")
    self:RegisterMessage("OnFlight_Taxi_Stop")
    self:RegisterMessage("OnFlight_Taxi_EarlyExit")
    self:RegisterMessage("OnFlight_Taxi_FAILED_ENTRY", "OnFlight_Taxi_Stop")
    self:RegisterMessage("OnFlight_Taxi_RESUME")
end

function statusBarModuleCore:OnDisable()
    self:UnregisterAllMessages()
end

function statusBarModuleCore:OnFlight_Taxi_Start(event, taxiSrcName, taxiDestName, taxiDuration, unknownFlight)
    if taxiDuration ~= 0 then
        self:StartTimerBar(taxiSrcName, taxiDestName, taxiDuration)
    elseif unknownFlight then
        self:StartTimerBar(taxiSrcName, taxiDestName, nil, nil, unknownFlight)
    end
end

function statusBarModuleCore:OnFlight_Taxi_Stop(event, ...)
    self:StopTimerBar(event)
end

function statusBarModuleCore:OnFlight_Taxi_EarlyExit(event, taxiSrcName, taxiDestName, exitReason)
    self:StopTimerBar(event)
end

function statusBarModuleCore:OnFlight_Taxi_RESUME(event, taxiSrcName, taxiDestName, taxiDuration, timeRemaining,
                                                  unknownFlight)
    self:StartTimerBar(taxiSrcName, taxiDestName, taxiDuration, timeRemaining, unknownFlight)
end

local function disp_time(time)
    local minutes = floor(mod(time, 3600) / 60)
    local seconds = floor(mod(time, 60))
    return format("%d:%02d", minutes, seconds)
end

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

        local ajdBarWidth = math.max(self.textObj:GetStringWidth() + 30, db.profile.barWidth) --dynamic size to min or make it bigger as needed
        self:SetWidth(math.max(ajdBarWidth, self:GetWidth()))                                 --make bar bigger only, don't shrink it.

        self.statusBar:SetValue(self.timeRemaining)
        self.spark:Show()
        local sparkPosition = (self.timeRemaining / self.duration) * self.statusBar:GetWidth()
        self.spark:SetPoint("CENTER", self.statusBar, "LEFT", sparkPosition, 0)
    elseif self.timeRemaining <= 0 then
        statusBarModuleCore:StopTimerBar("timerBarOnUpdate timedout")
        self:Hide()
    end
end

local bdrop = { edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }
local function ApplyLookAndFeel(self) --self is the baseFrame
    local barTexture = LSM:Fetch("statusbar", db.profile.barTexture)
    bdrop.bgFile = barTexture
    bdrop.edgeFile = LSM:Fetch("border", db.profile.borderTexture)

    --Set Frame Settings
    self:SetWidth(db.profile.barWidth)
    self:SetHeight(db.profile.barHeight)
    local barLocation = db.profile.barLocation
    self:SetPoint(barLocation.anchorPoint, UIParent, barLocation.relativePoint, barLocation.offsetX,
        barLocation.offsetY)
    self:ClearBackdrop()
    self:SetBackdrop(bdrop)
    self:SetBackdropColor(db.profile.backgroundColor.r, db.profile.backgroundColor.g, db.profile.backgroundColor.b,
        db.profile.backgroundColor.a)
    self:SetBackdropBorderColor(db.profile.borderColor.r, db.profile.borderColor.g, db.profile.borderColor.b,
        db.profile.borderColor.a)

    --Set Status Bar Settings
    local statusBar = self.statusBar
    statusBar:SetStatusBarTexture(barTexture)
    statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b,
        db.profile.barColor.a)
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
        statusBar:SetStatusBarColor(db.profile.unknownFlightColor.r, db.profile.unknownFlightColor.g,
            db.profile.unknownFlightColor.b, db.profile.unknownFlightColor.a)
    else
        statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b,
            db.profile.barColor.a)
    end
end

function statusBarModuleCore:SetupTimerBar()
    local barLocation = db.profile.barLocation
    local OnFlightTimerFrame = CreateFrame("Frame", "OnFlightTimerFrame", UIParent, "BackdropTemplate")
    local statusBar = CreateFrame("StatusBar", "OnFlightTimerFrameStatusBar", OnFlightTimerFrame)
    LowerFrameLevel(statusBar)
    local textObj = OnFlightTimerFrame:CreateFontString("OnFlightTimerFrameText", nil, "GameFontHighlight")
    OnFlightTimerFrame:SetScript("OnUpdate", timerBarOnUpdate)
    OnFlightTimerFrame:Hide()
    OnFlightTimerFrame:SetWidth(db.profile.barWidth)
    OnFlightTimerFrame:SetHeight(db.profile.barHeight)
    OnFlightTimerFrame:SetPoint(barLocation.anchorPoint, UIParent, barLocation.relativePoint, barLocation.offsetX,
        barLocation.offsetY)
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
    spark:SetHeight(16)
    spark:SetBlendMode("ADD")

    ApplyLookAndFeel(OnFlightTimerFrame)

    OnFlightTimerFrame:SetScript(
        "OnMouseDown",
        function(frame)
            if IsShiftKeyDown() then
                if frame.timeRemaining then
                    ChatEdit_ActivateChat(DEFAULT_CHAT_FRAME.editBox)
                    ChatEdit_InsertLink(("[%s]: %s - %s"):format(L["OnFlight"], frame.shortText,
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
            db.profile.barLocation.anchorPoint = anchorPoint
            db.profile.barLocation.relativePoint = relativePoint
            db.profile.barLocation.offsetX = offsetX
            db.profile.barLocation.offsetY = offsetY
        end
    )
    self.OnFlightTimerFrame = OnFlightTimerFrame
end

function statusBarModuleCore:StartTimerBar(taxiSrcName, taxiDestName, duration, timeRemaining, unknownFlight) --Bar Text and Duration in seconds--
    if not self:IsEnabled() then return end
    if not self.OnFlightTimerFrame then
        return
    end
    if ((not taxiSrcName) or (not taxiDestName)) then
        return
    end

    local timerFrame = self.OnFlightTimerFrame

    timerFrame.duration = duration
    timerFrame.timeRemaining = timeRemaining or duration

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
    ApplyLookAndFeel(self.OnFlightTimerFrame)

    timerFrame:Show()
end

function statusBarModuleCore:StopTimerBar(reason)
    if not self:IsEnabled() then return end
    self.OnFlightTimerFrame:Hide()
    self.OnFlightTimerFrame.timeRemaining = 0
    self.OnFlightTimerFrame.duration = 0
    self.OnFlightTimerFrame.text = nil
    self.OnFlightTimerFrame.shortText = nil
    self.OnFlightTimerFrame.unknownFlight = false
    self.OnFlightTimerFrame.textObj:SetText("")
end

function statusBarModuleCore:GetOption(info)
    if info.type == "color" then
        local t = db.profile[info[#info]]
        if t then
            return t.r, t.g, t.b, t.a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100,
                math.random(0, 100) / 100
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
    else
        db.profile[info[#info]] = ...
    end
    ApplyLookAndFeel(self.OnFlightTimerFrame)
end

addonCore.configOptionsTable.plugins = addonCore.configOptionsTable.plugins or {}
addonCore.configOptionsTable.plugins["StatusBarModule"] = {
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
                name = L
                    [" Shift Click on the Status Bar to send flight info to chat.\n  Control Click & Drag to Move It."],
                order = 1
            },
            barOptions = {
                type = "group",
                name = "Bar Options",
                inline = true,
                order = 100,
                args = {
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
                        order = 30,
                        inline = true,
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
                            statusBarModuleCore:StartTimerBar("City1, Zone1", "City2, Zone2", 300)
                        end
                    },
                    ["testUnknown"] = {
                        type = "execute",
                        name = L["Start Unknown Flight"],
                        order = 2,
                        func = function()
                            statusBarModuleCore:StartTimerBar("Unknown1, Zone1", "Unknown2, Zone2",
                                nil, nil, true)
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
