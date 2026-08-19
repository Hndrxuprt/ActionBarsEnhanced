local Addon = _G.HUI

if not Addon.CooldownViewerSwatchPool then
    Addon.CooldownViewerSwatchPool = CreateFramePool("Button", UIParent, "ColorSwatchTemplate")
end

local function SetupColorSwatchOnItem(item, index)
    if not item.__colorSwatch then
        local swatch = Addon.CooldownViewerSwatchPool:Acquire()
        swatch:SetParent(item)
        swatch:SetPoint("LEFT", item, "RIGHT", 4, 0)
        swatch:SetSize(20, 20)
        swatch:SetColorRGB(item.__color.r, item.__color.g, item.__color.b)
        swatch:Show()
        item.__colorSwatch = swatch
    end

    if not index then return end


    item.__colorSwatch:SetScript("OnClick", function(button, buttonName, down)
        local info = UIDropDownMenu_CreateInfo()

        if item.__color then
            info.r, info.g, info.b, info.opacity = item.__color.r, item.__color.g, item.__color.b, item.__color.a
        else
            info.r, info.g, info.b, info.opacity = 1, 1, 1, 1
        end

        info.hasOpacity = true

        if ColorPickerFrame then
            if not ColorPickerFrame.classButton then
                local button = CreateFrame("Button", nil, ColorPickerFrame, "UIPanelButtonTemplate")
                button:SetPoint("RIGHT", -20, 0)
                button:SetSize(90, 25)
                button:SetText("Class")
                button:Show()
                ColorPickerFrame.classButton = button
            end
            ColorPickerFrame.classButton:SetScript("OnClick", function()
                info.r, info.g, info.b = PlayerUtil.GetClassColor():GetRGB()
                info.a = 1.0
                ColorPickerFrame:SetupColorPickerAndShow(info)
            end)
        end

        info.swatchFunc = function ()
            local r,g,b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            item.__colorSwatch.Color:SetVertexColor(r,g,b)
            item.Bar.FillTexture:SetVertexColor(r,g,b)
            item.__color = { r=r, g=g, b=b, a=a }
            Addon:SaveSetting("BuffBar"..index, { r=r, g=g, b=b, a=a }, "BuffBarCooldownViewer")
        end

        info.cancelFunc = function ()
            local r,g,b,a = ColorPickerFrame:GetPreviousValues()
            item.__colorSwatch.Color:SetVertexColor(r,g,b)
            item.Bar.FillTexture:SetVertexColor(r,g,b)
            item.__color = { r=r, g=g, b=b, a=a }
            Addon:SaveSetting("BuffBar"..index, { r=r, g=g, b=b, a=a }, "BuffBarCooldownViewer")
        end

        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
end

local function Hook_CooldownViewerSettingsBar(self)
    local index = 0

    local activeItems = {}
    for item in self.itemPool:EnumerateActive() do
        table.insert(activeItems, item)
    end
    table.sort(activeItems, function(a, b)
        local aIdx = a.orderIndex
        local bIdx = b.orderIndex
        return aIdx < bIdx
    end)

    if #activeItems == 0 then return end

    for i, item in ipairs(activeItems) do
        local barName = item.Bar.Name:GetText()
        if barName then
            if item.__colorSwatch then
                Addon.CooldownViewerSwatchPool:Release(item.__colorSwatch)
                item.__colorSwatch = nil
            end
            if not item.Icon:IsDesaturated() then
                index = index + 1
                item.Bar.Name:SetText("["..index.."]: "..barName)
                local savedColor = Addon:GetValue("BuffBar"..index, nil, "BuffBarCooldownViewer") or { r = 1, g = 1, b = 1, a = 1 }
                item.__color = savedColor

                SetupColorSwatchOnItem(item, index)

                item.__colorSwatch:SetColorRGB(item.__color.r, item.__color.g, item.__color.b)
                item.Bar.FillTexture:SetVertexColor(item.__color.r, item.__color.g, item.__color.b, item.__color.a)
            else
                item.Bar.FillTexture:SetVertexColor(1, 1, 1, 1)
            end
        end
    end
end

Addon:RegisterEvent("PLAYER_LOGIN", function()
    hooksecurefunc(CooldownViewerSettingsBarCategoryMixin, "RefreshLayout", Hook_CooldownViewerSettingsBar)
end, "CooldownManagerView")