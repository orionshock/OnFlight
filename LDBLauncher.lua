-- Independent OnFlight wire receiver and broker display. See PROTOCOL.md.
-- Flight data comes only from CHAT_MSG_ADDON, including our own received packets.
--luacheck: no max line length
--luacheck: globals LibStub C_ChatInfo C_TaxiMap CreateFrame GetTime GetServerTime UnitFullName GetNormalizedRealmName wipe
local addonName, addonCore = ...
local module = addonCore:NewModule("LDBLauncher", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LDB, DBIcon = LibStub("LibDataBroker-1.1"), LibStub("LibDBIcon-1.0")
local flights = {}
local playerName, playerFullName, broker, nodeNames
local tooltip, tooltipOwner, lastTooltipUpdate
local timer = CreateFrame("Frame")
timer:Hide()

local function IsSelf(sender)
    return sender == playerName or sender == playerFullName
end

local function PositiveInteger(value)
    return value and value > 0 and value < math.huge and value == math.floor(value)
end

local function DestinationName(id)
    if not nodeNames then
        nodeNames = {}
        for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(947)) do nodeNames[node.nodeID] = node.name end
    end
    return nodeNames[id] or tostring(id)
end

local function TimeText(flight, now)
    if not flight.duration then return L["Flying"] end
    local elapsed = math.max(0, now - flight.startServerTime)
    local remaining = math.max(0, flight.duration - elapsed)
    return ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
end

local function UpdateText()
    local flight = flights[playerName]
    broker.text = flight and L["OnFlight: %s"]:format(TimeText(flight, GetServerTime())) or L["OnFlight"]
end

local function RenderTooltip(tip)
    tip:ClearLines()
    tip:SetText(L["OnFlight - Group Flights"])
    local senders = {}
    for sender in pairs(flights) do senders[#senders + 1] = sender end
    table.sort(senders)
    if #senders == 0 then
        tip:AddLine(L["No flights reported"], 1, 1, 1)
    else
        tip:AddDoubleLine(L["Player / Destination"], L["Remaining"], 1, 0.82, 0, 1, 0.82, 0)
        local now = GetServerTime()
        for _, sender in ipairs(senders) do
            local flight = flights[sender]
            local name = IsSelf(sender) and L["%s (you)"]:format(sender) or sender
            tip:AddDoubleLine(L["%s | %s"]:format(name, DestinationName(flight.destinationID)),
                TimeText(flight, now), 1, 1, 1, 1, 1, 1)
        end
    end
    tip:Show()
    lastTooltipUpdate = GetTime()
end

local function UpdateTimer()
    timer:SetShown(next(flights) ~= nil or tooltip ~= nil)
end

local function ShowTooltip(tip)
    if tooltip == tip and tip:IsShown() and tip:GetOwner() == tooltipOwner
        and GetTime() - lastTooltipUpdate < 1 then return end
    tooltip, tooltipOwner = tip, tip:GetOwner()
    RenderTooltip(tip)
    UpdateTimer()
end

local function LeaveTooltip()
    tooltip, tooltipOwner = nil, nil
    UpdateTimer()
end

function module:CHAT_MSG_ADDON(_, prefix, message, channel, sender)
    if prefix ~= "OnFlight" then return end
    local own = IsSelf(sender)
    if channel ~= "PARTY" and channel ~= "RAID" and not (channel == "WHISPER" and own) then return end
    local source, start, command, destination = message:match("^(%d+):(%d+):([^:]+):(%d+)$")
    if not source then return end
    local sourceID, startServerTime, destinationID = tonumber(source), tonumber(start), tonumber(destination)
    if not PositiveInteger(sourceID) or not PositiveInteger(startServerTime) or not PositiveInteger(destinationID) then return end
    local duration
    if command ~= "U" and command ~= "E" then
        if not command:match("^%d+$") then return end
        duration = tonumber(command)
        if not PositiveInteger(duration) then return end
    end
    -- Party/raid and self-whisper delivery may qualify our name differently.
    if own then sender = playerName end
    local current = flights[sender]
    local matches = current and current.sourceID == sourceID and current.startServerTime == startServerTime
        and current.destinationID == destinationID
    if command == "E" then
        if matches then flights[sender] = nil end
    elseif matches then
        if current.duration == duration then current.lastSeenAt = GetServerTime() end
    elseif not current or startServerTime > current.startServerTime then
        flights[sender] = { sourceID = sourceID, destinationID = destinationID,
            startServerTime = startServerTime, duration = duration, lastSeenAt = GetServerTime() }
    end
    UpdateText()
    UpdateTimer()
end

local elapsedSinceUpdate = 0
timer:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < 1 then return end
    elapsedSinceUpdate = 0
    local now = GetServerTime()
    for sender, flight in pairs(flights) do
        -- Expiry follows missing announcements, not the countdown reaching zero.
        if now - flight.lastSeenAt >= math.max(180, flight.duration or 0) then flights[sender] = nil end
    end
    UpdateText()
    if tooltip and tooltip:IsShown() and tooltip:GetOwner() == tooltipOwner then
        if GetTime() - lastTooltipUpdate >= 1 then RenderTooltip(tooltip) end
    else
        tooltip, tooltipOwner = nil, nil
    end
    UpdateTimer()
end)

function module:RefreshMinimapIcon()
    if self:IsEnabled() then
        DBIcon:Refresh("OnFlight", addonCore.db.profile.minimap)
    else
        DBIcon:Hide("OnFlight")
    end
end

function module:OnInitialize()
    local realm
    playerName, realm = UnitFullName("player")
    realm = realm and realm ~= "" and realm:gsub("%s+", "") or GetNormalizedRealmName()
    playerFullName = realm ~= "" and playerName .. "-" .. realm or playerName
    self:SetEnabledState(addonCore.db.profile.moduleState.LDBLauncher)
    broker = LDB:NewDataObject("OnFlight", {
        type = "launcher", label = L["OnFlight"], icon = 132172, text = L["OnFlight"],
        OnClick = function(_, button)
            if button == "LeftButton" then addonCore:OpenSettings() end
        end,
        OnTooltipShow = ShowTooltip,
        OnLeave = LeaveTooltip,
    })
    DBIcon:Register("OnFlight", broker, addonCore.db.profile.minimap)
    DBIcon:Hide("OnFlight") -- Enablement follows initialization, after the profile exists.
    addonCore.db.RegisterCallback(self, "OnProfileChanged", "RefreshMinimapIcon")
    addonCore.db.RegisterCallback(self, "OnProfileCopied", "RefreshMinimapIcon")
    addonCore.db.RegisterCallback(self, "OnProfileReset", "RefreshMinimapIcon")
end

function module:OnEnable()
    C_ChatInfo.RegisterAddonMessagePrefix("OnFlight")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RefreshMinimapIcon()
    UpdateTimer()
end

function module:OnDisable()
    self:UnregisterAllEvents()
    wipe(flights)
    UpdateText()
    if tooltip then tooltip:Hide() end
    tooltip, tooltipOwner = nil, nil
    timer:Hide()
    DBIcon:Hide("OnFlight")
end
