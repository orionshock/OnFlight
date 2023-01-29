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
        taxiTimerFrame:Hide()
    end

    local UnitOnTaxi, UnitInVehicle = UnitOnTaxi, UnitInVehicle
    taxiTimerFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            local prevState = self.taxiState
            self.taxiState = UnitOnTaxi("player") or UnitInVehicle("player")

            if (not self.taxiSrcName) or (not self.taxiDestName) then
                --if we don't know where we started or going to then reset it all for good mesure and hide
                self.taxiSrcName = nil
                self.taxiDestName = nil
                self.taxiStartTime = nil
                self:Hide()
            end

            if (prevState ~= self.taxiState) then --Status Changed
                if self.taxiState then --if we are on a taxi, then lets keep track of things a bit
                    self.taxiStartTime = GetTime()
                    print("InFlight Start:", self.taxiSrcName, "-->", self.taxiDestName, " -- StartTime:", self.taxiStartTime)

                    if db.global[playerFaction][self.taxiSrcName] then
                        if db.global[playerFaction][self.taxiSrcName][self.taxiDestName] then
                            --we have src,dest, and flight time, send known flight time event
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, db.global[playerFaction][self.taxiSrcName][self.taxiDestName])
                        else
                            --unknown flight time to destination, send 0
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0)
                        end
                    else
                        --unknown flight time from source or destination, send 0
                        addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0)
                    end
                elseif (not self.taxiState) and (self.taxiStartTime) then --We're off the Taxi and was on it previously
                    if not self.earlyExit then --we did not exit early
                        local flightDuration = abs(GetTime() - self.taxiStartTime) --figure out the flight time in seconds...
                        --safely create DB entries if not present
                        db.global[playerFaction][self.taxiSrcName] = db.global[playerFaction][self.taxiSrcName] or {}
                        db.global[playerFaction][self.taxiSrcName][self.taxiDestName] = math.floor(flightDuration) --stash the flight time.
                        addonCore:SendMessage("InFlight_Taxi_Stop", taxiSrcName, taxiDestName, flightDuration)
                        print("InFlight End:", self.taxiSrcName, "-->", self.taxiDestName, " -- Duration:", SecondsToTime(flightDuration))
                        ResetInFlightTimer()
                    elseif self.earlyExit then --we left the flight early, nill it out
                        addonCore:SendMessage("InFlight_Taxi_EarlyExit", taxiSrcName, taxiDestName, self.earlyExit)
                        print("InFlight EarlyExit:", self.taxiSrcName, "-->", self.taxiDestName, " -- Reason: ", self.earlyExit)
                        ResetInFlightTimer()
                    end
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
                    name = L["Confirm Flights"],
                    type = "toggle",
                    order = 20
                }
            }
        }
    }
}
