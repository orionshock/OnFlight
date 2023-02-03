--[[
    New OnFlight System
    Main Addon handles the Flight System
        Hooks,
        Figuring out when we're on flights and get off them
        Send Events via AceEvent when things happen.

        StatusBarMdoule handles the display
        Quartz also can handle the display
        --Maybe LDB will later?
Events:

OnFlight_Taxi_Start
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going
taxiDuration --Time in seconds from DB for how long the flight is.
    --if duration is 0 then it's an Unknown Flight--
unknownFlight -- true if there is no duration

OnFlight_Taxi_Stop
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going
taxiDuration --Time in seconds from DB for how long the flight is.

OnFlight_Taxi_EarlyExit
--Fired when any condtion happens that would prematurly exit a flight
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going
reason -- why did we exit early, a Displayable Name

OnFlight_Taxi_FAILED_ENTRY
--Fired when we think we're about to get on a fligth but it dosn't work
taxiSrcName --Full Proper name from API for where we started
taxiDestName --Full Proper name from API for where we are going

]]
--luacheck: no max line length
--luacheck: globals LibStub InCombatLockdown LibEdrik_GetDebugFunction TaxiNodeName GetNumRoutes NumTaxiNodes TaxiNodeGetType
--luacheck: globals UnitFactionGroup string UnitOnTaxi UnitInVehicle CreateFrame tostringall GetTime date SecondsToTime abs hooksecurefunc
--luacheck: globals C_SummonInfo OnFlight_GetEstimatedTime TaxiFrame TaxiGetNodeSlot OnFlight_TaxiFrame_TooltipHook GameTooltip

local Debug = LibEdrik_GetDebugFunction and LibEdrik_GetDebugFunction("|cff0040ffOn|cFF00FF00Flight|r|r-C", nil, nil, false) or function()
    end

local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "OnFlight", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = addonCore

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

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
    playerFaction = UnitFactionGroup("player")
    self.db = LibStub("AceDB-3.0"):New("OnFlightSV", svDefaults, true)
    db = self.db
    db.global[playerFaction] = db.global[playerFaction] or {}
    db.profile.ADVANCED_OPTIONS = false

    self.configOptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.configOptionsTable.args.profiles.order = 800

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 770, 475)

    self:RegisterChatCommand("OnFlight", "ChatCommand")
end

function addonCore:OnEnable()
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
        LibStub("AceConfigCmd-3.0").HandleCommand(addonCore, "OnFlight", addonName, input)
    end
end

function addonCore:ChatMessage(...)
    if not self.db.profile.showChat then
        return
    end
    local msg = string.join(" ", tostringall(...))
    msg = msg:trim()
    if msg then
        print("|cff0040ffOn|cFF00FF00Flight|r|r:", msg)
    end
end

local taxiTimerFrame = CreateFrame("frame")
taxiTimerFrame:Hide()
taxiTimerFrame.taxiState = false
do
    local function ResetOnFlightTimer(reason)
        taxiTimerFrame.taxiSrcName = nil
        taxiTimerFrame.taxiDestName = nil
        taxiTimerFrame.taxiStartTime = nil
        taxiTimerFrame.elapsedNotOnFlight = nil
        taxiTimerFrame.earlyExit = nil
        taxiTimerFrame:Hide()
        Debug("ResetOnFlightTimer()", reason)
    end

    function addonCore:StartAFlight(source, destination)
        --there are no sanity Checks here -- use with care.
        ResetOnFlightTimer("PreFlightReset")
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
                return ResetOnFlightTimer()
            end

            if (prevState ~= self.taxiState) then
                Debug("State Changed, Prev:", prevState, "New:", self.taxiState)
                if self.taxiState then
                    self.taxiStartTime = GetTime()
                    Debug("OnTaxi:", self.taxiSrcName, "-->", self.taxiDestName, " -- StartTime:", date("%I:%M:%S %p"))

                    if db.global[playerFaction][self.taxiSrcName] then
                        if db.global[playerFaction][self.taxiSrcName][self.taxiDestName] then
                            local flightDurationFromDB = db.global[playerFaction][self.taxiSrcName][self.taxiDestName] --for Readablity.
                            Debug("TriggerEvent: OnFlight_Taxi_Start -- Duration:", SecondsToTime(flightDurationFromDB))
                            addonCore:SendMessage("OnFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, flightDurationFromDB, false)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName, "-->", self.taxiDestName, "--", SecondsToTime(flightDurationFromDB))
                        else
                            Debug("TriggerEvent: OnFlight_Taxi_Start -- Unknown Duration")
                            addonCore:SendMessage("OnFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                        end
                    else
                        Debug("TriggerEvent: OnFlight_Taxi_Start -- Unknown Duration")
                        addonCore:SendMessage("OnFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                        addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                    end
                elseif (not self.taxiState) and (self.taxiStartTime) then
                    Debug("Off Taxi at:", date("%I:%M:%S %p"))
                    if not self.earlyExit then
                        Debug("No Early Exit")
                        local flightDuration = abs(GetTime() - self.taxiStartTime)
                        db.global[playerFaction][self.taxiSrcName] = db.global[playerFaction][self.taxiSrcName] or {}
                        db.global[playerFaction][self.taxiSrcName][self.taxiDestName] = math.floor(flightDuration)
                        Debug("TriggerEvent: OnFlight_Taxi_Stop", self.taxiSrcName, "-->", self.taxiDestName, "-- Duration:", SecondsToTime(flightDuration))
                        addonCore:SendMessage("OnFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, flightDuration)
                        addonCore:ChatMessage(L["Off Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName, "--", SecondsToTime(flightDuration))
                        return ResetOnFlightTimer("End Of Normal Flight")
                    elseif self.earlyExit then
                        Debug("EarlyExit:", self.taxiSrcName, "-->", self.taxiDestName, " -- Reason: ", self.earlyExit)
                        addonCore:SendMessage("OnFlight_Taxi_EarlyExit", self.taxiSrcName, self.taxiDestName, self.earlyExit)
                        addonCore:ChatMessage(L["Taxi Ended Early:"], self.earlyExit)
                        return ResetOnFlightTimer("End of Flight: " .. self.earlyExit)
                    end
                end
            end
            if (not self.taxiState) then
                self.elapsedNotOnFlight = (self.elapsedNotOnFlight or 0) + elapsed
                if self.elapsedNotOnFlight > 5 then
                    Debug("Failed Entry > 5sec, send Failed Entry Event and Reset?:", self.taxiSrcName, "-->", self.taxiDestName)
                    addonCore:SendMessage("OnFlight_Taxi_FAILED_ENTRY", self.taxiSrcName, self.taxiDestName)
                    return ResetOnFlightTimer("FAILED_ENTRY")
                end
            end
        end
    )
end

-- function hooks to detect if we left a flight early
hooksecurefunc(
    "TaxiRequestEarlyLanding",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Request Early Landing"]
            Debug("Early Exit Trigger: TaxiRequestEarlyLanding")
        end
    end
)

hooksecurefunc(
    "AcceptBattlefieldPort",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Battlefield Port"]
            Debug("Early Exit Trigger: AcceptBattlefieldPort")
        end
    end
)

hooksecurefunc(
    C_SummonInfo,
    "ConfirmSummon",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Accepted Summon"]
            Debug("Early Exit Trigger: ConfirmSummon")
        end
    end
)
---Estimated Flight Times - Transposed from origional code
function OnFlight_GetEstimatedTime(taxiDestSlot)
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
                    etimes[dstNode] = (etimes[srcNode] or 0) + (vars[taxiNodes[srcNode]][taxiNodes[dstNode]] or 0)
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
function OnFlight_TaxiFrame_TooltipHook(button)
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
            local eta = OnFlight_GetEstimatedTime(id)
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
                if tb and not tb.OnFlighted then
                    tb:HookScript("OnEnter", OnFlight_TaxiFrame_TooltipHook)
                    tb.OnFlighted = true
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

local gossipOptionTemplate = {
    name = "",
    type = "group",
    inline = true,
    args = {
        name = {
            order = 1,
            name = "Gossip ID",
            type = "input",
            get = function(info)
                return info[#info - 1]
            end,
            set = function()
            end,
            disabled = true
        },
        sourceName = {
            order = 2,
            type = "input",
            name = "Source Name",
            get = function(info)
                local id = tonumber(info[#info - 1])
                return db.global.gossipTriggered[id][1]
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                db.global.gossipTriggered[id][1] = value
            end
        },
        destinationName = {
            order = 3,
            type = "input",
            name = "Destination Name",
            get = function(info)
                local id = tonumber(info[#info - 1])
                return db.global.gossipTriggered[id][2]
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                db.global.gossipTriggered[id][2] = value
            end
        },
        remove = {
            order = 4,
            name = "Remove",
            type = "execute",
            func = function(info)
                local id = tonumber(info[#info - 1])
                db.global.gossipTriggered[id] = nil
                addonCore:RefreshAdvOptions()
            end
        }
    }
}

local addNew_Temp = {}
local addNew_Temp_get = function(info)
    return addNew_Temp[info[#info]]
end
local addNew_Temp_set = function(info, value)
    addNew_Temp[info[#info]] = value
end
local gossipOptionTemplate_AddNew = {
    name = "",
    type = "group",
    inline = true,
    order = 999,
    args = {
        name = {
            order = 1,
            name = "Gossip ID",
            type = "input",
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        sourceName = {
            order = 2,
            type = "input",
            name = "Source Name",
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        destinationName = {
            order = 3,
            type = "input",
            name = "Destination Name",
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        addNew = {
            order = 4,
            name = "Add New",
            type = "execute",
            func = function()
                local id = tonumber(addNew_Temp.name)
                if not id then
                    return
                end
                db.global.gossipTriggered[id] = {
                    addNew_Temp.sourceName,
                    addNew_Temp.destinationName
                }
                wipe(addNew_Temp)
                addonCore:RefreshAdvOptions()
            end
        }
    }
}

function addonCore:RefreshAdvOptions()
    local opt = wipe(self.configOptionsTable.args.advancedOptions.args)
    for k, _ in pairs(db.global.gossipTriggered) do
        opt[tostring(k)] = gossipOptionTemplate
    end
    opt.AddNewGossipID = gossipOptionTemplate_AddNew
end

addonCore.configOptionsTable = {
    type = "group",
    name = L["OnFlight Options"],
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
                ADVANCED_OPTIONS = {
                    name = L["Show Advanced Options"],
                    type = "toggle",
                    order = 100,
                    set = function(_, option)
                        db.profile.ADVANCED_OPTIONS = option
                        if db.profile.ADVANCED_OPTIONS then
                            addonCore:RefreshAdvOptions()
                        end
                    end
                },
                testButtons = {
                    type = "group",
                    inline = true,
                    name = "Test Buttons",
                    order = 350,
                    args = {
                        ["testKnown"] = {
                            type = "execute",
                            name = "Test Known Flight",
                            order = 1,
                            func = function()
                                addonCore:GetModule("StatusBarModule"):StartTimerBar("City1, Zone1", "City2, Zone2", 300)
                            end
                        },
                        ["testUnknown"] = {
                            type = "execute",
                            name = "Test Unknown Flight",
                            order = 2,
                            func = function()
                                addonCore:GetModule("StatusBarModule"):StartTimerBar("Unknown1, Zone1", "Unknown2, Zone2", 0, true)
                            end
                        },
                        ["stopTest"] = {
                            type = "execute",
                            name = "Stop Test",
                            order = 3,
                            func = function()
                                addonCore:GetModule("StatusBarModule"):StopTimerBar()
                            end
                        }
                    }
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
            args = {}
        }
    }
}
