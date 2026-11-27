-- Copy and merge learned flight durations using Forever's native encoding.
-- luacheck: globals LibStub C_EncodingUtil StaticPopupDialogs StaticPopup_Show CLOSE CANCEL
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local factions = {A = "Alliance", H = "Horde"}

local function IsPositiveInteger(value)
    return type(value) == "number" and value > 0 and value < 2^53 and value % 1 == 0
end

local function IsGossipKey(key)
    return type(key) == "string" and key:match("^%d+:.+$")
end

local function ParseEndpoint(field)
    if IsGossipKey(field) then return field end
    local id = tonumber(field)
    if field and field:match("^%d+$") and IsPositiveInteger(id) then return id end
end

local function FormatEndpoint(key)
    if IsPositiveInteger(key) then return ("%.0f"):format(key) end
    if IsGossipKey(key) then return key end
end

local function DecodeDurations(text)
    local decoded = C_EncodingUtil.DecodeBase64((text:gsub("%s+", "")))
    local inflated = decoded and C_EncodingUtil.DecompressString(decoded)
    local records = inflated and C_EncodingUtil.DeserializeCBOR(inflated)
    if type(records) ~= "table" then return end

    local length = #records
    local count = 0
    for index in pairs(records) do
        if not IsPositiveInteger(index) or index > length then return end
        count = count + 1
    end
    if count == length then return records end
end

local function ImportDurations(dialog)
    local ok, records = pcall(DecodeDurations, dialog:GetEditBox():GetText())
    local prefix = addonCore.OnFlightPrefixText
    if not ok or not records then
        print(prefix, L["Invalid flight duration data."])
        return true -- Keep the popup open for another paste.
    end

    local times = addonCore.db.global.flightTimes
    local added, unchanged, differing = 0, 0, 0
    for _, record in ipairs(records) do
        if type(record) == "string" then
            local code, source, destination, duration = record:match("^([AH])|([^|]+)|([^|]+)|(%d+)$")
            source, destination, duration = ParseEndpoint(source), ParseEndpoint(destination), tonumber(duration)
            if code and source and destination and IsPositiveInteger(duration) then
                local faction = factions[code]
                local routes = times[faction]
                routes[source] = routes[source] or {}
                local current = routes[source][destination]
                if current == nil then
                    routes[source][destination] = duration
                    added = added + 1
                elseif current == duration then
                    unchanged = unchanged + 1
                else
                    differing = differing + 1
                    print(prefix, L["%s %s to %s: kept %s s, imported %.0f s."]:format(
                        faction, FormatEndpoint(source), FormatEndpoint(destination), tostring(current), duration))
                end
            end
        end
    end
    print(prefix, L["Flight durations: %d added, %d unchanged, %d differing."]:format(added, unchanged, differing))
end

StaticPopupDialogs.ONFLIGHT_EXPORT_DURATIONS = {
    text = L["Copy flight duration data."],
    button1 = CLOSE,
    hasEditBox = true,
    maxLetters = 0,
    hideOnEscape = true
}

StaticPopupDialogs.ONFLIGHT_IMPORT_DURATIONS = {
    text = L["Paste flight duration data."],
    button1 = L["Import"],
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 0,
    hideOnEscape = true,
    OnAccept = ImportDurations
}

local function ShowDurationPopup(which, text)
    local dialog = StaticPopup_Show(which)
    if not dialog then return end
    local editBox = dialog:GetEditBox()
    editBox:SetMaxBytes(0)
    editBox:SetText(text)
    editBox:SetFocus()
    editBox:HighlightText()
end

function addonCore:ExportDurations()
    local records = {}
    local times = self.db.global.flightTimes
    for code, faction in pairs(factions) do
        for source, routes in pairs(times[faction]) do
            local sourceKey = FormatEndpoint(source)
            if sourceKey and type(routes) == "table" then
                for destination, duration in pairs(routes) do
                    local destinationKey = FormatEndpoint(destination)
                    if destinationKey and IsPositiveInteger(duration) then
                        if sourceKey:find("|", 1, true) or destinationKey:find("|", 1, true) then
                            local message = L["Could not export %s route %q to %q: a key contains a pipe."]
                            print(self.OnFlightPrefixText, message:format(faction, sourceKey, destinationKey))
                        else
                            records[#records + 1] = ("%s|%s|%s|%.0f"):format(code, sourceKey, destinationKey, duration)
                        end
                    end
                end
            end
        end
    end
    local serialized = C_EncodingUtil.SerializeCBOR(records)
    local compressed = C_EncodingUtil.CompressString(serialized)
    local encoded = compressed and C_EncodingUtil.EncodeBase64(compressed)
    if encoded then
        ShowDurationPopup("ONFLIGHT_EXPORT_DURATIONS", encoded)
    else
        print(self.OnFlightPrefixText, L["Could not export flight durations."])
    end
end

function addonCore.OpenDurationImport()
    ShowDurationPopup("ONFLIGHT_IMPORT_DURATIONS", "")
end
