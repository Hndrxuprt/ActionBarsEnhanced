local AddonName, Addon = ...

local profileTable

local isBeta = Addon.IsBeta

local function IsOnGCD()
    local gcdInfo = C_Spell.GetSpellCooldown(61304)

    local isOnGCD = false
    if gcdInfo and gcdInfo.duration ~= 0 then
        isOnGCD = true
    end

    return isOnGCD
end

ABE_CDMCustomItemMixin = {}

function ABE_CDMCustomItemMixin:GetAuraFrame()
    return self.Icon.AuraCooldown or self.AuraCooldown
end
function ABE_CDMCustomItemMixin:GetCooldownFrame()
    return self.Icon.Cooldown or self.Cooldown
end
function ABE_CDMCustomItemMixin:OnLoad()
    local cooldownFrame = self:GetCooldownFrame()
    local auraCooldown = self:GetAuraFrame()
    cooldownFrame:SetScript("OnCooldownDone", GenerateClosure(self.OnCooldownDone, self))
    auraCooldown:SetScript("OnCooldownDone", GenerateClosure(self.OnAuraDone, self))
    self:SetMouseClickEnabled(false)
end

function ABE_CDMCustomItemMixin:OnShow()
    if self:GetSpellID() then
        C_Timer.After(0, function()
            self:RefreshData()
        end)
    end

    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    self:RegisterEvent("SPELL_UPDATE_ICON")
    self:RegisterEvent("SPELL_UPDATE_CHARGES")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self:RegisterEvent("SPELL_UPDATE_USES")
    self:RegisterEvent("SPELL_UPDATE_USABLE")
    self:RegisterEvent("ITEM_COUNT_CHANGED")
    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
    
end

local function IsHealthstoneCreateCast(spellID)
    if spellID == 6201 then
        return true
    end
    return false
end

local function IsHealthstoneItem(spellID)
    local healthstoneIDs = {
        [1] = 224464,
        [2] = 5512,
    }
    for i, id in ipairs(healthstoneIDs) do
        if spellID == id then
            return true, healthstoneIDs
        end
    end

    return false
end

function ABE_CDMCustomItemMixin:OnEvent(event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" then
		local spellID, baseSpellID, category, startRecoveryCategory = ...
        if self.spellID == spellID or (baseSpellID and (self.baseSpellID == baseSpellID))
        or (self.overrideID == spellID) then
            if self.slotID == 13 or self.slotID == 14 then
                local frame = _G[self.parentName]
                frame:UpdateAllTrinkets(self.slotID)
            end

            self:OnSpellUpdateCooldownEvent()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        if self.spellID == spellID or self.baseSpellID == spellID or self.overrideID == spellID then
            if self.fakeAura then
                self:RefreshFakeAuraInfo()
                self:RefreshData()
            end
            -- HACK for spells withour GCD at all, interrupts for example
            self.isOnActualCooldown = true
        end
        if IsHealthstoneCreateCast(spellID) then
            C_Timer.After(0.5, function()
                self:RefreshCount()
            end)
        end
    elseif event == "SPELL_UPDATE_USES" then
        local spellID, baseSpellID = ...
        if self.spellID == spellID or (baseSpellID and (self.baseSpellID == baseSpellID))
        or (self.overrideID == spellID) then
            self:OnSpellUpdateUsesEvent()
        end        
    elseif event == "ITEM_COUNT_CHANGED" then
        local itemID = ...
        if self.itemID == itemID then
            self:RefreshCount()
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        if self.type == "item" then
            self:RefreshData()
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local spellID = ...
        if self.type == "spell" and self.spellID == spellID or self.baseSpellID == spellID then
            local isSpellOverlayed = spellID and C_SpellActivationOverlay.IsSpellOverlayed(spellID) or false
            if isSpellOverlayed then
                ActionButtonSpellAlertManager:ShowAlert(self)
            else
                ActionButtonSpellAlertManager:HideAlert(self)
            end

            --self:ShowProcGlow()
        end
    elseif event == "SPELL_UPDATE_ICON" then
        local spellID = ...
        if self.spellID == spellID or self.baseSpellID == spellID then
            self:RefreshSpellTexture()
        end
    elseif event == "SPELL_UPDATE_CHARGES" then
        if self.type == "spell" then
            self:RefreshData()
        end
    end
end

function ABE_CDMCustomItemMixin:OnEnter()
    local showTooltip = false
    if showTooltip then
        local tooltip = GetAppropriateTooltip()
        GameTooltip_SetDefaultAnchor(tooltip, self)
        if self.itemID then
            tooltip:SetItemByID(self.itemID)
        else
            tooltip:SetSpellByID(self.spellID, false)
        end
        tooltip:Show()
    end

    local frame = _G[self.parentName]

    if frame.fade then
        Addon:Fade(frame, true)
    end
end

function ABE_CDMCustomItemMixin:OnLeave()
    GetAppropriateTooltip():Hide()

    local frame = _G[self.parentName]

    if frame.fade then
        Addon:Fade(frame, false)
    end
end

function ABE_CDMCustomItemMixin:SetSlotID(slotID)
    local itemInfo = C_TooltipInfo.GetInventoryItem("player", slotID)
    local spellName, spellID
    if itemInfo then
        spellName, spellID = C_Item.GetItemSpell(itemInfo.id)
    end

    self.count = 0
    self.slotID = slotID
    self.itemID = itemInfo.id
    self.spellID = spellID
    self.baseSpellID = nil
    self.overrideID = nil
end

function ABE_CDMCustomItemMixin:SetSpellID(spellID, baseSpellID)
    self.slotID = nil
    self.itemID = nil
    self.spellID = spellID
    self.baseSpellID = baseSpellID
    self.count = 0
    self.overrideID = C_Spell.GetOverrideSpell(spellID)
    --self:FindAuraForCurrentSpellID()
end

function ABE_CDMCustomItemMixin:SetItemID(itemID)
    local spellName, spellID = C_Item.GetItemSpell(itemID)

    self.slotID = nil
    self.itemID = itemID
    self.spellID = spellID
    self.baseSpellID = nil
    self.overrideID = nil
end

function ABE_CDMCustomItemMixin:GetSpellID()
    if self.baseSpellID then
        return self.baseSpellID
    end

    return self.spellID
end

function ABE_CDMCustomItemMixin:FindAuraForCurrentSpellID()
    --local orderedCooldownIDs = CooldownViewerSettings:GetDataProvider():GetOrderedCooldownIDs()

    for cdID, data in pairs(CooldownViewerSettings:GetDataProvider():GetDisplayData().cooldownInfoByID) do
        local itemSpellID = data.spellID
        if itemSpellID == self.spellID then
            --Addon:DebugPrint("SpellFound", itemSpellID, self.spellID)
            self.linkedSpellID = data.linkedSpellID
            self.overrideTooltipSpellID = data.overrideTooltipSpellID
            self.overrideSpellID = data.overrideSpellID
            --self.cooldownInfo = CooldownViewerSettings:GetDataProvider():GetCooldownInfoForID(2272)
        end
    end

    --local auraData = C_UnitAuras.GetPlayerAuraBySpellID(self.spellID)
end

function ABE_CDMCustomItemMixin:FindAuraInstanceIDForCurrentSpellID()
    for itemFrame in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
        local auraInstanceID = itemFrame:GetAuraSpellInstanceID()
        local spellID = itemFrame:GetBaseSpellID()
        local cooldownID = itemFrame:GetCooldownID()
        --Addon:DebugPrint("AuraInstanceID Set:", self.spellID, spellID, cooldownID)
        if self.spellID == spellID then
            self.auraInstanceID = auraInstanceID
        end
    end
end

function ABE_CDMCustomItemMixin:SetAuraInstanceInfo(auraInfo)
    local auraSpellID, auraInstanceID = auraInfo.spellId, auraInfo.auraInstanceID
	self.auraInstanceID = auraInstanceID
    self.auraSpellID = auraSpellID
end

function ABE_CDMCustomItemMixin:ClearAuraInstanceInfo()
	local auraSpellID, auraInstanceID = self.auraSpellID, self.auraInstanceID
	if auraSpellID or auraInstanceID then
		self.auraInstanceID = nil
		self.auraSpellID = nil
	end
end

function ABE_CDMCustomItemMixin:RefreshAuraInstance()
	local auraData = C_UnitAuras.GetPlayerAuraBySpellID(self.spellID)
	if auraData then
		self:SetAuraInstanceInfo(auraData)
	else
		self:ClearAuraInstanceInfo()
	end
end

function ABE_CDMCustomItemMixin:GetAuraSpellID()
	return self.auraSpellID
end

function ABE_CDMCustomItemMixin:GetCooldownInfo()
    if self.type == "item" then
        local start, duration, enable = C_Item.GetItemCooldown(self.itemID)
        self.cooldownInfo = {
            startTime = start,
            duration = duration,
            enable = enable,
        }
    elseif self.type == "spell" then
        self.overrideID = C_Spell.GetOverrideSpell(self.spellID)
        local spellID = self.overrideID or self.spellID
        self.cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    elseif self.type == "slot" then
        --self.cooldownInfo = C_Spell.GetSpellCooldown(self:GetSpellID())
        local start, duration, enable = GetInventoryItemCooldown("player", self.slotID)
        self.cooldownInfo = {
            startTime = start,
            duration = duration,
            enable = enable,
        }
    end
    return self.cooldownInfo
end

function ABE_CDMCustomItemMixin:GetCooldownDurationObj()
    if self.type == "spell" then
        local spellID = self.overrideID or self.baseSpellID or self.spellID
        self.durationObj = C_Spell.GetSpellChargeDuration(spellID) or C_Spell.GetSpellCooldownDuration(spellID)
    end
    return self.durationObj or nil
end


function ABE_CDMCustomItemMixin:GetSpellTexture()
    local spellID = self:GetSpellID()
    local texture = 136243
    if self.type ~= "spell" and self.itemID then
        texture = C_Item.GetItemIconByID(self.itemID)
    elseif self.type == "spell" and spellID then
        texture = C_Spell.GetSpellTexture(spellID)
    end

	return texture
end

function ABE_CDMCustomItemMixin:RefreshSpellTexture()
    local spellTexture = self:GetSpellTexture()
    if self.auraData then
        spellTexture = self.auraData.icon
    end
    local icon = self.Icon.Icon or self.Icon
    icon:SetTexture(spellTexture)
end

function ABE_CDMCustomItemMixin:RefreshIconDesaturation(desaturated)
    local icon = self.Icon.Icon or self.Icon
    if self.type == "item" then
        if self.count == 0 or self.count == "" then
            desaturated = true
        else
            desaturated = false
        end
    end
    if desaturated == nil then return end
    icon:SetDesaturated(desaturated)
end

function ABE_CDMCustomItemMixin:RefreshIconColor()
    local frameName = self.parentName
    local color = {1,1,1,1}
    local desaturated = false
    if not self.isOnAuraTimer and self.isOnActualCooldown and Addon:GetValue("UseCDColor", nil, frameName) then
        color = {Addon:GetRGBA("CDColor", nil, frameName)}
        desaturated = Addon:GetValue("CDColorDesaturate", nil, frameName)
    elseif Addon:GetValue("UseNormalColor", nil, frameName) then
        color = {Addon:GetRGBA("NormalColor", nil, frameName)}
        desaturated = Addon:GetValue("NormalColorDesaturate", nil, frameName)
    end
    local icon = self.Icon.Icon or self.Icon
    icon:SetVertexColor(color[1], color[2], color[3], color[4])
    self:RefreshIconDesaturation(desaturated)
end

function ABE_CDMCustomItemMixin:RefreshCount()
    local applications = self.Icon.Applications or self.Applications
    local count = 0
    if self.type == "item" and self.itemID then
        count = C_Item.GetItemCount(self.itemID, nil, true) or 0
    elseif self.type == "spell" then
        if not self.spellID then return end

        local charges = C_Spell.GetSpellCharges(self.spellID)
        count = charges and charges.currentCharges or ""

        local charges = C_Spell.GetSpellCharges(self.spellID) or {}

        self.auraData = self.auraInstanceID and C_UnitAuras.GetAuraDataByAuraInstanceID("player", self.auraInstanceID) or nil
        --Addon:DebugPrint("RefreshCount", self.auraData, self.auraInstanceID)

        if self.auraData and not self.stages then
            charges.currentCharges = self.auraData.applications
        end

        count = charges.currentCharges or 0

        --self.Applications:SetAlphaFromBoolean(((charges.maxCharges > 1) and (charges.currentCharges ~= nil)), tonumber(charges.currentCharges), 0 )
        --applications:SetAlpha(charges.currentCharges ~= nil and tonumber(charges.currentCharges) or 1)
    end
    --[[ if self.spellID == 1966 then
        Addon:DebugPrint("RefreshCount: ", count)
    end ]]
    self.count = count
    applications.Applications:SetText(count)
    applications:SetAlpha(count)

    self:RefreshIconDesaturation()
    self:RefreshSpellTexture()
    --self.ProcGlow:SetAlpha(count ~= "" and count or 1)
end

function ABE_CDMCustomItemMixin:GetChargesCooldownInfo()
    local cooldownFrame = self:GetCooldownFrame()
    local auraCooldown = self:GetAuraFrame()

    if not self.spellID then return false end

    local charges = C_Spell.GetSpellCharges(self.spellID)

    if charges and charges.cooldownStartTime and charges.cooldownDuration then
        return {
            startTime = charges.cooldownStartTime,
            duration = charges.cooldownDuration,
            currentCharges = charges.currentCharges,
            maxCharges = charges.maxCharges
        }
    end

    return false
end

local function IsFakeAuraExpired(spellID)
    if not ABE_FAKE_AURAS[spellID] then
        return true
    else
        local startTime = ABE_FAKE_AURAS[spellID].startTime
        local duration = ABE_FAKE_AURAS[spellID].duration
        local time = GetTime()
        if (time - startTime) < duration then
            return false
        elseif (time - startTime) >= duration then
            ABE_FAKE_AURAS[spellID] = nil
        end
    end
    
    return true
end

function ABE_CDMCustomItemMixin:RefreshFakeAuraInfo()
    if not self.fakeAura then return false end

    local auraCooldown = self:GetAuraFrame()

    local startTime = GetTime()
    local duration = self.fakeAura
    local isExpired = IsFakeAuraExpired(self.spellID)

    local cooldownFrame = self:GetCooldownFrame()
    cooldownFrame:SetAlpha(0)
    cooldownFrame:Show()

    if not self.isOnAuraTimer then
        if ABE_FAKE_AURAS[self.spellID] then
            startTime = ABE_FAKE_AURAS[self.spellID].startTime
            duration = ABE_FAKE_AURAS[self.spellID].duration
        else
            ABE_FAKE_AURAS[self.spellID] = { startTime = startTime, duration = self.fakeAura }
        end
        self.isOnAuraTimer = true
        auraCooldown:SetCooldown(startTime, duration)
    end
end

function ABE_CDMCustomItemMixin:ClearFakeAuraSavedInfo()
    if ABE_FAKE_AURAS[self.spellID] then
        local auraCooldown = self:GetAuraFrame()
        CooldownFrame_Clear(auraCooldown)
        ABE_FAKE_AURAS[self.spellID] = nil
    end
    self:RefreshData()
end

function ABE_CDMCustomItemMixin:RefreshBackdrop()
    if not self.iconBorder then return end

    if self.isOnAuraTimer then
        if Addon:GetValue("UseCDMBackdropAuraColor", nil, self.parentName) then
            self.iconBorder:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropAuraColor", nil, self.parentName))
        end
    else
        if Addon:GetValue("UseCDMBackdropColor", nil, self.parentName) then
            self.iconBorder:SetBackdropBorderColor(Addon:GetRGBA("CDMBackdropColor", nil, self.parentName))
        end
    end
end

function ABE_CDMCustomItemMixin:RefreshSpellCooldownInfo()
    if not self.spellID then return end

    if self.fakeAura and not IsFakeAuraExpired(self.spellID) then
        --Addon:DebugPrint("RefreshSpellCooldownInfo check RefreshFakeAuraInfo", self.spellID, self.layoutIndex)
        self:RefreshFakeAuraInfo()
    end
    
    local cooldownFrame = self:GetCooldownFrame()
    local auraCooldown = self:GetAuraFrame()

    cooldownFrame.showGCDSwipe = not (Addon:GetValue("CDMRemoveGCDSwipe", nil, self.parentName))

    cooldownFrame:SetAlpha(0)

    local showDrawEdge = true
    --self.isOnActualCooldown = false
    cooldownFrame:SetReverse(cooldownFrame.isReversed)
    auraCooldown:SetReverse(auraCooldown.isReversed)

    local chargeCooldownInfo = self:GetChargesCooldownInfo()
    local cooldownInfo = self:GetCooldownInfo()

    --[[ cooldownFrame:SetScript("OnUpdate", function()
        local durationObj = self:GetCooldownDurationObj()
        if durationObj then
            local timerString = cooldownFrame:GetCountdownFontString()
            if not timerString:IsVisible() then return end

            local EvaluateDuration = durationObj.EvaluateRemainingDuration and durationObj:EvaluateRemainingDuration(Addon.cooldownColorCurve) or nil
    
            if EvaluateDuration then
                timerString:SetVertexColor(EvaluateDuration:GetRGBA())
            end
            
        end
    end) ]]

    local chargeDur = C_Spell.GetSpellChargeDuration(self.spellID)

    if chargeCooldownInfo and chargeCooldownInfo.startTime and chargeCooldownInfo.duration then
        cooldownFrame:SetDrawSwipe(false)

        if cooldownInfo.isOnGCD == false then
            self.isOnActualCooldown = true
        else
            self.isOnActualCooldown = false
        end
        cooldownFrame:SetCooldown(chargeCooldownInfo.startTime, chargeCooldownInfo.duration)

        if cooldownFrame:IsVisible() then
            self.isOnChargeCooldown = true
        end
        if not self.isOnAuraTimer then
            cooldownFrame:SetAlpha(chargeDur:GetRemainingDuration())
        end
        
        
        --cooldownFrame:SetAlphaFromBoolean((self.isOnAuraTimer == true) or (cooldownFrame.showGCDSwipe == false and (cooldownInfo.isOnGCD == true)), 0,1)
    elseif cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
        if not self.isOnChargeCooldown then
            if self.type == "spell" and cooldownInfo.isOnGCD == false then
                self.isOnActualCooldown = true
            elseif self.type ~="spell" and cooldownInfo.duration > 0 then
                self.isOnActualCooldown = true
            end
            cooldownFrame:SetDrawSwipe(true)
            cooldownFrame:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
            cooldownFrame:Show()

            if cooldownInfo.enable == false then
                cooldownFrame:Pause()
            else
                cooldownFrame:Resume()
            end
            cooldownFrame:SetAlphaFromBoolean(
                (self.isOnAuraTimer == true)
                or 
                (
                    not self.isOnActualCooldown == true
                    and cooldownFrame.showGCDSwipe == false
                    and (cooldownInfo.isOnGCD == true)
                ),
                0,1
            )
        end
    else
        CooldownFrame_Clear(cooldownFrame)
        self.isOnActualCooldown = false
        self.isOnAuraTimer = false
    end
end

function ABE_CDMCustomItemMixin:RefreshData()
    self:FindAuraInstanceIDForCurrentSpellID()
    --Addon:DebugPrint("RefreshData")
    --if not self:IsVisible() then return end
    self:RefreshSpellCooldownInfo()
    --self:RefreshAuraInstance()
    self:RefreshSpellTexture()
    if self.type == "item" and IsHealthstoneItem(self.itemID) then
        C_Timer.After(0.5, function()
            self:RefreshCount()
        end)
    else
        self:RefreshCount()
    end
    self:RefreshBackdrop()
    --self:RefreshProcAnim()
    
    self:RefreshVisibility()
    self:RefreshIconColor()
end

function ABE_CDMCustomItemMixin:RefreshVisibility()
    if not self.parentName then return end
    local parentFrame = _G[self.parentName]

    if not parentFrame then return end
    
    --[[ if (self.isOnActualCooldown or self.isOnAuraTimer or self.isOnChargeCooldown) then
        self:SetAlpha(1)
    elseif Addon:GetValue("UseCDMCustomAlphaNoCD", nil, self.parentName) then
        self:SetAlpha(Addon:GetValue("CDMCustomAlphaNoCD", nil, self.parentName))
    else
        self:SetAlpha(1)
    end ]]
    local hideType = parentFrame.Container.hideInactiveType

    if hideType == 3 then
        if self.isOnActualCooldown or self.isOnAuraTimer or self.isOnChargeCooldown then
            self.__isActive = true
        else
            self.__isActive = false
        end
        parentFrame:RefreshVisibileOnCD()
    elseif hideType == 2 then
        if self.isOnAuraTimer then
            self.__isActive = true
        else
            self.__isActive = false
        end
        parentFrame:RefreshVisibileOnCD()
    elseif hideType == 1 then
        self.__isActive = nil
    end
end

function ABE_CDMCustomItemMixin:OnSpellUpdateCooldownEvent()
    
    self:RefreshData()
end

function ABE_CDMCustomItemMixin:OnSpellUpdateUsesEvent()
    --self.count = C_Spell.GetSpellCharges(self:GetSpellID())
    RunNextFrame(function()
        self:RefreshCount()
    end)
    
end

function ABE_CDMCustomItemMixin:OnAuraDone()
    self.isOnAuraTimer = false
    --[[ self.Cooldown:SetAlpha(1)
    self.Cooldown:Show() ]]
    RunNextFrame(function()
        self:RefreshData()
    end)
end

function ABE_CDMCustomItemMixin:OnCooldownDone()
    self.isOnActualCooldown = false
    self.isOnChargeCooldown = false
    --self.isOnAuraTimer = false
    RunNextFrame(function()
        self:RefreshData()
    end)
end

--[[ function ABE_CDMCustomItemMixin:ShowProcGlow()
    self.ProcGlow:Show()
    self.ProcGlow.ProcStartAnim:Play()
end
function ABE_CDMCustomItemMixin:HideProcGlow()
    self.ProcGlow.ProcLoop:Stop()
    self.ProcGlow:Hide()
end ]]


function ABE_CDMCustomItemMixin:RefreshProcAnim()
    if not self:IsVisible() then return end
    --Addon:DebugPrint("RefreshProcAnim", self.isOnAuraTimer,self.isOnActualCooldown, self.ProcGlow.ProcLoop:IsPlaying())
    if self.isOnAuraTimer or self.isOnActualCooldown then
        self.ProcGlow.ProcLoop:Stop()
        self.ProcGlow:Hide()
    elseif not self.isOnAuraTimer and not self.isOnActualCooldown then
        --Addon:DebugPrint("RefreshProcAnim Playing", self.ProcGlow.ProcLoop:IsPlaying() )
        if not self.ProcGlow.ProcLoop:IsPlaying() then
            self.ProcGlow:Show()
            self.ProcGlow.ProcStartAnim:Play()
        end
    end
end
function ABE_CDMCustomItemMixin:GetFakeAura()
    if not self.spellID then return end
    local frameName = self.parentName
    local frameIndex = _G[frameName]:GetFrameIndexByName(frameName)
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.fakeAuras then
            return frameTbl.fakeAuras[self.itemID or self.spellID]
        end
    end
end

-----------------------------
ABE_CDMCustomItemProcGlow = {}

function ABE_CDMCustomItemProcGlow:OnLoad()
    self.ProcStartAnim:SetScript("OnFinished", function()
        self.ProcLoop:Play()
    end)
end

function ABE_CDMCustomItemProcGlow:OnHide()
    if self.ProcLoop:IsPlaying() then
        self.ProcLoop:Stop()
    end
end
------------------------------

-----------------------------
ABE_CDMCustomFrameMixin = {}

function ABE_CDMCustomFrameMixin:OnLoad()

    self:SetMovable(true)

    self.frameName = self:GetName()

    local frameIndex = self:GetFrameIndexByName(self.frameName)
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        self.itemList = frameTbl.trackedIDs
        self.displayName = frameTbl.name
    end

    self.hideInactive = false

    --self.itemList = CopyTable(Addon.trackedIDs)
    local itemResetCallback = function(pool, itemFrame)
		Pool_HideAndClearAnchors(pool, itemFrame)
		itemFrame.layoutIndex = nil
        itemFrame.fakeAura = nil
        itemFrame.slotID = nil
        itemFrame.itemID = nil
        itemFrame.spellID = nil
        itemFrame.baseSpellID = nil
        itemFrame.count = nil
        itemFrame.isOnAuraTimer = nil
        itemFrame.isOnActualCooldown = nil
        itemFrame.isOnChargeCooldown = nil
        local cooldownFrame = itemFrame:GetCooldownFrame()
        local auraCooldown = itemFrame:GetAuraFrame()
        CooldownFrame_Clear(cooldownFrame)
        CooldownFrame_Clear(auraCooldown)
        itemFrame:UnregisterAllEvents()
	end

    self.itemPool = CreateFramePool("Frame", self.Container, self.itemTemplate, itemResetCallback)

    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.EndOrderChange", self.OnCustomItemListReorderEnded)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemAdded", self.OnCustomItemListItemUpdate)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemRemoved", self.OnCustomItemListItemUpdate)
    self:AddDynamicEventMethod(EventRegistry, "EditMode.Enter", self.OnEditModeEnter)
    self:AddDynamicEventMethod(EventRegistry, "EditMode.Exit", self.OnEditModeExit)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.FakeAuraAdded", self.OnFakeAuraAdded)

    C_Timer.After(0.5, function()
        self:RefreshLayout()    
    end)

    self:SetMouseClickEnabled(false)

    Addon:BarsFadeAnim(self)
end

function ABE_CDMCustomFrameMixin:OnFakeAuraAdded(spellID, newDuration)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.itemID == spellID or itemFrame.spellID == spellID then
            itemFrame.fakeAura = newDuration
        end
    end
end

function ABE_CDMCustomFrameMixin:GetDisplayName()
    return self.displayName
end

function ABE_CDMCustomFrameMixin:SetDisplayName(name)
    self.displayName = name
end

function ABE_CDMCustomFrameMixin:GetFrameIndexByName(frameName)
    if profileTable["CDMCustomFrames"] then
        for index, data in ipairs(profileTable["CDMCustomFrames"]) do
            if data.label == frameName then
                return index
            end
        end
    end

    return false
end

function ABE_CDMCustomFrameMixin:SaveDisplayName(name)
    local frameName = self.frameName
    local frameIndex = self:GetFrameIndexByName(frameName)
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        frameTbl.name = name
    end
end

function ABE_CDMCustomFrameMixin:OnEditModeEnter()
    self.ABESelection:Show()
end

function ABE_CDMCustomFrameMixin:OnEditModeExit()
    self.ABESelection:Hide()
    self.ABESelection:SetSelected(false)
end

function ABE_CDMCustomFrameMixin:OnCustomItemListReorderEnded(itemList, frameName)
    if self:GetName() ~= frameName then return end
    self.itemList = CopyTable(itemList)
    self:RefreshLayout()
end
function ABE_CDMCustomFrameMixin:OnCustomItemListItemUpdate(itemList, frameName)
    if self:GetName() ~= frameName then return end
    self.itemList = CopyTable(itemList)
    self:RefreshLayout()
end
function ABE_CDMCustomFrameMixin:RegisterUnitAura()
    if self.hasSpellElement then
        self:RegisterUnitEvent("UNIT_AURA", "player")
        --self:RegisterUnitEvent("UNIT_AURA", "player", "target")
    else
        self:UnregisterEvent("UNIT_AURA")
    end
end

function ABE_CDMCustomFrameMixin:OnShow()
    self:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
	self:RegisterEvent("PLAYER_LEVEL_CHANGED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("FIRST_FRAME_RENDERED")
    self:RegisterEvent("UNIT_DIED")
    if self.hasSpellElement then
        self:RegisterUnitEvent("UNIT_AURA", "player")
        --self:RegisterUnitEvent("UNIT_AURA", "player", "target")
    else
        self:UnregisterEvent("UNIT_AURA")
    end
end

function ABE_CDMCustomFrameMixin:OnShow()
    self:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
	self:RegisterEvent("PLAYER_LEVEL_CHANGED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("FIRST_FRAME_RENDERED")
    self:RegisterEvent("UNIT_DIED")
    self:RegisterUnitAura()
    self:RegisterUnitEvent("UNIT_PET", "player")
    --self:RegisterEvent("PLAYER_TOTEM_UPDATE")
    --self:RegisterUnitEvent("UNIT_TARGET", "player")
end

function ABE_CDMCustomFrameMixin:OnHide()
    --[[ self:UnregisterEvent("PLAYER_IN_COMBAT_CHANGED")
	self:UnregisterEvent("PLAYER_LEVEL_CHANGED")
    self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
    self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:UnregisterEvent("PLAYER_TALENT_UPDATE")
    self:UnregisterEvent("ITEM_COUNT_CHANGED")
    self:UnregisterEvent("SPELL_UPDATE_USES")
    self:UnregisterEvent("BAG_UPDATE_DELAYED")
    self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:UnregisterEvent("TRAIT_CONFIG_UPDATED")
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED") ]]
end

local CooldownManagerFrames = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffBarCooldownViewer",
    "BuffIconCooldownViewer",
}

function ABE_CDMCustomFrameMixin:OnAuraAddedEvent(spellID, overrideSpellID, auraData)
    for itemFrame in self.itemPool:EnumerateActive() do
        if not itemFrame.__removeAura and ((itemFrame.spellID == spellID or itemFrame.baseSpellID == spellID)
        or (itemFrame.spellID == overrideSpellID or itemFrame.baseSpellID == overrideSpellID)) then
            itemFrame.auraInstanceID = auraData.auraInstanceID
            itemFrame.auraDuration = auraData.duration
            local auraDurationObject = C_UnitAuras.GetAuraDuration("player", itemFrame.auraInstanceID)
            if auraDurationObject then
                itemFrame.__auraDurationObject = auraDurationObject
                itemFrame.auraStartTime = auraDurationObject:GetStartTime()
                itemFrame.isOnAuraTimer = true
                local auraCooldown = itemFrame:GetAuraFrame()
                auraCooldown:SetCooldown(itemFrame.auraStartTime, auraData.duration)
                itemFrame:RefreshData()
            end
        end
    end
end

function ABE_CDMCustomFrameMixin:OnAuraUpdatedEvent(auraInstanceID)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.auraInstanceID == auraInstanceID then
            itemFrame.isOnAuraTimer = true
            local auraDurationObject = C_UnitAuras.GetAuraDuration("player", itemFrame.auraInstanceID)
            if auraDurationObject then
                itemFrame.auraStartTime = auraDurationObject:GetStartTime()
                local auraCooldown = itemFrame:GetAuraFrame()
                auraCooldown:SetCooldown(itemFrame.auraStartTime, itemFrame.auraDuration or auraDurationObject:GetTotalDuration()) 
                itemFrame:RefreshData()
            end
        end
    end
end
function ABE_CDMCustomFrameMixin:OnAuraRemoveEvent(auraInstanceID)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.auraInstanceID == auraInstanceID then
            itemFrame.isOnAuraTimer = false
            local auraCooldown = itemFrame:GetAuraFrame()
            CooldownFrame_Clear(auraCooldown)
            itemFrame:RefreshData()
        end
    end
end
function ABE_CDMCustomFrameMixin:UpdateAllTrinkets(usedSlot)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.slotID and itemFrame.slotID ~= usedSlot and itemFrame.slotID < 16 then
            itemFrame:RefreshData()
        end
    end
end

function ABE_CDMCustomFrameMixin:OnEvent(event, ...)
    if event == "PLAYER_IN_COMBAT_CHANGED" or event == "PLAYER_LEVEL_CHANGED" then
		--self:UpdateShownState()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot, isEmpty = ...
        if slot == 13 or slot == 14 or slot == 16 or slot == 17 then
            self:RefreshLayout()
        end
    elseif event == "PLAYER_TOTEM_UPDATE" then
        local slot = ...
		local _haveTotem, name, startTime, duration, _icon, modRate, spellID = GetTotemInfo(slot)

        --[[ for _, frameName in ipairs(CooldownManagerFrames) do
            local frame = _G[frameName]
            if frame then
                for _, itemFrame in ipairs(frame:GetItemFrames()) do
                    local totemData = itemFrame:GetTotemData()
                    if totemData then
                        print(issecretvalue(totemData.slot), totemData.slot)
                    end
                end
            end
        end ]]

    elseif event == "UNIT_AURA" then
        local unit, unitAuraUpdateInfo = ...
        if unitAuraUpdateInfo then
            if unitAuraUpdateInfo.removedAuraInstanceIDs then
                for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
                    self:OnAuraRemoveEvent(auraInstanceID)
                end
            end

            if unitAuraUpdateInfo.updatedAuraInstanceIDs then
                for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
                    self:OnAuraUpdatedEvent(auraInstanceID)
                end
            end

            if unitAuraUpdateInfo.addedAuras then
                for _, auraData in ipairs(unitAuraUpdateInfo.addedAuras) do
                    local itemFrames
                    for _, frameName in ipairs(CooldownManagerFrames) do
                        local frame = _G[frameName]
                        if frame then
                            RunNextFrame(function()
                                itemFrames = frame.auraInstanceIDToItemFramesMap[auraData.auraInstanceID]
                                if itemFrames then
                                    for _, item in ipairs(itemFrames) do
                                        local spellID = item.cooldownInfo.spellID
                                        --print("addedAuras", spellID)
                                        local overrideSpellID = item.cooldownInfo.overrideSpellID
                                        self:OnAuraAddedEvent(spellID, overrideSpellID, auraData)
                                        return
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    elseif event == "UNIT_TARGET" then
        local unit = ...
        for itemFrame in self.itemPool:EnumerateActive() do
            itemFrame:RefreshData()
        end
    elseif event == "UNIT_DIED" then
        local guid = ...
        if not issecretvalue(guid) and (guid == UnitGUID("player") and not UnitIsFeignDeath("player")) then
            for itemFrame in self.itemPool:EnumerateActive() do
                if itemFrame.isOnAuraTimer then
                    itemFrame.isOnAuraTimer = false
                    itemFrame:ClearFakeAuraSavedInfo()
                end
            end
        end
    end
    
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE"
    or event == "TRAIT_CONFIG_UPDATED" or event == "CHALLENGE_MODE_START"
    or event == "UNIT_PET" then
        self:RefreshLayout()
    end
    if event == "FIRST_FRAME_RENDERED" then
        ABE_CDMCustomFrameCustomized:RefreshAnchors(self, self.frameName)
    end
end

function ABE_CDMCustomFrameMixin:OnUpdate()

end

function ABE_CDMCustomFrameMixin:SetGridPadding(padding)
    padding = padding or (Addon:GetValue("CDMCustomIconPadding", nil, self.frameName) or 2)
    self.Container.childXPadding = padding
    self.Container.childYPadding = padding
end

function ABE_CDMCustomFrameMixin:SetGridDirection()
    local isHorizontal = Addon:GetValue("CDMCustomGridDirection", nil, self.frameName) == 1
    self.Container.isHorizontal = isHorizontal
end

function ABE_CDMCustomFrameMixin:SetGridStride()
    local stride = Addon:GetValue("CDMCustomStride", nil, self.frameName) or 7
    self.Container.stride = stride
end
    -- true - grows UP, false - grows DOWN
function ABE_CDMCustomFrameMixin:SetGridVerticalGrowth()

    local goingUp = Addon:GetValue("CDMVerticalGrowth", nil, self.frameName)
    self.Container.__layoutFramesGoingUp = goingUp
end
    -- true - grows LEFT, false - grows RIGHT
function ABE_CDMCustomFrameMixin:SetGridHorizontalGrowth()
    local goingRight = Addon:GetValue("CDMHorizontalGrowth", nil, self.frameName) == 1
    self.Container.layoutFramesGoingRight = goingRight
end

function ABE_CDMCustomFrameMixin:SetGridCentered(isCentered)
    self.Container.isCentered = isCentered
end

function ABE_CDMCustomFrameMixin:SetupGridLayoutParams()
    local padding = 2

    if Addon:GetValue("UseCDMCustomIconPadding", nil, self.frameName) then
        padding = (Addon:GetValue("CDMCustomIconPadding", nil, self.frameName) or 2)
    end

    local goingUp = Addon:GetValue("CDMVerticalGrowth", nil, self.frameName) == 1

    local goingRight = Addon:GetValue("CDMHorizontalGrowth", nil, self.frameName) == 1

    local isHorizontal = Addon:GetValue("CDMCustomGridDirection", nil, self.frameName) == 1

    local stride = 7

    if Addon:GetValue("UseCDMCustomStride", nil, self.frameName) then
        stride = (Addon:GetValue("CDMCustomStride", nil, self.frameName) or 7)
    end

    local container = self.Container
    container.childXPadding = padding
	container.childYPadding = padding
	container.isHorizontal = isHorizontal
	container.stride = stride
	container.layoutFramesGoingRight = goingRight
	container.layoutFramesGoingUp = goingUp
    container.alwaysUpdateLayout = true
    container.gridLayoutType = Addon:GetValue("CDMGridLayoutType", nil, self.frameName)
    container.hideInactiveType = Addon:GetValue("CurrentHideWhenInactive", nil, self.frameName)
    container.isCentered = tonumber(container.gridLayoutType) == 1
    container.keepEmpty = tonumber(container.gridLayoutType) == 3
    container.childrenSize = 30
end

function ABE_CDMCustomFrameMixin:OnAcquireItemFrame(itemFrame)
    itemFrame.wasAuraShown = itemFrame.wasAuraShown or false
    itemFrame.isOnActualCooldown = itemFrame.isOnActualCooldown or false
    local applications = itemFrame.Icon.Applications or itemFrame.Applications
    applications.Applications:SetText("")
    itemFrame.fakeAura = itemFrame:GetFakeAura()
    itemFrame.stages = nil
    --itemFrame:RefreshVisibility()
    --itemFrame:RefreshCount()
    itemFrame:RefreshData()
	--itemFrame:SetHideWhenInactive(self.hideWhenInactive);
end

function ABE_CDMCustomFrameMixin:FindAuraForCurrentSpellID(spellID)
    for cdID, data in pairs(CooldownViewerSettings:GetDataProvider():GetDisplayData().cooldownInfoByID) do
        local itemSpellID = data.spellID
        if itemSpellID == spellID and data.isKnown then
            return true
        end
    end
    return false
end

function ABE_CDMCustomFrameMixin:GetVisibleChildren()

    self.visibleChildren = {}
    self.hasSpellElement = false

    for index, data in ipairs(self.itemList) do
        local isKnown = false
        if data.type == "spell" then
            for i=1, 0, -1 do
                if not isKnown then
                    isKnown = C_SpellBook.IsSpellKnownOrInSpellBook(data.baseID or data.id, i)
                end
            end
            if not isKnown then
                isKnown = self:FindAuraForCurrentSpellID(data.baseID or data.id)
            end
        end
        if data.type == "slot" then
            local itemInfo = C_TooltipInfo.GetInventoryItem("player", data.id)
            local spellName, spellID
            if itemInfo then
                spellName, spellID = C_Item.GetItemSpell(itemInfo.id)
            end

            isKnown = spellID and true or false
        end
        if data.type == "item" then
            isKnown = true

            local isHealthstone = IsHealthstoneItem(data.id)

            if isHealthstone then
                local isDemonicHs = C_SpellBook.IsSpellKnown(386689)
                if isDemonicHs then
                    data.id = 224464
                else
                    data.id = 5512
                end
            end

            if not C_Item.IsItemDataCachedByID(data.id) then
                local itemData = Item:CreateFromItemID(tonumber(data.id))
                itemData:ContinueOnItemLoad(function()
                    self:RefreshLayout()
                end)
                return                
            end
            local spellName, spellID = C_Item.GetItemSpell(data.id)
            local count = C_Item.GetItemCount(data.id, nil, true) or 0
            local isUsable = C_Item.IsUsableItem(data.id)
            local hideEmpty = Addon:GetValue("CDMCustomHideEmpty", nil, self.frameName)
            if not spellID or ( count == 0 and hideEmpty ) then
                isKnown = false
            end
        end
        if isKnown then
            local item = self.itemPool:Acquire()
            item.layoutIndex = index
            if data.type == "spell" then
                item:SetSpellID(data.id, data.baseID)
                self.hasSpellElement = true
            elseif data.type == "item" then
                item:SetItemID(data.id)
            elseif data.type == "slot" then                
                item:SetSlotID(data.id)
            end
            
            item.type = data.type

            item:Show()
            table.insert(self.visibleChildren, item)
            item.parentName = self.frameName
            self:OnAcquireItemFrame(item)
        end
	end
    self:RegisterUnitAura()
    return self.visibleChildren

end

function ABE_CDMCustomFrameMixin:RefreshLayout()
    if not self.itemList then return end

    self:SetupGridLayoutParams()

    if self.itemPool then
	    self.itemPool:ReleaseAll()
    end
	local dataProvider = CreateDataProvider(self.itemList)

    local visibleChildren = self:GetVisibleChildren()

    if not visibleChildren then
        return
    end

    if self.itemPool:GetNumActive() == 0 then
        --show empty
    end

    ABE_CDMCustomFrameCustomized:RefreshSkin(self, self.frameName)

    self.Container.__wasVisibleChildren = nil

    if self.Container.isCentered then
        Addon:ApplyCenteredGridLayout(self.Container, visibleChildren, self.Container.stride, self.Container.childXPadding)
    else
        Addon:ApplyStandardGridLayout(self.Container, visibleChildren, self.Container.stride, self.Container.childXPadding)
    end
	--self.Container:Layout()
    self:ResizeFrame(self, visibleChildren)
end

function ABE_CDMCustomFrameMixin:RefreshVisibileOnCD()
    if self.visibleChildren then
        for _, frame in ipairs(self.visibleChildren) do
            frame.__isEditing = self.isEditing
        end
            
        if self.Container.isCentered then
            Addon:ApplyCenteredGridLayout(self.Container, self.visibleChildren, self.Container.stride, self.Container.childXPadding)
        else
            Addon:ApplyStandardGridLayout(self.Container, self.visibleChildren, self.Container.stride, self.Container.childXPadding)
        end

        self:ResizeFrame(self, self.visibleChildren)
    end
end

function ABE_CDMCustomFrameMixin:ResizeFrame(frame, visibleChildren)
    local layoutChildren = visibleChildren or self.Container:GetLayoutChildren()

    frame:SetSize(1,1)

    if #layoutChildren == 0 then
        self.Container:SetSize(38,38)
        self:UpdateContainerAnchor()
        return 
    end

    local width = layoutChildren[1]:GetWidth()
    local height = layoutChildren[1]:GetHeight()

    if width == 0 or height == 0 then
        width, height = 40, 40
    end

    local numActive = self.itemPool:GetNumActive()
    local isHorizontal = self.Container.isHorizontal
    local padding = self.Container.childXPadding
    local stride = self.Container.stride

    stride = math.min(stride, #layoutChildren)

    local numRows = math.ceil(numActive / stride)
    local totalWidth
    local totalHeight
    if isHorizontal then
        totalWidth = (stride * width) + ((stride - 1) * padding)
        totalHeight = (numRows * height) + ((numRows - 1) * padding)
    else
        totalWidth = (numRows * width) + ((numRows - 1) * padding)
        totalHeight = (stride * height) + ((stride - 1) * padding)
    end
    if self.Container.isCentered then
        --frame:SetSize(totalWidth, totalHeight)
    end

    frame:SetSize(width, height)
    self.Container:SetSize(totalWidth, totalHeight)
    self:UpdateContainerAnchor()
end

function ABE_CDMCustomFrameMixin:UpdateContainerAnchor()
    local container = self.Container
    local goingRight = container.layoutFramesGoingRight
    local goingUp = container.layoutFramesGoingUp
    local isCentered = container.isCentered

    container:ClearAllPoints()

    local point, relativePoint
    if isCentered then
        point = "CENTER"
    elseif goingUp then
        point = goingRight and "BOTTOMLEFT" or "BOTTOMRIGHT"
    else
        point = goingRight and "TOPLEFT" or "TOPRIGHT"
    end

    container:SetPoint(point, self, point)
end

function ABE_CDMCustomFrameMixin:CreateFrame(name, parent, point, relativePoint, offsetX, offsetY, template)
    parent = parent or _G["UIParent"]
    point = point or "CENTER"
    relativePoint = relativePoint or "CENTER"
    template = template or "ABE_CDMCustomFrame"

    local frame = CreateFrame("Frame", name, UIParent, template)
    frame:Show()
    frame:SetPoint(point, UIParent, relativePoint, math.ceil(offsetX) or 0, math.ceil(offsetY) or 0)
    frame.template = template

    return frame, { x = offsetX, y = offsetY }
end

function ABE_CDMCustomFrameMixin:DeleteFrame()
    
end
--------------------------------

local ABE_CDMCustomFrameSelectionLayout =
{
	["TopRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x=8, y=8 },
	["TopLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x=-8, y=8 },
	["BottomLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x=-8, y=-8 },
	["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner",  mirrorLayout = true, x=8, y=-8 },
	["TopEdge"] = { atlas = "_%s-NineSlice-EdgeTop" },
	["BottomEdge"] = { atlas = "_%s-NineSlice-EdgeBottom" },
	["LeftEdge"] = { atlas = "!%s-NineSlice-EdgeLeft" },
	["RightEdge"] = { atlas = "!%s-NineSlice-EdgeRight" },
	["Center"] = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8, },
}


ABE_CDMCustomFrameSelectionMixin = {}

ABE_CDMCustomFrameSelectionManager = {}

function ABE_CDMCustomFrameSelectionMixin:OnLoad()
    self:SetSelected(false)
    NineSliceUtil.ApplyLayout(self.MouseOverHighlight, ABE_CDMCustomFrameSelectionLayout, self.highlightTextureKit)
    self.MouseOverHighlight:SetBlendMode("ADD")
end

function ABE_CDMCustomFrameSelectionMixin:OnShow()
    local parent = self:GetParent()
    parent.PulseAnim:Play()

    parent.isEditing = true
    parent:RefreshVisibileOnCD()
end
function ABE_CDMCustomFrameSelectionMixin:OnHide()
    local parent = self:GetParent()
    parent.PulseAnim:Stop()

    parent.isEditing = false
    parent:RefreshVisibileOnCD()
end

function ABE_CDMCustomFrameSelectionMixin:OnDragStart()
    self:GetParent().moving = true
    self:GetParent():StartMoving()
end

function ABE_CDMCustomFrameSelectionMixin:OnDragStop()
    local frame = self:GetParent()
    frame.moving = nil
    frame:StopMovingOrSizing()

    local frameName = frame:GetName()
    local centerX, centerY = frame:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()
    local offsetX = centerX - uiCenterX
    local offsetY = centerY - uiCenterY

    if profileTable["CDMCustomFrames"] then
        for index, data in ipairs(profileTable["CDMCustomFrames"]) do
            if data.label == frameName then
                data.point.x = offsetX
                data.point.y = offsetY
            end
        end
    end
end

local movementKeys = {
	UP = true,
	DOWN = true,
	LEFT = true,
	RIGHT = true,
}

function ABE_CDMCustomFrameSelectionMixin:OnKeyDown(key)
    if not self.isSelected then return end

	if movementKeys[key] then
		self:ProcessMovementKey(key)
    elseif key == "ESCAPE" then
        self:SetSelected(false)
    end
end

function ABE_CDMCustomFrameSelectionMixin:OnMouseDown(button)
    if not self.isSelected then
        self:SetSelected(true)
    end
end

function ABE_CDMCustomFrameSelectionMixin:ProcessMovementKey(key)
    local frame = self:GetParent()

	if not self.isSelected then
		return
	end

	local deltaAmount = 1
    if IsShiftKeyDown() then
        deltaAmount = 10
    elseif IsAltKeyDown() then
        deltaAmount = 100
    end

	local xDelta, yDelta = 0, 0
	if key == "UP" then
		yDelta = deltaAmount
	elseif key == "DOWN" then
		yDelta = -deltaAmount
	elseif key == "LEFT" then
		xDelta = -deltaAmount
	elseif key == "RIGHT" then
		xDelta = deltaAmount
	end

	frame:StopMovingOrSizing()
	self:OnPositionChange(xDelta, yDelta)
end

function ABE_CDMCustomFrameSelectionMixin:OnPositionChange(deltaX, deltaY)
   
    local frame = self:GetParent()
    local frameName = frame:GetName()

    local centerX, centerY = frame:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()
    local offsetX = (centerX - uiCenterX) + deltaX
    local offsetY = (centerY - uiCenterY) + deltaY

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)

    if profileTable["CDMCustomFrames"] then
        for index, data in ipairs(profileTable["CDMCustomFrames"]) do
            if data.label == frameName then
                data.point.x = offsetX
                data.point.y = offsetY
            end
        end
    end
end

function ABE_CDMCustomFrameSelectionMixin:OnEnter()
    self.MouseOverHighlight:SetShown(true)
    self.Label:SetFontObjectsToTry("GameFontHighlightLarge", "GameFontHighlightMedium", "GameFontHighlightSmall", "GameFontWhiteTiny2")
    self.Label:SetText(self:GetParent():GetDisplayName())
    self.Label:Show()
    self.Label:SetIgnoreParentAlpha(true)
end

function ABE_CDMCustomFrameSelectionMixin:OnLeave()
    self.MouseOverHighlight:SetShown(false)
    self.Label:Hide()
end

function ABE_CDMCustomFrameSelectionMixin:SetSelected(selected)
    local selectionManager = ABE_CDMCustomFrameSelectionManager
    self.isSelected = selected
    if self.isSelected then
        if selectionManager.currentlySelected and selectionManager.currentlySelected ~= self then
            selectionManager.currentlySelected:SetSelected(false)
        end
        selectionManager.currentlySelected = self
        
        self:EnableKeyboard(true)
		NineSliceUtil.ApplyLayout(self, ABE_CDMCustomFrameSelectionLayout, self.selectedTextureKit)

        self.FrameGrid:Show()
	else
        if selectionManager.currentlySelected == self then
            selectionManager.currentlySelected = nil
        end

        self:EnableKeyboard(false)
        NineSliceUtil.ApplyLayout(self, ABE_CDMCustomFrameSelectionLayout, self.highlightTextureKit)

        self.FrameGrid:Hide()
    end
end

-----------------------------------------------


local function OnCreateNewMenuFrame(self, frameLabel, displayName)
    local frame = ABE_CDMCustomFrameMixin:CreateFrame(frameLabel, nil, nil, nil, 0, 0)
    frame:SetDisplayName(displayName)
end

local function OnDeleteMenuFrame(self, frameLabel)
    local frame = _G[frameLabel]
    if frame then
        frame:UnregisterAllEvents()
        frame:Hide()
        _G[frameLabel] = nil
    end

    local frameIndex = ABE_CDMCustomFrameMixin:GetFrameIndexByName(frameLabel)
    if profileTable["CDMCustomFrames"] then
        if frameLabel == profileTable["CDMCustomFrames"][frameIndex].label then
            table.remove(profileTable["CDMCustomFrames"], frameIndex)
        end
    end
    if profileTable[frameLabel] then
        wipe(profileTable[frameLabel])
        profileTable[frameLabel] = nil
    end
end


local function ProcessEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        
        if not ABE_FAKE_AURAS then
            ABE_FAKE_AURAS = {}
        end

        profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()

        EventRegistry:RegisterCallback("CDMCustomItemList.CreateNewFrame", OnCreateNewMenuFrame, eventHandlerFrame)
        EventRegistry:RegisterCallback("CDMCustomItemList.DeleteFrame", OnDeleteMenuFrame, eventHandlerFrame)

        if not profileTable["CDMCustomFrames"] then return end

        for index, data in ipairs(profileTable["CDMCustomFrames"]) do
            if data then
                local frame = ABE_CDMCustomFrameMixin:CreateFrame( profileTable["CDMCustomFrames"][index].label, nil, nil, nil, data.point.x or 0, data.point.y or 0, data.template)
                frame:SetDisplayName(data.name)
            end
        end
    end
end

local eventHandlerFrame = CreateFrame('Frame')
eventHandlerFrame:SetScript('OnEvent', ProcessEvent)
eventHandlerFrame:RegisterEvent('PLAYER_LOGIN')