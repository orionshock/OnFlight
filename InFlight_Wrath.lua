--[[
    New InFlight System
    We're Ace3'ing it, in for a peny, in for a pound.

]]
--luacheck: globals LibStub InCombatLockdown

local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "InFlight", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = addonCore

local L = LibStub("AceLocale-3.0"):GetLocale("InFlight")

local db
local svDefaults = {
    profile = {
        countUp = false,
        fillUp = false,
        showSpark = true,
        backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.6},
        unknownFlightColor = {r = 0.2, g = 0.2, b = 0.4, a = 1.0},
        barHeight = 12,
        barWidth = 300,
        barTexture = "Blizzard",
        barColor = {r = 0.5, g = 0.5, b = 0.8, a = 1.0},
        borderTexture = "Blizzard Dialog",
        borderColor = {r = 0.6, g = 0.6, b = 0.6, a = 0.8},
        compactMode = false,
        fontName = "2002 Bold",
        fontSize = 12,
        fontColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
        showChat = true,
        confirmFlight = false,
        barLocation = {
            x = 0,
            y = -170,
            anchor = "TOP",
            anchorPoint = "TOP"
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
                    name = L["Count Upwards"],
                    type = "toggle",
                    order = 10
                },
                fillUp = {
                    name = L["Fill Upwards"],
                    type = "toggle",
                    order = 20
                },
                showSpark = {
                    name = L["Show Spark"],
                    type = "toggle",
                    order = 30
                },
                backgroundColor = {
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

function addonCore:SetupTimerBar()
end
