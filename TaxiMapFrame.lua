-- Native TaxiFrame chrome, panel sizing, and map-side toggle.
-- luacheck: globals TaxiFrame TaxiRouteMap GetTaxiMapID C_Map C_Texture CreateVector2D CreateFrame hooksecurefunc
-- luacheck: globals GetUIPanelWidthUnscaled SetUIPanelAttribute UpdateUIPanelPositions NineSliceUtil
local _, addonCore = ...

local taxiWidth = TaxiFrame:GetWidth()
local taxiPanelWidth = GetUIPanelWidthUnscaled(TaxiFrame)
local browserExtent = 430
local expandedWidth = taxiWidth + browserExtent
local expandedPanelWidth = taxiPanelWidth + browserExtent + C_Texture.GetAtlasInfo("common-sidetab").width
local taxiBorder = {
    TopLeftCorner = TaxiFrame.TopLeftCorner,
    TopRightCorner = TaxiFrame.TopRightCorner,
    BottomLeftCorner = TaxiFrame.BotLeftCorner,
    BottomRightCorner = TaxiFrame.BotRightCorner,
    TopEdge = TaxiFrame.TopBorder,
    BottomEdge = TaxiFrame.BottomBorder,
    LeftEdge = TaxiFrame.LeftBorder,
    RightEdge = TaxiFrame.RightBorder,
    Center = TaxiFrame.Bg,
}
local leftBorderLayer

local function StyleTaxiFrame()
    -- NineSlice's legacy lookup lets the modern border reuse TaxiFrame's existing regions.
    TaxiFrame.GetNineSlicePiece = function(_, piece)
        return taxiBorder[piece]
    end
    for piece, texture in pairs(taxiBorder) do
        if piece ~= "Center" then
            texture:SetDrawLayer("OVERLAY")
        end
    end
    NineSliceUtil.ApplyLayoutByName(TaxiFrame, "ButtonFrameTemplateNoPortrait")
    TaxiFrame.GetNineSlicePiece = nil
    TaxiFrame.TitleBg:Hide()

    -- The detailed map is a child frame, so its textures otherwise cover the left edge.
    if not leftBorderLayer then
        leftBorderLayer = CreateFrame("Frame", nil, TaxiFrame)
        leftBorderLayer:SetAllPoints(TaxiFrame)
        leftBorderLayer:EnableMouse(false)
        TaxiFrame.TopLeftCorner:SetParent(leftBorderLayer)
        TaxiFrame.BotLeftCorner:SetParent(leftBorderLayer)
        TaxiFrame.LeftBorder:SetParent(leftBorderLayer)
    end
    leftBorderLayer:SetFrameLevel(TaxiRouteMap:GetFrameLevel() + 2)
end

function addonCore.ExpandTaxiFrame()
    StyleTaxiFrame()
    -- Keep Blizzard's 580x580 taxi map fixed while its outer frame grows.
    TaxiFrame.InsetBg:ClearAllPoints()
    TaxiFrame.InsetBg:SetPoint("TOPLEFT", TaxiFrame, "TOPLEFT", 4, -24)
    TaxiFrame.InsetBg:SetPoint("BOTTOMRIGHT", TaxiFrame, "TOPLEFT", 584, -604)
    TaxiFrame:SetWidth(expandedWidth)
    SetUIPanelAttribute(TaxiFrame, "width", expandedPanelWidth)
    if TaxiFrame:IsShown() then
        UpdateUIPanelPositions(TaxiFrame)
    end
end

function addonCore.RestoreTaxiFrame()
    TaxiFrame.InsetBg:ClearAllPoints()
    TaxiFrame.InsetBg:SetPoint("TOPLEFT", TaxiFrame, "TOPLEFT", 4, -24)
    TaxiFrame.InsetBg:SetPoint("BOTTOMRIGHT", TaxiFrame, "BOTTOMRIGHT", -6, 4)
    TaxiFrame:SetWidth(taxiWidth)
    SetUIPanelAttribute(TaxiFrame, "width", taxiPanelWidth)
    if TaxiFrame:IsShown() then
        UpdateUIPanelPositions(TaxiFrame)
    end
end

function addonCore:CreateTaxiFrameToggle()
    if self.taxiFrameToggle then return self.taxiFrameToggle end
    local toggle = CreateFrame("Button", "OnFlight_TaxiFrameToggleButton", TaxiFrame)
    self.taxiFrameToggle = toggle
    toggle:SetSize(32, 32)
    toggle:SetPoint("CENTER", TaxiFrame, "TOPLEFT", taxiWidth - 60, -45)
    toggle:SetFrameLevel(TaxiFrame:GetFrameLevel() + 5)
    toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local icon = toggle:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(132172)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    local border = toggle:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    return toggle
end
