local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

Addon.CASTBARS = {
    "PlayerCastingBarFrame",
    "TargetFrameSpellBar",
    "FocusFrameSpellBar",
    "BossTargetFrames"
}

ABE_CastingBarMixin = {}

local function ProcessIconMask(mask, frameName, iconSize, iconMaskTexture)
    mask:SetSize(iconSize, iconSize)
    Addon:SetTexture(mask, iconMaskTexture)

    if Addon:GetValue("UseIconMaskScale", nil, frameName) then
        mask:SetScale(Addon:GetValue("IconMaskScale", nil, frameName))
    else
        mask:SetScale(1)
    end
end

local function ProcessIcon(icon, frameName)
    icon:ClearAllPoints()
    icon:SetPoint("CENTER", icon:GetParent(), "CENTER")
    icon:SetSize(icon:GetParent():GetSize())
    if Addon:GetValue("UseIconScale", nil, frameName) then
        icon:SetScale(Addon:GetValue("IconScale", nil, frameName))
    end
end

local function ProcessFont(fontString, frameName, value)
    local useColorValue, colorValue, useSizeValue, sizeValue, NameFont
    if value == "name" then
        useColorValue = "UseCastBarCastNameColor"
        colorValue = "CastBarCastNameColor"
        useSizeValue = "UseCastBarCastNameSize"
        sizeValue = "CastBarCastNameSize"
        NameFont = "CurrentCastBarCastNameFont"
    elseif value == "timer" then
        useColorValue = "UseCastBarCastTimeColor"
        colorValue = "CastBarCastTimeColor"
        useSizeValue = "UseCastBarCastTimeSize"
        sizeValue = "CastBarCastTimeSize"
        NameFont = "CurrentCastBarCastTimeFont"
    elseif value == "targetName" then
        useColorValue = "UseCastBarCastTargetColor"
        colorValue = "CastBarCastTargetColor"
        useSizeValue = "UseCastBarCastTargetSize"
        sizeValue = "CastBarCastTargetSize"
        NameFont = "CurrentCastBarCastTargetFont"
    end
    local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

    if Addon:GetValue(useColorValue, nil, frameName) then
        color.r,color.g,color.b,color.a = Addon:GetRGBA(colorValue, nil, frameName)
    end
    local fontSize = Addon:GetValue(useSizeValue, nil, frameName) and Addon:GetValue(sizeValue, nil, frameName) or 10
    fontString:SetFont(
        LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue(NameFont, nil, frameName)),
        fontSize,
        "OUTLINE, SLUG"
    )
    fontString:SetTextColor(color.r,color.g,color.b,color.a)
end

local function ProcessBorder(frame, frameName)
    Addon.SetBackdropBorderSize(frame, Addon:GetValue("CastBarsBackdropSize", nil, frameName))
    frame:SetBackdropBorderColor(Addon:GetRGBA("CastBarsBackdropColor", nil, frameName))
    frame:SetFrameLevel(frame:GetParent():GetFrameLevel() + 5)
    frame:Show()
end

local function SetBackdropBorderColorByType(self, color)
    if not self.__border then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    local bColor = CopyTable(color)

    if not Addon:GetValue("CastBarsBackdropColorByType", nil, frameName) then
        bColor.r,bColor.g,bColor.b,bColor.a = Addon:GetRGBA("CastBarsBackdropColor", nil, frameName)
    end
    
    if self.__border then
        self.__border:SetBackdropBorderColor(bColor.r, bColor.g, bColor.b, bColor.a)
        self.__iconFrameLeft.border:SetBackdropBorderColor(bColor.r, bColor.g, bColor.b, bColor.a)
        self.__iconFrameRight.border:SetBackdropBorderColor(bColor.r, bColor.g, bColor.b, bColor.a)
    end
end

function ABE_CastingBarMixin.UpdateIconShown(self)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    local iconPos = Addon:GetValue("CurrentCastBarIconPos", nil, frameName)
    local point = iconPos ~= 3 and "RIGHT" or "LEFT"
    local relPoint = iconPos ~= 3 and "LEFT" or "RIGHT"
    local offsetX = Addon:GetValue("UseCastBarIconOffset", nil, frameName) and Addon:GetValue("CastBarIconOffsetX", nil, frameName) or -2
    local offsetY = Addon:GetValue("UseCastBarIconOffset", nil, frameName) and Addon:GetValue("CastBarIconOffsetY", nil, frameName) or 0
    local iconSize = Addon:GetValue("UseCastBarIconSize", nil, frameName) and Addon:GetValue("CastBarIconSize", nil, frameName) or self:GetHeight()
    local iconMaskTexture = T.IconMaskTextures[Addon:GetValue("CurrentIconMaskTexture", nil, frameName)].texture

    if self.IconMaskLeft and self.IconMaskRight then
        ProcessIconMask(self.IconMaskLeft, frameName, iconSize, iconMaskTexture)
        ProcessIconMask(self.IconMaskRight, frameName, iconSize, iconMaskTexture)
    end

    if self.Icon and self.__iconFrameLeft and iconPos > 1 then
        self.__iconFrameLeft:ClearAllPoints()
        self.__iconFrameLeft:SetPoint(point, self.Background, relPoint, iconPos ~= 3 and offsetX or offsetX*-1, offsetY)
        self.__iconFrameLeft:SetSize(iconSize, iconSize)
        self.__iconFrameLeft:Show()
        self.Icon:SetParent(self.__iconFrameLeft)
        self.Icon:SetPoint("CENTER", self.__iconFrameLeft, "CENTER")
        self.Icon:SetSize(iconSize, iconSize)
        self.Icon:Show()
        self.Icon:AddMaskTexture(self.IconMaskLeft)
        ProcessIcon(self.Icon, frameName)
    end

    if self.__rightIcon and self.__iconFrameRight and iconPos > 1 then
        if iconPos == 4 then
            self.__iconFrameRight:ClearAllPoints()
            self.__iconFrameRight:SetPoint("LEFT", self.Background, "RIGHT", offsetX * -1, offsetY)
            self.__iconFrameRight:SetSize(iconSize, iconSize)
            self.__iconFrameRight:Show()

            self.__rightIcon:SetTexture(self.Icon:GetTexture())
            self.__rightIcon:SetPoint("CENTER", self.__iconFrameRight, "CENTER")
            self.__rightIcon:SetSize(iconSize, iconSize)
            self.__rightIcon:Show()
            self.__rightIcon:AddMaskTexture(self.IconMaskRight)
            ProcessIcon(self.__rightIcon, frameName)
        else
            self.__iconFrameRight:Hide()
        end
    end
    ProcessFont(self.__valueText, frameName, "timer")

end

function ABE_CastingBarMixin.SetLook(self, look)
    if not self then return end

    self.__barType = self.__barType or {}

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    self:SetIgnoreParentAlpha(true)
    self:SetScale(1)

    self.__timerFormat = Addon:GetValue("CurrentCastBarCastTimeFormat", nil, frameName)

    self.__barWidth = Addon:GetValue("UseCastBarWidth", nil, frameName) and Addon:GetValue("CastBarWidth", nil, frameName) or 208
    self.__barHeight = Addon:GetValue("UseCastBarHeight", nil, frameName) and Addon:GetValue("CastBarHeight", nil, frameName) or 11
    self:SetWidth(self.__barWidth)
    self:SetHeight(self.__barHeight)

    self.CastTimeText = nil
    
    if self.Background then
        self.Background:ClearAllPoints()
        self.Background:SetAllPoints()

    end

    if self.InterruptGlow then
        self.InterruptGlow:Hide()
    end

    if self.TextBorder then
        if Addon:GetValue("CastHideTextBorder", nil, frameName) then
            self.TextBorder:Hide()
        else
            self.TextBorder:Show()
        end
    end
    if not self.__sqwBar then
        self.__sqwBar = self:CreateTexture(nil, "BACKGROUND", nil, 3)
        self.__sqwBar:SetPoint("RIGHT", self.Background, "RIGHT")
        --self.__sqwBar:SetIgnoreParentAlpha(true)
    end
    if not self.__latencyBar then
        self.__latencyBar = self:CreateTexture(nil, "BACKGROUND", nil, 3)
        self.__latencyBar:SetPoint("RIGHT", self.Background, "RIGHT")
        --self.__latencyBar:SetIgnoreParentAlpha(true)
    end
    self.__sqw = C_Spell.GetSpellQueueWindow() / 1000

    
    ProcessFont(self.Text, frameName, "name")

    self.Text:ClearAllPoints()
    local point = Addon.AttachPoints[Addon:GetValue("CurrentCastBarCastNamePoint", nil, frameName)]
    local relPoint = Addon.AttachPoints[Addon:GetValue("CurrentCastBarCastNameRelativePoint", nil, frameName)]
    local offsetX = Addon:GetValue("UseCastBarCastNameOffset", nil, frameName) and Addon:GetValue("CastBarCastNameOffsetX", nil, frameName) or 0
    local offsetY = Addon:GetValue("UseCastBarCastNameOffset", nil, frameName) and Addon:GetValue("CastBarCastNameOffsetY", nil, frameName) or 0
    self.Text:SetPoint(point, self, relPoint, offsetX, offsetY)

    self.Text:SetWidth(self.__barWidth * 0.8)
    self.Text:SetJustifyH(Addon.BarTextJustifyH[Addon:GetValue("CurrentCastBarCastNameJustifyH", nil, frameName)])
    --self.Text:SetJustifyH("LEFT")


    if not self.__iconFrameLeft then
        self.__iconFrameLeft = CreateFrame("FRAME")
        self.__iconFrameLeft:SetParent(self)
    end
    if not self.__iconFrameRight then
        self.__iconFrameRight = CreateFrame("FRAME")
        self.__iconFrameRight:SetParent(self)
        self.__rightIcon = self.__iconFrameRight:CreateTexture()
        self.__rightIcon:SetAllPoints()
    end

    if not self.IconMaskLeft and not self.IconMaskRight then
        self.IconMaskLeft = self:CreateMaskTexture()
        self.IconMaskLeft:SetParent(self)
        self.IconMaskLeft:SetPoint("CENTER", self.__iconFrameLeft, "CENTER")

        self.IconMaskRight = self:CreateMaskTexture()
        self.IconMaskRight:SetParent(self)
        self.IconMaskRight:SetPoint("CENTER", self.__iconFrameRight, "CENTER")
    end

    if Addon:GetValue("UseCastBarsBackdrop", nil, frameName) then
        if not self.__border then
            self.__border = Addon.CreateBorder(self, frameName)
            self.__iconFrameLeft.border = Addon.CreateBorder(self.__iconFrameLeft, frameName)
            self.__iconFrameRight.border = Addon.CreateBorder(self.__iconFrameRight, frameName)
        end
        ProcessBorder(self.__border, frameName)
        ProcessBorder(self.__iconFrameLeft.border, frameName)
        ProcessBorder(self.__iconFrameRight.border, frameName)
    else
        if self.__border then
            self.__border:Hide()
        end
        if self.__iconFrameLeft.border then
            self.__iconFrameLeft.border:Hide()
        end
        if self.__iconFrameRight.border then
            self.__iconFrameRight.border:Hide()
        end
    end

    if not self.__valueText then
        self.__valueText = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
        self.__valueText:SetWidth(0)
    end
    do
        local timerPoint = Addon.AttachPoints[Addon:GetValue("CurrentCastBarCastTimePoint", nil, frameName)]
        local timerRelPoint = Addon.AttachPoints[Addon:GetValue("CurrentCastBarCastTimeRelativePoint", nil, frameName)]
        local timerOffsetX = Addon:GetValue("UseCastBarCastTimeOffset", nil, frameName) and Addon:GetValue("CastBarCastTimeOffsetX", nil, frameName) or 0
        local timerOffsetY = Addon:GetValue("UseCastBarCastTimeOffset", nil, frameName) and Addon:GetValue("CastBarCastTimeOffsetY", nil, frameName) or 0
        self.__valueText:ClearAllPoints()
        self.__valueText:SetPoint(timerPoint, self.Background, timerRelPoint, timerOffsetX, timerOffsetY)
        self.__valueText:SetJustifyH(Addon.BarTextJustifyH[Addon:GetValue("CurrentCastBarCastTimeJustifyH", nil, frameName)])
        self.__valueText:Show()
    end

    self.__showTargetName = Addon:GetValue("CastBarCastTargetEnable", nil, frameName)
    if not self.__CastTargetNameText then
        self.__CastTargetNameText = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
        self.__CastTargetNameText:SetWidth(0)
        self.__CastTargetNameText:SetWidth(100)
        self.__CastTargetNameText:SetMaxLines(1)
    end

    if self.__showTargetName then
        local point = Addon.AttachPoints[Addon:GetValue("CurrentCastBarCastTargetPoint", nil, frameName)]
        local relPoint = Addon.AttachPoints[Addon:GetValue("CurrentCastBarCastTargetRelativePoint", nil, frameName)]
        local offsetX = Addon:GetValue("UseCastBarCastTargetOffset", nil, frameName) and Addon:GetValue("CastBarCastTargetOffsetX", nil, frameName) or 0
        local offsetY = Addon:GetValue("UseCastBarCastTargetOffset", nil, frameName) and Addon:GetValue("CastBarCastTargetOffsetY", nil, frameName) or 0
        self.__CastTargetNameText:ClearAllPoints()
        self.__CastTargetNameText:SetPoint(point, self.Background, relPoint, offsetX, offsetY)

        self.__CastTargetNameText:SetJustifyH(Addon.BarTextJustifyH[Addon:GetValue("CurrentCastBarCastTargetJustifyH", nil, frameName)])
       
        ProcessFont(self.__CastTargetNameText, frameName, "targetName")
        self.__CastTargetNameText:Show()
    else
        self.__CastTargetNameText:Hide()
    end

    --[[ if not self.interruptMarker then
        self.interruptMarker = CreateFrame("StatusBar", nil, self)
        self.interruptMarker:SetStatusBarTexture("_AnimaChannel-Reinforce-Line-horizontal")
        self.interruptMarker.Pip = self.interruptMarker:CreateTexture()
        self.interruptMarker.Pip:SetColorTexture(1,1,1,1)
        self.interruptMarker.Pip:SetWidth(2)
        self.interruptMarker.Pip:SetHeight(self.__barHeight)
        self.interruptMarker.Pip:SetPoint("CENTER", self.interruptMarker:GetStatusBarTexture(), "LEFT")
        self.interruptMarker:SetPoint("TOPLEFT", self, "TOPLEFT")
        self.interruptMarker:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
        self.interruptMarker.Pip:SetPoint("CENTER", self.interruptMarker:GetStatusBarTexture(), "RIGHT")
    end ]]
end

function ABE_CastingBarMixin.SetStatusBarTexture(self)
    
    --Addon:DebugPrint("SetStatusbarTexture")
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()
        
    local texture = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCastBarStatusbarTexture", nil, frameName))
    local textureBG = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCastBarBackgroundTexture", nil, frameName))
    local statusbarTexture = self:GetStatusBarTexture()
    Addon:SetTexture(statusbarTexture, texture)
    --self:SetStatusBarTexture(Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMStatusBarTexture", nil, "BuffBarCooldownViewer")))
    Addon:SetTexture(self.Background, textureBG)

    if Addon:GetValue("UseCastBarBackgroundColor", nil, frameName) then
        self.Background:SetVertexColor(Addon:GetRGBA("CastBarBackgroundColor", nil, frameName))
    else
        self.Background:SetVertexColor(0,0,0,0.6)
    end

    self.Border:SetTexture("")
end

function ABE_CastingBarMixin.HandleCastStop(self, event, castID, castComplete, interruptedBy)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    if Addon:GetValue("CastHideInterruptAnim", nil, frameName) then
        self:StopInterruptAnims()
    end
    
    if Addon:GetValue("CastQuickFinish", nil, frameName) then
        --self:StopFinishAnims()
        self:Hide()
    else
        if not self.FadeOutAnim:IsPlaying() then
            self.FadeOutAnim:Play()
        end
    end
end

function ABE_CastingBarMixin.OnPlayInterruptAnims(self)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    local texture = self:GetStatusBarTexture()

    local barType = self.__barType or {}

    barType.interrupted = true

    local color = self.CASTBAR_COLORS["standard"]

    color.r, color.g, color.b, color.a = texture:GetVertexColor()
    texture:SetVertexColorFromBoolean(barType.interrupted, self.CASTBAR_COLORS["interrupted"], color)

    SetBackdropBorderColorByType(self, self.CASTBAR_COLORS["interrupted"])
end

function ABE_CastingBarMixin.SetCustomColor(self)

    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    local texture = self:GetStatusBarTexture()

    local barType = self.__barType or {}

    local color = self.CASTBAR_COLORS["standard"]

    texture:SetVertexColor(color.r, color.g, color.b, color.a)
    
    if barType.channel ~= nil then
        texture:SetVertexColorFromBoolean(barType.channel, self.CASTBAR_COLORS["channel"], color)
    end
    if barType.empowered ~= nil then
        color.r, color.g, color.b, color.a = texture:GetVertexColor()
        texture:SetVertexColorFromBoolean(barType.empowered, self.CASTBAR_COLORS["empowered"], color)
    end
    if barType.uninterruptable ~= nil then
        color.r, color.g, color.b, color.a = texture:GetVertexColor()
        texture:SetVertexColorFromBoolean(barType.uninterruptable, self.CASTBAR_COLORS["uninterruptable"], color)

        SetBackdropBorderColorByType(self, color)
    end

    if self.spellID and Addon:GetValue("UseCastBarImportantColor", nil, frameName) then
        color.r, color.g, color.b, color.a = texture:GetVertexColor()
        local isImportant = C_Spell.IsSpellImportant(self.spellID)
        texture:SetVertexColorFromBoolean(isImportant, self.CASTBAR_COLORS["important"], color)
    end
end

function ABE_CastingBarMixin.GetTypeInfo(self, barType)
    if not self then return end

    barType = self.__barType or {}

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    if not self.CASTBAR_COLORS or self.__forceUpdate then
        local sr,sg,sb,sa = Addon:GetRGBA("CastBarStandardColor", nil, frameName)
        local cr,cg,cb,ca = Addon:GetRGBA("CastBarChannelColor", nil, frameName)
        local ur,ug,ub,ua = Addon:GetRGBA("CastBarUninterruptableColor", nil, frameName)
        local ir,ig,ib,ia = Addon:GetRGBA("CastBarInterruptedColor", nil, frameName)
        local imr,img,imb,ima = Addon:GetRGBA("CastBarImportantColor", nil, frameName)
        local rr,rg,rb,ra = Addon:GetRGBA("CastBarReadyColor", nil, frameName)
        self.CASTBAR_COLORS = {
            applyingcrafting    = { r=0.2, g=1.0, b=0.5, a=1 },
            applyingtalents     = { r=0.1, g=1.0, b=0.1, a=1 },
            standard            = Addon:GetValue("UseCastBarStandardColor", nil, frameName) and { r=sr, g=sg, b=sb, a=sa } or { r=1.0, g=1.0, b=0.4, a=1 },
            empowered           = { r=1.0, g=1.0, b=1.0, a=0.4 },
            channel             = Addon:GetValue("UseCastBarChannelColor", nil, frameName) and { r=cr, g=cg, b=cb, a=ca } or { r=0.2, g=0.4, b=0.98, a=1 },
            uninterruptable     = Addon:GetValue("UseCastBarUninterruptableColor", nil, frameName) and { r=ur, g=ug, b=ub, a=ua } or { r=0.5, g=0.5, b=0.5, a=1 },
            interrupted         = Addon:GetValue("UseCastBarInterruptedColor", nil, frameName) and { r=ir, g=ig, b=ib, a=ia } or { r=1, g=0.2, b=0.2, a=1 },
            important           = Addon:GetValue("UseCastBarImportantColor", nil, frameName) and { r=imr, g=img, b=imb, a=ima } or { r=0.95, g=0.55, b=0.2, a=1.0 },
            readytokick         = Addon:GetValue("UseCastBarReadyColor", nil, frameName) and { r=rr, g=rg, b=rb, a=ra } or { r=0.2, g=0.95, b=0.2, a=1.0 },
        }

        self.__forceUpdate = nil
    end

    ABE_CastingBarMixin.SetCustomColor(self)

    --[[ local color = self.CASTBAR_COLORS[barType]
    C_Timer.After(0, function() 
        self:SetStatusBarColor(color.r, color.g, color.b, color.a)
        if self.spellID and Addon:GetValue("UseCastBarImportantColor", nil, frameName) then
            local texture = self:GetStatusBarTexture()
            texture:SetVertexColorFromBoolean(C_Spell.IsSpellImportant(self.spellID), self.CASTBAR_COLORS["important"], color)
        end
    end)

    if Addon:GetValue("CastBarsBackdropColorByType", nil, frameName) and (barType == "interrupted" or barType == "uninterruptable") then
        SetBackdropBorderColorByType(self, color)
    else
        local r,g,b,a = Addon:GetRGBA("CastBarsBackdropColor", nil, frameName)
        SetBackdropBorderColorByType(self, {r=r,g=g,b=b,a=a})
    end ]]
end

function ABE_CastingBarMixin.AddStages(self, numStages)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    if not numStages or numStages <= 1 then return end

    local START_R, START_G, START_B = 0.961, 0.239, 0.239  -- #f53d3d
    local END_R,   END_G,   END_B   = 0.819, 0.819, 0.478  -- #d1d17a

    local texture = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCastBarStatusbarTexture", nil, frameName))

    for i = 1, numStages do
        local chargeTierName = "ChargeTier" .. i
		local chargeTier = self.ChargeTierPool[chargeTierName]
        if chargeTier then

            local t = (i - 1) / (numStages - 1)

            local r = START_R + (END_R - START_R) * t
            local g = START_G + (END_G - START_G) * t
            local b = START_B + (END_B - START_B) * t

            local h, s, v = C_ColorUtil.ConvertRGBToHSV(r, g, b)
            local darkR, darkG, darkB = C_ColorUtil.ConvertHSVToRGB(h, s * 0.4, v * 0.5)
            local glowR, glowG, glowB = C_ColorUtil.ConvertHSVToRGB(h, math.min(1.0, s * 1.3), math.min(1.0, v * 1.2))
            
            Addon:SetTexture(chargeTier.Normal, texture)
            chargeTier.Normal:SetVertexColor(r, g, b, 1)
            Addon:SetTexture(chargeTier.Disabled, texture)
            chargeTier.Disabled:SetVertexColor(darkR, darkG, darkB, 1)
            Addon:SetTexture(chargeTier.Glow, texture)
            chargeTier.Glow:SetVertexColor(glowR, glowG, glowB, 1)
        end

        self.StagePips[i].BasePip:SetAtlas("ui-castingbar-empower-pip", false)
        self.StagePips[i].BasePip:SetHeight(self.__barHeight or 10)

    end
end

function ABE_CastingBarMixin.UpdateStage(self)
    if self.playCastFX then
        self.StageFinish:Stop()
    end
    if self.StageFlash then
        self.StageFlash:Stop()
    end
end

function ABE_CastingBarMixin.OnUpdate(self, elapsed)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    if not self.value or not self.maxValue then return end
    local now = GetTime()
    if self.__lastCheck and (now - self.__lastCheck <= 0.1) then return end

    self.__lastCheck = now

    if not self.__valueText then return end

    local timerText = 0
    if self.__timerFormat == 3 then
        timerText = string.format("%.1f", self.value).. " / " .. string.format("%.1f",self.maxValue)
    elseif self.__timerFormat == 2 then
        timerText = string.format("%.1f",self.maxValue)
    else
        timerText = string.format("%.1f", self.value)
    end

    self.__valueText:SetText(timerText or "")
    if self.__showTargetName then
        local unit
        if self.unit == "player" then
            unit = "target"
        elseif self.unit == "target" then
            unit = "targettarget"
        elseif self.unit == "focus" then
            unit = "focustarget"
        else
            unit = self.unit.."target"
        end

        local targetNameText = UnitSpellTargetName(self.unit)
        local classFilename = UnitSpellTargetClass(self.unit)

        if not targetNameText or ((not issecretvalue(self.__barType.empowered) and self.__barType.empowered)
        or (not issecretvalue(self.__barType.interrupted) and self.__barType.interrupted)) then
            self.__CastTargetNameText:SetText("")
            return
        end

        local classColor
        if classFilename then
            classColor = UnitIsPlayer(unit) and C_ClassColor.GetClassColor(classFilename) or FACTION_BAR_COLORS[UnitReaction(unit, "player")]
        else
            classColor = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
            
        end
        if classColor then
            targetNameText = classColor:WrapTextInColorCode(targetNameText)
        else
            self.__CastTargetNameText:SetVertexColor(0.6,0.6,0.6,1)
        end

        self.__CastTargetNameText:SetText(targetNameText or "")
    end
    if (self.unit ~= "player" and UnitCanAttack(self.unit, "player")) and Addon:GetValue("UseCastBarReadyColor", nil, frameName) then
        local interruptSpellID = Addon:GetInterruptSpell()
        if interruptSpellID then
            local texture = self:GetStatusBarTexture()
            local color = {}
            color.r, color.g, color.b, color.a = texture:GetVertexColor()
            local interruptDuration = C_Spell.GetSpellCooldownDuration(interruptSpellID)
            texture:SetVertexColorFromBoolean(interruptDuration:IsZero(), self.CASTBAR_COLORS["readytokick"], color)
            if self.__barType.uninterruptable ~= nil then
                color.r, color.g, color.b, color.a = texture:GetVertexColor()
                texture:SetVertexColorFromBoolean(self.__barType.uninterruptable, self.CASTBAR_COLORS["uninterruptable"], color)
            end
        end
    end

end

function ABE_CastingBarMixin.ShowSpark(self)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    local sparkTexture = T.PipTextures[Addon:GetValue("CurrentCastBarPipTexture", nil, frameName)].texture
    local pipWidth = Addon:GetValue("UseCastBarPipSize", nil, frameName) and Addon:GetValue("CastBarPipSizeX", nil, frameName) or 8
    local pipHeight = Addon:GetValue("UseCastBarPipSize", nil, frameName) and Addon:GetValue("CastBarPipSizeY", nil, frameName) or 20

    local currentBarType = self.__barType
    if currentBarType == "interrupted" then
        Addon:SetTexture(self.Spark, sparkTexture, false)
		self.Spark:SetSize(pipWidth, pipHeight)
	elseif currentBarType == "empowered" then
        Addon:SetTexture(self.Spark, sparkTexture, false)
        self.Spark.offsetY = 0
		self.Spark:SetSize(pipWidth, pipHeight)
	else
        Addon:SetTexture(self.Spark, sparkTexture, false)
		self.Spark:SetSize(pipWidth, pipHeight)
	end

    if self.CraftGlow then
        self.CraftGlow:Hide()
    end
    if self.StandardGlow then
        self.StandardGlow:Hide()
    end
    if self.ChannelShadow then
        self.ChannelShadow:Hide()
    end

end

function ABE_CastingBarMixin.PlayFinishAnim(self)
    if self.CraftingFinish then
        self.CraftingFinish:Stop()
    end
    if self.StandardFinish then
        self.StandardFinish:Stop()
    end
    if self.ChannelFinish then
        self.ChannelFinish:Stop()
    end

    if self.FlashAnim then
		self.FlashAnim:Stop()
	end

    if Addon:GetValue("CastQuickFinish", nil, frameName) then
        self:StopFinishAnims()
        self:Hide()
    else
        self.FadeOutAnim:Play()
    end
end

function ABE_CastingBarMixin.SetColorFill(self)
    ABE_CastingBarMixin.GetTypeInfo(self, "empowered")
end

function ABE_CastingBarMixin.UpdateHighlightImportantCast(self)
    if self.spellID == nil then return end


end

function ABE_CastingBarMixin.AdjustPosition(self)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()
    
    local parentFrame = self:GetParent()
    local point = Addon.AttachPoints[Addon:GetValue("CurrentCastBarPoint", nil, frameName)]
    local relPoint = Addon.AttachPoints[Addon:GetValue("CurrentCastBarRelativePoint", nil, frameName)]
    local offsetX = Addon:GetValue("UseCastBarOffsetX", nil, frameName) and Addon:GetValue("CastBarOffsetX", nil, frameName) or 0
    local offsetY = Addon:GetValue("UseCastBarOffsetY", nil, frameName) and Addon:GetValue("CastBarOffsetY", nil, frameName) or 0
    self:ClearAllPoints()
    self:SetPoint(point, parentFrame, relPoint, offsetX, offsetY)
end

function ABE_CastingBarMixin.ProcessShieldBorder(self)
    if not self then return end

    local frameName = self.boss and "BossTargetFrames" or self:GetName()

    if self.BorderShield then
        local shieldAtlas = T.CastBarShieldIcons[Addon:GetValue("CurrentCastBarShieldIconTexture", nil, frameName)]
        if shieldAtlas.hide then
            self.BorderShield:SetAlpha(0)
        else
            self.BorderShield:ClearAllPoints()
            self.BorderShield:SetAlpha(1)
            self.BorderShield:SetShown(false)
            local layer, sublevel = self.Text:GetDrawLayer()
            self.BorderShield:SetDrawLayer("OVERLAY",7)
            Addon:SetTexture(self.BorderShield, shieldAtlas.texture, false)
            local size = Addon:GetValue("UseCastBarShieldIconSize", nil, frameName) and Addon:GetValue("CastBarShieldIconSize", nil, frameName) or 10
            self.BorderShield:SetSize(size, size)
            local point = Addon.AttachPoints[Addon:GetValue("CurrentCastBarShieldIconPoint", nil, frameName)]
            local relPoint = Addon.AttachPoints[Addon:GetValue("CurrentCastBarShieldIconRelativePoint", nil, frameName)]
            local offsetX = Addon:GetValue("UseCastBarShieldIconOffset", nil, frameName) and Addon:GetValue("CastBarShieldIconOffsetX", nil, frameName) or 0
            local offsetY = Addon:GetValue("UseCastBarShieldIconOffset", nil, frameName) and Addon:GetValue("CastBarShieldIconOffsetY", nil, frameName) or 0
            self.BorderShield:SetPoint(point, self, relPoint, offsetX, offsetY)
        end
    end
end

local function StartCastbar(self)
    local spellID = 150544
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local text = spellInfo.name
    local texture = spellInfo.iconID


    --self.barType = self:GetEffectiveType(false, false, false, false)
    --self:SetStatusBarTexture(self:GetTypeInfo(self.barType).filling)

    self.value = 5
    self.maxValue = 15
    self:SetMinMaxValues(0, self.maxValue);
    self:SetValue(self.value)
    self:UpdateCastTimeText()
    if ( self.Text ) then
        self.Text:SetText(text)
    end
    if ( self.Icon ) then
        self.Icon:SetTexture(texture)
    end
    self.casting = false

    self.channeling = nil
    self.reverseChanneling = nil

    self:UpdateIconShown()
    self:StopAnims()
    self:ApplyAlpha(1.0)

    self:ShowSpark()

    self:UpdateShownState(true)
end

function ABE_CastingBarMixin.OnOptionsSelected(self, show)
    if show then
        --StartCastbar(self)
    else
        self:Hide()
    end
end

function ABE_CastingBarMixin.OnGetEffectiveType(self, isChannel, notInterruptible, isTradeSkill, isEmpowered)
    self.__barType = {
        standard = true,
        channel = isChannel,
        uninterruptable = notInterruptible,
        applyingcrafting = isTradeSkill,
        empowered = isEmpowered,
        interrupted = false,
    }
end

function ABE_CastingBarMixin.SetHooks(frame)
    if frame.SetLook then
        hooksecurefunc(frame, "SetLook", ABE_CastingBarMixin.SetLook)
        ABE_CastingBarMixin.SetLook(frame)
    end
    if frame.UpdateIconShown then
        hooksecurefunc(frame, "UpdateIconShown", ABE_CastingBarMixin.UpdateIconShown)
    end
    if frame.SetStatusBarTexture then
        hooksecurefunc(frame, "SetStatusBarTexture", ABE_CastingBarMixin.SetStatusBarTexture)
    end
    if frame.HandleCastStop then
        hooksecurefunc(frame, "HandleCastStop", ABE_CastingBarMixin.HandleCastStop)
    end
    if frame.GetTypeInfo then
        hooksecurefunc(frame, "GetTypeInfo", ABE_CastingBarMixin.GetTypeInfo)
    end
    if frame.AddStages then
        hooksecurefunc(frame, "AddStages", ABE_CastingBarMixin.AddStages)
    end
    if frame.UpdateStage then
        hooksecurefunc(frame, "UpdateStage", ABE_CastingBarMixin.UpdateStage)
    end
    if frame.ShowSpark then
        hooksecurefunc(frame, "ShowSpark", ABE_CastingBarMixin.ShowSpark)
    end
    if frame.PlayFinishAnim then
        hooksecurefunc(frame, "PlayFinishAnim", ABE_CastingBarMixin.PlayFinishAnim)
    end
    if frame.SetColorFill then
        hooksecurefunc(frame, "SetColorFill", ABE_CastingBarMixin.SetColorFill)
    end
    if frame.OnUpdate then
        frame:HookScript("OnUpdate", ABE_CastingBarMixin.OnUpdate)
    end
    if frame.AdjustPosition then
        hooksecurefunc(frame, "AdjustPosition", ABE_CastingBarMixin.AdjustPosition)
    end
    if frame.UpdateHighlightImportantCast then
        hooksecurefunc(frame, "UpdateHighlightImportantCast", ABE_CastingBarMixin.UpdateHighlightImportantCast)
    end
    if frame.GetEffectiveType then
        hooksecurefunc(frame, "GetEffectiveType" , ABE_CastingBarMixin.OnGetEffectiveType)
    end
    if frame.PlayInterruptAnims then
        hooksecurefunc(frame, "PlayInterruptAnims", ABE_CastingBarMixin.OnPlayInterruptAnims)
    end
end