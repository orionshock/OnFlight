-- Slash commands and the AceDBOptions table embedded in native Settings.
-- luacheck: globals LibStub SlashCmdList SLASH_ONFLIGHT1 InCombatLockdown
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

function addonCore:InitializeConfig()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(addonName, {
        type = "group",
        name = L["OnFlight Options"],
        args = {
            profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
        }
    })
end

SLASH_ONFLIGHT1 = "/onflight"
SlashCmdList.ONFLIGHT = function(input)
    local command = (input or ""):match("^%s*(.-)%s*$"):lower()
    if command == "" then
        if InCombatLockdown() then
            print(addonCore.OnFlightPrefixText, L["In Combat"])
        else
            addonCore:OpenSettings()
        end
    elseif command == "export" then
        addonCore:ExportDurations()
    elseif command == "import" then
        addonCore.OpenDurationImport()
    elseif command == "test known" then
        addonCore:GetModule("TimerBar"):TogglePreview(false)
    elseif command == "test unknown" then
        addonCore:GetModule("TimerBar"):TogglePreview(true)
    elseif command == "test stop" then
        addonCore:GetModule("TimerBar"):StopPreview()
    elseif command == "debug" then
        local profile = addonCore.db.profile
        profile.taxiDebug = not profile.taxiDebug
        addonCore:UpdateTaxiDebug()
        print(addonCore.OnFlightPrefixText, L["Taxi debug logging %s."]:format(profile.taxiDebug and L["ON"] or L["OFF"]))
    elseif command == "debug clear" then
        addonCore:ClearTaxiDebugLog()
        print(addonCore.OnFlightPrefixText, L["Taxi debug log cleared."])
    elseif command == "chat" then
        local profile = addonCore.db.profile
        profile.showChat = not profile.showChat
        addonCore:RefreshSettings("showChat")
        print(addonCore.OnFlightPrefixText, L["Chat messages %s."]:format(profile.showChat and L["ON"] or L["OFF"]))
    else
        print(addonCore.OnFlightPrefixText,
            L["Usage: /onflight | /onflight export | /onflight import | /onflight test known | /onflight test unknown | /onflight test stop | /onflight debug | /onflight debug clear | /onflight chat"])
    end
end
