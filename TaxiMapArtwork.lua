-- Detailed continent artwork under Blizzard's taxi routes and buttons.
-- luacheck: globals TaxiFrame TaxiRouteMap GetTaxiMapID C_Map CreateVector2D CreateFrame hooksecurefunc
local _, addonCore = ...

local continentMaps = { [1464] = 1414, [1463] = 1415 }
local artwork = {}
local shownArtwork

local function MapPosition(taxiMapID, mapID, x, y)
    local instance, world = C_Map.GetWorldPosFromMapPos(taxiMapID, CreateVector2D(x, y))
    if not world then return end
    local _, position = C_Map.GetMapPosFromWorldPos(instance, world, mapID)
    if position then return position:GetXY() end
end

local function HideArtwork()
    if shownArtwork then
        shownArtwork:Hide()
        shownArtwork = nil
    end
end

local function ShowArtwork()
    local taxiMapID = GetTaxiMapID()
    local mapID = continentMaps[taxiMapID]
    if not TaxiFrame:IsShown() or not mapID or not addonCore.db.profile.useWorldMapFlightMaps then
        HideArtwork()
        return
    end
    HideArtwork()
    if artwork[taxiMapID] then
        shownArtwork = artwork[taxiMapID]
        shownArtwork:Show()
        return
    end

    local left, top = MapPosition(taxiMapID, mapID, 0, 0)
    local right, bottom = MapPosition(taxiMapID, mapID, 1, 1)
    local layers = C_Map.GetMapArtLayers(mapID)
    local layer = layers and layers[1]
    local files = layer and C_Map.GetMapArtLayerTextures(mapID, 1)
    if not (left and right and top and bottom and layer and files) then return end

    local cols = math.ceil(layer.layerWidth / layer.tileWidth)
    local rows = math.ceil(layer.layerHeight / layer.tileHeight)
    if #files < cols * rows then return end

    left, right = left * layer.layerWidth, right * layer.layerWidth
    top, bottom = top * layer.layerHeight, bottom * layer.layerHeight
    local width, height = TaxiFrame.InsetBg:GetSize()
    local scaleX = width / (right - left)
    local scaleY = height / (bottom - top)

    local frame = CreateFrame("Frame", nil, TaxiFrame)
    frame:SetAllPoints(TaxiFrame.InsetBg)
    frame:SetFrameLevel(TaxiRouteMap:GetFrameLevel())
    frame:EnableMouse(false)

    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local x = col * layer.tileWidth
            local y = row * layer.tileHeight
            local x0 = math.max(x, left)
            local y0 = math.max(y, top)
            local x1 = math.min(x + layer.tileWidth, right, layer.layerWidth)
            local y1 = math.min(y + layer.tileHeight, bottom, layer.layerHeight)
            if x1 > x0 and y1 > y0 then
                local tex = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
                tex:SetTexture(files[row * cols + col + 1])
                tex:SetTexCoord((x0 - x) / layer.tileWidth, (x1 - x) / layer.tileWidth,
                    (y0 - y) / layer.tileHeight, (y1 - y) / layer.tileHeight)
                tex:SetPoint("TOPLEFT", (x0 - left) * scaleX, -(y0 - top) * scaleY)
                tex:SetSize((x1 - x0) * scaleX, (y1 - y0) * scaleY)
            end
        end
    end
    artwork[taxiMapID] = frame
    shownArtwork = frame
end

addonCore:RegisterMessage("OnFlight_TaxiMapReady", ShowArtwork)
TaxiFrame:HookScript("OnHide", HideArtwork)

-- A displayed taxi map can change without the frame closing.
hooksecurefunc("SetTaxiMap", function()
    if shownArtwork and shownArtwork ~= artwork[GetTaxiMapID()] then HideArtwork() end
end)
