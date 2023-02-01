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
--luacheck: no max line length
--luacheck: globals LibStub InCombatLockdown LibEdrik_GetDebugFunction TaxiNodeName GetNumRoutes NumTaxiNodes TaxiNodeGetType
--luacheck: globals UnitFactionGroup string UnitOnTaxi UnitInVehicle CreateFrame tostringall GetTime date SecondsToTime abs hooksecurefunc
--luacheck: globals C_SummonInfo InFlight_GetEstimatedTime TaxiFrame TaxiGetNodeSlot InFlight_TaxiFrame_TooltipHook GameTooltip

local Debug = LibEdrik_GetDebugFunction and LibEdrik_GetDebugFunction("|cff0040ffIn|cff00aaffFlight-C|r|r:", nil, nil, false) or function()
    end

local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "InFlight", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = addonCore

local L = LibStub("AceLocale-3.0"):GetLocale("InFlight")

local TaxiNodeName, GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot = TaxiNodeName, GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot

local db, playerFaction
local svDefaults = {
    char = {},
    profile = {
        showChat = true,
        confirmFlight = false
    },
    global = {
        Horde = {},
        Alliance = {}
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

    self:RegisterEvent("TAXIMAP_OPENED")
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
    local function ResetInFlightTimer(reason)
        taxiTimerFrame.taxiSrcName = nil
        taxiTimerFrame.taxiDestName = nil
        taxiTimerFrame.taxiStartTime = nil
        taxiTimerFrame.elapsedNotOnFlight = nil
        taxiTimerFrame.earlyExit = nil
        taxiTimerFrame:Hide()
        Debug("ResetInFlightTimer()", reason)
    end

    function addonCore:StartAFlight(source, destination)
        --there are no sanity Checks here -- use with care.
        ResetInFlightTimer("PreFlightReset")
        taxiTimerFrame.taxiSrcName = source
        taxiTimerFrame.taxiDestName = destination
        taxiTimerFrame:Show()
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
                Debug("State Changed, Prev:", prevState, "New:", self.taxiState)
                if self.taxiState then
                    self.taxiStartTime = GetTime()
                    Debug("OnTaxi:", self.taxiSrcName, "-->", self.taxiDestName, " -- StartTime:", date("%I:%M:%S %p"))

                    if db.global[playerFaction][self.taxiSrcName] then
                        if db.global[playerFaction][self.taxiSrcName][self.taxiDestName] then
                            local flightDurationFromDB = db.global[playerFaction][self.taxiSrcName][self.taxiDestName] --for Readablity.
                            Debug("TriggerEvent: InFlight_Taxi_Start -- Duration:", SecondsToTime(flightDurationFromDB))
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, flightDurationFromDB, false)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName, "-->", self.taxiDestName, "--", SecondsToTime(flightDurationFromDB))
                        else
                            Debug("TriggerEvent: InFlight_Taxi_Start -- Unknown Duration")
                            addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                        end
                    else
                        Debug("TriggerEvent: InFlight_Taxi_Start -- Unknown Duration")
                        addonCore:SendMessage("InFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                        addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                    end
                elseif (not self.taxiState) and (self.taxiStartTime) then
                    Debug("Off Taxi at:", date("%I:%M:%S %p"))
                    if not self.earlyExit then
                        Debug("No Early Exit")
                        local flightDuration = abs(GetTime() - self.taxiStartTime)
                        db.global[playerFaction][self.taxiSrcName] = db.global[playerFaction][self.taxiSrcName] or {}
                        db.global[playerFaction][self.taxiSrcName][self.taxiDestName] = math.floor(flightDuration)
                        Debug("TriggerEvent: InFlight_Taxi_Stop", self.taxiSrcName, "-->", self.taxiDestName, "-- Duration:", SecondsToTime(flightDuration))
                        addonCore:SendMessage("InFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, flightDuration)
                        addonCore:ChatMessage(L["Off Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName, "--", SecondsToTime(flightDuration))
                        return ResetInFlightTimer("End Of Normal Flight")
                    elseif self.earlyExit then
                        Debug("EarlyExit:", self.taxiSrcName, "-->", self.taxiDestName, " -- Reason: ", self.earlyExit)
                        addonCore:SendMessage("InFlight_Taxi_EarlyExit", self.taxiSrcName, self.taxiDestName, self.earlyExit)
                        addonCore:ChatMessage(L["Taxi Ended Early:"], self.earlyExit)
                        return ResetInFlightTimer("End of Flight: "..self.earlyExit )
                    end
                end
            end
            if (not self.taxiState) then
                self.elapsedNotOnFlight = (self.elapsedNotOnFlight or 0) + elapsed
                if self.elapsedNotOnFlight > 5 then
                    Debug("Failed Entry > 5sec, send Failed Entry Event and Reset?:", self.taxiSrcName, "-->", self.taxiDestName)
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
        taxiTimerFrame.earlyExit = L["Request Early Landing"]
    end
)

hooksecurefunc(
    "AcceptBattlefieldPort",
    function()
        taxiTimerFrame.earlyExit = L["Battlefield Port"]
    end
)

hooksecurefunc(
    C_SummonInfo,
    "ConfirmSummon",
    function()
        taxiTimerFrame.earlyExit = L["Accepted Summon"]
    end
)
---Estimated Flight Times - Transposed from origional code
function InFlight_GetEstimatedTime(taxiDestSlot)
    if not TaxiFrame:IsShown() then
        return
    end
    taxiDestSlot = tonumber(taxiDestSlot)
    if not taxiDestSlot then
        return
    end

    local taxiSrcName
    local taxiDestName = TaxiNodeName(taxiDestSlot)
    local numRoutes = GetNumRoutes(taxiDestSlot)
    if numRoutes < 2 then --if there are no hops between points then we cannot estimate anything.
        return
    end
    --Find Current Index and Name (because no generic global variables for this stuff)
    for index = 1, NumTaxiNodes() do
        local nodeType = TaxiNodeGetType(index)
        if nodeType == "CURRENT" then
            taxiSrcName = TaxiNodeName(index)
        end
    end

    local taxiNodes = {
        [1] = taxiSrcName,
        [numRoutes + 1] = taxiDestName
    }

    for hop = 2, numRoutes do
        taxiNodes[hop] = TaxiNodeName(TaxiGetNodeSlot(taxiDestSlot, hop, true))
    end

    local vars = addonCore.db.global[playerFaction]
    local etimes, prevNode, nextNode = {}, {}, {}
    local srcNode = 1
    local dstNode = #taxiNodes - 1
    while srcNode and srcNode < #taxiNodes do
        while dstNode and dstNode > srcNode do
            if vars[taxiNodes[srcNode]] then
                if not etimes[dstNode] and vars[taxiNodes[srcNode]][taxiNodes[dstNode]] then
                    etimes[dstNode] = etimes[srcNode] + vars[taxiNodes[srcNode]][taxiNodes[dstNode]]
                    nextNode[srcNode] = dstNode - 1
                    prevNode[dstNode] = srcNode
                    srcNode = dstNode
                    dstNode = #taxiNodes
                else
                    dstNode = dstNode - 1
                end
            else
                srcNode = prevNode[srcNode]
                dstNode = nextNode[srcNode]
            end
        end

        if not etimes[#taxiNodes] then
            srcNode = prevNode[srcNode]
            dstNode = nextNode[srcNode]
        end
    end
    if etimes[#taxiNodes] then
        Debug("Eta:", taxiSrcName, "-->", taxiDestName, etimes[#taxiNodes])
    end
    return etimes[#taxiNodes]
end

--This is the DefaultUI's Taxi Button, the ID needs to make sense.
--Default UI just directly assumes the GameTooltip because there is no "OnTaxiNodeSet" type handler.
function InFlight_TaxiFrame_TooltipHook(button) 
    if TaxiFrame:IsShown() and button:GetID() and (GameTooltip:GetOwner() == button) then
        local id = button:GetID()
        if TaxiNodeGetType(id) ~= "REACHABLE" then
            return
        end
        local taxiSrcName
        for index = 1, NumTaxiNodes() do
            local nodeType = TaxiNodeGetType(index)
            if nodeType == "CURRENT" then
                taxiSrcName = TaxiNodeName(index)
            end
        end
        local vars = addonCore.db.global[playerFaction]
        local duration = vars[taxiSrcName] and vars[taxiSrcName][TaxiNodeName(id)]
        if duration then
            GameTooltip:AddDoubleLine(L["Duration:"], SecondsToTime(duration))
        else
            local eta = InFlight_GetEstimatedTime(id)
            if eta then
                GameTooltip:AddDoubleLine(L["Duration:"], "~" .. SecondsToTime(eta))
            else
                GameTooltip:AddDoubleLine(L["Duration:"], "Unknown")
            end
        end
    end
end

function addonCore:TAXIMAP_OPENED(event, uiMapSystem)
    if TaxiFrame:IsShown() then
        if (uiMapSystem == Enum.UIMapSystem.Taxi) then
            for i = 1, NumTaxiNodes(), 1 do
                local tb = _G["TaxiButton" .. i]
                if tb and not tb.inflighted then
                    tb:HookScript("OnEnter", InFlight_TaxiFrame_TooltipHook)
                    tb.inflighted = true
                end
            end
        end
    end
end

---External / Internal APIs
function addonCore:GetFlightDuration(source, destination, faction)
    local src = (source and (type(source) == "string")) and source:trim()
    local dest = (source and (type(destination) == "string")) and destination:trim()
    local fact = (faction and (type(faction) == "string")) and faction:trim() or playerFaction
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
    local totalDuration = self:GetFlightDuration(self:GetCurrentFlightDetail())
    local timeRemaining
    if totalDuration then
        timeRemaining = totalDuration - timeOnFlight
    end

    return timeOnFlight, timeRemaining, totalDuration
end
---

do --Hoook Func
    local oldTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(slot, ...)
        for taxiIndex = 1, NumTaxiNodes(), 1 do
            if TaxiNodeGetType(taxiIndex) == "CURRENT" then
                local taxiSrcName = TaxiNodeName(taxiIndex)
                local taxiDestName = TaxiNodeName(slot)
                if taxiSrcName and taxiDestName then
                    addonCore:StartAFlight(taxiSrcName, taxiDestName)
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
        Debug("Checking:", gossipOptionID, gossipSelection.name)
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
