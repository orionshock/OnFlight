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
--luacheck: globals LibStub InCombatLockdown TaxiNodeName GetNumRoutes NumTaxiNodes TaxiNodeGetType
--luacheck: globals UnitFactionGroup string UnitOnTaxi UnitInVehicle CreateFrame tostringall GetTime date SecondsToTime abs hooksecurefunc
--luacheck: globals C_SummonInfo OnFlight_GetEstimatedTime TaxiFrame TaxiGetNodeSlot OnFlight_TaxiFrame_TooltipHook GameTooltip wipe


local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "OnFlight", "AceConsole-3.0", "AceEvent-3.0")
addonCore.OnFlightPrefixText = "|cff0040ffOn|cFF00FF00Flight|r|r"
_G[addonName] = addonCore

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local TaxiNodeName, GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot = TaxiNodeName, GetNumRoutes,
    NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot

local db, playerFaction

local svDefaults = {
    char = {},
    profile = {
        showChat = true,
        gossipConfig = false,
        moduleState = {
            ["*"] = true,
        }
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

    self.configOptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.configOptionsTable.args.profiles.order = 800

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 770, 475)

    self.optionFrames = {
        mainPannel = { LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "On Flight") }
    }
    self:RegisterChatCommand("OnFlight", "ChatCommand")
end

function addonCore:OnEnable()
    self:RegisterEvent("TAXIMAP_OPENED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEAVING_WORLD")
    self:RegisterEvent("LFG_PROPOSAL_DONE")
end

-- function addonCore:OnDisable()
-- end

function addonCore.ChatCommand(_, input)
    if InCombatLockdown() then
        addonCore.SendMessage("In Combat")
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
        print(addonCore.OnFlightPrefixText, msg)
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
        taxiTimerFrame.timeRmaining = nil
        taxiTimerFrame:Hide()
    end

    function addonCore.StartAFlight(_, source, destination, timeRmaining, forceEarlyExitState)
        ResetOnFlightTimer("PreFlightReset")
        taxiTimerFrame.taxiSrcName = source
        taxiTimerFrame.taxiDestName = destination
        taxiTimerFrame.timeRmaining = timeRmaining
        if timeRmaining or forceEarlyExitState then
            taxiTimerFrame.earlyExit = forceEarlyExitState
        end
        taxiTimerFrame:Show()
    end

    local UnitOnTaxi, UnitInVehicle = UnitOnTaxi, UnitInVehicle
    taxiTimerFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            local prevState = self.taxiState
            self.taxiState = UnitOnTaxi("player") or UnitInVehicle("player")

            if (not self.taxiSrcName) or (not self.taxiDestName) then
                return ResetOnFlightTimer("OnUpdateMonitor, no src or dest")
            end

            if (prevState ~= self.taxiState) then
                if self.taxiState then
                    self.taxiStartTime = self.taxiStartTime or GetTime()
                    local flightDurationFromDB = addonCore:GetFlightDuration(self.taxiSrcName, self.taxiDestName)
                    if flightDurationFromDB then
                        if taxiTimerFrame.timeRmaining then
                            addonCore:SendMessage("OnFlight_Taxi_RESUME", self.taxiSrcName, self.taxiDestName,
                                flightDurationFromDB, self.timeRmaining)
                            addonCore:ChatMessage(L["Resume On Taxi:"], self.taxiSrcName, "-->", self.taxiDestName)
                        else
                            addonCore:SendMessage("OnFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName,
                                flightDurationFromDB, false)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName, "-->", self.taxiDestName, "--",
                                SecondsToTime(flightDurationFromDB))
                        end
                    else
                        if taxiTimerFrame.timeRmaining then
                            addonCore:SendMessage("OnFlight_Taxi_RESUME", self.taxiSrcName, self.taxiDestName, nil, nil,
                                true)
                            addonCore:ChatMessage(L["Resume On Taxi:"], self.taxiSrcName, "-->", self.taxiDestName)
                        else
                            addonCore:SendMessage("OnFlight_Taxi_Start", self.taxiSrcName, self.taxiDestName, 0, true)
                            addonCore:ChatMessage(L["On Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName)
                        end
                    end
                elseif (not self.taxiState) and (self.taxiStartTime) then
                    if not self.earlyExit then
                        local flightDuration = abs(GetTime() - self.taxiStartTime)
                        db.global[playerFaction][self.taxiSrcName] = db.global[playerFaction][self.taxiSrcName] or {}
                        db.global[playerFaction][self.taxiSrcName][self.taxiDestName] = math.floor(flightDuration)
                        addonCore:SendMessage("OnFlight_Taxi_Stop", self.taxiSrcName, self.taxiDestName, flightDuration)
                        addonCore:ChatMessage(L["Off Taxi:"], self.taxiSrcName .. " --> " .. self.taxiDestName, "--",
                            SecondsToTime(flightDuration))
                        return ResetOnFlightTimer("End Of Normal Flight")
                    elseif self.earlyExit then
                        addonCore:SendMessage("OnFlight_Taxi_EarlyExit", self.taxiSrcName, self.taxiDestName,
                            self.earlyExit)
                        addonCore:ChatMessage(L["Taxi Ended Early:"], self.earlyExit)
                        return ResetOnFlightTimer("End of Flight: " .. self.earlyExit)
                    end
                end
            end
            if (not self.taxiState) then
                self.elapsedNotOnFlight = (self.elapsedNotOnFlight or 0) + elapsed
                if self.elapsedNotOnFlight > 5 then
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
        end
    end
)

hooksecurefunc(
    "AcceptBattlefieldPort",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Battlefield Port"]
        end
    end
)

hooksecurefunc(
    C_SummonInfo,
    "ConfirmSummon",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Accepted Summon"]
        end
    end
)

hooksecurefunc(
    "ReloadUI",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Reloading UI"]
        end
    end
)
hooksecurefunc(
    "Logout",
    function()
        if taxiTimerFrame and taxiTimerFrame:IsShown() then
            taxiTimerFrame.earlyExit = L["Logout"]
        end
    end
)

function addonCore:LFG_PROPOSAL_DONE(event, ...)
    --if your in flight then there should be nothing preventing you from accepting a port
    --however there might be some quest taxis that will prevent it as they are vehicles not flights.
    if taxiTimerFrame and taxiTimerFrame:IsShown() then
        taxiTimerFrame.earlyExit = L["LFG Port"]
    end
end

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
            GameTooltip:Show()
        else
            local eta = OnFlight_GetEstimatedTime(id)
            if eta then
                GameTooltip:AddDoubleLine(L["Duration:"], "~" .. SecondsToTime(eta))
                GameTooltip:Show()
            else
                GameTooltip:AddDoubleLine(L["Duration:"], "Unknown")
                GameTooltip:Show()
            end
        end
    end
end

function addonCore.TAXIMAP_OPENED(_, event, uiMapSystem)
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

function addonCore:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    if (taxiTimerFrame.taxiSrcName and taxiTimerFrame.taxiDestName) and (not taxiTimerFrame.earlyExit) then
        taxiTimerFrame:Show()
        return
    end
    if db.char.taxiSrcName and db.char.taxiDestName then
        local flightDuration = self:GetFlightDuration(db.char.taxiSrcName, db.char.taxiDestName)
        if flightDuration then
            self:StartAFlight(db.char.taxiSrcName, db.char.taxiDestName, db.char.timeRemaining, db.char.earlyExit)
        else
            self:StartAFlight(db.char.taxiSrcName, db.char.taxiDestName, nil, db.char.earlyExit)
            if (not db.char.timeRemaining) and (not taxiTimerFrame.earlyExit) then
                taxiTimerFrame.taxiStartTime = db.char.taxiStartTime
            end
        end
        wipe(db.char)
    end
end

function addonCore:PLAYER_LEAVING_WORLD(event)
    if not self:IsOnFlight() then
        return
    end
    if not taxiTimerFrame.earlyExit then
        taxiTimerFrame:Hide() --to keep the onUpdate after PLW from causing db to save
        return
    elseif taxiTimerFrame.earlyExit then
        db.char.taxiSrcName = taxiTimerFrame.taxiSrcName
        db.char.taxiDestName = taxiTimerFrame.taxiDestName
        db.char.earlyExit = taxiTimerFrame.earlyExit
        local flightProgress = GetTime() - taxiTimerFrame.taxiStartTime
        local flightDuration = self:GetFlightDuration(db.char.taxiSrcName, db.char.taxiDestName)
        if flightDuration then
            db.char.timeRemaining = flightDuration - flightProgress
        else
            db.char.taxiStartTime = taxiTimerFrame.taxiStartTime
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

do --Direct Hoook Funcs
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
    hooksecurefunc(
        C_GossipInfo,
        "SelectOption",
        function(option, ...)
            if db.global.gossipTriggered[option] then
                addonCore:StartAFlight(unpack(db.global.gossipTriggered[option]))
            end
        end
    )

    local original_C_GossipInfo_SelectOptionByIndex = C_GossipInfo.SelectOptionByIndex

    function C_GossipInfo.SelectOptionByIndex(...)
        local selectedIndex = tonumber(...)
        local gossipOptions = C_GossipInfo.GetOptions()
        for _, optionData in ipairs(gossipOptions) do
            if optionData.orderIndex == selectedIndex then
                local selectedGossipID = optionData.gossipOptionID
                if db.global.gossipTriggered[selectedGossipID] then
                    addonCore:StartAFlight(unpack(db.global.gossipTriggered[selectedGossipID]))
                    break
                end
            end
        end
        original_C_GossipInfo_SelectOptionByIndex(...)
    end

    hooksecurefunc(
        GossipOptionButtonMixin,
        "Setup",
        function(self, optionInfo)
            self:SetScript(
                "OnEnter",
                function(frame)
                    if db and db.profile.showGossipConfig then
                        if frame.GetData then
                            local data = frame:GetData()
                            local gossipID = data and data.info.gossipOptionID or "??"
                            GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                            GameTooltip:AddLine("gossipOptionID: " .. gossipID)
                            GameTooltip:Show()
                        end
                    end
                end
            )
            self:SetScript(
                "OnLeave",
                function(frame)
                    GameTooltip:Hide()
                end
            )
        end
    )
end

---Ace3 Config Table
function addonCore:GetOption(info)
    if info.type == "color" then
        if db.profile[info[#info]] then
            return db.profile[info[#info]].r, db.profile[info[#info]].b, db[info[#info]].g, db.profile[info[#info]].a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100,
                math.random(0, 100) / 100
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
    else
        db.profile[info[#info]] = ...
    end
end

local gossipOptionTemplate = {
    name = "",
    type = "group",
    inline = true,
    order = function(info)
        return tonumber(info[#info])
    end,
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
    order = -1,
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

function addonCore:GetModuleStatus(info)
    return db.profile.moduleState[info[#info]]
end

function addonCore:SetModuleStatus(info, value)
    db.profile.moduleState[info[#info]] = value
    if value == true then
        addonCore:EnableModule(info[#info])
    else
        addonCore:DisableModule(info[#info])
    end
end

function addonCore:RefreshAdvOptions()
    local opt = wipe(self.configOptionsTable.args.gossipConfigTab.args)
    for k, _ in pairs(db.global.gossipTriggered) do
        opt[tostring(k)] = gossipOptionTemplate
    end
    opt.AddNewGossipID = gossipOptionTemplate_AddNew
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
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
            name = L["Main Options"],
            type = "group",
            order = 10,
            width = "full",
            args = {
                showChat = {
                    name = L["Show Chat Messages"],
                    desc = L["Show Flight Status Messages in Chat Window"],
                    type = "toggle",
                    order = 10
                },
                showGossipConfig = {
                    name = L["Show Gossip Config"],
                    desc = L["Show Gossip Config Pannel to add or remove Gossip Initated Travel"],
                    type = "toggle",
                    order = 20,
                    get = function(info)
                        return db.profile.showGossipConfig
                    end,
                    set = function(_, option)
                        db.profile.showGossipConfig = option
                        if db.profile.showGossipConfig then
                            addonCore:RefreshAdvOptions()
                        end
                    end
                },
                moduleControl = {
                    name = L["Module Control"],
                    type = "group",
                    inline = true,
                    order = 100,
                    args = {
                        StatusBarModule = {
                            name = L["Flight Timer Bar"],
                            desc = L["The Built in Timer Bar that comes with OnFlight"],
                            type = "toggle",
                            get = "GetModuleStatus",
                            set = "SetModuleStatus",

                        },
                        FlightListWindow = {
                            name = L["Flight Destinatoins"],
                            desc = L["Companion Window to the Flight Master"],
                            type = "toggle",
                            get = "GetModuleStatus",
                            set = "SetModuleStatus",
                        }
                    }
                }
            }
        },
        gossipConfigTab = {
            name = "Gossip Configuration",
            type = "group",
            order = 900,
            hidden = function()
                return not db.profile.showGossipConfig
            end,
            args = {}
        }
    }
}
