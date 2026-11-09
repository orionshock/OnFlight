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

local GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot = GetNumRoutes,
    NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot

local db, playerFaction

-- Node names are session-local presentation data, never database keys.
local nodeCache, taxiSession = {}, nil

function addonCore:GetTaxiNodeName(nodeID)
    if type(nodeID) ~= "number" then return end
    if not nodeCache[nodeID] then
        for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(947)) do
            nodeCache[node.nodeID] = node.name
        end
    end
    return nodeCache[nodeID]
end

function addonCore:GetTaxiSession()
    if taxiSession and TaxiFrame:IsShown() and taxiSession.mapID == GetTaxiMapID() then return taxiSession end
end

function addonCore:RefreshTaxiSession()
    if not TaxiFrame:IsShown() then return end
    local mapID = GetTaxiMapID()
    if not mapID then return end
    local session = { mapID = mapID, nodes = {}, slotToID = {}, idToSlot = {} }
    for _, node in ipairs(C_TaxiMap.GetAllTaxiNodes(mapID)) do
        local slot, id = node.slotIndex, node.nodeID
        if slot and slot > 0 and id and id > 0 then
            session.nodes[id], nodeCache[id] = node, node.name
            session.slotToID[slot], session.idToSlot[id] = id, slot
            if TaxiNodeGetType(slot) == "CURRENT" then session.sourceID = id end
        end
    end
    if not session.sourceID then return end
    for slot = 1, NumTaxiNodes() do
        if TaxiNodeGetType(slot) ~= "NONE" and not session.slotToID[slot] then return end
    end
    taxiSession = session
    return session
end

function addonCore:GetTaxiRoute(destinationID)
    local session = self:GetTaxiSession()
    local slot = session and session.idToSlot[destinationID]
    if not slot then return end
    local hops = GetNumRoutes(slot)
    local route = { [1] = session.sourceID, [hops + 1] = destinationID }
    -- Preserve the estimator's existing intermediate-source ordering.
    for hop = 2, hops do
        local id = session.slotToID[TaxiGetNodeSlot(slot, hop, true)]
        if not id then return end
        route[hop] = id
    end
    return route
end

local taxiSessionFrame = CreateFrame("Frame")

local svDefaults = {
    char = {},
    profile = {
        showChat = true,
        gossipConfig = false,
        showGossipConfig = false,
        gossipdebug = false,
        favorites = {},
        moduleState = {
            ["*"] = true,
        }
    },
    global = {
        flightTimes = { Horde = {}, Alliance = {} }
    }
}
addonCore.svDefaults = svDefaults

function addonCore:OnInitialize()
    playerFaction = UnitFactionGroup("player")
    self.db = LibStub("AceDB-3.0"):New("OnFlightSV", svDefaults, true)
    db = self.db
    -- Flights only survive loading screens within this Lua session, never a reload/login.
    wipe(db.char)
    db.global.flightTimes[playerFaction] = db.global.flightTimes[playerFaction] or {}
    db.profile.gossipConfig = false
    db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdated")
    db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdated")
    db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdated")

    self.configOptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.configOptionsTable.args.profiles.order = 800

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    self:RegisterChatCommand("OnFlight", "ChatCommand")
end

function addonCore:OnEnable()
    self:InitializeSettings()
    self:RegisterEvent("TAXIMAP_OPENED")
    self:RegisterEvent("TAXIMAP_CLOSED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEAVING_WORLD")
    self:RegisterEvent("LFG_PROPOSAL_DONE")
end

-- function addonCore:OnDisable()
-- end

function addonCore.ChatCommand(_, input)
    if InCombatLockdown() then
        addonCore:Print(L["In Combat"])
        return
    end
    if not input or input:trim() == "" then
        addonCore:OpenSettings()
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

-- The monitor schedules work; the private record owns all flight state.
local flight
local flightMonitor = CreateFrame("Frame")

local function ResetFlight()
    flight = nil
    flightMonitor:SetScript("OnUpdate", nil)
end

local function UpdateFlight(_, elapsed)
    local previous = flight.onTaxi
    flight.onTaxi = UnitOnTaxi("player") or UnitInVehicle("player")

    if previous ~= flight.onTaxi then
        if flight.onTaxi then
            flight.elapsedNotOnFlight = nil
            flight.startedAt = flight.startedAt or GetTime()
            local duration = addonCore:GetFlightDuration(flight.sourceID, flight.destinationID)
            if duration then
                if flight.resumeRemaining then
                    addonCore:SendMessage("OnFlight_Taxi_RESUME", flight.sourceName, flight.destinationName,
                        duration, flight.resumeRemaining)
                    addonCore:ChatMessage(L["Resume On Taxi:"], flight.sourceName, "-->", flight.destinationName)
                else
                    addonCore:SendMessage("OnFlight_Taxi_Start", flight.sourceName, flight.destinationName, duration, false)
                    addonCore:ChatMessage(L["On Taxi:"], flight.sourceName, "-->", flight.destinationName, "--", SecondsToTime(duration))
                end
            elseif flight.resumeRemaining then
                addonCore:SendMessage("OnFlight_Taxi_RESUME", flight.sourceName, flight.destinationName, nil, nil, true)
                addonCore:ChatMessage(L["Resume On Taxi:"], flight.sourceName, "-->", flight.destinationName)
            else
                addonCore:SendMessage("OnFlight_Taxi_Start", flight.sourceName, flight.destinationName, 0, true)
                addonCore:ChatMessage(L["On Taxi:"], flight.sourceName .. " --> " .. flight.destinationName)
            end
        elseif flight.startedAt then
            if not flight.earlyExit then
                local duration = abs(GetTime() - flight.startedAt)
                local times = db.global.flightTimes[playerFaction]
                times[flight.sourceID] = times[flight.sourceID] or {}
                times[flight.sourceID][flight.destinationID] = math.floor(duration)
                addonCore:SendMessage("OnFlight_Taxi_Stop", flight.sourceName, flight.destinationName, duration)
                addonCore:ChatMessage(L["Off Taxi:"], flight.sourceName .. " --> " .. flight.destinationName, "--", SecondsToTime(duration))
            else
                addonCore:SendMessage("OnFlight_Taxi_EarlyExit", flight.sourceName, flight.destinationName, flight.earlyExit)
                addonCore:ChatMessage(L["Taxi Ended Early:"], flight.earlyExit)
            end
            return ResetFlight()
        end
    end
    if not flight.onTaxi then
        flight.elapsedNotOnFlight = (flight.elapsedNotOnFlight or 0) + elapsed
        if flight.elapsedNotOnFlight > 5 then
            addonCore:SendMessage("OnFlight_Taxi_FAILED_ENTRY", flight.sourceName, flight.destinationName)
            ResetFlight()
        end
    end
end

function addonCore:StartAFlight(source, destination, timeRemaining, forceEarlyExitState, route)
    local sourceName = self:GetFlightEndpointName(source)
    local destinationName = self:GetFlightEndpointName(destination)
    if not sourceName or not destinationName then return end
    flight = { sourceID = source, destinationID = destination, route = route or {},
        sourceName = sourceName, destinationName = destinationName, onTaxi = false,
        resumeRemaining = timeRemaining, earlyExit = forceEarlyExitState }
    flightMonitor:SetScript("OnUpdate", UpdateFlight)
end

-- function hooks to detect if we left a flight early
hooksecurefunc(
    "TaxiRequestEarlyLanding",
    function()
        if flight and not flight.suspended then
            flight.earlyExit = L["Request Early Landing"]
        end
    end
)

hooksecurefunc(
    "AcceptBattlefieldPort",
    function()
        if flight and not flight.suspended then
            flight.earlyExit = L["Battlefield Port"]
        end
    end
)

hooksecurefunc(
    C_SummonInfo,
    "ConfirmSummon",
    function()
        if flight and not flight.suspended then
            flight.earlyExit = L["Accepted Summon"]
        end
    end
)

function addonCore:LFG_PROPOSAL_DONE(event, ...)
    if flight and not flight.suspended then
        flight.earlyExit = L["LFG Port"]
    end
end

---Estimated Flight Times - Transposed from origional code
---@param destinationID number
function OnFlight_GetEstimatedTime(destinationID)
    if not TaxiFrame:IsShown() then
        return
    end
    destinationID = tonumber(destinationID)
    local session = addonCore:GetTaxiSession()
    local taxiDestSlot = session and session.idToSlot[destinationID]
    if not taxiDestSlot then return end
    local numRoutes = GetNumRoutes(taxiDestSlot)
    if numRoutes < 2 then return end
    local taxiNodes = addonCore:GetTaxiRoute(destinationID)
    if not taxiNodes then return end
    local vars = addonCore.db.global.flightTimes[playerFaction]
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
        local session = addonCore:GetTaxiSession()
        if not session then return end
        local duration = addonCore:GetFlightDuration(session.sourceID, session.slotToID[id])
        if duration then
            GameTooltip:AddDoubleLine(L["Duration:"], SecondsToTime(duration))
            GameTooltip:Show()
        else
            local eta = OnFlight_GetEstimatedTime(session.slotToID[id])
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

function addonCore:TAXIMAP_OPENED(event, uiMapSystem)
    taxiSession = nil
    local function initialize()
        if self:RefreshTaxiSession() then
            taxiSessionFrame:SetScript("OnUpdate", nil)
            for i = 1, NumTaxiNodes(), 1 do
                local tb = _G["TaxiButton" .. i]
                if tb and not tb.OnFlighted then
                    tb:HookScript("OnEnter", OnFlight_TaxiFrame_TooltipHook)
                    tb.OnFlighted = true
                end
            end
            self:SendMessage("OnFlight_TaxiMapReady")
        end
    end
    -- Poll only until the open map has populated its slot mappings.
    taxiSessionFrame:SetScript("OnUpdate", initialize)
    initialize()
end

function addonCore:TAXIMAP_CLOSED()
    taxiSessionFrame:SetScript("OnUpdate", nil)
    taxiSession = nil
end

-- A different displayed continent has its own slot numbering.
hooksecurefunc("SetTaxiMap", function()
    if taxiSession and taxiSession.mapID ~= GetTaxiMapID() then addonCore:TAXIMAP_OPENED() end
end)

function addonCore:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    if flight then
        flight.suspended = nil
        flightMonitor:SetScript("OnUpdate", UpdateFlight)
        if flight.startedAt then
            -- World-entry resume uses the measured duration and full elapsed time.
            flight.resumeRemaining = nil
            local elapsed, remaining, duration = self:GetCurrentFlightProgress()
            self:SendMessage("OnFlight_Taxi_RESUME", flight.sourceName, flight.destinationName,
                duration, remaining, not duration, elapsed)
        end
    end
end

function addonCore:PLAYER_LEAVING_WORLD(event)
    if not self:IsOnFlight() then return end
    -- UnitOnTaxi may briefly be false during a transfer. Keep the timing origin.
    flight.suspended = true
    flightMonitor:SetScript("OnUpdate", nil)
    self:SendMessage("OnFlight_Taxi_Suspend")
end

---External / Internal APIs
function addonCore:GetFlightDuration(source, destination, faction)
    local fact = type(faction) == "string" and faction:trim() or playerFaction
    local times = db.global.flightTimes[fact]
    return times and times[source] and times[source][destination]
end

-- Consumers may read this record; only the core updates it.
function addonCore:GetCurrentFlight()
    return flight
end

function addonCore:IsOnFlight()
    return flight ~= nil and not flight.suspended
end

function addonCore:GetCurrentFlightDetail()
    if self:IsOnFlight() then return flight.sourceName, flight.destinationName end
end

function addonCore:GetCurrentFlightProgress()
    if not self:IsOnFlight() or not flight.startedAt then return end
    local elapsed = GetTime() - flight.startedAt
    local duration = self:GetFlightDuration(flight.sourceID, flight.destinationID)
    local remaining
    if duration then remaining = duration - elapsed end
    return elapsed, remaining, duration
end

do --Direct Hoook Funcs
    local oldTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(slot, ...)
        local session = addonCore:RefreshTaxiSession()
        local destinationID = session and session.slotToID[slot]
        if destinationID then
            local route = addonCore:GetTaxiRoute(destinationID)
            if route then addonCore:StartAFlight(session.sourceID, destinationID, nil, nil, route) end
        end
        oldTakeTaxiNode(slot, ...)
    end
end

-- Custom gossip endpoints never resolve by name to a taxi node.
function addonCore:GetGossipEndpoint(optionID, value)
    if type(value) == "number" then return value, self:GetTaxiNodeName(value) end
    if type(value) ~= "string" then return end
    local prefix = tostring(optionID) .. ":"
    local label = value:sub(1, #prefix) == prefix and value:sub(#prefix + 1) or value
    label = label:match("^%s*(.-)%s*$")
    if label ~= "" then return prefix .. label, label end
end

function addonCore:ParseGossipEndpoint(optionID, text)
    local value = text:match("^%s*(.-)%s*$")
    if value == "" then return nil, "Enter a taxi-node ID or custom location name." end
    if value:match("^%d+$") then
        local id = tonumber(value)
        local name = self:GetTaxiNodeName(id)
        if name then return id, name end
        return nil, "Unknown taxi-node ID. Saved value unchanged."
    end
    return tostring(optionID) .. ":" .. value, value
end

function addonCore:GetFlightEndpointName(key)
    if type(key) == "number" then return self:GetTaxiNodeName(key) end
    if type(key) == "string" then return key:match("^%d+:(.+)$") end
end

function addonCore:StartGossipFlight(optionID)
    local endpoints = db.global.gossipTriggered[optionID]
    if not endpoints then return end
    local source, sourceName = self:GetGossipEndpoint(optionID, endpoints[1])
    local destination, destinationName = self:GetGossipEndpoint(optionID, endpoints[2])
    if not sourceName or not destinationName then
        self:Print("Configure both gossip-flight endpoints in settings: " .. optionID)
        return
    end
    self:StartAFlight(source, destination)
end

do
    hooksecurefunc(
        C_GossipInfo,
        "SelectOption",
        function(option, ...)
            if db.global.gossipTriggered[option] then
                addonCore:StartGossipFlight(option)
            end
        end
    )

    local original_C_GossipInfo_SelectOptionByIndex = C_GossipInfo.SelectOptionByIndex

    ---@diagnostic disable-next-line: duplicate-set-field
    function C_GossipInfo.SelectOptionByIndex(...)
        local selectedIndex = tonumber(...)
        local gossipOptions = C_GossipInfo.GetOptions()
        for _, optionData in ipairs(gossipOptions) do
            if optionData.orderIndex == selectedIndex then
                local selectedGossipID = optionData.gossipOptionID
                if db.global.gossipTriggered[selectedGossipID] then
                    addonCore:StartGossipFlight(selectedGossipID)
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
            self.OnFlightGossipID = optionInfo.gossipOptionID
            if self.OnFlightTooltipHooked then return end
            self.OnFlightTooltipHooked = true
            self:HookScript("OnEnter", function(frame)
                if db and (db.profile.showGossipConfig or db.profile.gossipdebug) then
                    if GameTooltip:GetOwner() ~= frame then
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                    end
                    GameTooltip:AddLine("gossipOptionID: " .. (frame.OnFlightGossipID or "??"))
                    GameTooltip:Show()
                end
            end)
            self:HookScript("OnLeave", function(frame)
                if GameTooltip:GetOwner() == frame then
                    GameTooltip:Hide()
                end
            end)
        end
    )
end

---Ace3 Config Table
function addonCore:GetOption(info)
    if info.type == "color" then
        if db.profile[info[#info]] then
            local color = db.profile[info[#info]]
            return color.r, color.g, color.b, color.a
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
    self:RefreshSettings()
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
        sourceID = {
            order = 2,
            type = "input",
            name = "Source Node ID",
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = function(info)
                local id = tonumber(info[#info - 1])
                local value = db.global.gossipTriggered[id][1]
                return type(value) == "number" and tostring(value) or select(2, addonCore:GetGossipEndpoint(id, value))
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                db.global.gossipTriggered[id][1] = addonCore:ParseGossipEndpoint(id, value)
                addonCore:RefreshGossipEditor(id)
            end
        },
        destinationID = {
            order = 3,
            type = "input",
            name = "Destination Node ID",
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = function(info)
                local id = tonumber(info[#info - 1])
                local value = db.global.gossipTriggered[id][2]
                return type(value) == "number" and tostring(value) or select(2, addonCore:GetGossipEndpoint(id, value))
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                db.global.gossipTriggered[id][2] = addonCore:ParseGossipEndpoint(id, value)
                addonCore:RefreshGossipEditor(id)
            end
        },
        remove = {
            order = 4,
            name = "Remove",
            type = "execute",
            func = function(info)
                local id = tonumber(info[#info - 1])
                ---@diagnostic disable-next-line: need-check-nil
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
        sourceID = {
            order = 2,
            type = "input",
            name = "Source Node ID",
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        destinationID = {
            order = 3,
            type = "input",
            name = "Destination Node ID",
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        addNew = {
            order = 4,
            name = "Add New",
            type = "execute",
            func = function()
                local id = tonumber(addNew_Temp.name)
                if not id or not addNew_Temp.sourceID or not addNew_Temp.destinationID then return end
                local source = addonCore:ParseGossipEndpoint(id, addNew_Temp.sourceID)
                local destination = addonCore:ParseGossipEndpoint(id, addNew_Temp.destinationID)
                if not source or not destination then return end
                db.global.gossipTriggered[id] = { source, destination }
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
    self:RefreshSettings()
end

function addonCore:OnProfileUpdated()
    for name, module in self:IterateModules() do
        local enabled = db.profile.moduleState[name]
        if enabled and not module:IsEnabled() then
            self:EnableModule(name)
        elseif not enabled and module:IsEnabled() then
            self:DisableModule(name)
        end
    end
    self:RefreshAdvOptions()
    self:RefreshSettings()
    self:SendMessage("OnFlight_DiagnosticsChanged")
end

function addonCore:RefreshAdvOptions()
    local opt = wipe(self.configOptionsTable.args.gossipConfigTab.args)
    for k, _ in pairs(db.global.gossipTriggered) do
        opt[tostring(k)] = gossipOptionTemplate
    end
    opt.AddNewGossipID = gossipOptionTemplate_AddNew
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    self:RefreshGossipEditor()
end

-- Keep the existing command paths; only Profiles is rendered by AceConfigDialog.
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
                    name = "Show Diagnostic IDs",
                    desc = "Show gossip option IDs and taxi-node IDs.",
                    type = "toggle",
                    order = 20,
                    get = function(info)
                        return db.profile.showGossipConfig
                    end,
                    set = function(_, option)
                        db.profile.showGossipConfig = option
                        addonCore:RefreshSettings()
                        addonCore:SendMessage("OnFlight_DiagnosticsChanged")
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
                    }
                }
            }
        },
        gossipConfigTab = {
            name = "Gossip Configuration",
            type = "group",
            order = 900,
            args = {}
        }
    }
}
