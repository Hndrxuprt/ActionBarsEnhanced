local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

ABE_CDMCustomFrameCustomized = {}

function ABE_CDMCustomFrameCustomized:RefreshSkin(frame, frameName)
    frameName = frameName or frame.frameName

    if frame.RefreshSettings then
        frame:RefreshSettings()
        return
    end

    self:RefreshItemSize(frame, frameName)
    self:RefreshIconMask(frame, frameName)
    self:RefreshCooldownFrame(frame, frameName)
    self:RefreshBackdrop(frame, frameName)
    --self:RefreshLoopGlow(frame, frameName)
    self:RefreshCooldownFont(frame, frameName)
    self:RefreshStacksFont(frame, frameName)
    if frame:IsBarFrame() then
        self:RefreshBarSize(frame, frameName)
        self:RefreshPipTexture(frame, frameName)
        self:RefreshName(frame, frameName)
        self:RefreshStacks(frame, frameName)
        self:RefreshDuration(frame, frameName)
    end

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

function ABE_CDMCustomFrameCustomized:ApplyBarIconSize(itemFrame, frameName)
    local iconPos = Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, frameName)
    local size = Addon:GetValue("CDMCustomFrameBarIconSize", nil, frameName)
    itemFrame.Icon:SetSize(size, size)
    itemFrame.Icon:SetAlpha(1)

    local point = iconPos ~= 3 and "RIGHT" or "LEFT"
    local relPoint = iconPos ~= 3 and "LEFT" or "RIGHT"
    local offsetX = Addon:GetValue("UseCDMCustomFrameBarIconOffset", nil, frameName) and Addon:GetValue("CDMCustomFrameBarIconOffsetX", nil, frameName) or 0
    local offsetY = Addon:GetValue("UseCDMCustomFrameBarIconOffset", nil, frameName) and Addon:GetValue("CDMCustomFrameBarIconOffsetY", nil, frameName) or 0

    itemFrame.Icon:ClearAllPoints()
    itemFrame.Icon:SetPoint(point, itemFrame, relPoint, iconPos ~= 3 and offsetX or offsetX*-1, offsetY)
end

function ABE_CDMCustomFrameCustomized:RefreshBarIconSize(frame, frameName)
    frameName = frameName or frame.frameName
    local iconPos = Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, frameName)
    if iconPos > 1 then
        if Addon:GetValue("UseCDMCustomFrameBarIconSize", nil, frameName) then
            for itemFrame in frame.itemPool:EnumerateActive() do
                self:ApplyBarIconSize(itemFrame, frameName)    
            end
        end
    else
        for itemFrame in frame.itemPool:EnumerateActive() do
            itemFrame.Icon:Hide()
        end
    end
end

function ABE_CDMCustomFrameCustomized:ApplyBarSize(itemFrame, frameName)
    local width = Addon:GetValue("UseCDMCustomFrameBarWidth", nil, frameName) and Addon:GetValue("CDMCustomFrameBarWidth", nil, frameName) or 100
    local height = Addon:GetValue("UseCDMCustomFrameBarHeight", nil, frameName) and Addon:GetValue("CDMCustomFrameBarHeight", nil, frameName) or 10
    local statusbar = itemFrame:GetStatusbar()
    statusbar:SetSize(width, height)
end

function ABE_CDMCustomFrameCustomized:RefreshBarSize(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        if itemFrame.Bar then
            self:ApplyBarSize(itemFrame, frameName)
        end
    end
end

function ABE_CDMCustomFrameCustomized:ApplyBarTexture(itemFrame, frameName, spellID)
    local foreground = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMCustomFrameStatusbarTexture", nil, frameName))
    local background = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMCustomFrameBackgroundTexture", nil, frameName))
    local color = itemFrame:GetCustomColor(spellID) or { r=1, g=1, b=1, a=1 }
    local statusbar = itemFrame:GetStatusbar()
    statusbar:SetStatusBarTexture(foreground)
    statusbar:SetStatusBarColor(color.r, color.g, color.b, color.a)
    statusbar.BarBG:SetVertexColor(Addon:GetRGBA("CDMCustomFrameBackgroundColor", nil, frameName))
    Addon:SetTexture(statusbar.BarBG, background)
end

function ABE_CDMCustomFrameCustomized:RefreshBarTextures(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        if itemFrame.Bar then
            self:ApplyBarTexture(itemFrame, frameName)
        end
    end
end

function ABE_CDMCustomFrameCustomized:ApplyPipTexture(itemFrame, frameName)
    local pipTexture = T.PipTextures[Addon:GetValue("CurrentCDMCustomFramePipTexture", nil, frameName)].texture
    local pipWidth = Addon:GetValue("UseCDMCustomFramePipSize", nil, frameName) and Addon:GetValue("CDMCustomFramePipSizeX", nil, frameName) or 8
    local pipHeight = Addon:GetValue("UseCDMCustomFramePipSize", nil, frameName) and Addon:GetValue("CDMCustomFramePipSizeY", nil, frameName) or 20

    local statusbar = itemFrame:GetStatusbar()
    statusbar.Pip:SetSize(pipWidth, pipHeight)
    Addon:SetTexture(statusbar.Pip, pipTexture)

    statusbar.Pip:SetPoint("CENTER", statusbar:GetStatusBarTexture(), "RIGHT", 0, 0)
end

function ABE_CDMCustomFrameCustomized:RefreshPipTexture(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        if itemFrame.Bar then
            self:ApplyPipTexture(itemFrame, frameName)
        end
    end
end

function ABE_CDMCustomFrameCustomized:CustomizeCooldownFrame(cooldownFrame, frameName, cdParent)
    if not cooldownFrame then return end

    local swipeTextureIndex = Addon:GetValue("CurrentSwipeTexture", nil, frameName)

    if swipeTextureIndex > 1 then
        cooldownFrame:SetSwipeTexture(T.SwipeTextures[swipeTextureIndex].texture)
    end

    cdParent = cdParent or cooldownFrame:GetParent()

    if Addon:GetValue("UseSwipeSize", nil, frameName) then
        cooldownFrame:ClearAllPoints()
        cooldownFrame:SetPoint("CENTER", cdParent, "CENTER")
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

    cooldownFrame:SetReverse(Addon:GetValue("CDMReverseSwipe", nil, frameName))

    cooldownFrame.isReversed = Addon:GetValue("CDMReverseSwipe", nil, frameName)

    cooldownFrame.showGCDSwipe = not (Addon:GetValue("CDMRemoveGCDSwipe", nil, frameName))
end

function ABE_CDMCustomFrameCustomized:RefreshCooldownColor(cooldownFrame, frameName)
    if Addon:GetValue("UseCooldownColor", nil, frameName) then
        cooldownFrame:SetSwipeColor(Addon:GetRGBA("CooldownColor", nil, frameName))
    end
end

function ABE_CDMCustomFrameCustomized:RefreshAuraColor(cooldownFrame, frameName)
    if Addon:GetValue("UseCooldownAuraColor", nil, frameName) then
        cooldownFrame:SetSwipeColor(Addon:GetRGBA("CooldownAuraColor", nil, frameName))
    end
end

function ABE_CDMCustomFrameCustomized:RefreshAuraTimer(cooldownFrame, frameName)
    local timerString = cooldownFrame:GetCountdownFontString()

    if Addon:GetValue("UseCDMAuraTimerColor", nil, frameName) then
        timerString:SetVertexColor(Addon:GetRGBA("CDMAuraTimerColor", nil, frameName))
    else
        timerString:SetVertexColor(1,1,1,1)
    end
end

function ABE_CDMCustomFrameCustomized:ColorizeCooldownFont(cooldownFrame, frame, frameName, forceUpdate)
    local fontString = cooldownFrame:GetCountdownFontString()

    if not frame.__cooldownColor then
        frame.__cooldownColor = { r=1, g=1, b=1, a=1 }
    end

    local color = { r=1, g=1, b=1, a=1 }
    if Addon:GetValue("UseCooldownFontColor", nil, frameName) then
        color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownFontColor", nil, frameName)
    end
    if not tCompare(color, frame.__cooldownColor) then
        frame.__cooldownColor = color
        forceUpdate = true
    end

    if Addon:GetValue("ColorizedCooldownFont", nil, frameName) then
        if not frame.__numberFormatterColored or forceUpdate then
            local formatType = Addon:GetValue("CDMCooldownFormatType", nil, frameName)
            frame.__numberFormatterColored = Addon:GetNumberFormatter(color,nil,nil,formatType)
        end
        cooldownFrame:SetCountdownFormatter(frame.__numberFormatterColored)
    else
        if not frame.__numberFormater or forceUpdate then
            local formatType = Addon:GetValue("CDMCooldownFormatType", nil, frameName)
            frame.__numberFormater = Addon:GetNumberFormatter(color, color, color,formatType)
        end
        cooldownFrame:SetCountdownFormatter(frame.__numberFormater)
    end
end

function ABE_CDMCustomFrameCustomized:RefreshCooldownFrame(frame, frameName, forceUpdate)
    frameName = frameName or frame.frameName

    for itemFrame in frame.itemPool:EnumerateActive() do
        local cooldownFrame = itemFrame.Icon.Cooldown or itemFrame.Cooldown
        local auraFrame = itemFrame.Icon.AuraCooldown or itemFrame.AuraCooldown
        
        self:CustomizeCooldownFrame(cooldownFrame, frameName)
        self:RefreshCooldownColor(cooldownFrame, frameName)
        self:ColorizeCooldownFont(cooldownFrame, frame, frameName, forceUpdate)

        self:CustomizeCooldownFrame(auraFrame, frameName)
        self:RefreshAuraColor(auraFrame, frameName)
        self:RefreshAuraTimer(auraFrame, frameName)
    end

end

function ABE_CDMCustomFrameCustomized:CustomizeCooldownFont(cooldownFrame, frameName)
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

    local fontString = cooldownFrame:GetCountdownFontString()

    if Addon:GetValue("UseCooldownFontOffset", nil, frameName) then
        local offsetX = Addon:GetValue("CooldownFontOffsetX", nil, frameName)
        local offsetY = Addon:GetValue("CooldownFontOffsetY", nil, frameName)

        fontString:SetPointsOffset(offsetX, offsetY)
    else
        fontString:SetPointsOffset(0, 0)
    end
end

function ABE_CDMCustomFrameCustomized:RefreshCooldownFont(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do

        local cooldownFrame = itemFrame.Icon.Cooldown or itemFrame.Cooldown
        local auraCooldown  = itemFrame.Icon.AuraCooldown or itemFrame.AuraCooldown

        self:CustomizeCooldownFont(cooldownFrame, frameName)
        self:CustomizeCooldownFont(auraCooldown, frameName)

    end
end

function ABE_CDMCustomFrameCustomized:CustomizeStacksFont(fontString, frameName, parent)
    if not fontString then return end

    if Addon:GetValue("CurrentStacksFont", nil, frameName) ~= "Default" then
        fontString:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentStacksFont", nil, frameName)),
            (Addon:GetValue("UseStacksFontSize", nil, frameName) and Addon:GetValue("StacksFontSize", nil, frameName) or 16),
            "OUTLINE, SLUG"
        )
    end
    if Addon:GetValue("UseStacksColor", nil, frameName) then
        fontString:SetVertexColor(Addon:GetRGBA("StacksColor", nil, frameName))
    end

    local point = Addon.AttachPoints[Addon:GetValue("CurrentStacksPoint", nil, frameName)]
    local relativePoint = Addon.AttachPoints[Addon:GetValue("CurrentStacksRelativePoint", nil, frameName)]
    fontString:SetWidth(0)
    fontString:ClearAllPoints()
    parent = parent or fontString:GetParent()
    fontString:SetPoint(point, parent, relativePoint)

    if Addon:GetValue("UseStacksOffset", nil, frameName) then
        fontString:SetPointsOffset(Addon:GetValue("StacksOffsetX", nil, frameName), Addon:GetValue("StacksOffsetY", nil, frameName))
    end
end

function ABE_CDMCustomFrameCustomized:RefreshStacksFont(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        local stacksFrame = itemFrame.Icon.Applications or itemFrame.Applications
        local stacksString = stacksFrame.Applications
        if stacksString then
            self:CustomizeStacksFont(stacksString, frameName)
        end
    end
end

function ABE_CDMCustomFrameCustomized:SetupBackdrop(backdrop, frameName, color)

    if not color then
        color = {r=1, g=1, b=1, a=1}
        color.r, color.g, color.b, color.a = Addon:GetRGBA("CDMBackdropColor", nil, frameName)
    end
    --[[ auraColor.r, auraColor.g, auraColor.b, auraColor.a = Addon:GetRGBA("CDMBackdropAuraColor", nil, frameName)
    pandemicColor.r, pandemicColor.g, pandemicColor.b, pandemicColor.a = Addon:GetRGBA("CDMBackdropPandemicColor", nil, frameName) ]]

    Addon.SetBackdropBorderSize(backdrop, Addon:GetValue("CDMBackdropSize", nil, frameName))
    backdrop:SetBackdropBorderColor(color.r, color.g, color.b, color.a)

end

function ABE_CDMCustomFrameCustomized:RefreshBackdrop(frame, frameName)
    frameName = frameName or frame.frameName
    local color = {r=0,g=0,b=0,a=1}
    local auraColor = {r=0,g=0,b=0,a=1}
    local pandemicColor = {r=0,g=0,b=0,a=1}

    if Addon:GetValue("UseCDMBackdrop", nil, frameName) then
        for itemFrame in frame.itemPool:EnumerateActive() do
            if not itemFrame:HasAnyForbiddenAspects() then

                if not itemFrame.iconBorder then
                    itemFrame.iconBorder = Addon.CreateBorder(itemFrame.Icon, frameName)
                    itemFrame.iconBorder:SetShown(self.__isActive)
                elseif itemFrame.iconBorder then
                    self:SetupBackdrop(itemFrame.iconBorder, frameName)
                    itemFrame.iconBorder:SetShown(self.__isActive)
                end
                if itemFrame.Bar and not itemFrame.BarBorder then
                    itemFrame.BarBorder = Addon.CreateBorder(itemFrame.Bar, frameName)
                    itemFrame.BarBorder:Show()
                elseif itemFrame.BarBorder then
                    self:SetupBackdrop(itemFrame.iconBorder, frameName)
                    itemFrame.BarBorder:Show()
                end
                if itemFrame.realAuraFrame and itemFrame.realAuraFrame:CanBeAccessedInContext() and itemFrame.realAuraFrame.iconBorder then
                    auraColor.r, auraColor.g, auraColor.b, auraColor.a = Addon:GetRGBA("CDMBackdropAuraColor", nil, frameName)
                    self:SetupBackdrop(itemFrame.realAuraFrame.iconBorder, frameName, auraColor)
                end
                if itemFrame.realAuraFrame and itemFrame.realAuraFrame:CanBeAccessedInContext() and itemFrame.realAuraFrame.pandemicBorder then
                    pandemicColor.r, pandemicColor.g, pandemicColor.b, pandemicColor.a = Addon:GetRGBA("CDMBackdropPandemicColor", nil, frameName)
                    self:SetupBackdrop(itemFrame.realAuraFrame.pandemicBorder, frameName, pandemicColor)
                end
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

function ABE_CDMCustomFrameCustomized:ApplyBarName(itemFrame, frameName)
    local nameString = itemFrame.nameText or itemFrame.Name

    if Addon:GetValue("CustomFrameBarNameEnable", nil, frameName) then
        nameString:Show()

        local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

        if Addon:GetValue("UsCustomFrameBarNameColor", nil, frameName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CustomFrameBarNameColor", nil, frameName)
        end
        local fontSize = Addon:GetValue("UseCustomFrameBarNameSize", nil, frameName) and Addon:GetValue("CustomFrameBarNameSize", nil, frameName) or 14
        nameString:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentCustomFrameBarNameFont", nil, frameName)),
            fontSize,
            "OUTLINE, SLUG"
        )
        nameString:SetTextColor(color.r,color.g,color.b,color.a)

        local point = Addon.AttachPoints[Addon:GetValue("CustomFrameBarNamePoint", nil, frameName)]
        local relativePoint = Addon.AttachPoints[Addon:GetValue("CustomFrameBarNameRelativePoint", nil, frameName)]
        nameString:SetWidth(0)
        nameString:ClearAllPoints()
        nameString:SetPoint(point, nameString:GetParent(), relativePoint)

        if Addon:GetValue("UseCustomFrameBarNameOffset", nil, frameName) then
            nameString:SetPointsOffset(Addon:GetValue("CustomFrameBarNameOffsetX", nil, frameName), Addon:GetValue("CustomFrameBarNameOffsetY", nil, frameName))
        end

        --nameString:SetJustifyH(Addon.BarTextJustifyH[Addon:GetValue("CurrentCustomFrameBarNameJustifyH", nil, frameName)])
    else
        nameString:Hide()
    end
end


function ABE_CDMCustomFrameCustomized:RefreshName(frame, frameName)
    frameName = frameName or frame.frameName
   
    for itemFrame in frame.itemPool:EnumerateActive() do
        self:ApplyBarName(itemFrame, frameName)
    end
end

function ABE_CDMCustomFrameCustomized:ApplyStacks(itemFrame, frameName)
    local stacksString = itemFrame.countText or itemFrame.Bar.Count

    if Addon:GetValue("CustomFrameBarStacksEnable", nil, frameName) then
        stacksString:Show()

        local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

        if Addon:GetValue("UsCustomFrameBarStacksColor", nil, frameName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CustomFrameBarStacksColor", nil, frameName)
        end
        local fontSize = Addon:GetValue("UseCustomFrameBarStacksSize", nil, frameName) and Addon:GetValue("CustomFrameBarStacksSize", nil, frameName) or 14
        stacksString:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentCustomFrameBarStacksFont", nil, frameName)),
            fontSize,
            "OUTLINE, SLUG"
        )
        stacksString:SetTextColor(color.r,color.g,color.b,color.a)

        local point = Addon.AttachPoints[Addon:GetValue("CustomFrameBarStacksPoint", nil, frameName)]
        local relativePoint = Addon.AttachPoints[Addon:GetValue("CustomFrameBarStacksRelativePoint", nil, frameName)]
        stacksString:SetWidth(0)
        stacksString:ClearAllPoints()
        stacksString:SetPoint(point, itemFrame.countFrame or itemFrame.Bar, relativePoint)

        if Addon:GetValue("UseCustomFrameBarStacksOffset", nil, frameName) then
            stacksString:SetPointsOffset(Addon:GetValue("CustomFrameBarStacksOffsetX", nil, frameName), Addon:GetValue("CustomFrameBarStacksOffsetY", nil, frameName))
        end

        --nameString:SetJustifyH(Addon.BarTextJustifyH[Addon:GetValue("CurrentCustomFrameBarStacksJustifyH", nil, frameName)])
    else
        stacksString:Hide()
    end
end

function ABE_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
    frameName = frameName or frame.frameName
    for itemFrame in frame.itemPool:EnumerateActive() do
        self:ApplyStacks(itemFrame, frameName)
    end
end

function ABE_CDMCustomFrameCustomized:ApplyBarDuration(itemFrame, frameName)
    local durationString = itemFrame.durationText or itemFrame.Bar.Duration
    local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

    local parent = _G[frameName]
    
    if Addon:GetValue("CustomFrameBarTimeEnable", nil, frameName) then
        durationString:Show()

        parent.timerFormat = Addon:GetValue("CurrentCustomFrameBarTimeFormat", nil, frameName)

        if Addon:GetValue("UseCustomFrameBarTimeColor", nil, frameName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CustomFrameBarTimeColor", nil, frameName)
        end
        local fontSize = Addon:GetValue("UseCustomFrameBarTimeSize", nil, frameName) and Addon:GetValue("CustomFrameBarTimeSize", nil, frameName) or 14
        durationString:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentCustomFrameBarTimeFont", nil, frameName)),
            fontSize,
            "OUTLINE, SLUG"
        )
        durationString:SetTextColor(color.r,color.g,color.b,color.a)

        local point = Addon.AttachPoints[Addon:GetValue("CurrentCustomFrameBarTimePoint", nil, frameName)]
        local relativePoint = Addon.AttachPoints[Addon:GetValue("CurrentCustomFrameBarTimeRelativePoint", nil, frameName)]
        durationString:SetWidth(0)
        durationString:ClearAllPoints()
        durationString:SetPoint(point, itemFrame.durationFrame or itemFrame.Bar, relativePoint)

        if Addon:GetValue("UseCustomFrameBarTimeOffset", nil, frameName) then
            durationString:SetPointsOffset(Addon:GetValue("CustomFrameBarTimeOffsetX", nil, frameName), Addon:GetValue("CustomFrameBarTimeOffsetY", nil, frameName))
        end
        --nameString:SetJustifyH(Addon.BarTextJustifyH[Addon:GetValue("CurrentCustomFrameBarTimeJustifyH", nil, frameName)])
    else
        durationString:Hide()
        parent.timerFormat = nil
    end
end

function ABE_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
    frameName = frameName or frame.frameName

    for itemFrame in frame.itemPool:EnumerateActive() do
        self:ApplyBarDuration(itemFrame, frameName)
    end
    frame.bindingTextFormatter = Addon:GetNumberFormatter(color, color, color)
end
