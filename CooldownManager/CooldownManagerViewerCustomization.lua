local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

ABE_CDMCustomized = {}

function ABE_CDMCustomized:RefreshIconMask(child, frameName)
    frameName = frameName or child:GetParent():GetName()

    local iconMaskIndex = Addon:GetValue("CurrentIconMaskTexture", nil, frameName)
    local iconMaskAtlas = T.IconMaskTextures[iconMaskIndex]

    local icon = (frameName ~= "BuffBarCooldownViewer") and child.Icon or child.Icon.Icon
    local mask = icon:GetMaskTexture(1)

    if mask then
        mask:SetHorizTile(false)
        mask:SetVertTile(false)

        Addon:SetTexture(mask, iconMaskAtlas.texture)
    end

    if iconMaskAtlas.point then
        mask:ClearAllPoints()
        mask:SetPoint(iconMaskAtlas.point, mask:GetParent(), iconMaskAtlas.point)
    end

    if Addon:GetValue("UseIconScale", nil, frameName) then
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", icon:GetParent(), "CENTER")
        icon:SetSize(icon:GetParent():GetSize())
        icon:SetScale(Addon:GetValue("IconScale", nil, frameName))
    end

    if Addon:GetValue("UseIconMaskScale", nil, frameName) then
        local size = icon:GetSize()
        mask:SetSize(size, size)
        mask:SetScale(Addon:GetValue("IconMaskScale", nil, frameName))
    else
        mask:ClearAllPoints()
        mask:SetAllPoints()
    end

    if not child.__iconOverlay then
        local regions = (frameName ~= "BuffBarCooldownViewer") and { child:GetRegions() } or { child.Icon:GetRegions() }
        for k, region in ipairs(regions) do
            if region:IsObjectType("Texture") then
                local atlas = region:GetAtlas()
                if atlas == "UI-HUD-CoolDownManager-IconOverlay" then
                    child.__iconOverlay = region
                end
            end
        end
        child.__iconOverlay:Hide()
    end
end

local function Hook_OnItemSetScale(frame, scale)
    if scale ~= 1 then
        frame:SetScale(1)
    end
end

function ABE_CDMCustomized:RefreshItemSize(child, frameName)
    frameName = frameName or child:GetParent():GetName()

    local size = Addon:GetValue("CDMItemSize", nil, frameName)
    child:SetSize(size, size)
    if child.SetScale then
        hooksecurefunc(child, "SetScale", Hook_OnItemSetScale)
    end
end

function ABE_CDMCustomized:RefreshCooldownFrame(child, frameName)
    frameName = frameName or child:GetParent():GetName()

    local cooldownFrame = child.Cooldown
    local swipeTextureIndex = Addon:GetValue("CurrentSwipeTexture", nil, frameName)

    if Addon:GetValue("CurrentSwipeTexture", nil, frameName) > 1 then
        cooldownFrame:SetSwipeTexture(T.SwipeTextures[swipeTextureIndex].texture)
    end
    if Addon:GetValue("UseSwipeSize", nil, frameName) then
        cooldownFrame:ClearAllPoints()
        cooldownFrame:SetPoint("CENTER", child, "CENTER")
        local size = Addon:GetValue("SwipeSize", nil, frameName)
        cooldownFrame:SetSize(size, size)
    else
        cooldownFrame:SetAllPoints()
    end
    if not cooldownFrame:GetDrawEdge() then
        cooldownFrame:SetDrawEdge(Addon:GetValue("EdgeAlwaysShow", nil, frameName))
    end
    if cooldownFrame:GetDrawEdge() then
        cooldownFrame:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentEdgeTexture", nil, frameName)].texture)
        if Addon:GetValue("UseEdgeSize", nil, frameName) then
            local size = Addon:GetValue("EdgeSize", nil, frameName)
            cooldownFrame:SetEdgeScale(size)
        end
        if Addon:GetValue("UseEdgeColor", nil, frameName) then
            cooldownFrame:SetEdgeColor(Addon:GetRGBA("EdgeColor", nil, frameName))
        end
    end
end

function ABE_CDMCustomized:RefreshCooldownFont(child, frameName)
    frameName = frameName or child:GetParent():GetName()

    local parentFrame = child:GetParent()

    local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

    if Addon:GetValue("UseCooldownFontColor", nil, frameName) then
        color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownFontColor", nil, frameName)
        if not parentFrame.cooldownColorCurve or forceUpdate then
            parentFrame.cooldownColorCurve = C_CurveUtil.CreateColorCurve()
            parentFrame.cooldownColorCurve:SetType(Enum.LuaCurveType.Linear)
            parentFrame.cooldownColorCurve:AddPoint(0, CreateColor(1, 1, 1, color.a))
            parentFrame.cooldownColorCurve:AddPoint(0.01, CreateColor(1, 0, 0, color.a))
            parentFrame.cooldownColorCurve:AddPoint(5, CreateColor(1, 0, 0, color.a))
            parentFrame.cooldownColorCurve:AddPoint(5.2, CreateColor(1, 1, 0, color.a))
            parentFrame.cooldownColorCurve:AddPoint(10, CreateColor(1, 1, 0, color.a))
            parentFrame.cooldownColorCurve:AddPoint(10.2, CreateColor(color.r, color.g, color.b, color.a))
        end
    else
        parentFrame.cooldownColorCurve = Addon.cooldownColorCurve
    end

    local fontSize = Addon:GetValue("UseCooldownFontSize", nil, frameName) and Addon:GetValue("CooldownFontSize", nil, frameName) or 17

    local _, fontName = Addon:GetFontObject(
        Addon:GetValue("CurrentCooldownFont", nil, frameName),
        "OUTLINE, SLUG",
        color,
        fontSize,
        false,
        frameName
    )

    local timerString = child.Cooldown:GetCountdownFontString()

    if Addon:GetValue("UseCooldownFontOffset", nil, frameName) then
        local offsetX = Addon:GetValue("CooldownFontOffsetX", nil, frameName)
        local offsetY = Addon:GetValue("CooldownFontOffsetY", nil, frameName)

        timerString:SetPointsOffset(offsetX, offsetY)
    else
        timerString:SetPointsOffset(0, 0)
    end

    child.Cooldown:SetCountdownFont(fontName)
end

function ABE_CDMCustomized:RefreshStacksFont(child, frameName)
    frameName = frameName or child:GetParent():GetName()

    local stacksFrame = child.Applications or child.ChargeCount
    local stacksString = stacksFrame and (stacksFrame.Applications or stacksFrame.Current) or child.Icon.Applications

    if Addon:GetValue("CurrentStacksFont", nil, frameName) ~= "Default" then
        stacksString:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentStacksFont", nil, frameName)),
            (Addon:GetValue("UseStacksFontSize", nil, frameName) and Addon:GetValue("StacksFontSize", nil, frameName) or 16),
            "OUTLINE, SLUG"
        )
    end
    stacksString:SetFontHeight(Addon:GetValue("StacksFontSize", nil, frameName) or 16)
    if Addon:GetValue("UseStacksColor", nil, frameName) then
        stacksString:SetVertexColor(Addon:GetRGBA("StacksColor", nil, frameName))
    end

    local point = Addon.AttachPoints[Addon:GetValue("CurrentStacksPoint", nil, frameName)]
    local relativePoint = Addon.AttachPoints[Addon:GetValue("CurrentStacksRelativePoint", nil, frameName)]
    stacksString:SetWidth(0)
    stacksString:ClearAllPoints()
    stacksString:SetPoint(point, stacksString:GetParent(), relativePoint)

    if Addon:GetValue("UseStacksOffset", nil, frameName) then
        stacksString:SetPointsOffset(Addon:GetValue("StacksOffsetX", nil, frameName), Addon:GetValue("StacksOffsetY", nil, frameName))
    end
end

function ABE_CDMCustomized:RefreshBar(child, frameName)
    frameName = frameName or child:GetParent():GetName()

    if child.Icon and Addon:GetValue("UseCDMBarIconSize", nil, frameName) then
        local size = Addon:GetValue("CDMBarIconSize", nil, frameName)
        child.Icon:ClearAllPoints()
        child.Icon:SetPoint("LEFT", child, "LEFT")
        child.Icon:SetSize(size, size)
    end
    
    if Addon:GetValue("UseCDMBarHeight", nil, frameName) then
        local height = Addon:GetValue("CDMBarHeight", nil, frameName)
        child.Bar:SetHeight(height)
    end

    child:SetHeight(math.max(child.Icon:GetHeight(), child.Bar:GetHeight()))

    Addon:SetTexture(child.Bar.Pip, T.PipTextures[Addon:GetValue("CurrentCDMPipTexture", nil, frameName)].texture, true)

    if Addon:GetValue("CDMUseBarPipSize", nil, frameName) then
        child.Bar.Pip:SetSize(Addon:GetValue("CDMBarPipSizeX", nil, frameName), Addon:GetValue("CDMBarPipSizeY", nil, frameName))
    end
    
    child.Bar:SetStatusBarTexture(Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMStatusBarTexture", nil, frameName)))
    
    Addon:SetTexture(child.Bar.BarBG, Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMBGTexture", nil, frameName)))
    if Addon:GetValue("UseCDMBarBGColor", nil, frameName) then
        child.Bar.BarBG:SetVertexColor(Addon:GetRGBA("CDMBarBGColor", nil, frameName))
    else
        child.Bar.BarBG:SetVertexColor(1,1,1,1)
    end
    child.Bar.BarBG:ClearAllPoints()
    child.Bar.BarBG:SetPoint("TOPLEFT", child.Bar, "TOPLEFT")
    child.Bar.BarBG:SetPoint("BOTTOMRIGHT", child.Bar, "BOTTOMRIGHT")
    --child.Bar.BarBG:SetSize(child.Bar:GetWidth(), child.Bar:GetHeight())

    if child.Bar.Duration then

        local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

        if Addon:GetValue("UseCooldownFontColor", nil, frameName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownFontColor", nil, frameName)
        end
        local fontSize = Addon:GetValue("UseCooldownFontSize", nil, frameName) and Addon:GetValue("CooldownFontSize", nil, frameName) or 17
        local _, fontName = Addon:GetFontObject(
            Addon:GetValue("CurrentCooldownFont", nil, frameName),
            "OUTLINE, SLUG",
            color,
            fontSize,
            false,
            frameName
        )
        child.Bar.Duration:SetFontObject(fontName)
    end
    if child.Bar.Name then

        local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

        if Addon:GetValue("UseNameCDMFontColor", nil, frameName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("NameCCDMFontColor", nil, frameName)
        end
        local fontSize = Addon:GetValue("UseNameCDMFontSize", nil, frameName) and Addon:GetValue("NameCDMFontSize", nil, frameName) or 17
        child.Bar.Name:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentCDMNameFont", nil, frameName)),
            fontSize,
            "OUTLINE, SLUG"
        )
        child.Bar.Name:SetTextColor(color.r,color.g,color.b,color.a)
    end

end