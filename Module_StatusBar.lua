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
        showSpark = true,
        --Bar Background Color
        backgroundColor = {r = 0, g = 0, b = 1, a = 1},
        
        --Bar Size Settings
        barHeight = 12,
        barWidth = 300,
        --Bar Settings
        barTexture = "Blizzard",
        barColor = {r = 0, g = 1, b = 0, a = 1},
        unknownFlightColor = {r = 1, g = 0, b = 0, a = 1},
        --Border Settings
        borderTexture = "Blizzard Dialog",
        borderColor = {r = 0, g = 1, b = 0, a = 1},

        --Basic Text Options
        compactMode = false,
        shortNames = true,
        --Font Options
        fontName = "2002 Bold",
        fontSize = 12,
        fontColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},

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
end

function statusBarModuleCore:InFlight_Taxi_Start(event, taxiSrcName, taxiDestName, taxiDuration)
    Debug(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- Duration:", SecondsToTime(taxiDuration))
    if taxiDuration ~= 0 then
        Debug("Star Timer Bar:", taxiSrcName, taxiDestName,"--Duration:", taxiDuration)
        self:StartTimerBar(taxiSrcName, taxiDestName, taxiDuration)
    else
        Debug("Star Timer Bar", taxiSrcName, taxiDestName, "--Unknown Duration.")
        self:StartTimerBar(taxiSrcName, taxiDestName, 0, true)
    end
end

function statusBarModuleCore:InFlight_Taxi_Stop(event, taxiSrcName, taxiDestName, taxiDuration)
    Debug(event, " -- ", string.format("%s --> %s", taxiSrcName, taxiDestName), " -- Completed, Duration: ", SecondsToTime(taxiDuration))
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
        if db.profile.compactMode then
            _G[self:GetName() .. "Text"]:SetText(disp_time(self.timeRemaining))
        else
            if db.profile.shortNames then
                _G[self:GetName() .. "Text"]:SetFormattedText("%s - %s", self.shortText, disp_time(self.timeRemaining))
            else
                _G[self:GetName() .. "Text"]:SetFormattedText("%s - %s", self.text, disp_time(self.timeRemaining))
            end
        end
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

function statusBarModuleCore:StartTimerBar(taxiSrcName, taxiDestName, duration, unknownFlightFlag) --Bar Text and Duration in seconds--
    print("StartTimerBar:", taxiSrcName, taxiDestName, duration, unknownFlightFlag)
    if not self.InFlightTimerFrame then
        Debug("No Timer Bar?")
        return
    end
    if ((not taxiSrcName) or (not taxiDestName)) then
        Debug("No Src or Dest? ", taxiSrcName, taxiDestName)
        return
    end
    if not duration and unknownFlightFlag then
        Debug("Unknown Duration Flight, not Implemented :(")
        return
    end

    local timerFrame = self.InFlightTimerFrame
    timerFrame.duration = duration
    timerFrame.timeRemaining = duration
    timerFrame.text = ("%s - %s"):format(taxiSrcName, taxiDestName)

    local taxiSrcNameShort = taxiSrcName:match("(.+), .+")
    local taxiDestNameShort = taxiDestName:match("(.+), .+")
    timerFrame.shortText = ("%s - %s"):format(taxiSrcNameShort, taxiDestNameShort)

    local statusBar = _G[InFlightTimerFrame:GetName() .. "StatusBar"]
    statusBar:SetMinMaxValues(0, duration)
    statusBar:SetValue(duration)
    statusBar:SetStatusBarTexture( LSM:Fetch(db.profile.barTexture) )

    if unknownFlightFlag then
        statusBar:SetStatusBarColor(db.profile.unknownFlightColor.r, db.profile.unknownFlightColor.g, db.profile.unknownFlightColor.b, db.profile.unknownFlightColor.a)
    else
        statusBar:SetStatusBarColor(db.profile.barColor.r, db.profile.barColor.g, db.profile.barColor.b, db.profile.barColor.a)
    end

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
        Debug("SetColorOption:", info[#info], "to:", red, blue, green, alpha)
    else
        db.profile[info[#info]] = ...
        Debug("SetOption:", info[#info], "to:", ...)
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
                disabled = true,
                desc = "Not Implemented",
                name = L["Count Upwards"],
                type = "toggle",
                order = 10
            },
            fillUp = {
                disabled = true,
                desc = "Not Implemented",
                name = L["Fill Upwards"],
                type = "toggle",
                order = 20
            },
            showSpark = {
                disabled = true,
                desc = "Not Implemented",
                name = L["Show Spark"],
                type = "toggle",
                order = 30
            },
            backgroundColor = {
                disabled = true,
                desc = "Not Implemented",
                name = L["Background Color"],
                type = "color",
                order = 40
            },
            size = {
                disabled = true,
                desc = "Not Implemented",
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
                        name = L["Known Flight Color"],
                        type = "color",
                        order = 20
                    },
                    unknownFlightColor = {
                        name = L["Unknown Flight Color"],
                        type = "color",
                        order = 30
                    },
                }
            },
            borderSettings = {
                disabled = true,
                desc = "Not Implemented",
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
                disabled = true,
                desc = "Not Implemented",
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
