local AddonName, Addon = ...

local TILE_KEYS = { "left", "right", "top", "bottom", "topLeft", "topRight", "bottomLeft", "bottomRight" }

local TILE_EDGE_INSET = 2 / 256

local BORDER_UV = {
    left        = {0, 0, 0, 1, 0.125, 0, 0.125, 1},
    right       = {0.125, 0, 0.125, 1, 0.25, 0, 0.25, 1},
    top         = {0.25 + TILE_EDGE_INSET, 0, 0.25 + TILE_EDGE_INSET, 1, 0.375 - TILE_EDGE_INSET, 0, 0.375 - TILE_EDGE_INSET, 1},
    bottom      = {0.375 + TILE_EDGE_INSET, 0, 0.375 + TILE_EDGE_INSET, 1, 0.5 - TILE_EDGE_INSET, 0, 0.5 - TILE_EDGE_INSET, 1},
    topLeft     = {0.5, 0, 0.5, 1, 0.625, 0, 0.625, 1},
    topRight    = {0.625, 0, 0.625, 1, 0.75, 0, 0.75, 1},
    bottomLeft  = {0.75, 0, 0.75, 1, 0.875, 0, 0.875, 1},
    bottomRight = {0.875, 0, 0.875, 1, 1, 0, 1, 1},
}

local HUI_CustomBorder = {}

function HUI_CustomBorder:SetCustomBorderSize(size)
    if not size then return end
    self.size = size

    local half = size / 2
    local t = self.textures

    t.topLeft:SetPoint("TOPLEFT", self, "TOPLEFT", -half, half)
    t.topRight:SetPoint("TOPRIGHT", self, "TOPRIGHT", half, half)
    t.bottomLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -half, -half)
    t.bottomRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", half, -half)

    t.topLeft:SetSize(size, size)
    t.topRight:SetSize(size, size)
    t.bottomLeft:SetSize(size, size)
    t.bottomRight:SetSize(size, size)

    t.top:SetPoint("TOPLEFT", t.topLeft, "TOPRIGHT", 0, 0)
    t.top:SetPoint("BOTTOMRIGHT", t.topRight, "BOTTOMLEFT", 0, 0)

    t.bottom:SetPoint("TOPLEFT", t.bottomLeft, "TOPRIGHT", 0, 0)
    t.bottom:SetPoint("BOTTOMRIGHT", t.bottomRight, "BOTTOMLEFT", 0, 0)

    t.left:SetPoint("TOPLEFT", t.topLeft, "BOTTOMLEFT", 0, 0)
    t.left:SetPoint("BOTTOMRIGHT", t.bottomLeft, "TOPRIGHT", 0, 0)

    t.right:SetPoint("TOPLEFT", t.topRight, "BOTTOMLEFT", 0, 0)
    t.right:SetPoint("BOTTOMRIGHT", t.bottomRight, "TOPRIGHT", 0, 0)
end

function HUI_CustomBorder:SetCustomBorderColor(color)
    if not color then return end

    local r = color.r or color[1] or 1
    local g = color.g or color[2] or 1
    local b = color.b or color[3] or 1
    local a = color.a or color[4] or 1

    for _, texture in ipairs(self.all) do
        texture:SetVertexColor(r, g, b, a)
    end

    self.color = { r = r, g = g, b = b, a = a }
end

function Addon.CreateCustomBorder(frame, texturePath, size, color)
    local border = frame.HUICustomBorder
    if border then
        if border.path ~= texturePath then
            for _, texture in ipairs(border.all) do
                texture:SetTexture(texturePath)
            end
            border.path = texturePath
        end
        border:SetCustomBorderSize(size or border.size)
        border:SetCustomBorderColor(color)
        return border
    end

    border = CreateFrame("Frame", nil, frame)
    border:SetFrameStrata(frame:GetFrameStrata())
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    border:SetAllPoints(frame)

    local textures = {}
    local all = {}
    for i, key in ipairs(TILE_KEYS) do
        local texture = border:CreateTexture(nil, "OVERLAY", nil, 7)
        texture:SetTexture(texturePath)
        texture:SetTexCoord(unpack(BORDER_UV[key]))
        textures[key] = texture
        all[i] = texture
    end

    Mixin(border, HUI_CustomBorder)
    border.textures = textures
    border.all = all
    border.path = texturePath
    border.size = size or 16
    border.color = { r = 1, g = 1, b = 1, a = 1 }

    border:SetCustomBorderSize(border.size)
    border:SetCustomBorderColor(color)

    frame.HUICustomBorder = border
    return border
end
