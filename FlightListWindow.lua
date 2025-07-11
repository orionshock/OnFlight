---@diagnostic disable: undefined-field, invisible
local addonName, addonCore = ...
local moduleName = "FlightListWindow"
local module = addonCore:NewModule(moduleName, "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local db
local TaxiNodeName, GetNumRoutes, NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot = TaxiNodeName, GetNumRoutes,
    NumTaxiNodes, TaxiNodeGetType, TaxiGetNodeSlot

local OnTreeGroupSelected --because we use it in different places...

local svDefaults = {
    profile = {
        --Dictionary List of Flight locations for Fav/Special Menu
        --Defaults are the Major Faction Cities
        ["Orgrimmar, Durotar"] = true,
        ["Thunder Bluff, Mulgore"] = true,
        ["Undercity, Tirisfal"] = true,
        ["Silvermoon City"] = true,

        ["Stormwind, Elwynn"] = true,
        ["Ironforge, Dun Morogh"] = true,
        ["Darnassus, Teldrassil"] = true,
        ["Exodar, Azuremyst, Isle"] = true,

        ["Shattrath, Terokkar Forest"] = true,

        ["Dalaran"] = true
    }
}

function module:OnInitialize()
    self:SetEnabledState(addonCore.db.profile.moduleState[moduleName])
    self.db = addonCore.db:RegisterNamespace(moduleName, svDefaults)
    db = self.db
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
local favIcon = CreateSimpleTextureMarkup(134411, 16, 16)

function module:UpdateTaxiDestinations()
    for k, v in pairs(zoneDictionary) do
        wipe(v)
    end
    wipe(zoneDictionary)
    zoneDictionary[L["Special"]] = {}
    wipe(zoneList)
    wipe(masterTree)
    countSitesTotal, countSitesUnknown = 0, 0
    local currentZoneTag

    for taxiNodeIndex = 1, NumTaxiNodes(), 1 do
        local nodeName = TaxiNodeName(taxiNodeIndex)
        local siteName, zoneName = string.split(",", nodeName)
        siteName = siteName and siteName:trim()
        zoneName = zoneName and zoneName:trim()

        if db.profile[nodeName] then
            siteName = favIcon .. " " .. siteName
        end

        if zoneName then                                              --Some Places Don't have zone names, will handle that with a "Special" section
            zoneDictionary[zoneName] = zoneDictionary[zoneName] or {} --Add Zone Name to Dictionary
            zoneDictionary[zoneName][taxiNodeIndex] = siteName
        else
            zoneDictionary[L["Special"]][taxiNodeIndex] = siteName
        end

        local taxiNodeType = TaxiNodeGetType(taxiNodeIndex)
        if taxiNodeType == "DISTANT" then
            countSitesUnknown = countSitesUnknown + 1
        elseif taxiNodeType == "CURRENT" then
            currentZoneTag = zoneName or L["Special"]
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
            text = zoneName,
            icon = currentZoneTag == zoneName and 137033 --Green Taxi Icon
        })
    end

    for zoneName, zoneData in pairs(zoneDictionary) do
        for taxiNodeIndex, siteName in pairs(zoneData) do
            if TaxiNodeGetType(taxiNodeIndex) == "DISTANT" then
                masterTree[zoneList[zoneName]].icon = masterTree[zoneList[zoneName]].icon or
                    134400 --The Question Mark Icon
            end
        end
    end
    masterTree[zoneList[L["Special"]]].icon = 132172
    return masterTree
end

local function mainFrame_OnClose(widget, event)
    if module.AceGuiFrame then
        AceGUI:Release(module.AceGuiFrame)
        module.AceGuiFrame = nil
    end
end

local function flightButton_OnClick(widget, event, button, direction)
    --button seems to always be left click...
    if IsShiftKeyDown() then
        local siteName = TaxiNodeName(widget.frame:GetID())
        if db.profile[siteName] then
            db.profile[siteName] = nil
        else
            db.profile[siteName] = true
        end
        module:UpdateTaxiDestinations()
        OnTreeGroupSelected(widget.parent, "flightButton_OnClick", widget.parent.localstatus.selected)
    else
        TakeTaxiNode(widget.frame:GetID())
    end
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

local currentLocationIcon = CreateSimpleTextureMarkup(137033, 16, 16, 0, 0)

local function StageFlightButton(widget, siteName, siteIndex, taxiNodeType)
    widget.frame:SetID(siteIndex)
    widget:SetCallback("OnClick", flightButton_OnClick)
    widget:SetCallback("OnEnter", flightButton_OnEnter)
    widget:SetCallback("OnLeave", flightButton_OnLeave)
    if taxiNodeType == "DISTANT" then
        widget:SetText(siteName)
        widget:SetDisabled(true)
    elseif taxiNodeType == "CURRENT" then
        widget:SetText(currentLocationIcon .. " " .. siteName)
        widget:SetDisabled(true)
    else
        widget:SetText(siteName)
        widget:SetDisabled(false)
    end
    widget.width = "fill"
    return widget
end

local function GetCurrentlySelectedTreeIcon(widgetObject)
    if widgetObject and widgetObject.type == "TreeGroup" then
        for _, treeData in ipairs(widgetObject.tree) do
            if treeData.value == widgetObject.localstatus.selected then
                return treeData.icon
            end
        end
    end
end

function OnTreeGroupSelected(treeGroupWidget, event, selectedKey)
    local zoneName = selectedKey
    local zoneList = zoneDictionary[zoneName]
    treeGroupWidget:ReleaseChildren()
    if (zoneList) and (type(zoneList) == "table") and next(zoneList) then
        ---Zone Title---
        local zoneTitle = AceGUI:Create("Heading")
        local zoneTitleIcon = GetCurrentlySelectedTreeIcon(treeGroupWidget)
        if zoneTitleIcon then
            local iconTextEscapeString = CreateSimpleTextureMarkup(zoneTitleIcon, 16, 16)
            zoneTitle:SetText(iconTextEscapeString .. " " .. zoneName)
        else
            zoneTitle:SetText(zoneName)
        end
        zoneTitle.width = "fill"
        treeGroupWidget:AddChild(zoneTitle)
        ---

        ---Zone Buttons---
        for siteIndex = 1, NumTaxiNodes(), 1 do
            local siteName = zoneList[siteIndex]
            if siteName then
                local button = AceGUI:Create("Button")
                local taxiNodeType = TaxiNodeGetType(siteIndex)
                StageFlightButton(button, siteName, siteIndex, taxiNodeType)
                treeGroupWidget:AddChild(button)
            end
        end

        ---Favorite Spacer Lable
        local favSpacerLabel = AceGUI:Create("Label")
        favSpacerLabel:SetText("\n")
        favSpacerLabel.width = "fill"
        favSpacerLabel:SetJustifyH("CENTER")
        treeGroupWidget:AddChild(favSpacerLabel)
    end

    ---Special Zone Handling, theis is where fav list is---
    if zoneName == L["Special"] then
        ---Fav Buttons Heading---
        local specialZoneTitle = AceGUI:Create("Heading")
        specialZoneTitle:SetText(favIcon .. " " .. L["Favorite Destinations"])
        specialZoneTitle.width = "fill"
        treeGroupWidget:AddChild(specialZoneTitle)

        ---Fav Buttons---
        for taxiNodeIndex = 1, NumTaxiNodes(), 1 do
            local nodeName = TaxiNodeName(taxiNodeIndex)
            if db.profile[nodeName] then
                local button = AceGUI:Create("Button")
                local taxiNodeType = TaxiNodeGetType(taxiNodeIndex)
                button = StageFlightButton(button, nodeName, taxiNodeIndex, taxiNodeType)
                treeGroupWidget:AddChild(button)
            end
        end

        ---Fav Instructions lable---
        local instructionText = AceGUI:Create("Label")
        instructionText:SetText("\n(Shift Click to Toggle)")
        instructionText.width = "fill"
        instructionText:SetJustifyH("CENTER")
        treeGroupWidget:AddChild(instructionText)
    end
end

function module:BuildandShowGUI(treeOptions)
    if module.AceGuiFrame then return end
    local mainFrame = AceGUI:Create("Frame")
    mainFrame:SetHeight(450)
    mainFrame:SetWidth(495)
    mainFrame:SetTitle("Flight Destinations")
    mainFrame:SetStatusText((L["Total: %d -- Unknown: %d"]):format(countSitesTotal, countSitesUnknown))
    mainFrame:SetLayout("Fill")
    mainFrame:SetPoint("TOPLEFT", TaxiFrame, "TOPRIGHT", 0,0)
    mainFrame:SetCallback("OnClose", mainFrame_OnClose)


    local treeGroup = AceGUI:Create("TreeGroup")
    treeGroup:SetLayout("List")
    treeGroup:SetTree(treeOptions)
    treeGroup:SetCallback("OnGroupSelected", OnTreeGroupSelected)
    treeGroup:SetCallback("OnButtonEnter", treeGroup_OnButtonEnter)
    treeGroup:SetCallback("OnButtonLeave", treeGroup_OnButtonLeave)

    mainFrame:AddChild(treeGroup)
    treeGroup:SelectByValue(L["Special"])

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

--Taxi Frame Toggle Button
local taxiFrameToggleButton = CreateFrame("Button", "OnFlight_TaxiFrameToggleButton", TaxiFrame)
taxiFrameToggleButton:SetFrameStrata("MEDIUM")
taxiFrameToggleButton:SetWidth(32)
taxiFrameToggleButton:SetHeight(32)
taxiFrameToggleButton:SetFrameLevel(8)
taxiFrameToggleButton:EnableMouse(true)
taxiFrameToggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
taxiFrameToggleButton:SetPoint("CENTER", TaxiFrame, "TOPRIGHT", -60, -45)

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
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    if module:IsEnabled() then
        GameTooltip:AddLine(L["Left Click to Toggle Flight Destinations View"], 1, 1, 1)
    else
        GameTooltip:AddLine(L["Flight Destinations Module Disabled"], .5, .5, .5)
    end

    GameTooltip:AddLine(L["Right Click to Toggle OnFlight Settings"], 1, 1, 1)
    GameTooltip:Show()
end)

taxiFrameToggleButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

taxiFrameToggleButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if not module:IsEnabled() then return end
        if module.AceGuiFrame and module.AceGuiFrame:IsShown() then
            module:TAXIMAP_CLOSED()
        elseif not module.AceGuiFrame then
            module:TAXIMAP_OPENED()
        end
    elseif button == "RightButton" then
        if LibStub("AceConfigDialog-3.0").OpenFrames["OnFlight"] then
            LibStub("AceConfigDialog-3.0"):Close("OnFlight")
            if module:IsEnabled() then
                module:TAXIMAP_OPENED()
            end
        else
            module:TAXIMAP_CLOSED()
            LibStub("AceConfigDialog-3.0"):Open("OnFlight")
        end
    end
end)


addonCore.configOptionsTable.plugins = addonCore.configOptionsTable.plugins or {}
addonCore.configOptionsTable.plugins[moduleName] = {
    ["FlightListWindow"] = {
        handler = module,
        name = L["Flight Destinations"],
        type = "group",
        order = 200,
        disabled = function(info)
            return not module:IsEnabled()
        end,
        args = {
            resetToDefaults = {
                type = "execute",
                name = L["Reset Favorite Destinations"],
                func = function(info)
                    db:ResetProfile(true)
                end,
            },
        }
    }
}
