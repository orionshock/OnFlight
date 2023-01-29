--[[
    New InFlight System
    We're Ace3'ing it, in for a peny, in for a pound.

]]
--luacheck: globals LibStub InCombatLockdown

local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "InFlight", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = addonCore

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
        showChat = true,
        confirmFlight = false,
        barLocation = {
            offsetX = 0,
            offsetY = -170,
            anchorPoint = "TOP",
            relativePoint = "TOP"
        }
    },
    global = {}
}
addonCore.svDefaults = svDefaults

function addonCore:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("InFlightSV", svDefaults, true)
    db = self.db
end

function addonCore:OnEnable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    self:RegisterChatCommand("inflight", "ChatCommand")

    self:SetupTimerBar()
end

function addonCore:OnDisable()
end

function addonCore:ChatCommand(input)
    if InCombatLockdown() then
        return
    end
    if not input or input:trim() == "" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    end
end

---Ace3 Config Table
function addonCore:GetOption(info)
    if info.type == "color" then
        if db.profile[info[#info]] then
            return db.profile[info[#info]].r, db.profile[info[#info]].b, db[info[#info]].g, db.profile[info[#info]].a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100
        end
    else
        return db.profile[info[#info]]
    end
end
function addonCore:SetOption(info, ...)
    if info.type == "color" then
        local red, blue, green, alpha = ...
        db.profile[info[#info]] = db.profile[info[#info]] or {}
        db.profile[info[#info]].r = red
        db.profile[info[#info]].b = blue
        db.profile[info[#info]].g = green
        db.profile[info[#info]].a = alpha
        print("Option Color: " .. info[#info] .. " => " .. red, blue, green, alpha)
    else
        db.profile[info[#info]] = ...
        print("Option " .. info[#info] .. " => " .. tostringall(...))
    end
end

addonCore.configOptionsTable = {
    type = "group",
    name = L["InFlight Options"],
    handler = addonCore,
    get = "GetOption",
    set = "SetOption",
    childGroups = "tab",
    args = {
        barOptions = {
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
        },
        misc = {
            name = L["Misc Options"],
            type = "group",
            order = 300,
            args = {
                showChat = {
                    name = L["Show Chat Messages"],
                    type = "toggle",
                    order = 10
                },
                confirmFlight = {
                    name = L["Confirm Flights"],
                    type = "toggle",
                    order = 20
                }
            }
        }
    }
}
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

function addonCore:SetupTimerBar()
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
            print(frame:GetName(), button)
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

function addonCore:StartTimerBar(text, duration, unknownFlightFlag) --Bar Text and Duration in seconds--
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

function addonCore:StopTimerBar()
    self.InFlightTimerFrame:Hide()
    self.InFlightTimerFrame.timeRemaining = 0
    self.InFlightTimerFrame.duration = 0
    self.InFlightTimerFrame.text = ""
    _G[self.InFlightTimerFrame:GetName() .. "Text"]:SetText("")
end
