-- Forever group flight status. See PROTOCOL.md for the independent wire protocol.
--luacheck: no max line length
--luacheck: globals LibStub C_ChatInfo CreateFrame GetTime GetServerTime IsInRaid IsInGroup UnitName wipe
local _, addonCore = ...
local module = addonCore:NewModule("Communication", "AceEvent-3.0")
local PREFIX, STALE_SECONDS = "OnFlight", 180
local thresholds = { 0.3, 0.5, 0.7 }
local remoteFlights, ended = {}, {}
local outgoing
local timer = CreateFrame("Frame")
timer:Hide()

local function PositiveInteger(value)
    return value and value > 0 and value < math.huge and value == math.floor(value)
end

local function Broadcast(message)
    if IsInRaid(1) then
        C_ChatInfo.SendAddonMessage(PREFIX, message, "RAID")
    elseif IsInGroup(1) then
        C_ChatInfo.SendAddonMessage(PREFIX, message, "PARTY")
    end
end

local function Matches(flight, sourceID, startedAt, destinationID)
    return flight.sourceID == sourceID and flight.startServerTime == startedAt
        and flight.destinationID == destinationID
end

local function RemoveRemote(sender, reason, now)
    local flight = remoteFlights[sender]
    remoteFlights[sender] = nil
    ended[sender] = { startedAt = flight.startServerTime, expiresAt = now + STALE_SECONDS }
    module:SendMessage("OnFlight_RemoteFlightRemoved", sender, flight, reason)
end

function module:GetRemoteFlight(sender)
    return remoteFlights[sender]
end

-- Consumers may read these records; only this module changes them.
function module:GetRemoteFlights()
    return remoteFlights
end

function module:GetRemoteFlightProgress(sender)
    local flight = remoteFlights[sender]
    if not flight then return end
    local elapsed = math.max(0, GetServerTime() - flight.startServerTime)
    local remaining = flight.duration and math.max(0, flight.duration - elapsed)
    return elapsed, remaining, flight.duration
end

function module:CHAT_MSG_ADDON(_, prefix, message, channel, sender)
    if prefix ~= PREFIX or (channel ~= "PARTY" and channel ~= "RAID") or sender == UnitName("player") then return end
    local source, start, command, destination = message:match("^(%d+):(%d+):([^:]+):(%d+)$")
    if not source then return end
    local sourceID, startedAt, destinationID = tonumber(source), tonumber(start), tonumber(destination)
    if not PositiveInteger(sourceID) or not PositiveInteger(startedAt) or not PositiveInteger(destinationID) then return end
    local duration
    if command ~= "U" and command ~= "E" then
        if not command:match("^%d+$") then return end
        duration = tonumber(command)
        if not PositiveInteger(duration) then return end
    end
    local now = GetServerTime()
    local current = remoteFlights[sender]
    if command == "E" then
        if current and Matches(current, sourceID, startedAt, destinationID) then RemoveRemote(sender, "E", now) end
        return
    end
    local previous = ended[sender]
    if previous and previous.expiresAt > now and startedAt <= previous.startedAt then return end
    if current then
        if Matches(current, sourceID, startedAt, destinationID) then
            -- Keep the original duration/unknown status, and don't reset displays.
            if current.duration == duration then current.lastSeenAt = now end
            return
        end
        if startedAt <= current.startServerTime then return end
    end
    local flight = { sourceID = sourceID, destinationID = destinationID,
        startServerTime = startedAt, duration = duration, lastSeenAt = now }
    remoteFlights[sender] = flight
    self:SendMessage("OnFlight_RemoteFlightUpdated", sender, flight)
end

function module:FlightStarted()
    local flight = addonCore:GetCurrentFlight()
    if not flight or not flight.startedAt or not flight.startServerTime then return end
    if outgoing and outgoing.flight == flight then return end
    -- Gossip custom endpoints have no numeric identity in this protocol.
    if type(flight.sourceID) ~= "number" or type(flight.destinationID) ~= "number"
        or not PositiveInteger(flight.sourceID) or not PositiveInteger(flight.destinationID) then return end
    local _, _, duration = addonCore:GetCurrentFlightProgress()
    duration = duration and math.floor(duration)
    if not PositiveInteger(duration) then duration = nil end
    local format = "%d:%d:%s:%d"
    outgoing = { flight = flight, duration = duration, nextThreshold = 1,
        nextAnnouncement = GetTime() + 60,
        message = format:format(flight.sourceID, flight.startServerTime, duration and tostring(duration) or "U", flight.destinationID),
        endMessage = format:format(flight.sourceID, flight.startServerTime, "E", flight.destinationID) }
    Broadcast(outgoing.message)
end

function module:FlightEnded()
    if not outgoing then return end
    Broadcast(outgoing.endMessage)
    outgoing = nil
end

local function Update()
    if outgoing then
        local flight = addonCore:GetCurrentFlight()
        if flight == outgoing.flight and not flight.suspended then
            local now = GetTime()
            if outgoing.duration then
                local elapsed = now - flight.startedAt
                local index = outgoing.nextThreshold
                if thresholds[index] and elapsed >= outgoing.duration * thresholds[index] then
                    -- One packet covers any thresholds crossed during a loading gap.
                    repeat index = index + 1 until not thresholds[index] or elapsed < outgoing.duration * thresholds[index]
                    outgoing.nextThreshold = index
                    Broadcast(outgoing.message)
                end
            elseif now >= outgoing.nextAnnouncement then
                outgoing.nextAnnouncement = now + 60
                Broadcast(outgoing.message)
            end
        end
    end
    local now = GetServerTime()
    for sender, flight in pairs(remoteFlights) do
        if now - flight.lastSeenAt >= math.max(STALE_SECONDS, flight.duration or 0) then
            RemoveRemote(sender, "stale", now)
        end
    end
    for sender, previous in pairs(ended) do
        if now >= previous.expiresAt then ended[sender] = nil end
    end
end

local elapsedSinceUpdate = 0
timer:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < 1 then return end
    elapsedSinceUpdate = 0
    Update()
end)

function module:OnInitialize()
    self:SetEnabledState(addonCore.db.profile.moduleState.Communication)
end

function module:OnEnable()
    if outgoing and outgoing.flight ~= addonCore:GetCurrentFlight() then outgoing = nil end
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterMessage("OnFlight_Taxi_Start", "FlightStarted")
    self:RegisterMessage("OnFlight_Taxi_RESUME", "FlightStarted")
    self:RegisterMessage("OnFlight_Taxi_Stop", "FlightEnded")
    self:RegisterMessage("OnFlight_Taxi_EarlyExit", "FlightEnded")
    elapsedSinceUpdate = 0
    timer:Show()
end

function module:OnDisable()
    timer:Hide()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    -- Keep the frozen announcement if re-enabled on this flight; never send a false E.
    for sender in pairs(remoteFlights) do RemoveRemote(sender, "disabled", GetServerTime()) end
    wipe(ended)
end
