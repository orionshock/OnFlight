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
unknownFlight -- true if there is no duration

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

local db, playerFaction
local svDefaults = {
    char = {
        --resumed flight details from reloading UI or zoning, not sure i want to do this.
    },
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
        },
        Alliance = {},
        gossipTriggered = {
            -- [gossipOptionID] = {startingPoint, endingPoint},
            -- Gossip Triggered Flights get integrated in to main Horde/Alliance DB as they occur as any other flight
            -- we set a start locatoin name and end location name here as it's not provided otherwise and is needed for the rest of it to work.
            -- likely will be editable in the future via ADV Options pannel so people can and in more as desired / found.
            [93033] = {"Sun's Reach Harbor", "The Sin'loren"},
            [92694] = {"The Sin'loren", "Sun's Reach Harbor"}
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
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(addonCore, "inflight", addonName, input)
    end
end

function addonCore:ChatMessage(...)
    if not self.db.profile.showChat then
        return
    end
    local msg = string.join(" ", tostringall(...))
    msg = msg:trim()
    if msg then
        print("|cff0040ffIn|cff00aaffFlight|r|r:", msg)
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
                            local flightDurationFromDB = db.global[playerFaction][self.taxiSrcName][self.taxiDestName] --for Readablity.
                            Debug("Send Event: InFlight_Taxi_Start -- Duration:", SecondsToTime(flightDurationFromDB))
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, flightDurationFromDB, false)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName, self.taxiDestName, "--", L["Flight Time:"], SecondsToTime(flightDurationFromDB))
                        else
                            Debug("Send Event: InFlight_Taxi_Start -- Unknown Duration")
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                        end
                    else
                        Debug("Send Event: InFlight_Taxi_Start -- Unknown Duration")
                        addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                        addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                    end
                elseif (not self.taxiState) and (self.taxiStartTime) then
                    Debug("Off Taxi:", (not self.taxiState), date("%I:%M:%S %p"))
                    if not self.earlyExit then
                        Debug("No Exit Early:", self.earlyExit)
                        local flightDuration = abs(GetTime() - self.taxiStartTime)
                        db.global[playerFaction][self.taxiSrcName] = db.global[playerFaction][self.taxiSrcName] or {}
                        db.global[playerFaction][self.taxiSrcName][self.taxiDestName] = math.floor(flightDuration)
                        Debug("Send Event: InFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, "-- Druation:", SecondsToTime(flightDuration))
                        addonCore:SendMessage("InFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, flightDuration)
                        addonCore:ChatMessage(L["Taxi Ended:"], self.taxiSrcName .. " --> " .. self.taxiDestName, "--", L["Flight Time:"], SecondsToTime(flightDuration))
                        return ResetInFlightTimer()
                    elseif self.earlyExit then
                        Debug("EarlyExit:", self.taxiSrcName, "-->", self.taxiDestName, " -- Reason: ", self.earlyExit)
                        addonCore:SendMessage("InFlight_Taxi_EarlyExit", self.taxiSrcName, self.taxiDestName, self.earlyExit)
                        addonCore:ChatMessage(L["Taxi Ended Early:"], self.earlyExit)
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

-- function hooks to detect if we left a flight early
hooksecurefunc(
    "TaxiRequestEarlyLanding",
    function()
        taxiTimerFrame.earlyExit = "TaxiRequestEarlyLanding"
    end
)

hooksecurefunc(
    "AcceptBattlefieldPort",
    function()
        taxiTimerFrame.earlyExit = "AcceptBattlefieldPort"
    end
)

hooksecurefunc(
    C_SummonInfo,
    "ConfirmSummon",
    function()
        taxiTimerFrame.earlyExit = "C_SummonInfo.ConfirmSummon"
    end
)

---APIs
function addonCore:GetFlightDuration(source, destination, faction)
    local src = (source and (type(source) == "string")) and source:trim()
    local dest = (source and (type(destination) == "string")) and destination:trim()
    local fact = (faction and (type(faction) == "string")) and destination:trim() or playerFaction
    if src and dest then
        if db.global[fact][src] then
            return db.global[fact][src][dest]
        end
    end
end
function addonCore:IsOnFlight()
    if taxiTimerFrame and taxiTimerFrame:IsShown() then
        if taxiTimerFrame.taxiSrcName and taxiTimerFrame.taxiDestName then
            return true
        end
    end
    return false
end

function addonCore:GetCurrentFlightDetail()
    if self:IsOnFlight() then
        return taxiTimerFrame.taxiSrcName, taxiTimerFrame.taxiDestName
    end
end

function addonCore:GetCurrentFlightProgress()
    --time on flight, time remaining, total duration
    if not self:IsOnFlight() then
        return
    end
    local timeOnFlight = GetTime() - taxiTimerFrame.taxiStartTime
    local totalDuration = addonCore:GetFlightDuration(self:GetCurrentFlightDetail())
    local timeRemaining
    if totalDuration then
        timeRemaining = totalDuration - timeOnFlight
    end

    return timeOnFlight, timeRemaining, totalDuration
end
---

function addonCore:StartAFlight(source, destination)
    --there are no sanity Checks here -- use with care.
    taxiTimerFrame.taxiSrcName = source
    taxiTimerFrame.taxiDestName = destination
    taxiTimerFrame.elapsedNotOnFlight = 0
    taxiTimerFrame:Show()
end

do --Hoook Func
    local oldTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(slot, ...)
        for taxiIndex = 1, NumTaxiNodes(), 1 do
            if TaxiNodeGetType(taxiIndex) == "CURRENT" then
                local taxiSrcName = TaxiNodeName(taxiIndex)
                local taxiDestName = TaxiNodeName(slot)
                if taxiSrcName and taxiDestName then
                    addonCore:StartAFlight(source, destination)
                    break
                end
            end
        end
        oldTakeTaxiNode(slot, ...)
    end
end

do
    local orig_C_GossipInfo_SelectOption = C_GossipInfo.SelectOption
    function C_GossipInfo.SelectOption(option, ...)
        Debug("C_GossipInfo.SelectOption", option, ...)
        local gossipOptions = C_GossipInfo.GetOptions()
        local gossipSelection, gossipOptionID
        for _, v in pairs(gossipOptions) do
            if v.gossipOptionID == option then
                gossipOptionID = v.gossipOptionID
                gossipSelection = v --used for debugging....
            end
        end
        if not gossipSelection then
            --?? this should never really happen, but send back to game API and let it deal with it.
            orig_C_GossipInfo_SelectOption(option, ...)
            return
        end
        Debug(gossipOptionID, gossipSelection.name)
        if db.global.gossipTriggered[gossipOptionID] then
            Debug(unpack(db.global.gossipTriggered[gossipOptionID]))
            addonCore:StartAFlight(unpack(db.global.gossipTriggered[gossipOptionID]))
        end

        orig_C_GossipInfo_SelectOption(option, ...)
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
        local red, green, blue, alpha = ...
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
                showDebug = {
                    name = L["Debug"],
                    type = "toggle",
                    order = 99
                },
                ADVANCED_OPTIONS = {
                    name = L["Show Advanced Options"],
                    type = "toggle",
                    order = 100
                }
            }
        },
        testButtons = {
            type = "group",
            name = "Test Buttons",
            order = 350,
            args = {
                ["testKnown"] = {
                    type = "execute",
                    name = "Test Known Flight",
                    order = 1,
                    func = function(info)
                        addonCore:GetModule("StatusBarModule"):StartTimerBar("City1, Zone1", "City2, Zone2", 300)
                    end
                },
                ["testUnknown"] = {
                    type = "execute",
                    name = "Test Unknown Flight",
                    order = 2,
                    func = function(info)
                        addonCore:GetModule("StatusBarModule"):StartTimerBar("Unknown1, Zone1", "Unknown2, Zone2", 0, true)
                    end
                },
                ["stopTest"] = {
                    type = "execute",
                    name = "Stop Test",
                    order = 3,
                    func = function(info)
                        addonCore:GetModule("StatusBarModule"):StopTimerBar()
                    end
                }
            }
        },
        advancedOptions = {
            name = "Advanced Options",
            type = "group",
            order = 900,
            hidden = function()
                return not db.profile.ADVANCED_OPTIONS
            end,
            args = {
                helpText = {
                    name = "Not Implemented",
                    type = "description"
                }
            }
        }
    }
}
