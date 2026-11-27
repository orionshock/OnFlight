-- FlightTimes consumer: presentation and refresh belong to the broker.
-- luacheck: no max line length
-- luacheck: globals LibStub FlightTimes CreateFrame GetTime NameUtil IsInRaid GetNumGroupMembers UnitIsUnit InCombatLockdown
local addonName, addonCore = ...
local module = addonCore:NewModule("LDBLauncher", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LDB, DBIcon = LibStub("LibDataBroker-1.1"), LibStub("LibDBIcon-1.0")
local broker
local tooltip, tooltipOwner, lastTooltipUpdate
local timer = CreateFrame("Frame")
timer:Hide()

local function GroupFlights()
    local flights = {}
    local function AddUnit(unit)
        local flight = FlightTimes:GetFlightInfo(unit)
        if flight then
            flights[NameUtil.GetUnmodifiedUnitFullName(unit)] = flight
        end
    end
    AddUnit("player")
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = prefix .. i
        if not UnitIsUnit(unit, "player") then AddUnit(unit) end
    end
    return flights
end

local function TimeText(flight, now)
    local elapsed = math.max(0, now - flight.startTime)
    local seconds = flight.duration ~= "U" and math.max(0, flight.duration - elapsed) or elapsed
    seconds = math.floor(seconds)
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

local function UpdateText()
    local flight = FlightTimes:GetFlightInfo("player")
    broker.text = flight and L["OnFlight: %s"]:format(TimeText(flight, GetTime())) or L["OnFlight"]
end

local function RenderTooltip(tip)
    tip:ClearLines()
    tip:SetText(L["OnFlight - Group Flights"])
    local flights = GroupFlights()
    local senders = {}
    for sender in pairs(flights) do
        senders[#senders + 1] = sender
    end
    table.sort(senders)
    if #senders == 0 then
        tip:AddLine(L["No flights reported"], 1, 1, 1)
    else
        tip:AddDoubleLine(L["Player / Destination"], L["Remaining"], 1, 0.82, 0, 1, 0.82, 0)
        local now = GetTime()
        for _, sender in ipairs(senders) do
            local flight = flights[sender]
            tip:AddDoubleLine(L["%s | %s"]:format(sender, (flight.destinationName or tostring(flight.destinationNodeID or "?"))),
                flight.duration ~= "U" and TimeText(flight, now) or L["Flying"],
                1, 1, 1, 1, 1, 1)
        end
    end
    tip:AddLine(" ")
    tip:AddLine(L["Left-click: Resend current flight"], 0.7, 0.7, 0.7)
    tip:AddLine(L["Right-click: Open settings"], 0.7, 0.7, 0.7)
    tip:Show()
    lastTooltipUpdate = GetTime()
end

local function UpdateTimer()
    timer:SetShown(next(GroupFlights()) ~= nil or tooltip ~= nil)
end

local function ShowTooltip(tip)
    if tooltip == tip and tip:IsShown() and tip:GetOwner() == tooltipOwner and GetTime() - lastTooltipUpdate < 1 then
        return
    end
    tooltip, tooltipOwner = tip, tip:GetOwner()
    RenderTooltip(tip)
    UpdateTimer()
end

local function LeaveTooltip()
    tooltip, tooltipOwner = nil, nil
    UpdateTimer()
end

function module:FlightChanged()
    UpdateText()
    UpdateTimer()
end

local elapsedSinceUpdate = 0
timer:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < 1 then
        return
    end
    elapsedSinceUpdate = 0
    UpdateText()
    if tooltip and tooltip:IsShown() and tooltip:GetOwner() == tooltipOwner then
        if GetTime() - lastTooltipUpdate >= 1 then
            RenderTooltip(tooltip)
        end
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
    self:SetEnabledState(addonCore.db.profile.moduleState.LDBLauncher)
    broker = LDB:NewDataObject("OnFlight", {
        type = "launcher",
        label = L["OnFlight"],
        icon = 132172,
        text = L["OnFlight"],
        OnClick = function(_, button)
            if button == "LeftButton" then
                addonCore:GetModule("Communication"):RequestFlightAnnouncement()
            elseif button == "RightButton" and not InCombatLockdown() then
                addonCore:OpenSettings()
            end
        end,
        OnTooltipShow = ShowTooltip,
        OnLeave = LeaveTooltip
    })
    DBIcon:Register("OnFlight", broker, addonCore.db.profile.minimap)
    addonCore.db.RegisterCallback(self, "OnProfileChanged", "RefreshMinimapIcon")
    addonCore.db.RegisterCallback(self, "OnProfileCopied", "RefreshMinimapIcon")
    addonCore.db.RegisterCallback(self, "OnProfileReset", "RefreshMinimapIcon")
end

function module:OnEnable()
    FlightTimes:RegisterCallback("FlightStarted", self.FlightChanged, self)
    FlightTimes:RegisterCallback("FlightStopped", self.FlightChanged, self)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "FlightChanged")
    UpdateText()
    self:RefreshMinimapIcon()
    UpdateTimer()
end

function module:OnDisable()
    self:UnregisterAllEvents()
    FlightTimes:UnregisterCallback("FlightStarted", self)
    FlightTimes:UnregisterCallback("FlightStopped", self)
    broker.text = L["OnFlight"]
    if tooltip then
        tooltip:Hide()
    end
    tooltip, tooltipOwner = nil, nil
    timer:Hide()
    DBIcon:Hide("OnFlight")
end
