--[[
	Copyright (C) 2006-2007 Nymbia
	Copyright (C) 2010-2017 Hendrik "Nevcairiel" Leppkes < h.leppkes@gmail.com >

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program; if not, write to the Free Software Foundation, Inc.,
	51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]
-- OnFlight flight callbacks replace InFlight hooks.
-- luacheck: globals LibStub UnitCastingInfo UnitChannelInfo
local addonName, addonCore = ...
local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3", true)
if not Quartz3 then return end

local L = LibStub("AceLocale-3.0"):GetLocale("Quartz3")
local OL = LibStub("AceLocale-3.0"):GetLocale(addonName)
local MODNAME = "OnFlight"
local Flight = Quartz3:NewModule(MODNAME, "AceHook-3.0")
local Player = Quartz3:GetModule("Player")
local unpack = unpack
local db, getOptions
local displayedFlight, conflictReported

local defaults = {
    profile = {
        color = {0.7, 1, 0.7},
        deplete = false,
    },
}

do
    local options
    function getOptions()
        options = options or {
            type = "group",
            name = OL["OnFlight"],
            order = 600,
            args = {
                toggle = {
                    type = "toggle",
                    name = L["Enable"],
                    get = function() return Quartz3:GetModuleEnabled(MODNAME) end,
                    set = function(_, value) Quartz3:SetModuleEnabled(MODNAME, value) end,
                    order = 100,
                },
                color = {
                    type = "color",
                    name = L["Flight Map Color"],
                    desc = L["Set the color to turn the cast bar when taking a flight path"],
                    get = function() return unpack(db.color) end,
                    set = function(_, ...)
                        db.color = {...}
                        Flight:ApplySettings()
                    end,
                    order = 101,
                },
                deplete = {
                    type = "toggle",
                    name = L["Deplete"],
                    desc = L["Deplete"],
                    get = function() return db.deplete end,
                    set = function(_, value)
                        db.deplete = value
                        Flight:ApplySettings()
                    end,
                    order = 102,
                },
            },
        }
        return options
    end
end

function Flight:OnInitialize()
    self.db = Quartz3.db:RegisterNamespace(MODNAME, defaults)
    db = self.db.profile
    self:SetEnabledState(Quartz3:GetModuleEnabled(MODNAME))
    Quartz3:RegisterModuleOptions(MODNAME, getOptions, OL["OnFlight"])
end

function Flight:OnEnable()
    if addonCore:GetFlightDisplay() == "quartz" then
        Quartz3:SetModuleEnabled("Flight", false)
    end
    addonCore:RegisterCallback("OnFlight_Taxi_Start", self.StartFlight, self)
    addonCore:RegisterCallback("OnFlight_Taxi_Stop", self.EndFlight, self)
    addonCore:RegisterCallback("OnFlight_Taxi_EarlyExit", self.EndFlight, self)
    addonCore:RegisterCallback("OnFlight_Taxi_FAILED_ENTRY", self.EndFlight, self)
    -- A real cast has already populated the bar when this callback runs.
    self:SecureHook(Player, "UNIT_SPELLCAST_START", function() self:EndFlight(true) end)
    self:SecureHook(Player, "OnDisable", "EndFlight")
    self:SecureHook(Quartz3, "Unlock", "ClearFlightBar")
    self:SecureHook(Quartz3, "Lock", "RefreshFlight")
end

function Flight:OnDisable()
    addonCore:UnregisterCallback("OnFlight_Taxi_Start", self)
    addonCore:UnregisterCallback("OnFlight_Taxi_Stop", self)
    addonCore:UnregisterCallback("OnFlight_Taxi_EarlyExit", self)
    addonCore:UnregisterCallback("OnFlight_Taxi_FAILED_ENTRY", self)
    self:UnhookAll()
    self:EndFlight()
    conflictReported = nil
end

function Flight:ApplySettings()
    db = self.db.profile
    self:RefreshFlight()
end

function Flight:RefreshFlight()
    if displayedFlight and displayedFlight == addonCore:GetCurrentFlight() and not Quartz3.unlock then
        self:StartFlight()
    end
end

-- Layout mode clears the bar while retaining the flight it presented.
function Flight.ClearFlightBar()
    if not displayedFlight then return end
    local bar = Player.Bar
    bar.casting, bar.channeling, bar.fadeOut = nil, nil, nil
    bar.startTime, bar.endTime, bar.stopTime = nil, nil, nil
    bar.Spark:Hide()
    bar.TimeText:SetText("")
    bar:Hide()
end

function Flight:EndFlight(keepCast)
    if keepCast ~= true then
        self:ClearFlightBar()
    end
    displayedFlight = nil
end

function Flight:StartFlight()
    local current = addonCore:GetCurrentFlight()
    local elapsed, _, duration = addonCore:GetCurrentFlightProgress()
    if not current or elapsed == nil then return end
    self:EndFlight()
    if addonCore:GetFlightDisplay() ~= "quartz" then return end
    if not Player:IsEnabled() or Quartz3.unlock then return end
    -- Like Quartz's original Flight module, only display measured positive durations.
    if not duration or duration <= 0 then return end
    local original = Quartz3:GetModule("Flight")
    if original:IsEnabled() then
        if not conflictReported then
            Quartz3:Print(OL["Disable Quartz's Flight module to let its OnFlight module use the Player bar."])
            conflictReported = true
        end
        return
    end
    conflictReported = nil
    if UnitCastingInfo("player") or UnitChannelInfo("player") then return end
    self:BeginFlight(duration, current.destinationName, current.startedAt, elapsed)
    displayedFlight = current
end

function Flight:BeginFlight(duration, destination, startedAt, elapsed)
    local bar = Player.Bar
    bar:CancelTimerAnimation()
    Player:ClearStages(bar)
    bar.chargeSpell, bar.castGUID = nil, nil
    bar.delay, bar.fadeOut, bar.stopTime = 0, nil, nil
    bar.Bar:SetMinMaxValues(0, 1)
    bar.Bar:SetStatusBarColor(unpack(db.color))
    bar.Icon:SetTexture("Interface\\Icons\\ability_eyeoftheowl")
    bar.Text:SetText(destination)
    bar:SetAlpha(Player.db.profile.alpha)

    bar.startTime, bar.endTime = startedAt, startedAt + duration
    bar.casting, bar.channeling = not db.deplete, db.deplete
    local progress = math.min(1, math.max(0, elapsed / duration))
    bar.Bar:SetValue(db.deplete and (1 - progress) or progress)
    bar.Spark:SetShown(Quartz3.db.profile.sparkenabled)

    local profile = Player.db.profile
    local position = profile.timetextposition
    if position == "caststart" or position == "castend" then
        local side = position == "caststart" and "LEFT" or "RIGHT"
        bar.TimeText:ClearAllPoints()
        bar.TimeText:SetPoint(side, bar.Bar, side,
            (side == "LEFT" and 1 or -1) * profile.timetextx, profile.timetexty)
        bar.TimeText:SetJustifyH(side)
    end
    bar:Show()
end
