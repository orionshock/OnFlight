-- Public flight state; transport and flight detection remain with their existing owners.
-- luacheck: globals GetTime GetServerTime NameUtil UnitExists UnitIsUnit IsInRaid GetNumGroupMembers
-- luacheck: globals C_Secrets canaccessvalue
local _, addonCore = ...
local module = addonCore:NewModule("FlightTimes", "AceEvent-3.0")

local API = {}
_G.FlightTimes = API
local playerFlight, playerRecord
local remote = {}

function API:RegisterCallback(event, callback, owner)
    assert(event == "FlightStarted" or event == "FlightStopped", "Unknown FlightTimes event")
    return addonCore:RegisterCallback(event, callback, owner)
end

function API:UnregisterCallback(event, owner)
    assert(event == "FlightStarted" or event == "FlightStopped", "Unknown FlightTimes event")
    addonCore:UnregisterCallback(event, owner)
end

function API:GetTaxiNodeName(nodeID)
    if canaccessvalue(nodeID) then
        return addonCore:GetTaxiNodeName(nodeID)
    end
end

local function GetReadableUnitName(unit)
    -- NameUtil can concatenate the name and realm before returning.
    if not C_Secrets.ShouldUnitIdentityBeSecret(unit) then
        local name = NameUtil.GetUnmodifiedUnitFullName(unit)
        if canaccessvalue(name) then return name end
    end
end

local function IsPlayerUnit(unit)
    if C_Secrets.CanCompareUnitTokens(unit, "player") then
        local result = UnitIsUnit(unit, "player")
        if canaccessvalue(result) then return not not result end
    end
end

function module.CanResolveGroupMembers()
    if C_Secrets.ShouldUnitIdentityBeSecret("player") then return false end
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if UnitExists(unit) and (C_Secrets.ShouldUnitIdentityBeSecret(unit) or IsPlayerUnit(unit) == nil) then
            return false
        end
    end
    return true
end

local function SenderUnit(sender)
    -- The default group APIs use the active roster, including instance groups.
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if IsPlayerUnit(unit) == false and GetReadableUnitName(unit) == sender then
            return unit
        end
    end
end

function API:GetFlightInfo(unit)
    if not canaccessvalue(unit) or type(unit) ~= "string" or (unit ~= "player" and not unit:match("^party%d+$") and
        not unit:match("^raid%d+$")) then
        return
    end
    local sender = GetReadableUnitName(unit)
    if not sender then return end
    local isPlayer = unit == "player" or IsPlayerUnit(unit)
    if isPlayer == nil then return end
    if isPlayer then
        return playerFlight
    end
    local entry = remote[sender]
    if entry and SenderUnit(sender) then
        return entry.flight
    end
end

local function FlightInfo(source, destination, startTime, duration)
    local sourceID = type(source) == "number" and source or nil
    local destinationID = type(destination) == "number" and destination or nil
    return {
        sourceName = API:GetTaxiNodeName(sourceID),
        sourceNodeID = sourceID,
        destinationName = API:GetTaxiNodeName(destinationID),
        destinationNodeID = destinationID,
        startTime = startTime,
        duration = duration or "U"
    }
end

function module:LocalStarted()
    local current = addonCore:GetCurrentFlight()
    if not current or not current.startedAt or current == playerRecord then return end
    playerRecord = current
    playerFlight = FlightInfo(current.sourceID, current.destinationID, current.startedAt,
        addonCore:GetFlightDuration(current.sourceID, current.destinationID))
    addonCore:TriggerEvent("FlightStarted", "player", playerFlight)
end

function module:LocalStopped()
    local previous = playerFlight
    playerFlight, playerRecord = nil, nil
    if previous then addonCore:TriggerEvent("FlightStopped", "player", previous) end
end

function module:RemoteRemoved(sender)
    local previous = remote[sender]
    remote[sender] = nil
    if previous then addonCore:TriggerEvent("FlightStopped", previous.unit, previous.flight) end
end

function module:RemoteStarted(sender, record)
    local unit = SenderUnit(sender)
    if not unit then return end
    self:RemoteRemoved(sender)
    local info = FlightInfo(record.sourceID, record.destinationID,
        GetTime() - math.max(0, GetServerTime() - record.startServerTime), record.duration)
    remote[sender] = {unit = unit, flight = info}
    addonCore:TriggerEvent("FlightStarted", unit, info)
end

function module:GROUP_ROSTER_UPDATE()
    if not self.CanResolveGroupMembers() then return end
    -- Resolve current tokens instead of maintaining a second roster.
    for sender, entry in pairs(remote) do
        local unit = SenderUnit(sender)
        if not unit then
            self:RemoteRemoved(sender)
        else
            entry.unit = unit
        end
    end
end

function module:OnEnable()
    addonCore:RegisterCallback("OnFlight_Taxi_Start", self.LocalStarted, self)
    addonCore:RegisterCallback("OnFlight_Taxi_RESUME", self.LocalStarted, self)
    addonCore:RegisterCallback("OnFlight_Taxi_Stop", self.LocalStopped, self)
    addonCore:RegisterCallback("OnFlight_Taxi_EarlyExit", self.LocalStopped, self)
    addonCore:RegisterCallback("OnFlight_RemoteFlightUpdated", self.RemoteStarted, self)
    addonCore:RegisterCallback("OnFlight_RemoteFlightRemoved", self.RemoteRemoved, self)
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end
