-- Flight detection, duration learning, and the shared native callback registry.
-- luacheck: no max line length
-- luacheck: globals LibStub TaxiNodeName GetNumRoutes NumTaxiNodes TaxiNodeGetType
-- luacheck: globals UnitFactionGroup UnitOnTaxi UnitInVehicle CreateFrame tostringall GetTime GetServerTime SecondsToTime abs hooksecurefunc string
-- luacheck: globals C_SummonInfo OnFlight_GetEstimatedTime TaxiFrame TaxiGetNodeSlot OnFlight_TaxiFrame_TooltipHook GameTooltip
-- luacheck: globals FlashClientIcon PlaySoundFile
-- luacheck: globals CreateFromMixins CallbackRegistryMixin C_TaxiMap GetTaxiMapID TakeTaxiNode
local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "OnFlight", "AceEvent-3.0")
addonCore.OnFlightPrefixText = "|cff0040ffOn|cFF00FF00Flight|r|r"
_G[addonName] = addonCore

local callbacks = CreateFromMixins(CallbackRegistryMixin)
callbacks:OnLoad()
callbacks:GenerateCallbackEvents({
    "FlightStarted", "FlightStopped",
    "OnFlight_Taxi_Start", "OnFlight_Taxi_Stop", "OnFlight_Taxi_EarlyExit",
    "OnFlight_Taxi_FAILED_ENTRY",
    "OnFlight_RemoteFlightUpdated", "OnFlight_RemoteFlightRemoved",
    "OnFlight_TaxiMapReady", "OnFlight_DiagnosticsChanged"
})

function addonCore:RegisterCallback(event, callback, owner, ...)
    return callbacks:RegisterCallback(event, callback, owner, ...)
end

function addonCore:UnregisterCallback(event, owner)
    callbacks:UnregisterCallback(event, owner)
end

function addonCore:TriggerEvent(event, ...)
    callbacks:TriggerEvent(event, ...)
end

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LSM = LibStub("LibSharedMedia-3.0")
local landingSoonSound = "OnFlight: Level Up"
local landedSound = "OnFlight: PvP Queue"
LSM:Register("sound", landingSoonSound, 567431)
LSM:Register("sound", landedSound, 568011)

local GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot = GetNumRoutes, NumTaxiNodes, TaxiNodeGetType,
    TaxiGetNodeSlot

local db, playerFaction

-- Node names are session-local presentation data, never database keys.
local nodeCache, taxiSession = {}, nil

function addonCore:GetTaxiNodeName(nodeID)
    if type(nodeID) ~= "number" then
        return
    end
    if not nodeCache[nodeID] then
        for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(947)) do
            nodeCache[node.nodeID] = node.name
        end
    end
    return nodeCache[nodeID]
end

function addonCore:GetTaxiSession()
    if taxiSession and TaxiFrame:IsShown() and taxiSession.mapID == GetTaxiMapID() then
        return taxiSession
    end
end

function addonCore:RefreshTaxiSession()
    if not TaxiFrame:IsShown() then
        return
    end
    local mapID = GetTaxiMapID()
    if not mapID then
        return
    end
    local session = {
        mapID = mapID,
        nodes = {},
        slotToID = {},
        idToSlot = {}
    }
    for _, node in ipairs(C_TaxiMap.GetAllTaxiNodes(mapID)) do
        local slot, id = node.slotIndex, node.nodeID
        if slot and slot > 0 and id and id > 0 then
            session.nodes[id], nodeCache[id] = node, node.name
            session.slotToID[slot], session.idToSlot[id] = id, slot
            if TaxiNodeGetType(slot) == "CURRENT" then
                session.sourceID = id
            end
        end
    end
    if not session.sourceID then
        return
    end
    for slot = 1, NumTaxiNodes() do
        local nodeType = TaxiNodeGetType(slot)
        -- Some DISTANT placeholders have no node ID and cannot be destinations.
        if nodeType ~= "NONE" and nodeType ~= "DISTANT" and not session.slotToID[slot] then
            return
        end
    end
    taxiSession = session
    return session
end

function addonCore:GetTaxiRoute(destinationID)
    local session = self:GetTaxiSession()
    local slot = session and session.idToSlot[destinationID]
    if not slot then
        return
    end
    local hops = GetNumRoutes(slot)
    local route = {
        [1] = session.sourceID,
        [hops + 1] = destinationID
    }
    -- Preserve the estimator's existing intermediate-source ordering.
    for hop = 2, hops do
        local id = session.slotToID[TaxiGetNodeSlot(slot, hop, true)]
        if not id then
            return
        end
        route[hop] = id
    end
    return route
end

local taxiSessionFrame = CreateFrame("Frame")

local svDefaults = {
    profile = {
        flightNotifications = false,
        landingWarningTime = 30,
        landingSoonSound = landingSoonSound,
        landingSoonFlash = false,
        landedSound = landedSound,
        landedFlash = false,
        showChat = true,
        taxiDebug = false,
        showUnknownFlightPoints = false,
        useWorldMapFlightMaps = true,
        showGossipConfig = false,
        favorites = {
            [2] = true, -- Stormwind
            [6] = true, -- Ironforge
            [27] = true, -- Rut'theran Village
            [23] = true, -- Orgrimmar
            [22] = true, -- Thunder Bluff
            [11] = true, -- Undercity
        },
        minimap = {
            hide = false,
            minimapPos = 225
        },
        flightDisplay = "builtin"
    },
    global = {}
}
addonCore.svDefaults = svDefaults

function addonCore:OnInitialize()
    playerFaction = UnitFactionGroup("player")
    self.db = LibStub("AceDB-3.0"):New("OnFlightSV", svDefaults, true)
    db = self.db
    db.global.flightTimes[playerFaction] = db.global.flightTimes[playerFaction] or {}
    db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdated")
    db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdated")
    db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdated")

    self:InitializeConfig()
end

function addonCore:OnEnable()
    self:InitializeSettings()
    self:UpdateTaxiDebug()
    self:RegisterEvent("TAXIMAP_OPENED")
    self:RegisterEvent("TAXIMAP_CLOSED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEAVING_WORLD")
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
local nextFlightNotifications

function addonCore:GetNextFlightNotifications()
    if nextFlightNotifications ~= nil then
        return nextFlightNotifications
    end
    return self.db.profile.flightNotifications
end

function addonCore:SetNextFlightNotifications(value)
    nextFlightNotifications = value
    self:RefreshFlightNotificationCheckbox()
end

function addonCore:SetFlightNotifications(value, clearOverride)
    db.profile.flightNotifications = value
    if clearOverride then
        nextFlightNotifications = nil
    end
    self:RefreshFlightNotificationCheckbox()
    self:RefreshSettings("flightNotifications")
end

local function NotifyFlight(sound, flash)
    if sound ~= "None" then
        local file = LSM:Fetch("sound", sound, true)
        if file and file ~= 1 then
            PlaySoundFile(file, "Master")
        end
    end
    if flash then
        FlashClientIcon(true)
    end
end

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
            if not flight.startedAt then
                flight.notifications = addonCore:GetNextFlightNotifications()
                addonCore:SetNextFlightNotifications(nil)
            end
            flight.startedAt = flight.startedAt or GetTime()
            flight.startServerTime = flight.startServerTime or GetServerTime()
            local duration = addonCore:GetFlightDuration(flight.sourceID, flight.destinationID)
            if duration then
                addonCore:TriggerEvent("OnFlight_Taxi_Start", flight.sourceName, flight.destinationName, duration, false)
                addonCore:ChatMessage(L["On Taxi: %s --> %s -- %s"]:format(flight.sourceName,
                    flight.destinationName, SecondsToTime(duration)))
            else
                addonCore:TriggerEvent("OnFlight_Taxi_Start", flight.sourceName, flight.destinationName, 0, true)
                addonCore:ChatMessage(L["On Taxi: %s --> %s"]:format(flight.sourceName, flight.destinationName))
            end
        elseif flight.startedAt then
            if not flight.earlyExit then
                if flight.notifications then
                    NotifyFlight(db.profile.landedSound, db.profile.landedFlash)
                end
                local duration = abs(GetTime() - flight.startedAt)
                local times = db.global.flightTimes[playerFaction]
                times[flight.sourceID] = times[flight.sourceID] or {}
                times[flight.sourceID][flight.destinationID] = math.floor(duration)
                addonCore:TriggerEvent("OnFlight_Taxi_Stop", flight.sourceName, flight.destinationName, duration)
                addonCore:ChatMessage(L["Off Taxi: %s --> %s -- %s"]:format(flight.sourceName, flight.destinationName,
                    SecondsToTime(duration)))
            else
                addonCore:TriggerEvent("OnFlight_Taxi_EarlyExit", flight.sourceName, flight.destinationName,
                    flight.earlyExit)
                addonCore:ChatMessage(L["Taxi Ended Early: %s"]:format(flight.earlyExit))
            end
            return ResetFlight()
        end
    end
    if flight.onTaxi then
        if flight.notifications and not flight.warned and not flight.earlyExit then
            local warning = db.profile.landingWarningTime
            if warning > 0 then
                local _, remaining, duration = addonCore:GetCurrentFlightProgress()
                if duration and duration > warning and remaining <= warning and remaining > 0 then
                    flight.warned = true
                    NotifyFlight(db.profile.landingSoonSound, db.profile.landingSoonFlash)
                end
            end
        end
    else
        flight.elapsedNotOnFlight = (flight.elapsedNotOnFlight or 0) + elapsed
        if flight.elapsedNotOnFlight > 5 then
            addonCore:TriggerEvent("OnFlight_Taxi_FAILED_ENTRY", flight.sourceName, flight.destinationName)
            ResetFlight()
        end
    end
end

function addonCore:StartAFlight(source, destination, route)
    local sourceName = self:GetFlightEndpointName(source)
    local destinationName = self:GetFlightEndpointName(destination)
    if not sourceName or not destinationName then
        return
    end
    flight = {
        sourceID = source,
        destinationID = destination,
        route = route or {},
        sourceName = sourceName,
        destinationName = destinationName,
        onTaxi = false
    }
    flightMonitor:SetScript("OnUpdate", UpdateFlight)
    return flight
end

-- function hooks to detect if we left a flight early
hooksecurefunc("TaxiRequestEarlyLanding", function()
    if flight and not flight.suspended then
        flight.earlyExit = L["Request Early Landing"]
    end
end)

hooksecurefunc("AcceptBattlefieldPort", function(_, accept)
    if accept and flight and not flight.suspended then
        flight.earlyExit = L["Battlefield Port"]
    end
end)

hooksecurefunc(C_SummonInfo, "ConfirmSummon", function()
    if flight and not flight.suspended then
        flight.earlyExit = L["Accepted Summon"]
    end
end)

---Estimated Flight Times - Transposed from origional code
---@param destinationID number
function OnFlight_GetEstimatedTime(destinationID)
    if not TaxiFrame:IsShown() then
        return
    end
    destinationID = tonumber(destinationID)
    local session = addonCore:GetTaxiSession()
    local taxiDestSlot = session and session.idToSlot[destinationID]
    if not taxiDestSlot then
        return
    end
    local numRoutes = GetNumRoutes(taxiDestSlot)
    if numRoutes < 2 then
        return
    end
    local taxiNodes = addonCore:GetTaxiRoute(destinationID)
    if not taxiNodes then
        return
    end
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

function addonCore:GetTaxiDurationText(sourceID, destinationID)
    local duration = self:GetFlightDuration(sourceID, destinationID)
    if duration then
        return SecondsToTime(duration)
    end
    local session = self:GetTaxiSession()
    local estimate = session and session.sourceID == sourceID and OnFlight_GetEstimatedTime(destinationID)
    return estimate and "~" .. SecondsToTime(estimate) or L["Unknown"]
end

-- This is the DefaultUI's Taxi Button, the ID needs to make sense.
-- Default UI just directly assumes the GameTooltip because there is no "OnTaxiNodeSet" type handler.
function OnFlight_TaxiFrame_TooltipHook(button)
    if TaxiFrame:IsShown() and button:GetID() and (GameTooltip:GetOwner() == button) then
        local id = button:GetID()
        if TaxiNodeGetType(id) ~= "REACHABLE" then
            return
        end
        local session = addonCore:GetTaxiSession()
        if not session then
            return
        end
        GameTooltip:AddDoubleLine(L["Duration:"], addonCore:GetTaxiDurationText(session.sourceID, session.slotToID[id]))
        GameTooltip:Show()
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
            self:TriggerEvent("OnFlight_TaxiMapReady")
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
    if taxiSession and taxiSession.mapID ~= GetTaxiMapID() then
        addonCore:TAXIMAP_OPENED()
    end
end)

function addonCore.PLAYER_ENTERING_WORLD()
    if flight then
        flight.suspended = nil
        flightMonitor:SetScript("OnUpdate", UpdateFlight)
    end
end

function addonCore.PLAYER_LEAVING_WORLD()
    if not flight or flight.suspended then
        return
    end
    -- Avoid sampling taxi state while out of world.
    flight.suspended = true
    flightMonitor:SetScript("OnUpdate", nil)
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

function addonCore:GetCurrentFlightProgress()
    if not flight or not flight.startedAt then
        return
    end
    local elapsed = GetTime() - flight.startedAt
    local duration = self:GetFlightDuration(flight.sourceID, flight.destinationID)
    local remaining
    if duration then
        remaining = duration - elapsed
    end
    return elapsed, remaining, duration
end

do -- Direct Hoook Funcs
    local oldTakeTaxiNode = TakeTaxiNode
    TakeTaxiNode = function(slot, ...)
        local session = addonCore:RefreshTaxiSession()
        local destinationID = session and session.slotToID[slot]
        if session and destinationID then
            local route = addonCore:GetTaxiRoute(destinationID)
            if route then
                addonCore:StartAFlight(session.sourceID, destinationID, route)
            end
        end
        oldTakeTaxiNode(slot, ...)
    end
end

function addonCore:GetFlightEndpointName(key)
    if type(key) == "number" then
        return self:GetTaxiNodeName(key)
    end
    if type(key) == "string" then
        return key:match("^%d+:(.+)$")
    end
end

function addonCore:OnProfileUpdated()
    self:ApplyFlightDisplay()
    self:RefreshSettings()
    self:RefreshFlightNotificationCheckbox()
    self:RefreshDiagnostics()
    self:UpdateTaxiDebug()
end
