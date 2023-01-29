--[[
    This Module's Entire Job is to handle the Status Bar
]]
local addonName, addonCore = ...
local statusBarModuleCore = addonCore:NewModule("StatusBarModule", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("InFlight")
local LSM = LibStub("LibSharedMedia-3.0")

local db
local svDefaults = {
    profile = {
        countUp = false,
        fillUp = false,
        showSpark = true,
        backgroundColor = {r = 0, g = 0, b = 1, a = 1},
        unknownFlightColor = {r = 1, g = 0, b = 0, a = 1},
        barHeight = 12,
        barWidth = 300,
        barTexture = "Blizzard",
        barColor = {r = 0, g = 1, b = 0, a = 1},
        borderTexture = "Blizzard Dialog",
        borderColor = {r = 0, g = 1, b = 0, a = 1},
        compactMode = false,
        fontName = "2002 Bold",
        fontSize = 12,
        fontColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
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
end

function statusBarModuleCore:InFlight_Taxi_Start(event, taxiSrcName, taxiDestName, taxiDuration)
    print(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- ",taxiDuration)
    if taxiDuration ~= 0 then
        self:StartTimerBar(string.format("%s --> %s", taxiSrcName, taxiDestName), taxiDuration)
    else
        --eventually we'll show a bar for unknown times but empty if statement for now.
    end
end

function statusBarModuleCore:InFlight_Taxi_Stop(event, taxiSrcName, taxiDestName, taxiDuration)
    print(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- Completed")
    self:StopTimerBar()
end

function statusBarModuleCore:InFlight_Taxi_EarlyExit(event, taxiSrcName, taxiDestName, exitReason)
    print(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- ExitReason: ", exitReason)
    self:StopTimerBar()
end

local function disp_time(time)
    local minutes = floor(mod(time, 3600) / 60)
    local seconds = floor(mod(time, 60))
    return format("%d:%02d", minutes, seconds)
end

local function timerBarOnUpdate(self, elapsed)
    if not self.timeRemaining then
        self:Hide()
        return
    end
    self.timeRemaining = self.timeRemaining - elapsed
    if self.timeRemaining > 0 then
        _G[self:GetName() .. "StatusBar"]:SetValue(self.timeRemaining)
        _G[self:GetName() .. "Text"]:SetFormattedText("%s - %s", self.text, disp_time(self.timeRemaining))
    else
        self:Hide()
        self.timeRemaining = 0
        self.duration = 0
        self.text = ""
        _G[self:GetName() .. "Text"]:SetText("")
    end
end

function statusBarModuleCore:SetupTimerBar()
    local barLocation = db.profile.barLocation
    local InFlightTimerFrame = CreateFrame("Frame", "InFlightTimerFrame", UIParent, "MirrorTimerTemplate")
    InFlightTimerFrame:UnregisterAllEvents()
    InFlightTimerFrame:SetScript("OnEvent", nil)
    InFlightTimerFrame:SetScript("OnUpdate", timerBarOnUpdate)
    InFlightTimerFrame:Hide()
    InFlightTimerFrame:SetPoint(barLocation.anchorPoint, UIParent, barLocation.relativePoint, barLocation.offsetX, barLocation.offsetY)
    InFlightTimerFrame:SetMovable(true)
    InFlightTimerFrame:EnableMouse(true)
    InFlightTimerFrame:SetClampedToScreen(true)
    InFlightTimerFrame:RegisterForDrag("LeftButton")

    local statusBar = _G[InFlightTimerFrame:GetName() .. "StatusBar"]
    statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b, db.profile.barColor.a)

    InFlightTimerFrame:SetScript(
        "OnMouseUp",
        function(frame, button)
            --print(frame:GetName(), button)
        end
    )

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
            local a, b, c, d, e = frame:GetPoint()
            db.p, db.rp, db.x, db.y = a, c, floor(d + 0.5), floor(e + 0.5)
            local anchorPoint, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint()
            db.profile.barLocation.anchorPoint = anchorPoint
            db.profile.barLocation.relativePoint = relativePoint
            db.profile.barLocation.offsetX = offsetX
            db.profile.barLocation.offsetY = offsetY
        end
    )
    self.InFlightTimerFrame = InFlightTimerFrame
end

function statusBarModuleCore:StartTimerBar(text, duration, unknownFlightFlag) --Bar Text and Duration in seconds--
    if not self.InFlightTimerFrame then
        return
    end
    if (not text) or (not duration) then
        return
    end

    local timerFrame = self.InFlightTimerFrame
    timerFrame.duration = duration
    timerFrame.timeRemaining = duration
    timerFrame.text = text

    local statusBar = _G[InFlightTimerFrame:GetName() .. "StatusBar"]
    statusBar:SetMinMaxValues(0, duration)
    statusBar:SetValue(duration)

    if unknownFlightFlag then
        statusBar:SetStatusBarColor(db.profile.unknownFlightColor.r, db.profile.unknownFlightColor.g, db.profile.unknownFlightColor.b, db.profile.unknownFlightColor.a)
    else
        statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b, db.profile.barColor.a)
    end

    local displayText = _G[timerFrame:GetName() .. "Text"]
    displayText:SetFormattedText("%s - %s", text, disp_time(duration))

    timerFrame:Show()
end

function statusBarModuleCore:StopTimerBar()
    self.InFlightTimerFrame:Hide()
    self.InFlightTimerFrame.timeRemaining = 0
    self.InFlightTimerFrame.duration = 0
    self.InFlightTimerFrame.text = ""
    _G[self.InFlightTimerFrame:GetName() .. "Text"]:SetText("")
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
        local red, blue, green, alpha = ...
        db.profile[info[#info]] = db.profile[info[#info]] or {}
        db.profile[info[#info]].r = red
        db.profile[info[#info]].b = blue
        db.profile[info[#info]].g = green
        db.profile[info[#info]].a = alpha
    else
        db.profile[info[#info]] = ...
    end
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
                name = L["Count Upwards"],
                type = "toggle",
                order = 10
            },
            fillUp = {
                hidden = true,
                name = L["Fill Upwards"],
                type = "toggle",
                order = 20
            },
            showSpark = {
                hidden = true,
                name = L["Show Spark"],
                type = "toggle",
                order = 30
            },
            backgroundColor = {
                hidden = true,
                name = L["Background Color"],
                type = "color",
                order = 40
            },
            unknownFlightColor = {
                name = L["Unknown Flight Color"],
                type = "color",
                order = 50
            },
            size = {
                hidden = true,
                name = L["Bar Size Settings"],
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
                name = L["Bar Settings"],
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
                    barColor = {
                        name = L["Bar Color"],
                        type = "color",
                        order = 20
                    }
                }
            },
            borderSettings = {
                hidden = true,
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
                order = 10
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
                        name = L["Size"],
                        type = "input",
                        order = 20
                    },
                    fontColor = {
                        name = L["Color"],
                        type = "color",
                        order = 30
                    }
                }
            }
        }
    }
}
