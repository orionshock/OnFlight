local addonName, addonCore = ...
local module = addonCore:NewModule("FlightListWindow", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local TaxiNodeName, GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot = TaxiNodeName, GetNumRoutes,
    NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot

function module:OnInitialize()
end

function module:OnEnable()
    self:RegisterEvent("TAXIMAP_OPENED")
    self:RegisterEvent("TAXIMAP_CLOSED")
end

function module:OnDisable()
    self:UnregisterEvent("TAXIMAP_OPENED")
    self:UnregisterEvent("TAXIMAP_CLOSED")
end

local zoneDictionary = {}
local zoneList = {}
local masterTree = {}
local countSitesTotal, countSitesUnknown = 0, 0
local specialZoneAdditions = {
    ["Orgrimmar, Durotar"] = true,
    ["Thunder Bluff, Mulgore"] = true,
    ["Undercity, Tristfall"] = true,
    ["Silvermoon City"] = true,

    ["Stormwind, Elwynn"] = true,
    ["Ironforge, Dun Morogh"] = true,
    ["Darnassus, Teldrassil"] = true,
    ["Exodar, Azuremyst, Isle"] = true,

    ["Shattrath, Terokkar Forest"] = true,

    ["Dalaran"] = true
}

function module:UpdateTaxiDestinations()
    for k, v in pairs(zoneDictionary) do
        wipe(v)
    end
    wipe(zoneDictionary)
    zoneDictionary["Special"] = {}
    wipe(zoneList)
    wipe(masterTree)
    countSitesTotal, countSitesUnknown = 0, 0
    local currentZoneTag

    for taxiNodeIndex = 1, NumTaxiNodes(), 1 do
        local nodeName = TaxiNodeName(taxiNodeIndex)
        local siteName, zoneName = string.split(",", nodeName)
        siteName = siteName and siteName:trim()
        zoneName = zoneName and zoneName:trim()

        if zoneName then                                              --Some Places Don't have zone names, will handle that with a "Special" section
            zoneDictionary[zoneName] = zoneDictionary[zoneName] or {} --Add Zone Name to Dictionary
            zoneDictionary[zoneName][taxiNodeIndex] = siteName
        else
            zoneDictionary["Special"][taxiNodeIndex] = siteName
        end

        local taxiNodeType = TaxiNodeGetType(taxiNodeIndex)
        if taxiNodeType == "DISTANT" then
            countSitesUnknown = countSitesUnknown + 1
        elseif taxiNodeType == "CURRENT" then
            currentZoneTag = zoneName or "Special"
        end
        countSitesTotal = countSitesTotal + 1
    end
    for zName in pairs(zoneDictionary) do --Send Dict to List
        table.insert(zoneList, zName)
    end
    table.sort(zoneList) --Sort The List

    for zoneIndex, zoneName in ipairs(zoneList) do
        zoneList[zoneName] = zoneIndex --Make Reverse Lookup for zone List

        --Add Each Zone in it's proper place, avoids sorting this later
        table.insert(masterTree, {
            value = zoneName,
            text = ((currentZoneTag == zoneName) and ("*%s*"):format(zoneName)) or (zoneName),
        })
    end

    for zoneName, zoneData in pairs(zoneDictionary) do
        for taxiNodeIndex, siteName in pairs(zoneData) do
            if TaxiNodeGetType(taxiNodeIndex) == "DISTANT" then
                masterTree[zoneList[zoneName]].icon = 134400
            end
        end
    end
    masterTree[zoneList["Special"]].icon = 132172
    return masterTree
end

local function mainFrame_OnClose(widget, event)
    if module.AceGuiFrame then
        AceGUI:Release(module.AceGuiFrame)
        module.AceGuiFrame = nil
    end
end

local function flightButton_OnClick(widget, event, button, direction)
    TakeTaxiNode(widget.frame:GetID())
end

local function flightButton_OnEnter(widget, event, button, direction)
    if widget.frame:GetID() then
        TaxiNodeOnButtonEnter(widget.frame) --Call the Default Game Function
        if OnFlight_TaxiFrame_TooltipHook then
            OnFlight_TaxiFrame_TooltipHook(widget.frame)
        end
        for index = 1, NUM_TAXI_BUTTONS do
            local button = _G["TaxiButton" .. index];
            if button:GetID() == widget.frame:GetID() then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end
        local noteText = module:GetFlightPointNote(TaxiNodeName(widget.frame:GetID()))
        if noteText then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.join(" ", addonCore.OnFlightPrefixText, L["Note:"], noteText), nil, nil, nil, true)
            GameTooltip:Show()
        end
    end
end

local function flightButton_OnLeave(widget)
    GameTooltip:Hide()
    for index = 1, NUM_TAXI_BUTTONS do
        local button = _G["TaxiButton" .. index];
        button:UnlockHighlight()
    end
end

local function treeGroup_OnButtonEnter(widget, event, path, frame)
    local zoneData = zoneDictionary[path]
    if zoneData then
        for taxiNodeID, siteName in pairs(zoneData) do
            for index = 1, NUM_TAXI_BUTTONS do
                local button = _G["TaxiButton" .. index];
                if taxiNodeID == button:GetID() then
                    button:LockHighlight()
                end
            end
        end
    end
end

local function treeGroup_OnButtonLeave(widget)
    GameTooltip:Hide()
    for index = 1, NUM_TAXI_BUTTONS do
        local button = _G["TaxiButton" .. index];
        button:UnlockHighlight()
    end
end

local function OnTreeGroupSelected(widget, event, selectedKey)
    local zoneName = selectedKey
    if zoneDictionary[zoneName] then
        widget:ReleaseChildren()
        for siteIndex, siteName in pairs(zoneDictionary[zoneName]) do
            local button = AceGUI:Create("Button")

            button.frame:SetID(siteIndex)
            button:SetCallback("OnClick", flightButton_OnClick)
            button:SetCallback("OnEnter", flightButton_OnEnter)
            button:SetCallback("OnLeave", flightButton_OnLeave)

            local taxiNodeType = TaxiNodeGetType(siteIndex)
            if taxiNodeType == "DISTANT" then
                button:SetText(siteName)
                button:SetDisabled(true)
            elseif taxiNodeType == "CURRENT" then
                button:SetText(("*%s*"):format(siteName))
                button:SetDisabled(true)
            else
                button:SetText(siteName)
                button:SetDisabled(false)
            end
            button:SetAutoWidth(true)
            widget:AddChild(button)
        end
        if zoneName == "Special" then
            local seperator = AceGUI:Create("Label")
            seperator:SetText("\n\nCommon Destinations:")
            widget:AddChild(seperator)
            for specialSite in pairs(specialZoneAdditions) do
                for taxiNodeIndex = 1, NumTaxiNodes(), 1 do
                    local nodeName = TaxiNodeName(taxiNodeIndex)
                    if nodeName == specialSite then
                        local button = AceGUI:Create("Button")
                        button.frame:SetID(taxiNodeIndex) --Prolly Shouldn't do this with AceGUI - but as the taxi tooltip function is expecting it, we set it.
                        button:SetUserData("taxiNodeID", taxiNodeIndex)
                        button:SetCallback("OnClick", flightButton_OnClick)
                        button:SetCallback("OnEnter", flightButton_OnEnter)
                        button:SetCallback("OnLeave", flightButton_OnLeave)

                        local taxiNodeType = TaxiNodeGetType(taxiNodeIndex)
                        if taxiNodeType == "DISTANT" then
                            button:SetText(nodeName)
                            button:SetDisabled(true)
                        elseif taxiNodeType == "CURRENT" then
                            button:SetText(("*%s*"):format(nodeName))
                            button:SetDisabled(true)
                        else
                            button:SetText(nodeName)
                            button:SetDisabled(false)
                        end
                        button:SetAutoWidth(true)
                        widget:AddChild(button)
                    end
                end
            end
        end
    end
end

function module:BuildandShowGUI(treeOptions)
    if module.AceGuiFrame then return end
    local mainFrame = AceGUI:Create("Frame")
    mainFrame:SetHeight(450)
    mainFrame:SetWidth(430)
    mainFrame:SetTitle("Flight Destinations")
    mainFrame:SetStatusText(("Total Taxi Sites: %d -- Total Unknown Sites: %d"):format(countSitesTotal, countSitesUnknown))
    mainFrame:SetLayout("Fill")
    mainFrame:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", -32, -10)
    mainFrame:SetCallback("OnClose", mainFrame_OnClose)


    local treeGroup = AceGUI:Create("TreeGroup")
    treeGroup:SetLayout("List")
    treeGroup:SetTree(treeOptions)
    treeGroup:SetCallback("OnGroupSelected", OnTreeGroupSelected)
    treeGroup:SetCallback("OnButtonEnter", treeGroup_OnButtonEnter)
    treeGroup:SetCallback("OnButtonLeave", treeGroup_OnButtonLeave)

    mainFrame:AddChild(treeGroup)
    treeGroup:SelectByValue("Special")

    mainFrame:Show()
    mainFrame:ClearAllPoints()
    module.AceGuiFrame = mainFrame
end

function module:TAXIMAP_OPENED()
    for i = 1, NumTaxiNodes() do
        for j = 1, GetNumRoutes(i) do
            TaxiGetNodeSlot(i, j, true)
            TaxiGetNodeSlot(i, j, false)
        end
    end
    local flightTree = module:UpdateTaxiDestinations()
    self:BuildandShowGUI(flightTree)
end

function module:TAXIMAP_CLOSED()
    if module.AceGuiFrame then
        AceGUI:Release(module.AceGuiFrame)
        module.AceGuiFrame = nil
    end
end

local flightPointNotes = {
    [L["Silver Tide Hollow, Vashj'ir"]] = L["Earthenring Quartermaster"],
    [L["Bloodgulch, Twilight Highlands"]] = L["Dragonmaw Clan Quartermaster & Dailies"],
    [L["Iron Summit, Searing Gorge"]] = L["Black Rock Mountain - Dungeons and Raids"]
}

function module:GetFlightPointNote(fullNodeName)
    return flightPointNotes[fullNodeName]
end

--Taxi Frame Toggle Button  taxiFrameToggleButton

local taxiFrameToggleButton = CreateFrame("Button", "OnFlight_TaxiFrameToggleButton", TaxiFrame)
taxiFrameToggleButton:SetFrameStrata("MEDIUM")
taxiFrameToggleButton:SetWidth(32)
taxiFrameToggleButton:SetHeight(32)
taxiFrameToggleButton:SetFrameLevel(8)
taxiFrameToggleButton:EnableMouse(true)
taxiFrameToggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
taxiFrameToggleButton:SetPoint("CENTER", TaxiFrame, "TOPRIGHT", -55, -55)

local taxiFrameToggleButtonIcon = taxiFrameToggleButton:CreateTexture(nil, "BACKGROUND")
taxiFrameToggleButtonIcon:SetTexture(132172) -- Set the texture using the provided ID
taxiFrameToggleButtonIcon:SetWidth(20)
taxiFrameToggleButtonIcon:SetHeight(20)
taxiFrameToggleButtonIcon:SetPoint("CENTER", taxiFrameToggleButton, "CENTER", 0, 0)

local taxiFrameToggleButtonBorder = taxiFrameToggleButton:CreateTexture(nil, "OVERLAY")
taxiFrameToggleButtonBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
taxiFrameToggleButtonBorder:SetWidth(54)
taxiFrameToggleButtonBorder:SetHeight(54)
taxiFrameToggleButtonBorder:SetPoint("TOPLEFT", taxiFrameToggleButton, "TOPLEFT")

taxiFrameToggleButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(L["Toggle Flight Destinations View"], 1, 1, 1)
    GameTooltip:Show()
end)

taxiFrameToggleButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

taxiFrameToggleButton:SetScript("OnClick", function(self, button)
    print(self:GetName(), button)
    if button == "LeftButton" then
        if module.AceGuiFrame and module.AceGuiFrame:IsShown() then
            module:TAXIMAP_CLOSED()
        elseif not module.AceGuiFrame then
            module:TAXIMAP_OPENED()
        end
    elseif button == "RightButton" then
        if LibStub("AceConfigDialog-3.0").OpenFrames["OnFlight"] then
            LibStub("AceConfigDialog-3.0"):Close("OnFlight")
        else
            module:TAXIMAP_CLOSED()
            LibStub("AceConfigDialog-3.0"):Open("OnFlight")
        end
    end
end)
