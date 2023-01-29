--[[
    New InFlight System
    Main Addon handles the Flight System
        Hooks,
        Figuring out when we're on flights and get off them
        Send Events via AceEvent when things happen.

        StatusBarMdoule handles the display
            Quartz also can handle the display
            --Maybe LDB will later?

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
        showChat = true,
        confirmFlight = false,
    },
}
addonCore.svDefaults = svDefaults

function addonCore:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("InFlightSV", svDefaults, true)
    db = self.db
end

function addonCore:OnEnable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    self:RegisterChatCommand("inflight", "ChatCommand")
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
    else
        db.profile[info[#info]] = ...
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
    },
}
