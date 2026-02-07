local AddonName, Addon = ...

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

function CooldownManagerEnhanced:ForceUpdate(frameName)
    if not frameName then return end

    CooldownManagerEnhanced.forced = frameName
    local frame = _G[frameName]
    
    frame:Layout()
    --frame:RefreshData()
    --frame:UpdateShownState()
    CooldownManagerEnhanced.forced = nil
end

local COLOR_PRIORITY = {
    ["default"]   = 0,
    ["aura"]      = 1,
    ["pandemic"]  = 2,
    ["reset"]     = 3,
}

function Addon.SetBorderColor(button, color, state)
    if not button or not color or not state then return end

    do
        if button.__iconBorder then
            button.__iconBorder:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
        end
        if button.__barBorder then
            button.__barBorder:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
        end
        
        return
    end

    local newPriority = COLOR_PRIORITY[state]
    if not newPriority then
        return
    end

    local currentPriority = button.__borderColorState or -1
    
    if newPriority == currentPriority then return end

    if newPriority >= currentPriority then
        if button.__iconBorder then
            button.__iconBorder:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
        end
        if button.__barBorder then
            button.__barBorder:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
        end

        button.__borderColorState = newPriority < 3 and newPriority or -1
    end
end


function Addon.SetBackdropBorderSize(frame, borderSize)
    local parent = frame:GetParent()
    local ppBorderSize = PixelUtil.ConvertPixelsToUIForRegion(borderSize, frame)

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    frame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = ppBorderSize,
    })
end

function Addon.CreateBorder(frame, frameName)
    if frame:GetObjectType() == "Texture" then
        frame = frame:GetParent()
    end
    local edgeSize = Addon:GetValue("CDMBackdropSize", nil, frameName) > 0 and Addon:GetValue("CDMBackdropSize", nil, frameName) or 1
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    Addon.SetBackdropBorderSize(border, edgeSize)
    border:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropColor", nil, frameName))
    frame:SetClampedToScreen(false)
    
    return border
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
    
    local frame = button:GetParent()
    local frameName = frame:GetName()
    
    button.__cooldownSet = nil
    button.__isOnGCD = false
    button.__isOnActualCooldown = false
    button.__isOnAura = false

    if Addon:GetValue("UseCDMBackdrop", nil, frameName) then
        Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, frameName)}, "reset")
    end
end

--[[ local function Hook_CooldownFrame_Clear(self)
     if not self then return end
    local button = self:GetParent()
    if not button then return end

    if not button.__cooldownSet then return end

    local bar = button:GetParent()
    local barName = bar and bar:GetName() or ""

    if bar and tContains(CooldownManagerFrames, barName) then

        button.__cooldownSet = nil
        button.__isOnGCD = false
        button.__isOnActualCooldown = false
        button.__isOnAura = false

        if Addon:GetValue("UseCDMBackdrop", nil, barName) then
            Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, barName)}, "reset")
        end
    end
end ]]

local function OnCooldownClear(cooldownFrame, button)
    if not cooldownFrame or not button then return end

    if not button.__cooldownSet then return end

    local bar = button:GetParent()
    local barName = bar and bar:GetName() or ""

    button.__cooldownSet = nil
    button.__isOnGCD = false
    button.__isOnActualCooldown = false
    button.__isOnAura = false

    if Addon:GetValue("UseCDMBackdrop", nil, barName) then
        Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, barName)}, "reset")
    end
end

local function CheckCooldownState(button)
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

local function OnCooldownSet(cooldownFrame, button)
    if not cooldownFrame or not button then return end

    local barFrame = button:GetParent()
    local barName = barFrame:GetName()

    if not cooldownFrame then return end

    if not Addon:GetValue("CDMEnable", nil, barName) then return end
    button.__isOnActualCooldown = false
    if not button.__cooldownDoneHooked then
       cooldownFrame:HookScript("OnCooldownDone", Hook_OnCooldownDone)
        button.__cooldownDoneHooked = true
    end

    local timerString
    if not isBeta then
        if not cooldownFrame.__timer then
            local cdRegions = { cooldownFrame:GetRegions() }
            if cdRegions then
                for i, region in ipairs(cdRegions) do
                    if region:IsObjectType("FontString") then
                        cooldownFrame.__timer = region
                        break
                    end
                end
            end
            cooldownFrame:SetCooldownFromDurationObject(duration, true)
            
            CheckCooldownState(button)
        end
        timerString = cooldownFrame.__timer
    else
        timerString = cooldownFrame:GetCountdownFontString()
    end

    button.__cooldownSet = true
    if button.cooldownUseAuraDisplayTime or button.pandemicAlertTriggerTime then
        button.__isOnAura = true

        if Addon:GetValue("UseCDMAuraSwipeColor", nil, barName) then
            cooldownFrame:SetSwipeColor(Addon:GetRGBA("CDMAuraSwipeColor", nil, barName)) 
        end
        if Addon:GetValue("UseCDMBackdropAuraColor", nil, barName) and not button.__isInPandemic then
            Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropAuraColor", nil, barName)}, "aura")
        end
        if Addon:GetValue("UseCDMAuraTimerColor", nil, barName) then
            timerString:SetVertexColor(Addon:GetRGBA("CDMAuraTimerColor", nil, barName)) 
        else
            timerString:SetVertexColor(1,1,1,1)
        end

        cooldownFrame:SetReverse(Addon:GetValue("CDMAuraReverseSwipe", nil, barName))
    else
        button.__isOnAura = false

        if Addon:GetValue("UseCDMSwipeColor", nil, barName) then
            cooldownFrame:SetSwipeColor(Addon:GetRGBA("CDMSwipeColor", nil, barName))
        end
        if Addon:GetValue("UseCDMBackdrop", nil, barName) then
            Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, barName)}, "reset")
        end
        
        if not isBeta then
            local spellID = button:GetSpellID()
            button.__isOnGCD, button.__isOnActualCooldown = Addon:IsSpellOnGCD(spellID)
            if (button.__isOnGCD and not button.__isOnActualCooldown) and Addon:GetValue("CDMRemoveGCDSwipe", nil, barName) then
                cooldownFrame:SetSwipeColor(0,0,0,0)
            end
        else
            if (button.isOnGCD and not button.isOnActualCooldown) then
                button.__isOnGCD = true
            else
                if not button.wasSetFromCharges then
                    button.__isOnActualCooldown = true
                else
                    button.__isOnActualCooldown = false
                end
            end
            if (button.isOnGCD and not button.isOnActualCooldown) and Addon:GetValue("CDMRemoveGCDSwipe", nil, barName) then
                cooldownFrame:Clear()
            end
            
        end

        timerString:SetVertexColor(1,1,1,1)

        cooldownFrame:SetReverse(Addon:GetValue("CDMReverseSwipe", nil, barName))
    end

    cooldownFrame:SetCountdownAbbrevThreshold(620)

    if Addon:GetValue("CurrentCDMSwipeTexture", nil, barName) > 1 then
        cooldownFrame:SetSwipeTexture(T.SwipeTextures[Addon:GetValue("CurrentCDMSwipeTexture", nil, barName)].texture)
    end
    if Addon:GetValue("UseCDMSwipeSize", nil, barName) then
        cooldownFrame:ClearAllPoints()
        cooldownFrame:SetPoint("CENTER", button, "CENTER")
        local size = Addon:GetValue("CDMSwipeSize", nil, barName)
        cooldownFrame:SetSize(size, size)
    else
        cooldownFrame:SetAllPoints()
    end

    if not cooldownFrame:GetDrawEdge() then
        cooldownFrame:SetDrawEdge(Addon:GetValue("CDMEdgeAlwaysShow", nil, barName))
    end

    if cooldownFrame:GetDrawEdge() then
        cooldownFrame:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentCDMEdgeTexture", nil, barName)].texture)
        if Addon:GetValue("UseCDMEdgeSize", nil, barName) then
            local size = Addon:GetValue("CDMEdgeSize", nil, barName)
            cooldownFrame:SetEdgeScale(size)
        end
        if Addon:GetValue("UseCDMEdgeColor", nil, barName) then
            cooldownFrame:SetEdgeColor(Addon:GetRGBA("CDMEdgeColor", nil, barName))
        end
    end

end
--[[ local function Hook_CooldownFrame_Set(self)
    if not self then return end
    if not self.GetParent then return end

    local button = self:GetParent()
    if not button then return end

    local bar = button:GetParent()
    local barName = bar and bar:GetName() or ""

    if bar and tContains(CooldownManagerFrames, barName) then
        if not Addon:GetValue("CDMEnable", nil, barName) then return end
        button.__isOnActualCooldown = false

        if not button.__cooldownDoneHooked then
            button.Cooldown:HookScript("OnCooldownDone", Hook_OnCooldownDone)
            button.__cooldownDoneHooked = true
        end

        local timerString
        if not isBeta then
            if not button.Cooldown.__timer then
                local cdRegions = { button.Cooldown:GetRegions() }
                if cdRegions then
                    for i, region in ipairs(cdRegions) do
                        if region:IsObjectType("FontString") then
                            button.Cooldown.__timer = region
                            break
                        end
                    end
                end
            end
            timerString = button.Cooldown.__timer
        else
            timerString = button.Cooldown:GetCountdownFontString()
        end
        
        button.__cooldownSet = true
        if button.cooldownUseAuraDisplayTime or button.pandemicAlertTriggerTime then
            button.__isOnAura = true
            
            if Addon:GetValue("UseCDMAuraSwipeColor", nil, barName) then
                button.Cooldown:SetSwipeColor(Addon:GetRGBA("CDMAuraSwipeColor", nil, barName)) 
            end
            if Addon:GetValue("UseCDMBackdropAuraColor", nil, barName) and not button.__isInPandemic then
                Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropAuraColor", nil, barName)}, "aura")
            end
            if Addon:GetValue("UseCDMAuraTimerColor", nil, barName) then
                timerString:SetVertexColor(Addon:GetRGBA("CDMAuraTimerColor", nil, barName)) 
            else
                timerString:SetVertexColor(1,1,1,1)
            end

            button.Cooldown:SetReverse(Addon:GetValue("CDMAuraReverseSwipe", nil, barName))
        else
            button.__isOnAura = false

            if Addon:GetValue("UseCDMSwipeColor", nil, barName) then
                button.Cooldown:SetSwipeColor(Addon:GetRGBA("CDMSwipeColor", nil, barName))
            end
            if Addon:GetValue("UseCDMBackdrop", nil, barName) then
                Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, barName)}, "reset")
            end
            
            if not isBeta then
                local spellID = button:GetSpellID()
                button.__isOnGCD, button.__isOnActualCooldown = Addon:IsSpellOnGCD(spellID)
                if (button.__isOnGCD and not button.__isOnActualCooldown) and Addon:GetValue("CDMRemoveGCDSwipe", nil, barName) then
                    button.Cooldown:SetSwipeColor(0,0,0,0)
                end
            else
                if (button.isOnGCD and not button.isOnActualCooldown) then
                    button.__isOnGCD = true
                else
                    if not button.wasSetFromCharges then
                        button.__isOnActualCooldown = true
                    else
                        button.__isOnActualCooldown = false
                    end
                end
                if (button.isOnGCD and not button.isOnActualCooldown) and Addon:GetValue("CDMRemoveGCDSwipe", nil, barName) then
                    button.Cooldown:Clear()
                end
                
            end

            timerString:SetVertexColor(1,1,1,1)

            button.Cooldown:SetReverse(Addon:GetValue("CDMReverseSwipe", nil, barName))
        end

        button.Cooldown:SetCountdownAbbrevThreshold(620)

        if Addon:GetValue("CurrentCDMSwipeTexture", nil, barName) > 1 then
            button.Cooldown:SetSwipeTexture(T.SwipeTextures[Addon:GetValue("CurrentCDMSwipeTexture", nil, barName)].texture)
        end
        if Addon:GetValue("UseCDMSwipeSize", nil, barName) then
            button.Cooldown:ClearAllPoints()
            button.Cooldown:SetPoint("CENTER", button, "CENTER")
            local size = Addon:GetValue("CDMSwipeSize", nil, barName)
            button.Cooldown:SetSize(size, size)
        else
            button.Cooldown:SetAllPoints()
        end

        if not button.Cooldown:GetDrawEdge() then
            button.Cooldown:SetDrawEdge(Addon:GetValue("CDMEdgeAlwaysShow", nil, barName))
        end

        if button.Cooldown:GetDrawEdge() then
            button.Cooldown:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentCDMEdgeTexture", nil, barName)].texture)
            if Addon:GetValue("UseCDMEdgeSize", nil, barName) then
                local size = Addon:GetValue("CDMEdgeSize", nil, barName)
                button.Cooldown:SetEdgeScale(size)
            end
            if Addon:GetValue("UseCDMEdgeColor", nil, barName) then
                button.Cooldown:SetEdgeColor(Addon:GetRGBA("CDMEdgeColor", nil, barName))
            end
        end
    end
end ]]

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
    if frame.hideInactive then
        local frameName = frame:GetName()

        if frameName == "BuffBarCooldownViewer" or frameName == "BuffIconCooldownViewer" then
            if child:IsVisible() then
                child.__isActive = true
            else
                child.__isActive = false
            end
            return
        end
        if child.__isOnActualCooldown or child.__isOnAura or child.wasSetFromCharges then
            child.__isActive = true
        else
            child.__isActive = false
        end
    else
        child.__isActive = nil
    end
end

local function OnButtonVisibilityChanged(child)
    local isVisible = child:IsVisible()
    local frame = child:GetParent()

    CheckItemVisibility(child, isVisible, frame)

    --[[ if child.__isActive == child.__wasActive then
        return
    end

    child.__wasActive = child.__isActive ]]

    frame:RefreshLayoutGrid()

    --[[ local newCount = #frame.__visibleChildren

    if frame.__wasVisibleChildren ~= newCount then
        frame.__wasVisibleChildren = newCount
        if newCount > 0 then
            table.sort(frame.__visibleChildren, function(a, b)
                local aIdx = a.layoutIndex or 9999
                local bIdx = b.layoutIndex or 9999
                return aIdx < bIdx
            end)
            --frame:ShouldUpdateLayout(true)
            frame:Layout()
        end
    end ]]
end

local function RefreshDesaturation(self)
    if not self or self.__desaturated == nil then return end
    local frameName = self:GetParent():GetName()

    if Addon:GetValue("CDMRemoveDesaturation", nil, frameName) then
        self.__desaturated = false
    end
    
    local icon = self:GetIconTexture()
    icon:SetDesaturated(self.__desaturated)
end

local function OnButtonRefreshIconColor(self)
    local spellID = self:GetSpellID()
    if not spellID then
        return
    end
    
    local frame = self:GetParent()
    local frameName = frame:GetName()
    local iconTexture = self:GetIconTexture()
    local outOfRangeTexture = self:GetOutOfRangeTexture()
    
    local color = {1, 1, 1, 1}

    local iconColor = {iconTexture:GetVertexColor()}
    if iconColor then
        for i, number in pairs(iconColor) do
            iconColor[i] = RoundToSignificantDigits(number, 2)
        end
    end
    
    local OORColor = CooldownManagerEnhanced.constants.OORColor
    local OOMColor = CooldownManagerEnhanced.constants.OOMColor  
    local NUColor = CooldownManagerEnhanced.constants.NUColor

    if Addon:GetValue("UseOORColor", nil, frameName) and 
       (iconColor[1] == OORColor[1] and iconColor[2] == OORColor[2] and iconColor[3] == OORColor[3]) then
        color = {Addon:GetRGBA("OORColor", nil, frameName)}
        outOfRangeTexture:SetShown(false)
        self.__desaturated = Addon:GetValue("OORDesaturate", nil, frameName)
    
    elseif self.__isOnActualCooldown and Addon:GetValue("UseCDColor", nil, frameName) then
        color = {Addon:GetRGBA("CDColor", nil, frameName)}
        self.__desaturated = Addon:GetValue("CDColorDesaturate", nil, frameName)
    
    elseif self.__isOnGCD and Addon:GetValue("UseGCDColor", nil, frameName) then
        color = {Addon:GetRGBA("GCDColor", nil, frameName)}
        self.__desaturated = Addon:GetValue("GCDColorDesaturate", nil, frameName)
    
    else
        if Addon:GetValue("UseNoUseColor", nil, frameName) and 
           (iconColor[1] == NUColor[1] and iconColor[2] == NUColor[2] and iconColor[3] == NUColor[3]) then
            color = {Addon:GetRGBA("NoUseColor", nil, frameName)}
            self.__desaturated = Addon:GetValue("NoUseDesaturate", nil, frameName)
        
        elseif Addon:GetValue("UseOOMColor", nil, frameName) and 
               (iconColor[1] == OOMColor[1] and iconColor[2] == OOMColor[2] and iconColor[3] == OOMColor[3]) then
            color = {Addon:GetRGBA("OOMColor", nil, frameName)}
            self.__desaturated = Addon:GetValue("OOMDesaturate", nil, frameName)
        
        else
            if not self.__isOnAura then
                if Addon:GetValue("UseNormalColor", nil, frameName) then
                    color = {Addon:GetRGBA("NormalColor", nil, frameName)}
                    self.__desaturated = Addon:GetValue("NormalColorDesaturate", nil, frameName)
                else
                    self.__desaturated = false
                end
            else
                self.__desaturated = false
            end
        end
    end
    iconTexture:SetVertexColor(color[1], color[2], color[3], color[4])
    RefreshDesaturation(self)
end

local function OnButtonRefreshIconDesaturation(self)
    local frame = self:GetParent()
    local frameName = frame:GetName()

    local iconTexture = self:GetIconTexture()
    
    RefreshDesaturation(self)
end

local function Hook_OnItemSetScale(frame, scale)
    if scale ~= 1 then
        frame:SetScale(1)
    end
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

--[[ local function OnRefreshActive(self, spellID)
    if self.__isOnActualCooldown then
        self:Show()
    else
        self:Hide()
    end
    OnButtonVisibilityChanged(self)
end ]]

local function Hook_Layout(self)
    if self.__locked then
        return
    end
    self.__locked = true
    --[[ if EditModeManagerFrame:IsEditModeActive() or CooldownViewerSettings:IsVisible() then
        return
    end ]]

    local frameName = self:GetName()
    if not frameName or not tContains(CooldownManagerFrames, frameName) then
        self.__locked = false
        return
    end

    local forceUpdate = CooldownManagerEnhanced.forced == frameName

    if (not self.__layoutFramesGoingUp or not self.__layoutFramesGoingRight) or forceUpdate then
        self.__layoutFramesGoingUp = Addon:GetValue("CDMVerticalGrowth", nil, frameName)
        self.__layoutFramesGoingRight = Addon:GetValue("CDMHorizontalGrowth", nil, frameName)
    end
    
    if not self.__padding or forceUpdate then
        if Addon:GetValue("UseCDMIconPadding", nil, frameName) then
            self.__padding = Addon:GetValue("CDMIconPadding", nil, frameName)
            self.__padding = self.childXPadding or self.childYPadding
        else
            self.__padding = self.childXPadding or self.childYPadding or 100
        end
    end

    if not self.grildLayoutType or forceUpdate then
        self.gridLayoutType = Addon:GetValue("CDMGridLayoutType", nil, frameName)
    end

    if self.hideInactive == nil or forceUpdate then
        self.hideInactive = Addon:GetValue("CDMHideWhenInactive", nil, frameName)
    end

    local layoutChildren = self:GetLayoutChildren()
    if not self:ShouldUpdateLayout(layoutChildren) then
        self.__locked = false
        return
    end

    for _, child in ipairs(layoutChildren) do

        if child:HasEditModeData() then
            self.__locked = false
            return
        end

        --for future visible alert hook

        --[[ if child.TriggerAvailableAlert and not child.__alertHook then
            hooksecurefunc(child, "TriggerAvailableAlert", OnTriggerAvailableAlert)
            child.__alertHook = true
        end ]]

        --CheckItemVisibility(child, child:IsVisible(), self)

        if not child.__hooked and Addon:GetValue("CDMEnable", nil, frameName) then
            --[[ if child.OnActiveStateChanged then
                hooksecurefunc(child, "OnActiveStateChanged", OnButtonVisibilityChanged)
            end
            if child.OnUnitAuraAddedEvent then
                hooksecurefunc(child, "OnUnitAuraAddedEvent", OnButtonVisibilityChanged)
            end
            if child.OnUnitAuraRemovedEvent then
                hooksecurefunc(child, "OnUnitAuraRemovedEvent", OnButtonVisibilityChanged)
            end ]]
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
            child.__hooked = true
        end

        if not child.__refreshIconHook then
            if child.RefreshIconColor then
                hooksecurefunc(child, "RefreshIconColor", OnButtonRefreshIconColor)
            end
            if child.RefreshIconDesaturation then
                hooksecurefunc(child, "RefreshIconDesaturation", OnButtonRefreshIconDesaturation)  
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
        end

        if child.Cooldown and (not child.__cooldown or forceUpdate) then
            local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}

            if Addon:GetValue("UseCooldownCDMFontColor", nil, frameName) then
                color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownCDMFontColor", nil, frameName)
            end
            
            local fontSize = Addon:GetValue("UseCooldownCDMFontSize", nil, frameName) and Addon:GetValue("CooldownCDMFontSize", nil, frameName) or 17
            
            local _, fontName = Addon:GetFontObject(
                Addon:GetValue("CurrentCDMCooldownFont", nil, frameName),
                "OUTLINE",
                color,
                fontSize,
                false,
                frameName
            )
            child.Cooldown:SetCountdownFont(fontName)
            child.__cooldown = true
        end
        
        local stacksFrame = child.Applications or child.ChargeCount
        local stacksString = stacksFrame and (stacksFrame.Applications or stacksFrame.Current) or child.Icon.Applications
        if stacksString and (not child.__stacksString or forceUpdate) then
            if Addon:GetValue("CurrentCDMStacksFont", nil, frameName) ~= "Default" then
                stacksString:SetFont(
                    LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentCDMStacksFont", nil, frameName)),
                    (Addon:GetValue("UseCDMStacksFontSize", nil, frameName) and Addon:GetValue("CDMStacksFontSize", nil, frameName) or 16),
                    "OUTLINE"
                )
            end
            stacksString:SetFontHeight(Addon:GetValue("CDMStacksFontSize", nil, frameName) or 16)
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

            child.__stacksString = true
        end

        if Addon:GetValue("CDMUseItemSize", nil, frameName) and (not child.__sizeHooked or forceUpdate) then
            local size = Addon:GetValue("CDMItemSize", nil, frameName)
            child:SetSize(size, size)
            if child.SetScale then
                hooksecurefunc(child, "SetScale", Hook_OnItemSetScale)
            end
            child.__sizeHooked = true
        end
        
        if Addon:GetValue("CurrentIconMaskTexture", nil, frameName) > 1 and (not child.__iconHooked or forceUpdate) then

            local iconMaskAtlas = T.IconMaskTextures[Addon:GetValue("CurrentIconMaskTexture", nil, frameName)]

            local icon = (frameName ~= "BuffBarCooldownViewer") and child.Icon or child.Icon.Icon
            local mask = icon:GetMaskTexture(1)

            mask:SetHorizTile(false)
            mask:SetVertTile(false)

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

            child.__iconHooked = true
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

                    if Addon:GetValue("UseCooldownCDMFontColor", nil, frameName) then
                        color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownCDMFontColor", nil, frameName)
                    end
                    local fontSize = Addon:GetValue("UseCooldownCDMFontSize", nil, frameName) and Addon:GetValue("CooldownCDMFontSize", nil, frameName) or 17
                    local _, fontName = Addon:GetFontObject(
                        Addon:GetValue("CurrentCDMCooldownFont", nil, frameName),
                        "OUTLINE",
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
                        "OUTLINE"
                    )
                    child.Bar.Name:SetTextColor(color.r,color.g,color.b,color.a)
                end

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
                local offset = Addon:GetValue("CDMBarOffset", nil, frameName)
                child.Bar:SetPoint("LEFT", child, "LEFT", offset, 0)
                child.Bar:SetPoint("RIGHT", child, "RIGHT")
            else
                child.Bar:SetPoint("LEFT", child.Icon, "RIGHT", 2, 0)
                child.Bar:SetPoint("RIGHT", child, "RIGHT")
            end

            local invert = false
            if invert then
                child.Icon:ClearAllPoints()
                child.Icon:SetPoint("RIGHT", child, "RIGHT")
                child.Bar:ClearAllPoints()
                child.Bar:SetPoint("LEFT", child, "LEFT")
                child.Bar:SetPoint("RIGHT", child.Icon, "LEFT", -2, 0)
                local statusBarTexture = child.Bar:GetStatusBarTexture()
                child.Bar:SetReverseFill(true)
                child.Bar.Pip:ClearAllPoints()
                child.Bar.Pip:SetPoint("CENTER", statusBarTexture, "LEFT")
            end        
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
                Addon:ResizeLayout(self, layoutChildren)
                self:CacheLayoutSettings(layoutChildren)
            else
                Addon:ApplyStandardGridLayout(self, layoutChildren, stride, padding)
                Addon:ResizeLayout(self, layoutChildren)
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

        if not button.__isInPandemic then
            if Addon:GetValue("CDMRemovePandemic", nil, frameName) then
                if not frame.__pandemicRemoved then
                    frame.Border.Border:SetTexture("") --отключает стандартную красную рамку для пандемика
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
                Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropPandemicColor", nil, frameName)}, "pandemic")
            end

            button.__isInPandemic = true
        end

    end
end
local function Hook_HidePandemic(self, frame)
    local button = frame:GetParent()
    local frameName = button:GetParent():GetName()

    if button.__isInPandemic then
        if not button.__hidePandemicScheduled then
            button.__hidePandemicScheduled = true
            C_Timer.After(0.0, function()
                button.__hidePandemicScheduled = false
                
                if button.PandemicIcon and button.PandemicIcon:IsVisible() then
                    return
                end

                local state = frameName ~= "BuffBarCooldownViewer" and "default" or "reset"
                if Addon:GetValue("UseCDMBackdropColor", nil, frameName) then
                    Addon.SetBorderColor(button, {Addon:GetRGBA("CDMBackdropColor", nil, frameName)}, state)
                end
                button.__isInPandemic = nil          
            end)
        end
    end
end

local function ProcessEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        for _, frameName in ipairs(CooldownManagerFrames) do
            local frame = _G[frameName]
            if Addon:GetValue("CDMEnable", nil, frameName) then
                if frame and frame.Layout then
                    hooksecurefunc(frame, "Layout", Hook_Layout)
                end
                if frame and frame.SetupPandemicStateFrameForItem then
                    hooksecurefunc(frame, "AnchorPandemicStateFrame", Hook_SetupPandemic)
                end
                if frame and frame.HidePandemicStateFrame then
                    hooksecurefunc(frame, "HidePandemicStateFrame", Hook_HidePandemic)
                end
            end
        end
        --hooksecurefunc("CooldownFrame_Set", Hook_CooldownFrame_Set)
        --hooksecurefunc("CooldownFrame_Clear", Hook_CooldownFrame_Clear)
    end
end

local eventHandlerFrame = CreateFrame('Frame')
eventHandlerFrame:SetScript('OnEvent', ProcessEvent)
eventHandlerFrame:RegisterEvent('PLAYER_LOGIN')