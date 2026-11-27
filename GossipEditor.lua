-- Native gossip configuration editor and shared endpoint input validation.
-- luacheck: no max line length
-- luacheck: globals LibStub Settings CreateFrame GameTooltip GameTooltip_Hide
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local gossipPage

local function MakeInput(parent, width)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width, 22)
    input:SetAutoFocus(false)
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return input
end

local function MakeButton(parent, text, width, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", click)
    return button
end

local function EndpointText(optionID, value)
    if type(value) == "number" then
        return tostring(value), addonCore:GetTaxiNodeName(value)
    end
    local _, label = addonCore:GetGossipEndpoint(optionID, value)
    return label or "", label
end

local function SetEndpointInput(input, optionID, value)
    local text, label = EndpointText(optionID, value)
    input.dirty = nil
    input:SetText(text)
    input.feedback:SetText(label or "")
    input.feedback:SetTextColor(1, 0.82, 0)
end

local function CommitEndpoint(input)
    if not input.dirty then
        return
    end
    input.dirty = nil
    local row = input:GetParent()
    local key, message = addonCore:ParseGossipEndpoint(row.optionID or 0, input:GetText())
    if not key then
        input:SetText("")
        input.feedback:SetText(message)
        input.feedback:SetTextColor(1, 0.3, 0.3)
        return
    end
    if row.optionID then
        addonCore.db.global.gossipTriggered[row.optionID][input.endpoint] = key
    end
    -- Keep the original label in the input so Add cannot mistake a sanitized label for a taxi ID.
    input:SetText(type(key) == "number" and tostring(key) or message)
    input.feedback:SetText(type(key) == "string" and key:match("^%d+:(.*)$") or message)
    input.feedback:SetTextColor(1, 0.82, 0)
end

local function CreateGossipRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(114)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 0, -2)
    for index, name in ipairs({L["Source"], L["Destination"]}) do
        local input = MakeInput(row, 200)
        input.endpoint = index
        input:SetPoint("TOPLEFT", index == 1 and 8 or 270, -46)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 4)
        label:SetText(name)
        input.feedback = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        input.feedback:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -5)
        input.feedback:SetWidth(235)
        input.feedback:SetJustifyH("LEFT")
        input:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                self.dirty = true
            end
        end)
        input:SetScript("OnEnterPressed", function(self)
            CommitEndpoint(self);
            self:ClearFocus()
        end)
        input:SetScript("OnEditFocusLost", CommitEndpoint)
        row[index] = input
    end
    return row
end

function addonCore:RefreshGossipEditor(optionID)
    if not gossipPage then
        return
    end
    local ids = {}
    for id in pairs(self.db.global.gossipTriggered) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for id, row in pairs(gossipPage.rows) do
        if not self.db.global.gossipTriggered[id] then
            -- Do not commit focused inputs after their configuration has been removed.
            for index = 1, 2 do
                row[index].dirty = nil;
                row[index]:ClearFocus()
            end
            row:Hide()
            gossipPage.rows[id] = nil
            gossipPage.freeRows[#gossipPage.freeRows + 1] = row
        end
    end
    for index, id in ipairs(ids) do
        local row = gossipPage.rows[id]
        if not row then
            row = table.remove(gossipPage.freeRows) or CreateGossipRow(gossipPage.content)
            row.optionID = id
            row.title:SetFormattedText(L["Gossip ID: %d"], id)
            if not row.remove then
                row.remove = MakeButton(row, L["Remove"], 80, function()
                    local removedID = row.optionID
                    local data = self.db.global
                    local endpoints = data.gossipTriggered[removedID]
                    local source = self:GetGossipEndpoint(removedID, endpoints[1])
                    local destination = self:GetGossipEndpoint(removedID, endpoints[2])
                    if source and destination then
                        for _, faction in ipairs({"Alliance", "Horde"}) do
                            local routes = data.flightTimes[faction]
                            local durations = routes[source]
                            if durations then
                                durations[destination] = nil
                                if not next(durations) then
                                    routes[source] = nil
                                end
                            end
                        end
                    end
                    data.gossipTriggered[removedID] = nil
                    self:RefreshGossipEditor(removedID)
                end)
                row.remove:SetPoint("TOPRIGHT", -8, 0)
            end
            gossipPage.rows[id] = row
            for endpoint = 1, 2 do
                SetEndpointInput(row[endpoint], id, self.db.global.gossipTriggered[id][endpoint])
            end
        end
        if optionID == id then
            for endpoint = 1, 2 do
                SetEndpointInput(row[endpoint], id, self.db.global.gossipTriggered[id][endpoint])
            end
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 114)
        row:SetPoint("TOPRIGHT", 0, -(index - 1) * 114)
        row:Show()
    end
    gossipPage.content:SetHeight(math.max(1, #ids * 114))
end

function addonCore:CreateGossipSettings(parentCategory, register)
    local page = CreateFrame("Frame")
    page:Hide()
    page.rows, page.freeRows = {}, {}
    gossipPage = page
    local category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, page, L["Gossip Configuration"])
    local help =
        L["Shows gossip option IDs in NPC dialogue tooltips and taxi-node IDs beside destinations in Flight Destinations. Use these IDs to configure gossip flights."]
    local diagnosticSetting = register(category, "showGossipConfig", "boolean", L["Show Diagnostic IDs"], false, function()
        return addonCore.db.profile.showGossipConfig
    end, function(value)
        addonCore.db.profile.showGossipConfig = value
        addonCore:RefreshDiagnostics()
    end)
    local checkbox = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 12, -8)
    checkbox.Text:SetText(L["Show Diagnostic IDs"])
    checkbox.Text:SetFontObject("GameFontNormal")
    checkbox:SetScript("OnClick", function(control)
        diagnosticSetting:SetValue(control:GetChecked())
    end)
    checkbox:SetScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Show Diagnostic IDs"], 1, 1, 1)
        GameTooltip:AddLine(help, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", GameTooltip_Hide)
    diagnosticSetting:SetValueChangedCallback(function(_, value)
        checkbox:SetChecked(value)
    end)
    local diagnosticHelp = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    diagnosticHelp:SetPoint("TOPLEFT", 18, -44)
    diagnosticHelp:SetPoint("TOPRIGHT", -20, -44)
    diagnosticHelp:SetJustifyH("LEFT")
    diagnosticHelp:SetText(L["Enable this while configuring a gossip flight."])
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", diagnosticHelp, "BOTTOMLEFT", 0, -16)
    title:SetPoint("TOPRIGHT", diagnosticHelp, "BOTTOMRIGHT", 0, -16)
    title:SetJustifyH("LEFT")
    title:SetText(L["Gossip Flights"])
    local explanation = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    explanation:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    explanation:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    explanation:SetJustifyH("LEFT")
    explanation:SetText(
        L["Configure flights started through NPC dialogue. A Gossip ID identifies the dialogue option that starts a flight."])
    local endpointsTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    endpointsTitle:SetPoint("TOPLEFT", explanation, "BOTTOMLEFT", 0, -14)
    endpointsTitle:SetPoint("TOPRIGHT", explanation, "BOTTOMRIGHT", 0, -14)
    endpointsTitle:SetJustifyH("LEFT")
    endpointsTitle:SetText(L["Endpoints"])
    local endpointsHelp = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    endpointsHelp:SetPoint("TOPLEFT", endpointsTitle, "BOTTOMLEFT", 0, -8)
    endpointsHelp:SetPoint("TOPRIGHT", endpointsTitle, "BOTTOMRIGHT", 0, -8)
    endpointsHelp:SetJustifyH("LEFT")
    endpointsHelp:SetText(
        L["Enter a taxi-node ID or a custom location name for Source and Destination. Press Enter or click away to save."])

    local new = CreateGossipRow(page)
    new:SetPoint("TOPLEFT", endpointsHelp, "BOTTOMLEFT", 0, -20)
    new:SetPoint("TOPRIGHT", endpointsHelp, "BOTTOMRIGHT", -8, -20)
    new.title:SetText(L["New Gossip ID:"])
    new.id = MakeInput(new, 95)
    new.id:SetPoint("TOPLEFT", 140, 2)
    new.id:SetNumeric(true)
    new.id:SetScript("OnEnterPressed", function(input)
        input:ClearFocus()
    end)
    new.add = MakeButton(new, L["Add"], 80, function()
        CommitEndpoint(new[1]);
        CommitEndpoint(new[2])
        local id = tonumber(new.id:GetText())
        if not id or id <= 0 or id % 1 ~= 0 then
            new[1].feedback:SetText(L["Enter a Gossip ID from a dialogue tooltip: digits only, greater than zero."])
            return
        end
        if addonCore.db.global.gossipTriggered[id] then
            new[1].feedback:SetText(L["This Gossip ID already exists. Edit its endpoints below."])
            return
        end
        local source, sourceMessage = addonCore:ParseGossipEndpoint(id, new[1]:GetText())
        local destination, destinationMessage = addonCore:ParseGossipEndpoint(id, new[2]:GetText())
        if not source or not destination then
            if not source then
                new[1].feedback:SetText(sourceMessage)
            end
            if not destination then
                new[2].feedback:SetText(destinationMessage)
            end
            return
        end
        addonCore.db.global.gossipTriggered[id] = {source, destination}
        new.id:SetText("");
        new.id:ClearFocus()
        for index = 1, 2 do
            new[index].dirty = nil
            new[index]:SetText("")
            new[index].feedback:SetText("")
            new[index]:ClearFocus()
        end
        addonCore:RefreshGossipEditor(id)
    end)
    new.add:SetPoint("TOPRIGHT", -8, 0)

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", new, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMRIGHT", -36, 12)
    page.content = CreateFrame("Frame", nil, scroll)
    page.content:SetSize(1, 1)
    scroll:SetScrollChild(page.content)
    scroll:SetScript("OnSizeChanged", function(_, width)
        page.content:SetWidth(width)
    end)
    page.OnRefresh = function()
        checkbox:SetChecked(diagnosticSetting:GetValue())
        addonCore:RefreshGossipEditor()
        for id, row in pairs(page.rows) do
            for index = 1, 2 do
                SetEndpointInput(row[index], id, addonCore.db.global.gossipTriggered[id][index])
            end
        end
    end
    page:SetScript("OnHide", function()
        new.id:ClearFocus()
        for index = 1, 2 do
            new[index]:ClearFocus()
        end
        for _, row in pairs(page.rows) do
            for index = 1, 2 do
                row[index]:ClearFocus()
            end
        end
    end)
end

-- Validate endpoint text entered in the native gossip editor.
function addonCore:ParseGossipEndpoint(optionID, text)
    local value = text:match("^%s*(.-)%s*$")
    if value == "" then
        return nil, L["Enter a taxi-node ID or a custom location name."]
    end
    if value:match("^%d+$") then
        local id = tonumber(value)
        local name = self:GetTaxiNodeName(id)
        if name then
            return id, name
        end
        return nil, L["Unknown taxi-node ID. Check the ID or use a name. Saved value unchanged."]
    end
    local key = self.MakeGossipEndpointKey(optionID, value)
    if not key then
        return nil, L["Enter a taxi-node ID or a custom location name."]
    end
    return key, value
end
