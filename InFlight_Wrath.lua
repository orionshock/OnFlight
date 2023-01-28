--[[
    New InFlight System
    We're Ace3'ing it, in for a peny, in for a pound.

]]

--luachekc: globals LibStub

local addonName, addonCore = ...
addonCore = LibStub("AceAddon-3.0"):NewAddon(addonCore, "InFlight", "AceConsole-3.0", "AceEvent-3.0")
_G[addonName] = addonCore

local db

function addonCore:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("WelcomeHomeDB", defaults, true)
end

function addonCore:OnEnable()

end

function addonCore:OnDisable()

end