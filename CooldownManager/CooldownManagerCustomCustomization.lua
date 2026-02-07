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
            local bgColor = Addon:GetRGBA("CDMCustomFrameBackgroundColor", nil, frameName)
            itemFrame.Bar:SetStatusBarTexture(foreground)
            Addon:SetTexture(itemFrame.Bar.BarBG, background)
        end
    end
end

function ABE_CDMCustomFrameCustomized:RefreshCooldownFrame(frame, frameName)
    frameName = frameName or frame.frameName

    frame.cooldownColorCurve = C_CurveUtil.CreateColorCurve()
    frame.cooldownColorCurve:AddPoint(0, CreateColor(1, 1, 1, 1))
    frame.cooldownColorCurve:AddPoint(4.9, CreateColor(1, 0, 0, 1))
    frame.cooldownColorCurve:AddPoint(5, CreateColor(1, 0, 0, 1))
    frame.cooldownColorCurve:AddPoint(10, CreateColor(1, 1, 0, 1))
    frame.cooldownColorCurve:AddPoint(30, CreateColor(1, 0.7, 0, 1))
    frame.cooldownColorCurve:AddPoint(60, CreateColor(1, 1, 1, 1))

    for itemFrame in frame.itemPool:EnumerateActive() do
        local cooldownFrame = itemFrame.Icon.Cooldown or itemFrame.Cooldown
        local auraFrame = itemFrame.Icon.AuraCooldown or itemFrame.AuraCooldown
        

        itemFrame.__removeAura = Addon:GetValue("CDMAuraRemoveSwipe", nil, frameName)
        
        local swipeTextureIndex = Addon:GetValue("CurrentSwipeTexture", nil, frameName)

        if swipeTextureIndex > 1 then
            cooldownFrame:SetSwipeTexture(T.SwipeTextures[swipeTextureIndex].texture)
            auraFrame:SetSwipeTexture(T.SwipeTextures[swipeTextureIndex].texture)
        end

        if Addon:GetValue("UseCDMSwipeSize", nil, frameName) then
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
            cooldownFrame:SetDrawEdge(Addon:GetValue("CDMEdgeAlwaysShow", nil, frameName))
        end
        if not auraFrame:GetDrawEdge() then
            auraFrame:SetDrawEdge(Addon:GetValue("CDMEdgeAlwaysShow", nil, frameName))
        end

        if cooldownFrame:GetDrawEdge() then
            cooldownFrame:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentCDMEdgeTexture", nil, frameName)].texture)
            if Addon:GetValue("UseCDMEdgeSize", nil, frameName) then
                local size = Addon:GetValue("CDMEdgeSize", nil, frameName)
                cooldownFrame:SetEdgeScale(size)
            end
            if Addon:GetValue("UseCDMEdgeColor", nil, frameName) then
                cooldownFrame:SetEdgeColor(Addon:GetRGBA("CDMEdgeColor", nil, frameName))
            end
        end
        if auraFrame:GetDrawEdge() then
            auraFrame:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentCDMEdgeTexture", nil, frameName)].texture)
            if Addon:GetValue("UseCDMEdgeSize", nil, frameName) then
                local size = Addon:GetValue("CDMEdgeSize", nil, frameName)
                auraFrame:SetEdgeScale(size)
            end
            if Addon:GetValue("UseCDMEdgeColor", nil, frameName) then
                auraFrame:SetEdgeColor(Addon:GetRGBA("CDMEdgeColor", nil, frameName))
            end
        end

        if Addon:GetValue("UseCDMSwipeColor", nil, frameName) then
            cooldownFrame:SetSwipeColor(Addon:GetRGBA("CDMSwipeColor", nil, frameName))
        end

        if Addon:GetValue("UseCDMAuraSwipeColor", nil, frameName) then
            auraFrame:SetSwipeColor(Addon:GetRGBA("CDMAuraSwipeColor", nil, frameName)) 
        end

        local timerString
        if not isBeta then
            if not auraFrame.__timer then
                local cdRegions = { auraFrame:GetRegions() }
                if cdRegions then
                    for i, region in ipairs(cdRegions) do
                        if region:IsObjectType("FontString") then
                           auraFrame.__timer = region
                            break
                        end
                    end
                end
            end
            timerString = auraFrame.__timer
        else
            timerString = auraFrame:GetCountdownFontString()
        end

        if Addon:GetValue("UseCDMAuraTimerColor", nil, frameName) then
            timerString:SetVertexColor(Addon:GetRGBA("CDMAuraTimerColor", nil, frameName)) 
        else
            timerString:SetVertexColor(1,1,1,1)
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

        local actionButtonSize = 42
        local size = itemFrame:GetHeight()
        local scaleMult = size / actionButtonSize

        local region = itemFrame.ProcGlow
        if loopAnim.atlas then
            region.ProcLoopFlipbook:SetAtlas(loopAnim.atlas)    
        elseif loopAnim.texture then
            region.ProcLoopFlipbook:SetTexture(loopAnim.texture)
        end
        if loopAnim then
            region.ProcLoopFlipbook:ClearAllPoints()
            region.ProcLoopFlipbook:SetSize(region:GetSize())
            region.ProcLoopFlipbook:SetPoint("CENTER", region, "CENTER")
            region.ProcLoop.FlipAnim:SetFlipBookRows(loopAnim.rows or 6)
            region.ProcLoop.FlipAnim:SetFlipBookColumns(loopAnim.columns or 5)
            region.ProcLoop.FlipAnim:SetFlipBookFrames(loopAnim.frames or 30)
            region.ProcLoop.FlipAnim:SetDuration(loopAnim.duration or 1.0)
            region.ProcLoop.FlipAnim:SetFlipBookFrameWidth(loopAnim.frameW or 0.0)
            region.ProcLoop.FlipAnim:SetFlipBookFrameHeight(loopAnim.frameH or 0.0)
            region.ProcLoopFlipbook:SetScale((loopAnim.scale or 1) * scaleMult)
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
                    region.ProcStartFlipbook:SetSize(size * 2.5, size * 2.5)
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
        if Addon:GetValue("UseCooldownCDMFontColor", nil, frameName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownCDMFontColor", nil, frameName)
        end
        
        local fontSize = Addon:GetValue("UseCooldownCDMFontSize", nil, frameName) and Addon:GetValue("CooldownCDMFontSize", nil, frameName) or 17
        
        --print("CustomFrame stacks Font:", Addon:GetValue("CurrentCDMCooldownFont", nil, frameName))
        local _, fontName = Addon:GetFontObject(
            Addon:GetValue("CurrentCDMCooldownFont", nil, frameName),
            "OUTLINE",
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
            if Addon:GetValue("CurrentCDMStacksFont", nil, frameName) ~= "Default" then
                stacksString:SetFont(
                    LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentCDMStacksFont", nil, frameName)),
                    (Addon:GetValue("UseCDMStacksFontSize", nil, frameName) and Addon:GetValue("CDMStacksFontSize", nil, frameName) or 16),
                    "OUTLINE"
                )
            end
            if Addon:GetValue("UseCDMStacksFontColor", nil, frameName) then
                stacksString:SetVertexColor(Addon:GetRGBA("CDMStacksFontColor", nil, frameName))
            end

            local point = Addon.AttachPoints[Addon:GetValue("CDMCurrentStacksPoint", nil, frameName)]
            local relativePoint = Addon.AttachPoints[Addon:GetValue("CDMCurrentStacksRelativePoint", nil, frameName)]
            stacksString:SetWidth(0)
            stacksString:ClearAllPoints()
            stacksString:SetPoint(point, stacksString:GetParent(), relativePoint)

            if Addon:GetValue("UseCDMStacksOffset", nil, frameName) then
                stacksString:AdjustPointsOffset(Addon:GetValue("CDMStacksOffsetX", nil, frameName), Addon:GetValue("CDMStacksOffsetY", nil, frameName))
            end
        end


    end
end