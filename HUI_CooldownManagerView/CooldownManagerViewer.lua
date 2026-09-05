local Addon = _G.HUI

local L = Addon.L
local T = Addon.Templates

local isBeta = Addon.IsBeta

local debugPrint = Addon.DebugPrint

CooldownManagerEnhanced = {}
CooldownManagerEnhanced.constants = {
    OORColor = {0.64, 0.15, 0.15, 1.0},
    OOMColor = {0.5, 0.5, 1.0, 1.0},
    NUColor = {0.4, 0.4, 0.4, 1.0},
}

local OnButtonVisibilityChanged

function CooldownManagerEnhanced:ForceUpdate(frameName)
    if not frameName then return end

    CooldownManagerEnhanced.forced = frameName
    local frame = _G[frameName]

    frame:Layout()
    --frame:RefreshData()
    --frame:UpdateShownState()
    CooldownManagerEnhanced.forced = nil
end

function CooldownManagerEnhanced:RefreshFormatters(frameName)
    if not frameName then return end

    local frame = _G[frameName]
    if not frame then return end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if child.Cooldown and child.__cooldownSet then
            local barFrame = child:GetParent()
            local cooldownFrame = child.Cooldown
            local formatType = Addon:GetValue("CDMCooldownFormatType", nil, frameName)
            local formatOptions = Addon:GetCooldownFormatOptions(frameName)
            barFrame.__formatType = formatType
            if not barFrame.__formatOptions or not tCompare(formatOptions, barFrame.__formatOptions) then
                barFrame.__formatOptions = formatOptions
            end
            self:ApplyCooldownFormatter(cooldownFrame, child, barFrame, frameName, true)
            if cooldownFrame.SetUseAuraDisplayTime then
                local useAura = child.cooldownUseAuraDisplayTime and not child.__removeAura
                cooldownFrame:SetUseAuraDisplayTime(not useAura)
                cooldownFrame:SetUseAuraDisplayTime(useAura)
            end
        end
    end
end
function Addon.SetBorderColor(button, color)
    if not button or not color then return end
    if button.__iconBorder then
        button.__iconBorder:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
    end
    if button.__barBorder then
        button.__barBorder:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
    end
end

function Addon.UpdateBorderColor(button, barName)
    if not Addon:GetValue("UseCDMBackdrop", nil, barName) then return end
    if button.__isOnAura and not button.__removeAura and Addon:GetValue("UseCDMBackdropAuraColor", nil, barName) then
        Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropAuraColor", nil, barName)})
    elseif Addon:GetValue("UseCDMBackdropColor", nil, barName) then
        Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, barName)})
    end
end

local CooldownManagerFrames = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
}
local function Hook_OnCooldownDone(self)
    local button = self:GetParent()

    if not button.__cooldownSet then return end

    local bar = button:GetParent()
    local barName = bar:GetName()

    button.__cooldownSet = nil
    button.__isOnGCD = false
    button.__isOnActualCooldown = false
    button.__isOnAura = false

    Addon.RefreshDesaturationOnCooldownOnly(button)

    Addon.UpdateBorderColor(button, barName)

    OnButtonVisibilityChanged(button)
end

local function OnCooldownClear(cooldownFrame, button)
    if not cooldownFrame or not button then return end

    local bar = button:GetParent()
    local barName = bar and bar:GetName() or ""

    if not button.__cooldownSet then return end

    button.__cooldownSet = nil
    button.__isOnGCD = false
    button.__isOnActualCooldown = false
    button.__isOnAura = false

    Addon.UpdateBorderColor(button, barName)

    OnButtonVisibilityChanged(button)
end

local function CheckCooldownState(button)
    local barFrame = button:GetParent()
    local barName = barFrame:GetName()
    if barName == "BuffIconCooldownViewer" then 
        button.__isOnAura = true
        --button:GetCooldownFrame():SetReverse(Addon:GetValue("CDMReverseSwipe", nil, barName))
        --HUI_CDMCustomized:RefreshCooldownFrame(button, barName)
        return
    end
    if not button.cooldownUseAuraDisplayTime or button.__removeAura then
        if (button.isOnGCD and not button.isOnActualCooldown) then
            button.__isOnGCD = true
        else
            if not button.wasSetFromCharges then
                button.__isOnActualCooldown = true
            else
                button.__isOnActualCooldown = false
            end
        end
    end
end

function CooldownManagerEnhanced:ApplyCooldownFormatter(cooldownFrame, button, barFrame, barName, forceUpdate)
    local useAuraTimerColor = Addon:GetValue("UseCDMAuraTimerColor", nil, barName)
    local auraColorized = Addon:GetValue("ColorizedAuraFont", nil, barName)

    if not button.__removeAura and button.__isOnAura and (useAuraTimerColor or auraColorized) then
        local color = { r=1, g=1, b=1, a=1 }
        if not barFrame.__auraColor then
            barFrame.__auraColor = { r=1, g=1, b=1, a=1 }
        end
        local needUpdAuraFormatter = false
        if useAuraTimerColor then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CDMAuraTimerColor", nil, barName)
        end
        if not tCompare(color, barFrame.__auraColor) then
            barFrame.__auraColor = color
            needUpdAuraFormatter = true
        end
        if auraColorized then
            if not barFrame.__auraFormatterColored or needUpdAuraFormatter or forceUpdate then
                barFrame.__auraFormatterColored = Addon:GetNumberFormatter(barFrame.__auraColor, nil, nil, barFrame.__formatType, barFrame.__formatOptions)
            end
            cooldownFrame:SetCountdownFormatter(barFrame.__auraFormatterColored)
        else
            if not barFrame.__auraFormatter or needUpdAuraFormatter or forceUpdate then
                barFrame.__auraFormatter = Addon:GetNumberFormatter(barFrame.__auraColor, barFrame.__auraColor, barFrame.__auraColor, barFrame.__formatType, barFrame.__formatOptions)
            end
            cooldownFrame:SetCountdownFormatter(barFrame.__auraFormatter)
        end
        --timerString:SetVertexColor(Addon:GetRGBA("CDMAuraTimerColor", nil, barName))
    else
        local needUpdCooldownFormatter = false
        if not barFrame.__cooldownColor then
            barFrame.__cooldownColor = { r=1, g=1, b=1, a=1 }
        end
        local color = { r=1, g=1, b=1, a=1 }
        if Addon:GetValue("UseCooldownFontColor", nil, barName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownFontColor", nil, barName)
        end
        if not tCompare(color, barFrame.__cooldownColor) then
            barFrame.__cooldownColor = color
            needUpdCooldownFormatter = true
        end
        if Addon:GetValue("ColorizedCooldownFont", nil, barName) then
            if not barFrame.__numberFormatterColored or needUpdCooldownFormatter or forceUpdate then
                barFrame.__numberFormatterColored = Addon:GetNumberFormatter(barFrame.__cooldownColor,nil,nil,barFrame.__formatType, barFrame.__formatOptions)
            end
            cooldownFrame:SetCountdownFormatter(barFrame.__numberFormatterColored)
        else
            if not barFrame.__numberFormater or needUpdCooldownFormatter or forceUpdate then
                barFrame.__numberFormater = Addon:GetNumberFormatter(barFrame.__cooldownColor, barFrame.__cooldownColor, barFrame.__cooldownColor,barFrame.__formatType, barFrame.__formatOptions)
            end
            cooldownFrame:SetCountdownFormatter(barFrame.__numberFormater)
        end
        --timerString:SetVertexColor(color.r,color.g,color.b,color.a)
    end
end

local function OnCooldownSet(cooldownFrame, button)
    if not cooldownFrame or not button then return end

    local barFrame = button:GetParent()
    local barName = barFrame:GetName()

    if not cooldownFrame then return end

    if barName == "BuffIconCooldownViewer" and button.__cooldownSet then
        cooldownFrame:SetSwipeColor(Addon:GetColor("CooldownColor", "UseCooldownColor", nil, barName))
        if Addon:GetValue("UseCDMBackdrop", nil, barName) then
            Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, barName)})
        end
        HUI_CDMCustomized:RefreshCooldownFrame(button, barName)

        button.__removeAura = Addon:GetValue("CDMAuraRemoveSwipe", nil, barName)
        local formatType = Addon:GetValue("CDMCooldownFormatType", nil, barName)
        local forceUpdate = barFrame.__formatType ~= formatType
        barFrame.__formatType = formatType
        local formatOptions = Addon:GetCooldownFormatOptions(barName)
        if not barFrame.__formatOptions or not tCompare(formatOptions, barFrame.__formatOptions) then
            forceUpdate = true
            barFrame.__formatOptions = formatOptions
        end
        CooldownManagerEnhanced:ApplyCooldownFormatter(cooldownFrame, button, barFrame, barName, forceUpdate)
        return
    end

    if not Addon:GetValue("CDMEnable", nil, barName) then return end

    button.__cooldownSet = true
    button.__isOnActualCooldown = false
    if not button.__cooldownDoneHooked then
        cooldownFrame:HookScript("OnCooldownDone", Hook_OnCooldownDone)
        button.__cooldownDoneHooked = true
    end

    local formatType = Addon:GetValue("CDMCooldownFormatType", nil, barName)
    local forceUpdate = false
    if barFrame.__formatType and barFrame.__formatType ~= formatType then
        forceUpdate = true
    end
    barFrame.__formatType = formatType

    local formatOptions = Addon:GetCooldownFormatOptions(barName)
    if not barFrame.__formatOptions or not tCompare(formatOptions, barFrame.__formatOptions) then
        forceUpdate = true
        barFrame.__formatOptions = formatOptions
    end

    local timerString = cooldownFrame:GetCountdownFontString()

    button.__removeAura = Addon:GetValue("CDMAuraRemoveSwipe", nil, barName)

    if button.cooldownUseAuraDisplayTime or button.pandemicAlertTriggerTime then
        button.__isOnAura = not button.__removeAura
        cooldownFrame:SetHideCountdownNumbers(false)

        if button.__removeAura then
            local duration = C_Spell.GetSpellChargeDuration(button:GetSpellID()) or C_Spell.GetSpellCooldownDuration(button:GetSpellID())
            cooldownFrame:SetUseAuraDisplayTime(false)
            cooldownFrame:Clear()
            cooldownFrame:SetSwipeColor(Addon:GetColor("CooldownColor", "UseCooldownColor", nil, barName))
            cooldownFrame:SetCooldownFromDurationObject(duration, true)
            CheckCooldownState(button)
        end

        if not button.__removeAura then
            cooldownFrame:SetSwipeColor(Addon:GetColor("CooldownAuraColor", "UseCooldownAuraColor", nil, barName))
        end
        if not button.__isInPandemic then
            Addon.UpdateBorderColor(button, barName)
        end

        EventRegistry:TriggerEvent("CDMCustomItem.AddAura", button)
    else
        button.__isOnAura = false
        cooldownFrame:SetSwipeColor(Addon:GetColor("CooldownColor", "UseCooldownColor", nil, barName))
        Addon.UpdateBorderColor(button, barName)
        
        CheckCooldownState(button)

        if (button.isOnGCD and not button.isOnActualCooldown and not button.wasSetFromCharges) and Addon:GetValue("CDMRemoveGCDSwipe", nil, barName) then
            cooldownFrame:Clear()
        end
        if button.wasSetFromCharges then
            local showCountdonwNumbers =  Addon:GetValue("ShowCountdownNumbersForCharges", nil, barName)
            cooldownFrame:SetHideCountdownNumbers(not showCountdonwNumbers)
        end
    end
    --cooldownFrame:SetCountdownFormatter(Addon.numberFormatter)

    CooldownManagerEnhanced:ApplyCooldownFormatter(cooldownFrame, button, barFrame, barName, forceUpdate)

    HUI_CDMCustomized:RefreshCooldownFrame(button, barName)
end

local function OnRefreshCooldownInfo(button)
    local barFrame = button:GetParent()
    local barName = barFrame:GetName()

    if barName == "BuffBarCooldownViewer" then return end

    local cooldownFrame = button:GetCooldownFrame()

    if not cooldownFrame then return end

    if barName ~= "BuffIconCooldownViewer" then
        if not button.__removeAura and button.__isOnAura then
            cooldownFrame:SetSwipeColor(Addon:GetColor("CooldownAuraColor", "UseCooldownAuraColor", nil, barName))
        end
    end
    if not button.__isOnAura then
        cooldownFrame:SetSwipeColor(Addon:GetColor("CooldownColor", "UseCooldownColor", nil, barName))
    end
    HUI_CDMCustomized:RefreshCooldownFrame(button, barName)

    OnButtonVisibilityChanged(button)
end

local function tContainsByIndex(table, item)
    for index, data in ipairs(table) do
        if data.layoutIndex == item.layoutIndex then
            return index
        end
    end
    return false
end

local function CheckItemVisibility(child, isVisible, frame)
    if not frame then
        frame = child:GetParent()
    end

    local frameName = frame:GetName()
    --[[ local frameName = frame:GetName()

    if frameName == "BuffBarCooldownViewer" or frameName == "BuffIconCooldownViewer" then
        if child:IsVisible() then
            child.__isActive = true
        else
            child.__isActive = false
        end
        return
    end ]]

    if child.__hideType == 3 then
        if child.__isOnActualCooldown or child.__isOnAura or child.wasSetFromCharges then
            child.__isActive = true
        else
            child.__isActive = false
        end
    elseif child.__hideType == 2 then
        if child.__isOnAura then
            child.__isActive = true
        else
            child.__isActive = false
        end
    elseif child.__hideType == 1 then
        child.__isActive = nil
    end
end

function OnButtonVisibilityChanged(child)
    local isVisible = child:IsVisible()
    local frame = child:GetParent()
    local frameName = frame:GetName()
    if not Addon:GetValue("CDMEnable", nil, frameName) then
        return
    end

    --BuffIconCooldownViewer doesn't have RefreshIconColor so put it here
    if frame:GetName() == "BuffIconCooldownViewer" then
        Addon.OnButtonRefreshIconColor(child)
    end

    CheckItemVisibility(child, isVisible, frame)

    if frame.RefreshLayoutGrid then
        frame:RefreshLayoutGrid()
    end
end

function Addon.RefreshDesaturation(self)
    if not self or self.__desaturated == nil then return end
    local frameName = self:GetParent():GetName()

    if Addon:GetValue("CDMRemoveDesaturation", nil, frameName) then
        self.__desaturated = false
    end
    local icon = self:GetIconTexture()
    icon:SetDesaturated(self.__desaturated)
end
local function PackRGBA(color)
    return {r=color[1], g=color[2], b=color[3], a=color[4]}
end
local function SetVertexColorFromSecret(region, secret, color, reason, reverse)
    color = color or {1,1,1,1}

    local fallbackColor = {region:GetVertexColor()}

    if not reverse then
        region:SetVertexColorFromBoolean(secret, PackRGBA(color), PackRGBA(fallbackColor))
    else
        region:SetVertexColorFromBoolean(secret, PackRGBA(fallbackColor), PackRGBA(color))
    end
end
local function GetColorFromSecret(region, secret, color, reverse)
    local fallbackColor = {region:GetVertexColor()}

    local secretColor

    if not reverse then
        secretColor = C_CurveUtil.EvaluateColorFromBoolean(secret, PackRGBA(color), PackRGBA(fallbackColor))
    else
        secretColor = C_CurveUtil.EvaluateColorFromBoolean(secret, PackRGBA(fallbackColor), PackRGBA(color))
    end
    return secretColor
end

function Addon.OnButtonRefreshIconColor2(self)
    local spellID = self:GetSpellID()
    if not spellID then
        return
    end

    local frame = self:GetParent()
    local frameName = frame:GetName()
    local iconTexture = self:GetIconTexture()
    local outOfRangeTexture = self.GetOutOfRangeTexture and self:GetOutOfRangeTexture() or nil

    local normalColor = Addon:GetValue("UseNormalColor", nil, frameName) and {Addon:GetRGBA("NormalColor", nil, frameName)} or {1, 1, 1, 1}
    local color = {1, 1, 1, 1}

    local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellID)

    iconTexture:SetVertexColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4])
    --iconTexture:SetVertexColor(color[1], color[2], color[3], color[4])

    if not self.__removeAura and self.__isOnAura and Addon:GetValue("UseAuraColor", nil, frameName) then
        color = {Addon:GetRGBA("AuraColor", nil, frameName)}
        --SetVertexColorFromSecret(iconTexture, self.__isOnAura, color, "AuraColor")
        color = GetColorFromSecret(iconTexture, self.__isOnAura, color)
    end
    if Addon:GetValue("UseOOMColor", nil, frameName) then
        color = {Addon:GetRGBA("OOMColor", nil, frameName)}
        --SetVertexColorFromSecret(iconTexture, notEnoughMana, color, "OOMColor")
        color = GetColorFromSecret(iconTexture, notEnoughMana, color)
    end
    if Addon:GetValue("UseNoUseColor", nil, frameName) then
        color = {Addon:GetRGBA("NoUseColor", nil, frameName)}
        local reverse = true
        --SetVertexColorFromSecret(iconTexture, isUsable, color, "NoUseColor", reverse)
        color = GetColorFromSecret(iconTexture, notEnoughMana, color, reverse)
    end
    if self.__isOnGCD and Addon:GetValue("UseGCDColor", nil, frameName) then
        color = {Addon:GetRGBA("GCDColor", nil, frameName)}
        --SetVertexColorFromSecret(iconTexture, self.__isOnGCD, color, "GCDColor")
        color = GetColorFromSecret(iconTexture,  self.__isOnGCD, color)
    end
    if self.__isOnActualCooldown and Addon:GetValue("UseCDColor", nil, frameName) then
        color = {Addon:GetRGBA("CDColor", nil, frameName)}
        --SetVertexColorFromSecret(iconTexture, self.__isOnActualCooldown, color, "CDColor")
        color = GetColorFromSecret(iconTexture,  self.__isOnActualCooldown, color)
    end
    if self.spellOutOfRange ~= nil and Addon:GetValue("UseOORColor", nil, frameName) then
        color = {Addon:GetRGBA("OORColor", nil, frameName)}
        --SetVertexColorFromSecret(iconTexture, self.spellOutOfRange, color, "OORColor")
        color = GetColorFromSecret(iconTexture,  self.spellOutOfRange, color)
    end
    iconTexture:SetVertexColor(color.r, color.g, color.b, color.a)
    Addon.RefreshDesaturation(self)
end

function Addon.OnButtonRefreshIconColor(self)
    local spellID = self:GetSpellID()
    if not spellID then
        return
    end
    
    local frame = self:GetParent()
    local frameName = frame:GetName()
    local iconTexture = self:GetIconTexture()
    local outOfRangeTexture = self.GetOutOfRangeTexture and self:GetOutOfRangeTexture() or nil
    
    local color = {1, 1, 1, 1}

    --todo rewrite for SetVertexColorFromBoolean

    local iconColor = {iconTexture:GetVertexColor()}
    if iconColor then
        for i, number in pairs(iconColor) do
            iconColor[i] = RoundToSignificantDigits(number, 2)
        end
    end
    
    local OORColor = CooldownManagerEnhanced.constants.OORColor
    local OOMColor = CooldownManagerEnhanced.constants.OOMColor
    local NUColor = CooldownManagerEnhanced.constants.NUColor
    
    local OORCheck = false
    local NUCheck = false
    local OOMCheck = false

    if (iconColor[1] == OORColor[1] and iconColor[2] == OORColor[2] and iconColor[3] == OORColor[3]) then
        OORCheck = true
    elseif (iconColor[1] == NUColor[1] and iconColor[2] == NUColor[2] and iconColor[3] == NUColor[3]) then
        NUCheck = true
    elseif (iconColor[1] == OOMColor[1] and iconColor[2] == OOMColor[2] and iconColor[3] == OOMColor[3]) then
        OOMCheck = true
    end

    if self.__isOnActualCooldown and Addon:GetValue("UseCDColor", nil, frameName) then
        color = {Addon:GetRGBA("CDColor", nil, frameName)}
        self.__desaturated = Addon:GetValue("CDColorDesaturate", nil, frameName)

    elseif Addon:GetValue("UseOORColor", nil, frameName) and OORCheck then
        color = {Addon:GetRGBA("OORColor", nil, frameName)}
        if outOfRangeTexture then
            outOfRangeTexture:SetTexture("Interface/AddOns/HUI/assets/empty.png")
            outOfRangeTexture:SetShown(false)
        end
        self.__desaturated = Addon:GetValue("OORDesaturate", nil, frameName)
    
    elseif self.__isOnGCD and Addon:GetValue("UseGCDColor", nil, frameName) then
        color = {Addon:GetRGBA("GCDColor", nil, frameName)}
        self.__desaturated = Addon:GetValue("GCDColorDesaturate", nil, frameName)
    
    elseif not self.__removeAura and self.__isOnAura and Addon:GetValue("UseAuraColor", nil, frameName) then
        color = {Addon:GetRGBA("AuraColor", nil, frameName)}
        self.__desaturated = Addon:GetValue("AuraColorDesaturate", nil, frameName)
    else
        if Addon:GetValue("UseNoUseColor", nil, frameName) and NUCheck then
            color = {Addon:GetRGBA("NoUseColor", nil, frameName)}
            self.__desaturated = Addon:GetValue("NoUseDesaturate", nil, frameName)
        
        elseif Addon:GetValue("UseOOMColor", nil, frameName) and OOMCheck then
            color = {Addon:GetRGBA("OOMColor", nil, frameName)}
            self.__desaturated = Addon:GetValue("OOMDesaturate", nil, frameName)
        
        else
            if Addon:GetValue("UseNormalColor", nil, frameName) then
                color = {Addon:GetRGBA("NormalColor", nil, frameName)}
                self.__desaturated = Addon:GetValue("NormalColorDesaturate", nil, frameName)
            else
                self.__desaturated = false
            end
        end
    end

    iconTexture:SetVertexColor(color[1], color[2], color[3], color[4])
    Addon.RefreshDesaturation(self)
end

function Addon.RefreshDesaturationOnCooldownOnly(self)
    if self.spellOutOfRange == true then return end

    local frame = self:GetParent()
    local frameName = frame:GetName()

    local iconTexture = self:GetIconTexture()

    if self.__isOnActualCooldown and Addon:GetValue("UseCDColor", nil, frameName) then
        self.__desaturated = Addon:GetValue("CDColorDesaturate", nil, frameName)
    elseif self.__isOnGCD and Addon:GetValue("UseGCDColor", nil, frameName) then
        self.__desaturated = Addon:GetValue("GCDColorDesaturate", nil, frameName)
    else
        if not self.__removeAura and self.__isOnAura and Addon:GetValue("UseAuraColor", nil, frameName) then
            self.__desaturated = Addon:GetValue("AuraColorDesaturate", nil, frameName)
        elseif Addon:GetValue("UseNormalColor", nil, frameName) then
            self.__desaturated = Addon:GetValue("NormalColorDesaturate", nil, frameName)
        else
            self.__desaturated = false
        end
    end

    Addon.RefreshDesaturation(self)
end

local function OnButtonRefreshIconDesaturation(self)
    local frame = self:GetParent()
    local frameName = frame:GetName()

    local iconTexture = self:GetIconTexture()
    
    Addon.RefreshDesaturation(self)
end

--[[ local function OnTriggerAvailableAlert(self)
    --for future visible alert hook

    local alertFrame = self:GetAlertContainer()
    for index, alert in pairs(alertFrame) do
        if alert.Flipbook or alert.Glow then
            alert.durationSeconds = 10
            alert:ClearAllPoints()
            alert:SetPoint("CENTER", self, "CENTER", 0, 0)
            alert:SetSize(self:GetSize())
            alert:SetScale(1.5)
            --alert.Flipbook:SetLooping("REPEAT")
        end
    end
end ]]

local function OnUpdateFromAuraData(self, auraData)
    local frameName = self:GetParent():GetParent():GetName()
    if auraData and Addon:GetValue("CDMRemoveAuraTypeBorder", nil, frameName) then
        self:Hide()
    end
end

local function OnUpdateButton(child, elapsed)

    local parentFrame = child:GetParent()
    local parentName = parentFrame:GetName()
    if not child:IsVisible() then return end

    if child.__isOnAura then return end
    if not child.Cooldown then return end

    local cooldownFrame = child.Cooldown

    local fontString = cooldownFrame:GetCountdownFontString()

    if not fontString or not fontString:IsVisible() then return end

    local spellID = child:GetSpellID()
    if not spellID then return end

    local durationObj = C_Spell.GetSpellChargeDuration(spellID) or C_Spell.GetSpellCooldownDuration(spellID)
    if durationObj then
        local EvaluateDuration = durationObj.EvaluateRemainingDuration and durationObj:EvaluateRemainingDuration(parentFrame.cooldownColorCurve) or nil

        if EvaluateDuration and not child.__isOnGCD then
            fontString:SetVertexColor(EvaluateDuration:GetRGBA())
        end
        
    end
end

--[[ local function OnRefreshActive(self, spellID)
    if self.__isOnActualCooldown then
        self:Show()
    else
        self:Hide()
    end
    OnButtonVisibilityChanged(self)
end ]]

local function Hook_OnEnter(self)
    local frame = self:GetParent()
    if frame.fade then
        Addon:Fade(frame, true)
    end
end
local function Hook_OnLeave(self)
    local frame = self:GetParent()
    if frame.fade then
        Addon:Fade(frame, false)
    end
end
local function Hook_OnAuraInstanceInfoSet(self, auraSpellID,  auraInstanceID )

    --print("Hook_OnAuraInstanceInfoSet", self:GetBaseSpellID(), auraSpellID, auraInstanceID )
end

local function Hook_Layout(self)
    if self.__locked then
        return
    end
    self.__locked = true
    --[[ if EditModeManagerFrame:IsEditModeActive() or CooldownViewerSettings:IsVisible() then
        return
    end ]]

    local frameName = self:GetName()

    if not Addon:GetValue("CDMEnable", nil, frameName) then
        self.__locked = false
        return
    end

    if not frameName or not tContains(CooldownManagerFrames, frameName) then
        self.__locked = false
        return
    end

    local forceUpdate = CooldownManagerEnhanced.forced == frameName

    if (not self.__layoutFramesGoingUp or not self.__layoutFramesGoingRight) or forceUpdate then
        self.__layoutFramesGoingUp = Addon:GetValue("CDMVerticalGrowth", nil, frameName)
        self.__layoutFramesGoingRight = Addon:GetValue("CDMHorizontalGrowth", nil, frameName)
    end
    
    self.__padding = self.childXPadding or self.childYPadding

    if not self.grildLayoutType or forceUpdate then
        self.gridLayoutType = Addon:GetValue("CDMGridLayoutType", nil, frameName)
    end

    local layoutChildren = self:GetLayoutChildren()
    if not forceUpdate and not self:ShouldUpdateLayout(layoutChildren) then
        self.__locked = false
        return
    end

    for _, child in ipairs(layoutChildren) do

        if child:HasEditModeData() then
            self.__locked = false
            return
        end

        child.__hideType = Addon:GetValue("CurrentHideWhenInactive", nil, frameName)
        if child.__hideType ~= 1 and child.__isActive == nil then
            child.__isActive = false
        end
        --for future visible alert hook

        --[[ if child.TriggerAvailableAlert and not child.__alertHook then
            hooksecurefunc(child, "TriggerAvailableAlert", OnTriggerAvailableAlert)
            child.__alertHook = true
        end ]]

        --CheckItemVisibility(child, child:IsVisible(), self)

        if not child.__hooked and Addon:GetValue("CDMEnable", nil, frameName) then
            if child.RefreshData then
                hooksecurefunc(child, "RefreshData", OnButtonVisibilityChanged)
            end
            if child.Cooldown and child.Cooldown.SetCooldown then
                hooksecurefunc(child.Cooldown, "SetCooldown", function(self)
                    OnCooldownSet(self, child)
                end)
                hooksecurefunc(child.Cooldown, "Clear", function(self)
                    OnCooldownClear(self, child)
                end)
            end
            if child.RefreshCooldownInfo then
                hooksecurefunc(child, "RefreshCooldownInfo", OnRefreshCooldownInfo)
            end
            if child.RefreshSpellCooldownInfo then
                hooksecurefunc(child, "RefreshSpellCooldownInfo", OnRefreshCooldownInfo)
            end
            if child.UpdateShownState and not child.__updateShownHooked then
                hooksecurefunc(child, "UpdateShownState", function(self)
                    if self.__hideType and self.__hideType ~= 1 and self.__isActive == false
                        and not self.__isEditing
                        and not EditModeManagerFrame:IsEditModeActive()
                        and not CooldownViewerSettings:IsVisible() then
                        self:SetShown(false)
                    end
                end)
                child.__updateShownHooked = true
            end
            if child.OnEnter then
                child:HookScript("OnEnter", Hook_OnEnter)
            end
            if child.OnLeave then
                child:HookScript("OnLeave", Hook_OnLeave)
            end
            --[[ if child.OnAuraInstanceInfoSet then
                hooksecurefunc(child, "OnAuraInstanceInfoSet", Hook_OnAuraInstanceInfoSet)
            end ]]
            child.__hooked = true
        end
        --[[ if not child.__onUpdateHooked and Addon:GetValue("ColorizedCooldownFont", nil, frameName) then
            if child.OnUpdate and frameName ~= "BuffIconCooldownViewer" then --"BuffIconCooldownViewer" have weird behavior right now
                child:HookScript("OnUpdate", OnUpdateButton)
            end
            child.__onUpdateHooked = true
        end ]]

        if not child.__refreshIconHook then
            if child.RefreshIconColor then
                hooksecurefunc(child, "RefreshIconColor", Addon.OnButtonRefreshIconColor)
            end
            if child.RefreshIconDesaturation then
                hooksecurefunc(child, "RefreshIconDesaturation", OnButtonRefreshIconDesaturation)  
            end
            if child.RefreshCooldownOnly then
                --hooksecurefunc(child, "RefreshCooldownOnly", OnButtonRefreshIconDesaturation)
            end
            child.__refreshIconHook = true
        end
        
        if Addon:GetValue("UseCDMBackdrop", nil, frameName) then
            if child.Icon and not child.__iconBorder then
                child.__iconBorder = Addon.CreateBorder(child.Icon, frameName)
                child.__iconBorder:Show()
            elseif child.Icon and child.__iconBorder then
                if forceUpdate then
                    Addon.SetBackdropBorderSize(child.__iconBorder, Addon:GetValue("CDMBackdropSize", nil, frameName))
                    child.__iconBorder:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropColor", nil, frameName))
                end
                child.__iconBorder:Show()
            end
            if child.Bar and not child.__barBorder then
                child.__barBorder = Addon.CreateBorder(child.Bar, frameName)
                child.__barBorder:Show()
            elseif child.Bar and child.__barBorder then
                if forceUpdate then
                    Addon.SetBackdropBorderSize(child.__barBorder, Addon:GetValue("CDMBackdropSize", nil, frameName))
                    child.__barBorder:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropColor", nil, frameName))
                end
                child.__barBorder:Show()
            end
        else
            if child.__barBorder then
                child.__barBorder:Hide()
                child.__barBorder = nil
            end
            if child.__iconBorder then
                child.__iconBorder:Hide()
                child.__iconBorder = nil
            end
        end

        if child.Cooldown and (not child.__cooldown or forceUpdate) then
            HUI_CDMCustomized:RefreshCooldownFont(child, frameName)
            child.__cooldown = true
        end
        
        local stacksFrame = child.Applications or child.ChargeCount
        local stacksString = stacksFrame and (stacksFrame.Applications or stacksFrame.Current) or child.Icon.Applications
        if stacksString and (not child.__stacksString or forceUpdate) then
            HUI_CDMCustomized:RefreshStacksFont(child, frameName)
            child.__stacksString = true
        end

        if Addon:GetValue("CDMUseItemSize", nil, frameName) and (not child.__sizeHooked or forceUpdate) then
            HUI_CDMCustomized:RefreshItemSize(child, frameName)
            child.__sizeHooked = true
        end

        if child.DebuffBorder and not child.__debuffBorderHooked then
            if child.DebuffBorder.UpdateFromAuraData then
                hooksecurefunc(child.DebuffBorder, "UpdateFromAuraData", OnUpdateFromAuraData)
                child.__debuffBorderHooked = true
            end
        end
        

        if frameName == "BuffBarCooldownViewer" then
            
            --self.layoutFramesGoingUp = Addon:GetValue("CDMVerticalGrowth", nil, frameName) == 1

            if child.Bar and (not child.__barHooked or forceUpdate) then

                HUI_CDMCustomized:RefreshBar(child, frameName)

                child.__barHooked = true
            end
            local barColor = Addon:GetValue("BuffBar"..child.layoutIndex, nil, "BuffBarCooldownViewer")
            if barColor then
                child.Bar:SetStatusBarColor(barColor.r, barColor.g, barColor.b, barColor.a)
            else
                child.Bar:SetStatusBarColor(1, 1, 1, 1)
            end
            

            --child.Icon:Hide()
            if Addon:GetValue("UseCDMBarOffset", nil, frameName) then
                child.Bar:ClearAllPoints()
                local offset = Addon.PP.Scale(Addon:GetValue("CDMBarOffset", nil, frameName))
                child.Bar:SetPoint("LEFT", child, "LEFT", offset, 0)
                child.Bar:SetPoint("RIGHT", child, "RIGHT")
            else
                child.Bar:SetPoint("LEFT", child.Icon, "RIGHT", Addon.PP.Scale(2), 0)
                child.Bar:SetPoint("RIGHT", child, "RIGHT")
            end

            local invert = false
            if invert then
                child.Icon:ClearAllPoints()
                child.Icon:SetPoint("RIGHT", child, "RIGHT")
                child.Bar:ClearAllPoints()
                child.Bar:SetPoint("LEFT", child, "LEFT")
                child.Bar:SetPoint("RIGHT", child.Icon, "LEFT", Addon.PP.Scale(-2), 0)
                local statusBarTexture = child.Bar:GetStatusBarTexture()
                child.Bar:SetReverseFill(true)
                child.Bar.Pip:ClearAllPoints()
                child.Bar.Pip:SetPoint("CENTER", statusBarTexture, "LEFT")
            end        
        end

        if Addon:GetValue("CurrentIconMaskTexture", nil, frameName) > 1 and (not child.__iconHooked or forceUpdate) then

            HUI_CDMCustomized:RefreshIconMask(child, frameName)

            child.__iconHooked = true
        end
    end

    if #layoutChildren == 0 then
        CooldownManagerEnhanced.forced = nil
        self.__locked = false
        return
    end

    self.keepEmpty = self.gridLayoutType == 3
    self.__wasVisibleChildren = nil
    self.__visibleChildren = layoutChildren
    --self.alwaysUpdateLayout = false
    if not self.RefreshLayoutGrid then
        self.RefreshLayoutGrid = function(self)
            local frameName = self:GetName()
            local layoutChildren = self:GetLayoutChildren()
            local stride = self.stride
            local padding = self.__padding

            if self.gridLayoutType == 1 then
                Addon:ApplyCenteredGridLayout(self, layoutChildren, stride, padding)
                if not InCombatLockdown() then
                    Addon:ResizeLayout(self, layoutChildren)
                end
                self:CacheLayoutSettings(layoutChildren)
            else
                Addon:ApplyStandardGridLayout(self, layoutChildren, stride, padding)
                if not InCombatLockdown() then
                    Addon:ResizeLayout(self, layoutChildren)
                end
                self:CacheLayoutSettings(layoutChildren)
            end
        end
    end

    self:RefreshLayoutGrid()    

    self.__locked = false
    CooldownManagerEnhanced.forced = nil
end

local function IterateAllAnimationGroups(frame, func)
	local animGroups = { frame:GetAnimationGroups() }
	for _, animGroup in ipairs(animGroups) do
		func(animGroup)
	end

	local children = { frame:GetChildren() }
	for _, child in ipairs(children) do
		IterateAllAnimationGroups(child, func)
	end
end


local function Hook_SetupPandemic(self, frame, cooldownItem)
    if frame then
        local button = frame:GetParent()
        local frameName = button:GetParent():GetName()

        if not Addon:GetValue("CDMEnable", nil, frameName) then
            return
        end

        if not button.__isInPandemic then
            if Addon:GetValue("CDMRemovePandemic", nil, frameName) then
                if not frame.__pandemicRemoved then
                    frame.Border.Border:SetTexture("")
                    IterateAllAnimationGroups(frame, function(animGroup)
                        if animGroup then
                            animGroup:RemoveAnimations()
                        end
                    end)
                    if frameName ~= "BuffBarCooldownViewer" then
                        frame.FX:Hide()
                    else
                        frame.Texture:Hide()
                    end
                    frame.__pandemicRemoved = true
                end
            end
            if Addon:GetValue("UseCDMBackdropPandemicColor", nil, frameName) then
                Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropPandemicColor", nil, frameName)})
            end

            button.__isInPandemic = true
        end

    end
end
local function Hook_HidePandemic(self, frame)
    local button = frame:GetParent()
    local frameName = button:GetParent():GetName()

    if not Addon:GetValue("CDMEnable", nil, frameName) then
        return
    end

    if button.__isInPandemic then
        if not button.__hidePandemicScheduled then
            button.__hidePandemicScheduled = true
            C_Timer.After(0.0, function()
                button.__hidePandemicScheduled = false
                
                if button.PandemicIcon and button.PandemicIcon:IsVisible() then
                    return
                end

                button.__isInPandemic = nil
                Addon.UpdateBorderColor(button, frameName)
            end)
        end
    end
end

function Addon:CDM_SetHooks()
    for _, frameName in ipairs(CooldownManagerFrames) do
        local frame = _G[frameName]
        if Addon:GetValue("CDMEnable", nil, frameName) and not frame.__HooksSet then
            if frame and frame.Layout then
                hooksecurefunc(frame, "Layout", Hook_Layout)
                C_Timer.After(0, function()
                    frame:Layout()
                end)
            end
            if frame and frame.SetupPandemicStateFrameForItem then
                hooksecurefunc(frame, "AnchorPandemicStateFrame", Hook_SetupPandemic)
            end
            if frame and frame.HidePandemicStateFrame then
                hooksecurefunc(frame, "HidePandemicStateFrame", Hook_HidePandemic)
            end
            frame.__HooksSet = true
        end
    end
end

local function RegisterCDMHooks()
    EventRegistry:RegisterCallback("CooldownViewerSettings.OnDataChanged", function()
        Addon:CDM_SetHooks()
    end, CooldownManagerEnhanced)
end

if CooldownViewerSettings then
    RegisterCDMHooks()
else
    Addon:RegisterEvent("PLAYER_LOGIN", RegisterCDMHooks, "CooldownManagerView")
end