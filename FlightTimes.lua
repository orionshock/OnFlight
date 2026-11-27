-- Public flight state; transport and flight detection remain with their existing owners.
-- luacheck: globals GetTime GetServerTime NameUtil
-- luacheck: globals C_Secrets canaccessvalue issecretvalue
local _, addonCore = ...
local module = addonCore:NewModule("FlightTimes")

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

-- Keep one readable local identity for callbacks and for filtering our own announcements.
local function RememberPlayerName()
    if not addonCore.playerName and not C_Secrets.ShouldUnitIdentityBeSecret("player") then
        local name = NameUtil.GetUnmodifiedUnitFullName("player")
        if canaccessvalue(name) and not issecretvalue(name) then
            addonCore.playerName = name
        end
    end
end

function API:GetFlightInfo(playerName)
    if not canaccessvalue(playerName) or issecretvalue(playerName) or type(playerName) ~= "string" then return end
    if playerName == addonCore.playerName then return playerFlight end
    return remote[playerName]
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
    RememberPlayerName()
    if not addonCore.playerName then return end
    playerRecord = current
    playerFlight = FlightInfo(current.sourceID, current.destinationID, current.startedAt,
        addonCore:GetFlightDuration(current.sourceID, current.destinationID))
    addonCore:TriggerEvent("FlightStarted", addonCore.playerName, playerFlight)
end

function module:LocalStopped()
    local previous = playerFlight
    playerFlight, playerRecord = nil, nil
    if previous then addonCore:TriggerEvent("FlightStopped", addonCore.playerName, previous) end
end

function module:RemoteRemoved(sender)
    local previous = remote[sender]
    remote[sender] = nil
    if previous then addonCore:TriggerEvent("FlightStopped", sender, previous) end
end

function module:RemoteStarted(sender, record)
    self:RemoteRemoved(sender)
    local info = FlightInfo(record.sourceID, record.destinationID,
        GetTime() - math.max(0, GetServerTime() - record.startServerTime), record.duration)
    remote[sender] = info
    addonCore:TriggerEvent("FlightStarted", sender, info)
end

function module:OnEnable()
    RememberPlayerName()
    addonCore:RegisterCallback("OnFlight_Taxi_Start", self.LocalStarted, self)
    addonCore:RegisterCallback("OnFlight_Taxi_Stop", self.LocalStopped, self)
    addonCore:RegisterCallback("OnFlight_Taxi_EarlyExit", self.LocalStopped, self)
    addonCore:RegisterCallback("OnFlight_RemoteFlightUpdated", self.RemoteStarted, self)
    addonCore:RegisterCallback("OnFlight_RemoteFlightRemoved", self.RemoteRemoved, self)
end
