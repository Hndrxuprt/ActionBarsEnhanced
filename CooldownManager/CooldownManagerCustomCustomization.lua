local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

ABE_CDMCustomFrameCustomized = {}

function ABE_CDMCustomFrameCustomized:RefreshSkin(frame, frameName)
    frameName = frameName or frame.frameName

    self:RefreshItemSize(frame, frameName)
    self:RefreshIconMask(frame, frameName)
    self:RefreshCooldownFrame(frame, frameName)
    self:RefreshBackdrop(frame, frameName)
    --self:RefreshLoopGlow(frame, frameName)
    self:RefreshCooldownFont(frame, frameName)   

end

function ABE_CDMCustomFrameCustomized:RefreshIconMask(frame, frameName)
    
    frameName = frameName or frame.frameName

    local iconMaskIndex = Addon:GetValue("CurrentIconMaskTexture", nil, frameName)
    local iconMaskAtlas = T.IconMaskTextures[iconMaskIndex]

    for itemFrame in frame.itemPool:EnumerateActive() do

        local mask = itemFrame.Icon.IconMask or itemFrame.IconMask
        local icon = itemFrame.Icon.Icon or itemFrame.Icon
        local iconOverlay = itemFrame.Icon.IconOverlay or itemFrame.IconOverlay

        Addon:SetTexture(mask, iconMaskAtlas.texture)
                
        if iconMaskAtlas.point then
            mask:ClearAllPoints()
            mask:SetPoint(iconMaskAtlas.point, mask:GetParent(), iconMaskAtlas.point)
        end

        if Addon:GetValue("UseIconMaskScale", nil, frameName) then
            mask:SetSize(mask:GetParent():GetSize())
            mask:SetScale(Addon:GetValue("IconMaskScale", nil, frameName))
        else
            mask:ClearAllPoints()
            mask:SetAllPoints()
        end

        if Addon:GetValue("UseIconScale", nil, frameName) then
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", icon:GetParent(), "CENTER")
            icon:SetSize(icon:GetParent():GetSize())
            icon:SetScale(Addon:GetValue("IconScale", nil, frameName))
        else
            icon:ClearAllPoints()
            icon:SetAllPoints()
        end

        if iconOverlay and iconMaskIndex > 1 then
            iconOverlay:Hide()
        elseif iconOverlay then
            iconOverlay:Show()
        end
    end
end

function ABE_CDMCustomFrameCustomized:RefreshItemSize(frame, frameName)
    frameName = frameName or frame.frameName

    if Addon:GetValue("UseCDMCustomItemSize", nil, frameName) then
        for itemFrame in frame.itemPool:EnumerateActive() do
            if not itemFrame.Bar then
                local size = Addon:GetValue("CDMCustomItemSize", nil, frameName)
                itemFrame.frameSize = size
                itemFrame:SetSize(size, size)                
            end
        end
    end
end

function ABE_CDMCustomFrameCustomized:RefreshBarIconSize(frame, frameName)
    frameName = frameName or frame.frameName
    local iconPos = Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, frameName)
    if iconPos > 1 then
        if Addon:GetValue("UseCDMCustomFrameBarIconSize", nil, frameName) then
            for itemFrame in frame.itemPool:EnumerateActive() do
                local size = Addon:GetValue("CDMCustomFrameBarIconSize", nil, frameName)
                itemFrame.Icon:SetSize(size, size)
                itemFrame.Icon:SetAlpha(1)

                if Addon:GetValue("UseCDMCustomFrameBarIconOffset", nil, frameName) then
                    local offsetX = Addon:GetValue("CDMCustomFrameBarIconOffsetX", nil, frameName)
                    local offsetY = Addon:GetValue("CDMCustomFrameBarIconOffsetY", nil, frameName)
                    itemFrame.Icon:SetPointsOffset(offsetX, offsetY)
                end
            end
        end
    else
        for itemFrame in frame.itemPool:EnumerateActive() do
            itemFrame.Icon:SetAlpha(0)
        end
    end
end
function ABE_CDMCustomFrameCustomized:RefreshBarSize(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        if itemFrame.Bar then
            local width = Addon:GetValue("UseCDMCustomFrameBarWidth", nil, frameName) and Addon:GetValue("CDMCustomFrameBarWidth", nil, frameName) or 100
            local height = Addon:GetValue("UseCDMCustomFrameBarHeight", nil, frameName) and Addon:GetValue("CDMCustomFrameBarHeight", nil, frameName) or 10
            itemFrame:SetSize(width, height)
        end
    end
end
function ABE_CDMCustomFrameCustomized:RefreshBarTextures(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        if itemFrame.Bar then
            local foreground = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMCustomFrameStatusbarTexture", nil, frameName))
            local background = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMCustomFrameBackgroundTexture", nil, frameName))
            local color = itemFrame:GetCustomColor() or { r=1, g=1, b=1, a=1 }
            itemFrame.Bar:SetStatusBarTexture(foreground)
            itemFrame.Bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
            itemFrame.Bar.BarBG:SetVertexColor(Addon:GetRGBA("CDMCustomFrameBackgroundColor", nil, frameName))
            Addon:SetTexture(itemFrame.Bar.BarBG, background)
        end
    end
end

function ABE_CDMCustomFrameCustomized:RefreshCooldownFrame(frame, frameName)
    frameName = frameName or frame.frameName

    for itemFrame in frame.itemPool:EnumerateActive() do
        local cooldownFrame = itemFrame.Icon.Cooldown or itemFrame.Cooldown
        local auraFrame = itemFrame.Icon.AuraCooldown or itemFrame.AuraCooldown
        

        itemFrame.__removeAura = Addon:GetValue("CDMAuraRemoveSwipe", nil, frameName)
        
        local swipeTextureIndex = Addon:GetValue("CurrentSwipeTexture", nil, frameName)

        if swipeTextureIndex > 1 then
            cooldownFrame:SetSwipeTexture(T.SwipeTextures[swipeTextureIndex].texture)
            auraFrame:SetSwipeTexture(T.SwipeTextures[swipeTextureIndex].texture)
        end

        if Addon:GetValue("UseSwipeSize", nil, frameName) then
            cooldownFrame:ClearAllPoints()
            cooldownFrame:SetPoint("CENTER", cooldownFrame:GetParent(), "CENTER")
            local size = Addon:GetValue("SwipeSize", nil, frameName)
            cooldownFrame:SetSize(size, size)

            auraFrame:ClearAllPoints()
            auraFrame:SetPoint("CENTER", auraFrame:GetParent(), "CENTER")
            local size = Addon:GetValue("SwipeSize", nil, frameName)
            auraFrame:SetSize(size, size)            
        else
            cooldownFrame:SetAllPoints()
            auraFrame:SetAllPoints()
        end

        if not cooldownFrame:GetDrawEdge() then
            cooldownFrame:SetDrawEdge(Addon:GetValue("EdgeAlwaysShow", nil, frameName))
        end
        if not auraFrame:GetDrawEdge() then
            auraFrame:SetDrawEdge(Addon:GetValue("EdgeAlwaysShow", nil, frameName))
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
        if auraFrame:GetDrawEdge() then
            auraFrame:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentEdgeTexture", nil, frameName)].texture)
            if Addon:GetValue("UseEdgeSize", nil, frameName) then
                local size = Addon:GetValue("EdgeSize", nil, frameName)
                auraFrame:SetEdgeScale(size)
            end
            if Addon:GetValue("UseEdgeColor", nil, frameName) then
                auraFrame:SetEdgeColor(Addon:GetRGBA("EdgeColor", nil, frameName))
            end
        end

        if Addon:GetValue("UseCooldownColor", nil, frameName) then
            cooldownFrame:SetSwipeColor(Addon:GetRGBA("CooldownColor", nil, frameName))
        end

        if Addon:GetValue("UseCooldownAuraColor", nil, frameName) then
            auraFrame:SetSwipeColor(Addon:GetRGBA("CooldownAuraColor", nil, frameName)) 
        end

        local timerString = auraFrame:GetCountdownFontString()
        

        if Addon:GetValue("UseCDMAuraTimerColor", nil, frameName) then
            timerString:SetVertexColor(Addon:GetRGBA("CDMAuraTimerColor", nil, frameName)) 
        else
            timerString:SetVertexColor(1,1,1,1)
        end

        local fontString = cooldownFrame:GetCountdownFontString()

        if Addon:GetValue("UseCooldownFontOffset", nil, frameName) then
            local offsetX = Addon:GetValue("CooldownFontOffsetX", nil, frameName)
            local offsetY = Addon:GetValue("CooldownFontOffsetY", nil, frameName)

            timerString:SetPointsOffset(offsetX, offsetY)
            fontString:SetPointsOffset(offsetX, offsetY)
        else
            timerString:SetPointsOffset(0, 0)
            fontString:SetPointsOffset(0, 0)
        end

        cooldownFrame.isReversed = Addon:GetValue("CDMReverseSwipe", nil, frameName)
        auraFrame.isReversed = Addon:GetValue("CDMAuraReverseSwipe", nil, frameName)

        cooldownFrame.showGCDSwipe = not (Addon:GetValue("CDMRemoveGCDSwipe", nil, frameName))
    end

end

function ABE_CDMCustomFrameCustomized:RefreshBackdrop(frame, frameName)
    frameName = frameName or frame.frameName
    if Addon:GetValue("UseCDMBackdrop", nil, frameName) then
        for itemFrame in frame.itemPool:EnumerateActive() do
            if not itemFrame.iconBorder then
                itemFrame.iconBorder = Addon.CreateBorder(itemFrame.Icon, frameName)
                itemFrame.iconBorder:Show()
            elseif itemFrame.iconBorder then
                Addon.SetBackdropBorderSize(itemFrame.iconBorder, Addon:GetValue("CDMBackdropSize", nil, frameName))
                itemFrame.iconBorder:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropColor", nil, frameName))
                itemFrame.iconBorder:Show()
            end
            if itemFrame.Bar and not itemFrame.BarBorder then
                itemFrame.BarBorder = Addon.CreateBorder(itemFrame.Bar, frameName)
                itemFrame.BarBorder:Show()
            elseif itemFrame.BarBorder then
                Addon.SetBackdropBorderSize(itemFrame.BarBorder, Addon:GetValue("CDMBackdropSize", nil, frameName))
                itemFrame.BarBorder:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropColor", nil, frameName))
                itemFrame.BarBorder:Show()
            end
        end
    end
end

function ABE_CDMCustomFrameCustomized:RefreshLoopGlow(frame, frameName)
    local function GetFlipBook(...)
        local Animations = {...}

        for _, Animation in ipairs(Animations) do
            if Animation:GetObjectType() == "FlipBook" then
                Animation:SetParentKey("FlipAnim")
                return Animation
            end
        end
    end

    frameName = frameName or frame.frameName
    local loopAnim = T.LoopGlow[Addon:GetValue("CurrentLoopGlow", nil, frameName)]
    local procAnim = T.ProcGlow[Addon:GetValue("CurrentProcGlow", nil, frameName)]
    
    for itemFrame in frame.itemPool:EnumerateActive() do

        local actionButtonSize = 31
        local size = itemFrame.ProcGlow:GetHeight()
        local scaleMult = math.min(size / actionButtonSize, 1.4)
        
        local region = itemFrame.ProcGlow
        if loopAnim.atlas then
            region.ProcLoopFlipbook:SetAtlas(loopAnim.atlas)    
        elseif loopAnim.texture then
            region.ProcLoopFlipbook:SetTexture(loopAnim.texture)
        end
        if loopAnim then
            region.ProcLoopFlipbook:ClearAllPoints()
            region.ProcLoopFlipbook:SetSize(size, size)
            region.ProcLoopFlipbook:SetPoint("CENTER", region, "CENTER")
            region.ProcLoopFlipbook:SetScale((loopAnim.scale or 1) * scaleMult)
            
            region.ProcLoop.FlipAnim:SetFlipBookRows(loopAnim.rows or 6)
            region.ProcLoop.FlipAnim:SetFlipBookColumns(loopAnim.columns or 5)
            region.ProcLoop.FlipAnim:SetFlipBookFrames(loopAnim.frames or 30)
            region.ProcLoop.FlipAnim:SetDuration(loopAnim.duration or 1.0)
            region.ProcLoop.FlipAnim:SetFlipBookFrameWidth(loopAnim.frameW or 0.0)
            region.ProcLoop.FlipAnim:SetFlipBookFrameHeight(loopAnim.frameH or 0.0)
        end

        region.ProcLoopFlipbook:SetDesaturated(Addon:GetValue("DesaturateGlow", nil, frameName))
        if Addon:GetValue("UseLoopGlowColor", nil, frameName) then
            region.ProcLoopFlipbook:SetVertexColor(Addon:GetRGB("LoopGlowColor", nil, frameName))
        else
            region.ProcLoopFlipbook:SetVertexColor(1.0, 1.0, 1.0)
        end

        local startProc = region.ProcStartAnim.FlipAnim or GetFlipBook(region.ProcStartAnim:GetAnimations())

        if startProc and region.ProcStartFlipbook:IsVisible() then
            if Addon:GetValue("HideProc", nil, frameName) then
                startProc:SetDuration(0)
                region.ProcStartFlipbook:Hide()
            else
                region.ProcStartFlipbook:Show()
                if procAnim.atlas then
                    region.ProcStartFlipbook:SetAtlas(procAnim.atlas)
                elseif procAnim.texture then
                    region.ProcStartFlipbook:SetTexture(procAnim.texture)
                end
                if procAnim then
                    region.ProcStartFlipbook:ClearAllPoints()
                    local size = region:GetHeight()
                    region.ProcStartFlipbook:SetSize(size, size)
                    region.ProcStartFlipbook:SetPoint("CENTER", region, "CENTER")
                    startProc:SetFlipBookRows(procAnim.rows or 6)
                    startProc:SetFlipBookColumns(procAnim.columns or 5)
                    startProc:SetFlipBookFrames(procAnim.frames or 30)
                    startProc:SetDuration(procAnim.duration or 0.702)
                    startProc:SetFlipBookFrameWidth(procAnim.frameW or 0.0)
                    startProc:SetFlipBookFrameHeight(procAnim.frameH or 0.0)
                    region.ProcStartFlipbook:SetScale((procAnim.scale or 1) * scaleMult)
                end
                region.ProcStartFlipbook:SetDesaturated(Addon:GetValue("DesaturateProc", nil, frameName))

                if Addon:GetValue("UseProcColor", nil, frameName) then
                    region.ProcStartFlipbook:SetVertexColor(Addon:GetRGB("ProcColor", nil, frameName))
                else
                    region.ProcStartFlipbook:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        end
    end
end

function ABE_CDMCustomFrameCustomized:RefreshCooldownFont(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do

        local cooldownFrame = itemFrame.Icon.Cooldown or itemFrame.Cooldown
        local auraCooldown  = itemFrame.Icon.AuraCooldown or itemFrame.AuraCooldown

        cooldownFrame:SetCountdownAbbrevThreshold(920)

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
        cooldownFrame:SetCountdownFont(fontName)
        auraCooldown:SetCountdownFont(fontName)

        local stacksFrame = itemFrame.Icon.Applications or itemFrame.Applications
        local stacksString = stacksFrame.Applications
        if stacksString then
            if Addon:GetValue("CurrentStacksFont", nil, frameName) ~= "Default" then
                stacksString:SetFont(
                    LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentStacksFont", nil, frameName)),
                    (Addon:GetValue("UseStacksFontSize", nil, frameName) and Addon:GetValue("StacksFontSize", nil, frameName) or 16),
                    "OUTLINE, SLUG"
                )
            end
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


    end
end

function ABE_CDMCustomFrameCustomized:RefreshAnchors(frame, frameName)
    frameName = frameName or frame.frameName
    if Addon:GetValue("CDMEnableAttach", nil, frameName) then
        local relativeKeyName = Addon:GetValue("CurrentAttachFrame", nil, frameName)
        if relativeKeyName ~= "" and relativeKeyName ~= "UIParent" and relativeKeyName ~= frameName then
            local relativeKey = _G[relativeKeyName]
            if relativeKey then
                frame.ABESelection:SetMouseClickEnabled(false)

                local point = Addon.AttachPoints[Addon:GetValue("CurrentAttachPoint", nil, frameName)]
                local relPoint = Addon.AttachPoints[Addon:GetValue("CurrentAttachRelativePoint", nil, frameName)]
                local offsetX = Addon:GetValue("UseAttachOffset", nil, frameName) and Addon:GetValue("AttachOffsetX", nil, frameName) or 0
                local offsetY = Addon:GetValue("UseAttachOffset", nil, frameName) and Addon:GetValue("AttachOffsetY", nil, frameName) or 0
                frame:ClearAllPoints()
                frame:SetPoint(point, relativeKey, relPoint, offsetX, offsetY)
            end
        end
    else
        frame.ABESelection:SetMouseClickEnabled(true)
    end
end