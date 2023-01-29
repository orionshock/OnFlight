--[[
    New InFlight System
    Main Addon handles the Flight System
        Hooks,
        Figuring out when we're on flights and get off them
        Send Events via AceEvent when things happen.

        StatusBarMdoule handles the display
            Quartz also can handle the display
            --Maybe LDB will later?
Events:

InFlight_Taxi_Start
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going
taxiDuration --Time in seconds from DB for how long the flight is.
    --if duration is 0 then we don't know how long it'll be--

InFlight_Taxi_Stop
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going
taxiDuration --Time in seconds from DB for how long the flight is.

InFlight_Taxi_EarlyExit
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going
reason -- why did we exit early

]]
--luacheck: globals LibStub InCombatLockdown

local Debug = LibEdrik_GetDebugFunction and LibEdrik_GetDebugFunction("|cff0040ffIn|cff00aaffFlight-C|r|r:", nil, nil, false) or function()
    end

local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "InFlight", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = addonCore

local L = LibStub("AceLocale-3.0"):GetLocale("InFlight")
--local LSM = LibStub("LibSharedMedia-3.0")

local db, playerFaction
local svDefaults = {
    profile = {
        showChat = true,
        confirmFlight = false
    },
    global = {
        Horde = {
            ["Booty Bay, Stranglethorn"] = {
                ["Grom'gol, Stranglethorn"] = 75
            },
            ["Grom'gol, Stranglethorn"] = {
                ["Booty Bay, Stranglethorn"] = 78
            }
        }
    }
}
addonCore.svDefaults = svDefaults

function addonCore:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("InFlightSV", svDefaults, true)
    db = self.db
    playerFaction = UnitFactionGroup("player")
    db.global[playerFaction] = db.global[playerFaction] or {}
end

function addonCore:OnEnable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    self:RegisterChatCommand("inflight", "ChatCommand")

    --Hack to Q3 Flight Module for now--
    local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3", true)
    if Quartz3 then
        local Flight = Quartz3:GetModule("Flight")
        Flight:Disable()
        Flight:UnregisterEvent("TAXIMAP_OPENED")
    end
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

local taxiTimerFrame = CreateFrame("frame")
taxiTimerFrame:Hide()
taxiTimerFrame.taxiState = false
do
    local function ResetInFlightTimer()
        taxiTimerFrame.taxiSrcName = nil
        taxiTimerFrame.taxiDestName = nil
        taxiTimerFrame.taxiStartTime = nil
        taxiTimerFrame.elapsedNotOnFlight = nil
        taxiTimerFrame:Hide()
        Debug("ResetInFlightTimer()")
    end

    local UnitOnTaxi, UnitInVehicle = UnitOnTaxi, UnitInVehicle
    taxiTimerFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            local prevState = self.taxiState
            self.taxiState = UnitOnTaxi("player") or UnitInVehicle("player")

            if (not self.taxiSrcName) or (not self.taxiDestName) then
                Debug("OnUpdateMonitor - No Source or Destination. Reset & Exit")
                return ResetInFlightTimer()
            end

            if (prevState ~= self.taxiState) then
                Debug("State Changed, Old:", prevState, "New:", self.taxiState)
                if self.taxiState then
                    self.taxiStartTime = GetTime()
                    Debug("On Taxi", self.taxiSrcName, "-->", self.taxiDestName, " -- StartTime:", date("%I:%M:%S %p"))

                    if db.global[playerFaction][self.taxiSrcName] then
                        if db.global[playerFaction][self.taxiSrcName][self.taxiDestName] then
                            Debug("Send Event: InFlight_Taxi_Start -- Duration:", SecondsToTime(db.global[playerFaction][self.taxiSrcName][self.taxiDestName]))
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, db.global[playerFaction][self.taxiSrcName][self.taxiDestName])
                        else
                            Debug("Send Event: InFlight_Taxi_Start -- Unknown Duration")
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0)
                        end
                    else
                        Debug("Send Event: InFlight_Taxi_Start -- Unknown Duration")
                        addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0)
                    end
                elseif (not self.taxiState) and (self.taxiStartTime) then
                    Debug("Off Taxi:", (not self.taxiState), date("%I:%M:%S %p"))
                    if not self.earlyExit then
                        Debug("No Exit Early:", self.earlyExit)
                        local flightDuration = abs(GetTime() - self.taxiStartTime)
                        db.global[playerFaction][self.taxiSrcName] = db.global[playerFaction][self.taxiSrcName] or {}
                        db.global[playerFaction][self.taxiSrcName][self.taxiDestName] = math.floor(flightDuration) + 2 --Add 2 sec slosh
                        Debug("Send Event: InFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, "-- Druation:", SecondsToTime(flightDuration))
                        addonCore:SendMessage("InFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, flightDuration)
                        return ResetInFlightTimer()
                    elseif self.earlyExit then
                        Debug("EarlyExit:", self.taxiSrcName, "-->", self.taxiDestName, " -- Reason: ", self.earlyExit)
                        addonCore:SendMessage("InFlight_Taxi_EarlyExit", self.taxiSrcName, self.taxiDestName, self.earlyExit)
                        return ResetInFlightTimer()
                    end
                end
            end
            if (not self.taxiState) then
                self.elapsedNotOnFlight = (self.elapsedNotOnFlight or 0) + elapsed
                Debug("Failed Entry - TaxiState:", self.taxiState, self.elapsedNotOnFlight)
                if self.elapsedNotOnFlight > 10 then
                    Debug("Failed Entry > 10sec, send Failed Entry Event and Reset?:", self.taxiSrcName, "-->", self.taxiDestName)
                    addonCore:SendMessage("InFlight_Taxi_FAILED_ENTRY", self.taxiSrcName, self.taxiDestName)
                    return ResetInFlightTimer()
                end
            end
        end
    )
end

do --Hoook Func
    local oldTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(slot, ...)
        for taxiIndex = 1, NumTaxiNodes(), 1 do
            if TaxiNodeGetType(taxiIndex) == "CURRENT" then
                taxiTimerFrame.taxiSrcName = TaxiNodeName(taxiIndex)
                taxiTimerFrame.taxiDestName = TaxiNodeName(slot)
                taxiTimerFrame.elapsedNotOnFlight = 0
                taxiTimerFrame:Show() --we'll let the OnUpdate frame handle the AceEvent Messages
                break
            end
        end
        oldTakeTaxiNode(slot, ...)
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
                    disabled = true,
                    desc = "Not Implemented, Might not be. What's the point?",
                    name = L["Confirm Flights"],
                    type = "toggle",
                    order = 20
                },
                showDebug = {
                    name = L["Debug"],
                    type = "toggle",
                    order = 30
                },
                ADVANCED_OPTIONS = {
                    name = L["Show Advanced Options"],
                    type = "toggle",
                    order = 100
                }
            }
        },
        advancedOptions = {
            name = "Advanced Options",
            type = "group",
            order = 900,
            hidden = function() return not db.profile.ADVANCED_OPTIONS end,
            args ={
                helpText = {
                    name = "Not Implemented",
                    type = "description",
                }
            }
        }
    }
}
