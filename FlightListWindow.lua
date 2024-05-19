local addonName, addonCore = ...
local module = addonCore:NewModule("FlightListWindow", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

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
            zoneDictionary[zoneName][siteName] = taxiNodeIndex
        else
            zoneDictionary["Special"][siteName] = taxiNodeIndex
        end

        local taxiNodeType = TaxiNodeGetType(taxiNodeIndex)
        if taxiNodeType == "DISTANT" then
            countSitesUnknown = countSitesUnknown + 1
            countSitesTotal = countSitesTotal + 1
        elseif taxiNodeType == "CURRENT" then
            countSitesTotal = countSitesTotal + 1
            currentZoneTag = zoneName or "Special"
        else
            countSitesTotal = countSitesTotal + 1
        end
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
            text = ((currentZoneTag == zoneName) and "*" .. zoneName .. "*") or (zoneName),
        })
    end

    for zoneName, zoneData in pairs(zoneDictionary) do
        for siteName, taxiNodeIndex in pairs(zoneData) do
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
    TakeTaxiNode(widget:GetUserData("taxiNodeID"))
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
        for siteName, taxiNodeID in pairs(zoneData) do
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
        local list = {}
        for siteName, taxiNodeIndex in pairs(zoneDictionary[zoneName]) do
            table.insert(list, siteName)
        end
        table.sort(list)
        for index, siteName in ipairs(list) do
            local siteID = zoneDictionary[zoneName][siteName]
            local button = AceGUI:Create("Button")

            button.frame:SetID(siteID)
            button:SetUserData("taxiNodeID", siteID)
            button:SetCallback("OnClick", flightButton_OnClick)
            button:SetCallback("OnEnter", flightButton_OnEnter)
            button:SetCallback("OnLeave", flightButton_OnLeave)

            local taxiNodeType = TaxiNodeGetType(siteID)
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
                        button.frame:SetID(taxiNodeIndex)
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
    mainFrame:SetHeight(430)
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
