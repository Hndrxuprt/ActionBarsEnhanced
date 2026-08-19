local Addon = _G.HUI

local profileTable

Addon.SPELLID_TO_AURASPELLID = {
    
}

local function BuildSpellIDToAuraSpellID()
    for cdID, data in pairs(CooldownViewerSettings:GetDataProvider():GetDisplayData().cooldownInfoByID) do
        if data.overrideTooltipSpellID or data.overrideSpellID or data.spellID then
            local spellID = data.overrideTooltipSpellID or data.overrideSpellID or data.spellID
            if spellID then
                if not Addon.SPELLID_TO_AURASPELLID[spellID] then
                    Addon.SPELLID_TO_AURASPELLID[spellID] = {}
                end
                if data.hasAura then
                    Addon.SPELLID_TO_AURASPELLID[spellID].linkedSpellIDs = #data.linkedSpellIDs > 0 and data.linkedSpellIDs or {[1] = spellID}
                elseif data.selfAura then
                    Addon.SPELLID_TO_AURASPELLID[spellID].linkedSpellIDs = {[1] = spellID}
                end
                Addon.SPELLID_TO_AURASPELLID[spellID].auraUnit = C_Spell.IsSpellHelpful(spellID) and "player" or "target"
            end
        end
    end
end

local CooldownManagerFrames = {
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

local isBeta = Addon.IsBeta

local function IsOnGCD()
    local gcdInfo = C_Spell.GetSpellCooldown(61304)

    local isOnGCD = false
    if gcdInfo and gcdInfo.duration ~= 0 then
        isOnGCD = true
    end

    return isOnGCD
end

HUI_CDMCustomItemMixin = {}

function HUI_CDMCustomItemMixin:GetAuraFrame()
    return self.Icon.AuraCooldown or self.AuraCooldown
end
function HUI_CDMCustomItemMixin:GetCooldownFrame()
    return self.Icon.Cooldown or self.Cooldown
end
function HUI_CDMCustomItemMixin:OnLoad()
    local cooldownFrame = self:GetCooldownFrame()
    local auraCooldown = self:GetAuraFrame()
    cooldownFrame:SetScript("OnCooldownDone", GenerateClosure(self.OnCooldownDone, self))
    auraCooldown:SetScript("OnCooldownDone", GenerateClosure(self.OnAuraDone, self))
    self:SetMouseClickEnabled(false)
end

function HUI_CDMCustomItemMixin:OnShow()
    --[[ if self:GetSpellID() then
        C_Timer.After(0, function()
            Addon:DebugPrint("OnShow", self.spellID)
            self:RefreshData()
        end)
    end ]]
    
    if not self.registeredEvents then
        self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
        self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
        self:RegisterEvent("SPELL_UPDATE_ICON")
        self:RegisterEvent("SPELL_UPDATE_CHARGES")
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        self:RegisterEvent("SPELL_UPDATE_USES")
        self:RegisterEvent("SPELL_UPDATE_USABLE")
        self:RegisterEvent("ITEM_COUNT_CHANGED")
        self:RegisterEvent("BAG_UPDATE_DELAYED")
        self:RegisterEvent("BAG_UPDATE_COOLDOWN")
        --self:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
        self:RegisterEvent("ENCOUNTER_END")
        self:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

        --because icon bugged on AuraButton after STOP_MOVIE event
        self:RegisterEvent("CINEMATIC_STOP")
        self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
        self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
        self:RegisterUnitEvent("UNIT_FACTION", "player")
        self:RegisterUnitEvent("UNIT_FLAGS", "player")

        self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
        self.registeredEvents = true
    end
    
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

function HUI_CDMCustomItemMixin:OnEvent(event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" then
		local spellID, baseSpellID, category, startRecoveryCategory = ...
        if spellID and (self.spellID == spellID or (baseSpellID and (self.baseSpellID == baseSpellID))
        or (self.overrideID == spellID)) then
            if self.slotID == 13 or self.slotID == 14 then
                local frame = _G[self.parentName]
                frame:UpdateAllTrinkets(self.slotID)
            end
            self:OnSpellUpdateCooldownEvent()
        elseif startRecoveryCategory == 133 then
            local cooldownFrame = self:GetCooldownFrame()
            if cooldownFrame.showGCDSwipe then
                self:OnSpellUpdateCooldownEvent()
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        if self.spellID == spellID or self.baseSpellID == spellID or self.overrideID == spellID then
            if self.fakeAura then
                self:RefreshFakeAuraInfo(true)
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
    elseif event == "BAG_UPDATE_COOLDOWN" then
        if self.type == "item" then
            self:RefreshCount()
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local spellID = ...
        local baseSpellID = C_Spell.GetBaseSpell(spellID)
        local isBar = self:IsBarFrame()
        if not isBar and (self.type == "spell" and (self.spellID == spellID or self.baseSpellID == spellID)
        or (self.spellID == baseSpellID or self.baseSpellID == baseSpellID)) then
            local isSpellOverlayed = spellID and C_SpellActivationOverlay.IsSpellOverlayed(spellID) or false
            local parent = self.realAuraFrame or self
            if isSpellOverlayed then
                ActionButtonSpellAlertManager:ShowAlert(self)
                if self.SpellActivationAlert then
                    self.SpellActivationAlert:SetFrameLevel(self:GetFrameLevel() + 10)
                end
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
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        if difficultyID > 13 and difficultyID < 18 then
            self.isOnActualCooldown = false
            self.isOnChargeCooldown = false
            RunNextFrame(function()
                self:RefreshData()
            end)
        end
    elseif event == "PLAYER_IN_COMBAT_CHANGED" then
        local inCombat = ...
        --self:RefreshProcAnim(inCombat)
    elseif event == "SPELL_RANGE_CHECK_UPDATE" then
        if self.type == "spell" then
            local spellID, inRange, checksRange = ...
            if self.rangeCheckSpellID == spellID then
                if not checksRange or inRange then
                    self.spellOutOfRange = false
                else
                    self.spellOutOfRange = true
                end
                self:RefreshIconColor()
            end
        end
    elseif event == "SPELL_UPDATE_USABLE" then
        if self.type == "spell" then
            self:RefreshIconColor()
        end
    elseif event == "CINEMATIC_STOP"
        or event == "UNIT_FACTION"
        or event == "UNIT_FLAGS"
        or event == "UNIT_ENTERED_VEHICLE"
        or event == "UNIT_EXITED_VEHICLE" then
            if not self.auraResetTimer then
                self:ResetAuraContainerAfterMovie()
            end
    end
end

function HUI_CDMCustomItemMixin:OnEnter()
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

function HUI_CDMCustomItemMixin:OnLeave()
    GetAppropriateTooltip():Hide()

    local frame = _G[self.parentName]

    if frame.fade then
        Addon:Fade(frame, false)
    end
end

function HUI_CDMCustomItemMixin:SetSlotID(slotID, fallbackItemID)
    local itemInfo = C_TooltipInfo.GetInventoryItem("player", slotID)
    local itemID = itemInfo and itemInfo.id or GetInventoryItemID("player", slotID) or fallbackItemID
    local spellName, spellID
    if itemID then
        spellName, spellID = C_Item.GetItemSpell(itemID)
    end

    self.count = 0
    self.slotID = slotID
    self.itemID = itemID
    self.spellID = spellID
    self.baseSpellID = nil
    self.overrideID = nil
end

function HUI_CDMCustomItemMixin:SetSpellID(spellID, baseSpellID)
    self.slotID = nil
    self.itemID = nil
    self.spellID = spellID
    self.baseSpellID = baseSpellID
    self.count = 0
    self.overrideID = C_Spell.GetOverrideSpell(spellID)
    --self:FindAuraForCurrentSpellID()

    self.rangeCheckSpellID = spellID
    self.spellOutOfRange = nil
    if C_Spell.SpellHasRange(spellID) then
        C_Spell.EnableSpellRangeCheck(spellID, true)
    end
end

function HUI_CDMCustomItemMixin:SetItemID(itemID)
    local spellName, spellID = C_Item.GetItemSpell(itemID)

    self.slotID = nil
    self.itemID = itemID
    self.spellID = spellID
    self.baseSpellID = nil
    self.overrideID = nil
end

function HUI_CDMCustomItemMixin:GetSpellID()
    if self.baseSpellID then
        return self.baseSpellID
    end

    return self.spellID
end

function HUI_CDMCustomItemMixin:GetCooldownInfo()
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

function HUI_CDMCustomItemMixin:GetCooldownDurationObj()
    if self.type == "spell" then
        local cooldownFrame = self:GetCooldownFrame()
        local ignoreGCD = not cooldownFrame.showGCDSwipe or self.barType ~= nil
        local forceSpellCD = false

        local chargeCooldownInfo = self:GetChargesCooldownInfo()

        local spellID = self.overrideID or self.baseSpellID or self.spellID

        if chargeCooldownInfo then
            if chargeCooldownInfo.maxCharges == 1 then
                forceSpellCD = true
            end
        end
        if not chargeCooldownInfo or forceSpellCD then
            self.durationObj = C_Spell.GetSpellCooldownDuration(spellID, ignoreGCD)
        else
            self.durationObj = C_Spell.GetSpellChargeDuration(spellID, ignoreGCD)
        end
    end
    return self.durationObj or nil
end


function HUI_CDMCustomItemMixin:GetSpellTexture()
    local spellID = self:GetSpellID()
    local texture = 136243
    if self.type ~= "spell" and self.itemID then
        texture = C_Item.GetItemIconByID(self.itemID)
    elseif self.type == "spell" and spellID then
        texture = C_Spell.GetSpellTexture(spellID)
    end

	return texture
end

function HUI_CDMCustomItemMixin:IsBarFrame()
    return self.barType ~= nil
end

function HUI_CDMCustomItemMixin:RefreshSpellTexture()
    local spellTexture = self:GetSpellTexture()

    local icon = self.Icon.Icon or self.Icon
    icon:SetTexture(spellTexture)
end

function HUI_CDMCustomItemMixin:RefreshIconDesaturation(desaturated)
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

function HUI_CDMCustomItemMixin:RefreshIconColor()
    local isBar = self:IsBarFrame()
    local frameName = self.parentName
    local color = {1,1,1,1}
    local desaturated = false
    local isUsable, notEnoughMana
    if self.spellID then
        isUsable, notEnoughMana = C_Spell.IsSpellUsable(self.spellID)
    end

    if (not self.isOnAuraTimer or isBar) and self.isOnActualCooldown and Addon:GetValue("UseCDColor", nil, frameName) then
        color = {Addon:GetRGBA("CDColor", nil, frameName)}
        desaturated = Addon:GetValue("CDColorDesaturate", nil, frameName)
    elseif Addon:GetValue("UseAuraColor", nil, frameName) and self.isOnAuraTimer then
        color = {Addon:GetRGBA("AuraColor", nil, frameName)}
        desaturated = Addon:GetValue("AuraColorDesaturate", nil, frameName)
    elseif self.spellOutOfRange and Addon:GetValue("UseOORColor", nil, frameName) then
        color = {Addon:GetRGBA("OORColor", nil, frameName)}
        desaturated = Addon:GetValue("OORDesaturate", nil, frameName)
    elseif notEnoughMana and Addon:GetValue("UseOOMColor", nil, frameName) then
        color = {Addon:GetRGBA("OOMColor", nil, frameName)}
        desaturated = Addon:GetValue("OOMDesaturate", nil, frameName)
    elseif not isUsable and Addon:GetValue("UseNoUseColor", nil, frameName) then
        color = {Addon:GetRGBA("NoUseColor", nil, frameName)}
        desaturated = Addon:GetValue("NoUseDesaturate", nil, frameName)
    elseif Addon:GetValue("UseNormalColor", nil, frameName) then
        color = {Addon:GetRGBA("NormalColor", nil, frameName)}
        desaturated = Addon:GetValue("NormalColorDesaturate", nil, frameName)
    end
    local icon = self.Icon.Icon or self.Icon
    icon:SetVertexColor(color[1], color[2], color[3], color[4])
    self:RefreshIconDesaturation(desaturated)
end

function HUI_CDMCustomItemMixin:RefreshCount()
    local applications = self.Icon.Applications or self.Applications
    local count = 0
    if self.type == "item" and self.itemID then
        count = C_Item.GetItemCount(self.itemID, nil, true) or 0
    elseif self.type == "spell" then
        if not self.spellID then return end

        local charges = C_Spell.GetSpellCharges(self.spellID) or {}

        count = charges and charges.currentCharges or ""

        count = charges.currentCharges or 0

        if charges.maxCharges == 1 then
            count = 0
        end

        --self.Applications:SetAlphaFromBoolean(((charges.maxCharges > 1) and (charges.currentCharges ~= nil)), tonumber(charges.currentCharges), 0 )
        --applications:SetAlpha(charges.currentCharges ~= nil and tonumber(charges.currentCharges) or 1)
    end
    self.count = count
    applications.Applications:SetText(count)
    applications:SetAlpha(count)

    if self.Bar and self.Bar.Count then
        self.Bar.Count:SetText(count)
        self.Bar.Count:SetAlpha(count)
    end

    self:RefreshIconDesaturation()
    self:RefreshSpellTexture()
    --self.ProcGlow:SetAlpha(count ~= "" and count or 1)
end

function HUI_CDMCustomItemMixin:GetChargesCooldownInfo()
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
    if not HUI_FAKE_AURAS[spellID] then
        return true
    else
        local startTime = HUI_FAKE_AURAS[spellID].startTime
        local duration = HUI_FAKE_AURAS[spellID].duration
        local savedTime = HUI_FAKE_AURAS[spellID].savedTime
        local currentTime = time()
        local time = GetTime()
        if not savedTime or not duration or ((currentTime - savedTime) >= duration) then
            HUI_FAKE_AURAS[spellID] = nil
            return true
        end
        if (time - startTime) < duration then
            return false
        elseif (time - startTime) >= duration then
            HUI_FAKE_AURAS[spellID] = nil
        end
    end
    
    return true
end

function HUI_CDMCustomItemMixin:RefreshFakeAuraInfo(reset)
    if not self.fakeAura or not self.fakeAura.duration then return false end

    if not self:IsBarFrame() and Addon:GetValue("CDMAuraRemoveSwipe", nil, self.parentName) then
        return false
    end

    local auraCooldown = self:GetAuraFrame()

    local startTime = GetTime()
    local duration = self.fakeAura.duration
    local isExpired = IsFakeAuraExpired(self.spellID)

    local cooldownFrame = self:GetCooldownFrame()
    cooldownFrame:SetAlpha(0)
    if not self.Bar then
        cooldownFrame:Show()
    end

    if HUI_FAKE_AURAS[self.spellID] then
        startTime = HUI_FAKE_AURAS[self.spellID].startTime
        duration = HUI_FAKE_AURAS[self.spellID].duration
    end

    if not self.auraDurationObj then
        self.auraDurationObj = C_DurationUtil.CreateDuration()
    end
    if not self.isOnAuraTimer then
        self.isOnAuraTimer = true
        self.auraDurationObj:SetTimeFromStart(startTime, duration)
        auraCooldown:SetCooldown(startTime, duration)
        HUI_FAKE_AURAS[self.spellID] = { startTime = startTime, duration = duration, savedTime = time() }
    elseif reset and self.fakeAura.type > 1 then
        if self.fakeAura.type == 2 then
            local curDur = self.auraDurationObj:GetRemainingDuration()
            local newDuration = curDur + self.fakeAura.duration
            self.auraDurationObj:SetTimeFromStart(GetTime(), newDuration)
            auraCooldown:SetCooldown(GetTime(), newDuration)
            HUI_FAKE_AURAS[self.spellID] = { startTime = GetTime(), duration = newDuration, savedTime = time() }
        elseif self.fakeAura.type == 3 then
            self.auraDurationObj:SetTimeFromStart(GetTime(), duration)
            auraCooldown:SetCooldown(GetTime(), duration)
            HUI_FAKE_AURAS[self.spellID] = { startTime = GetTime(), duration = duration, savedTime = time() }
        end
    end
end

function HUI_CDMCustomItemMixin:ClearFakeAuraSavedInfo()
    if HUI_FAKE_AURAS[self.spellID] then
        local auraCooldown = self:GetAuraFrame()
        CooldownFrame_Clear(auraCooldown)
        HUI_FAKE_AURAS[self.spellID] = nil
    end
    self:RefreshData()
end

function HUI_CDMCustomItemMixin:RefreshBackdrop()
    if not self.iconBorder then return end

    --self.iconBorder:SetFrameLevel(self:GetFrameLevel() + 10)

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

function HUI_CDMCustomItemMixin:RefreshSpellCooldownInfo()
    if not self.spellID then return end

    --Addon:DebugPrint("RefreshSpellCooldownInfo", self.spellID)
    local cooldownFrame = self:GetCooldownFrame()
    local auraCooldown = self:GetAuraFrame()

    if self.fakeAura and not IsFakeAuraExpired(self.spellID) then
        --Addon:DebugPrint("RefreshSpellCooldownInfo check RefreshFakeAuraInfo", self.spellID, self.layoutIndex)
        self:RefreshFakeAuraInfo()
    end

    cooldownFrame.showGCDSwipe = not (Addon:GetValue("CDMRemoveGCDSwipe", nil, self.parentName))

    cooldownFrame:SetAlpha(0)

    local showDrawEdge = true
    --self.isOnActualCooldown = false
    cooldownFrame:SetReverse(cooldownFrame.isReversed)
    auraCooldown:SetReverse(auraCooldown.isReversed)

    local chargeCooldownInfo = self:GetChargesCooldownInfo()
    local cooldownInfo = self:GetCooldownInfo()

    local durationObj

    if self.type == "spell" then
        durationObj = self:GetCooldownDurationObj()
    else
        durationObj = C_DurationUtil.CreateDuration()
        if cooldownInfo then
            durationObj:SetTimeFromStart(cooldownInfo.startTime or 0, cooldownInfo.duration or 0)
        end
    end

    if chargeCooldownInfo and chargeCooldownInfo.startTime and chargeCooldownInfo.duration then
        if chargeCooldownInfo.maxCharges > 1 then
            cooldownFrame:SetDrawSwipe(false)
        else
            cooldownFrame:SetDrawSwipe(true)
        end

        if cooldownInfo.isOnGCD == false then
            self.isOnActualCooldown = true
        else
            self.isOnActualCooldown = false
        end
        
        if self.type == "spell" and durationObj then
            cooldownFrame:SetCooldownFromDurationObject(durationObj, true)
        else
            cooldownFrame:SetCooldown(chargeCooldownInfo.startTime, chargeCooldownInfo.duration)
        end
        
        -- Action/Spell cooldown APIs now return a new non-secret isActive boolean, which is set to true if the UI should render a cooldown display.
        -- For regular cooldowns, it's true if isEnabled and startTime > 0 and duration > 0.
        -- For charge cooldowns, it's true if maxCharges > 1 and currentCharges < maxCharges and startTime > 0 and duration > 0.

        -- 12.0.5 We are adding a new ignoreGCD parameter to APIs that construct and return duration objects for cooldowns.

        if cooldownInfo.isActive or cooldownFrame:IsVisible() then
            self.isOnChargeCooldown = true
        else
            self.isOnChargeCooldown = false
        end

        --cooldownFrame:SetAlphaFromBoolean((self.isOnAuraTimer == true) or (cooldownFrame.showGCDSwipe == false and (cooldownInfo.isOnGCD == true)), 0,1)
        if not self.isOnAuraTimer then
            cooldownFrame:SetAlpha(durationObj:EvaluateRemainingDuration(Addon.alphaCurve, 0))
        end
    elseif cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
        if not self.isOnChargeCooldown then
            if self.type == "spell" and (cooldownInfo.isActive and cooldownInfo.isOnGCD ~= true) then
                self.isOnActualCooldown = true
            elseif self.type == "spell" and cooldownInfo.isOnGCD then
                self.isOnActualCooldown = false
            elseif self.type ~="spell" and cooldownInfo.duration > 0 then
                self.isOnActualCooldown = true
            end
            cooldownFrame:SetDrawSwipe(true)
            if self.type == "spell" and durationObj then
                cooldownFrame:SetCooldownFromDurationObject(durationObj, true)
            else
                cooldownFrame:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
            end
            if not self.Bar then
                cooldownFrame:Show()
            end

            if cooldownInfo.enable == false then
                cooldownFrame:Pause()
            else
                cooldownFrame:Resume()
            end
            if not self.isOnAuraTimer and durationObj then
                cooldownFrame:SetAlpha(durationObj:EvaluateRemainingDuration(Addon.alphaCurve, 0))
            end
            --[[ cooldownFrame:SetAlphaFromBoolean(self.isOnActualCooldown or cooldownInfo.isOnGCD == true,1,0)
            if self.spellID == 322101 then
                print(self.isOnActualCooldown, cooldownInfo.isOnGCD, cooldownInfo.isActive)
                print(cooldownFrame:GetAlpha())
            end ]]
        end
    else
        CooldownFrame_Clear(cooldownFrame)
        self.isOnActualCooldown = false
        self.isOnAuraTimer = false
    end
end

function HUI_CDMCustomItemMixin:RefreshData()
    --if not self:IsVisible() then return end
    self:RefreshSpellCooldownInfo()
    --self:RefreshAuraInstance()
    --self:RefreshSpellTexture()
    self:AddAuraSlot()
    if self.type == "item" and IsHealthstoneItem(self.itemID) then
        C_Timer.After(0.5, function()
            self:RefreshCount()
            self:RefreshVisibility()
        end)
    else
        self:RefreshCount()
        self:RefreshVisibility()
    end
    self:RefreshBackdrop()
    self:RefreshIconColor()

    
    --self:RefreshProcAnim()
end

function HUI_CDMCustomItemMixin:RefreshVisibility()
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
    self.Icon:Show()
    if self.iconBorder then
        self.iconBorder:Show()
    end
    local cooldownFrame = self:GetCooldownFrame()
    if cooldownFrame then cooldownFrame:Show() end

    local hideType = parentFrame.Container.hideInactiveType

    local hideEmpty = Addon:GetValue("CDMCustomHideEmpty", nil, self.parentName)
    if hideType == 5 then
        if self.isOnActualCooldown then
            self.__isActive = true
        else
            self.__isActive = false
        end
        parentFrame:RefreshVisibileOnCD()
    elseif hideType == 4 then
        
        if not self.isOnActualCooldown or self.isOnAuraTimer then
            self.__isActive = true
        else
            self.__isActive = false
        end
        parentFrame:RefreshVisibileOnCD()
    elseif hideType == 3 then
        if self.isOnActualCooldown or self.isOnAuraTimer or self.isOnChargeCooldown then
            self.__isActive = true
        else
            self.__isActive = false
        end
        parentFrame:RefreshVisibileOnCD()
    elseif hideType == 2 then
        if self.isOnAuraTimer or self.AuraSet then
            self.__isActive = true
            if self.AuraSet then
                self.Icon:Hide()
                if self.iconBorder then
                    self.iconBorder:Hide()
                end
            end
            local cooldownFrame = self:GetCooldownFrame()
            if cooldownFrame then cooldownFrame:Hide() end
        else
            self.__isActive = false
        end
        parentFrame:RefreshVisibileOnCD()
    elseif hideType == 1 then
        self.__isActive = nil
    end

    if hideEmpty and self.type == "item" then
        if not self.isOnAuraTimer and not self.AuraSet and self.count == 0 then
            self.__isActive = false
            self.__shouldBeVisible = false
        else
            self.__shouldBeVisible = true
        end
        parentFrame:RefreshVisibileOnCD()
    end
end

function HUI_CDMCustomItemMixin:OnSpellUpdateCooldownEvent()
    self.isOnChargeCooldown = false
    self.isOnActualCooldown = false
    
    self:RefreshData()
end

function HUI_CDMCustomItemMixin:OnSpellUpdateUsesEvent()
    --self.count = C_Spell.GetSpellCharges(self:GetSpellID())
    RunNextFrame(function()
        self:RefreshCount()
    end)
    
end

function HUI_CDMCustomItemMixin:OnAuraDone()
    self.isOnAuraTimer = false
    --[[ self.Cooldown:SetAlpha(1)
    self.Cooldown:Show() ]]
    RunNextFrame(function()
        self:RefreshData()
    end)
end

function HUI_CDMCustomItemMixin:OnCooldownDone()
    self.isOnActualCooldown = false
    self.isOnChargeCooldown = false
    --self.isOnAuraTimer = false
    RunNextFrame(function()
        self:RefreshData()
    end)
end

--[[ function HUI_CDMCustomItemMixin:ShowProcGlow()
    self.ProcGlow:Show()
    self.ProcGlow.ProcStartAnim:Play()
end
function HUI_CDMCustomItemMixin:HideProcGlow()
    self.ProcGlow.ProcLoop:Stop()
    self.ProcGlow:Hide()
end ]]


function HUI_CDMCustomItemMixin:RefreshProcAnim(inCombat)
    if not self:IsVisible() then return end
    local inCombat = inCombat or InCombatLockdown()
    local count
    if self.item then
        count = self.count
    end
    if self.isOnAuraTimer or self.isOnActualCooldown or not inCombat or (count == 0) then
        ActionButtonSpellAlertManager:HideAlert(self)
    elseif not self.isOnAuraTimer and not self.isOnActualCooldown and inCombat then
        --Addon:DebugPrint("RefreshProcAnim Playing", self.ProcGlow.ProcLoop:IsPlaying() )
        ActionButtonSpellAlertManager:ShowAlert(self)
    end
end

function HUI_CDMCustomItemMixin:GetFakeAura()
    if not self.spellID then return end
    local frameName = self.parentName
    local parentFrame = _G[frameName]
    if not parentFrame then return end
    local frameIndex = parentFrame:GetFrameIndexByName(frameName)
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.fakeAuras and frameTbl.fakeAuras[self.itemID or self.spellID] then
            return frameTbl.fakeAuras[self.itemID or self.spellID]
        end
    end
end

function HUI_CDMCustomItemMixin:SaveRealAuraInit(spellIDs)

    if not self.spellID and not self.itemID then return end

    local frameName = self.parentName
    local parentFrame = _G[frameName]
    if not parentFrame then return end
    local frameIndex = parentFrame:GetFrameIndexByName(frameName)
    local spellID = self.itemID or self.spellID

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl then
            if not frameTbl.realAuras then
                frameTbl.realAuras = {}
            end
            if not frameTbl.realAuras[spellID] then
                frameTbl.realAuras[spellID] = spellIDs
            end
        end
    end

end

function HUI_CDMCustomItemMixin:GetRealAura()
    if not self.spellID then return end
    local frameName = self.parentName
    local parentFrame = _G[frameName]
    if not parentFrame then return end
    local frameIndex = parentFrame:GetFrameIndexByName(frameName)
    local spellID = self.itemID or self.baseSpellID or self.spellID

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.realAuras and frameTbl.realAuras[spellID] then
            return frameTbl.realAuras[spellID] or {}
        end
    end
end

function HUI_CDMCustomItemMixin:GetAuraContainer()
    return self.AuraContainer
end

function HUI_CDMCustomItemMixin:CreateAuraContainer()
    if not self.AuraContainer then
        self.AuraContainer = CreateFrame("AuraContainer", nil, self, "HUI_CDMAuraContainer")
    end
    return self.AuraContainer
end

function HUI_CDMCustomItemMixin:AnchorAuraContainer()
    local container = self:GetAuraContainer()

    container:ClearAllPoints()
    container:SetPoint("CENTER", self, "CENTER")

end

function HUI_CDMCustomItemMixin:CreatePandemicElements(auraButton)
    local realAuraFrame = self.realAuraFrame
    if not realAuraFrame or realAuraFrame.pandemicBorder then return end
    if Addon:GetValue("CDMRemovePandemic", nil, self.parentName) then return end

    realAuraFrame.pandemicBorder = Addon.CreateBorder(realAuraFrame, self.parentName)
    local pColor = {}
    pColor.r, pColor.g, pColor.b, pColor.a = Addon:GetRGBA("CDMBackdropPandemicColor", nil, self.parentName)
    realAuraFrame.pColor = pColor
    realAuraFrame.pandemicBorder:Show()
    realAuraFrame.pandemicBorder:SetFrameLevel(realAuraFrame:GetFrameLevel() + 2)

    realAuraFrame.pandemicGlow = CreateFrame("Frame", nil,  realAuraFrame, "HUI_CDMCustomItemPandemicGlow")
    realAuraFrame.pandemicGlow:SetPoint("TOPLEFT", realAuraFrame, "TOPLEFT", -6, 6)
    realAuraFrame.pandemicGlow:SetPoint("BOTTOMRIGHT", realAuraFrame, "BOTTOMRIGHT", 6, -6)
    realAuraFrame.pandemicGlow:SetFrameLevel(realAuraFrame:GetFrameLevel() + 3)
    realAuraFrame.pandemicGlow:Show()
    realAuraFrame.pandemicGlow.FX.Anim:Play()

    realAuraFrame.pandemicBorder.pandemicRegionIndex = auraButton:AddPandemicRegion(realAuraFrame.pandemicBorder)
    realAuraFrame.pandemicGlow.pandemicRegionIndex = auraButton:AddPandemicRegion(realAuraFrame.pandemicGlow)
end

function HUI_CDMCustomItemMixin:ConfigureAuraContainer(auraButton)
    if not auraButton:CanBeAccessedInContext() then
        return
    end

    local container = self:GetAuraContainer()
    local auraCooldown = self:GetAuraFrame()
    
    if not self.realAuraFrame then
        self.realAuraFrame = CreateFrame("Frame", nil, auraButton)
        self.realAuraFrame:SetAllPoints(self)
        self.realAuraFrame:SetFrameLevel(self:GetFrameLevel() + 6)

        self.realAuraFrame.iconBorder = Addon.CreateBorder(self.realAuraFrame, self.parentName)
        local color = {r=1,g=0,b=0,a=1}
        color.r, color.g, color.b, color.a = Addon:GetRGBA("CDMBackdropAuraColor", nil, self.parentName)
        self.realAuraFrame.color = color
        --self.realAuraFrame.iconBorder:Show()
        self.realAuraFrame.iconBorder:SetFrameLevel(self.realAuraFrame:GetFrameLevel() + 1)

        self:CreatePandemicElements(auraButton)

        self.realAuraCooldownFrame = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
        self.realAuraCooldownFrame:SetFrameLevel(self:GetFrameLevel() + 5)

        self.realAuraFrame.dispelBorder = auraButton:CreateTexture(nil, "OVERLAY")
        self.realAuraFrame.dispelBorder:SetAllPoints(auraButton)

        self.realAuraFrame.icon = auraButton:CreateTexture(nil, "OVERLAY")
        self.realAuraFrame.icon:SetAllPoints(self.Icon)
        local mask = self.Icon:GetMaskTexture(1)
        if mask then
            self.realAuraFrame.icon:AddMaskTexture(mask)
        end
        

        self.realAuraFrame.overlayFrame = CreateFrame("Frame", nil, self.realAuraFrame)
        self.realAuraFrame.overlayFrame:SetAllPoints(self.realAuraFrame)
        self.realAuraFrame.overlayFrame:SetFrameLevel(self.realAuraFrame:GetFrameLevel() + 4)

        self.realAuraFrame.overlayFrame.count = self.realAuraFrame.overlayFrame:CreateFontString(nil, "OVERLAY")
    end

    if auraButton.SetAuraBorder then
        auraButton:SetAuraBorder(self.realAuraFrame.dispelBorder, {
            showIcon = true,
            showWhenHarmful = true,
            showWhenHelpful = false,
        })
    end
    
    HUI_CDMCustomFrameCustomized:CustomizeCooldownFrame(self.realAuraCooldownFrame, self.parentName, self.Icon, true)
    HUI_CDMCustomFrameCustomized:RefreshAuraColor(self.realAuraCooldownFrame, self.parentName)
    HUI_CDMCustomFrameCustomized:RefreshAuraTimer(self.realAuraCooldownFrame, self.parentName)
    HUI_CDMCustomFrameCustomized:CustomizeCooldownFont(self.realAuraCooldownFrame, self.parentName)
    HUI_CDMCustomFrameCustomized:CustomizeStacksFont(self.realAuraFrame.overlayFrame.count, self.parentName, self.realAuraFrame)
    HUI_CDMCustomFrameCustomized:SetupBackdrop(self.realAuraFrame.iconBorder, self.parentName, self.realAuraFrame.color)
    if self.realAuraFrame.pandemicBorder then
        HUI_CDMCustomFrameCustomized:SetupBackdrop(self.realAuraFrame.pandemicBorder, self.parentName, self.realAuraFrame.pColor)
    end

    if Addon:GetValue("UseCDMBackdrop", nil, self.parentName) and Addon:GetValue("UseCDMBackdropAuraColor", nil, self.parentName) then
        self.realAuraFrame.iconBorder:Show()
    else
        self.realAuraFrame.iconBorder:Hide()
    end

    local countFormatter = Addon:GetValue("AlwaysShowStacks", nil, self.parentName) and { formatter = Addon.defaultCountFormatter } or {}
    auraButton:SetIcon(self.realAuraFrame.icon)
    auraButton:SetApplicationCount(self.realAuraFrame.overlayFrame.count, countFormatter)
    auraButton:SetDurationCooldown(self.realAuraCooldownFrame)
    auraButton:SetSize(auraCooldown:GetSize())

    local auraUnit = self:GetAuraUnit()
    container:SetUnit(auraUnit)

    self:AnchorAuraContainer()

    return auraButton
end

local elemEB = {
    [173184] = true,
    [118522] = true,
    [173183] = true,
}

function HUI_CDMCustomItemMixin:ClearAuraSlots()
    local container = self:GetAuraContainer()
    if not container then return end

    container:SetEnabled(false)
end

function HUI_CDMCustomItemMixin:AddAuraSlot()

    if self.fakeAura and self.fakeAura.duration then return end

    if not self:IsBarFrame() and Addon:GetValue("CDMAuraRemoveSwipe", nil, self.parentName) then
        return
    end

    local spellIDsRaw = self:GetRealAura()
    if not spellIDsRaw or not next(spellIDsRaw) then return end

    local spellIDs = {}
    for _, spellID in ipairs(spellIDsRaw) do
        spellIDs[tonumber(spellID)] = true
    end
    if not next(spellIDs) then return end

    local container = self:CreateAuraContainer()

    local auraUnit = self:GetAuraUnit()
    local filterString = auraUnit == "player" and "HELPFUL|PLAYER" or "HARMFUL|PLAYER"
    local IsElemHackNeeded = self:IsElemHackNeeded() == true
    local candidateFilters = {includeSpellIDs = IsElemHackNeeded and elemEB or spellIDs}

    if not self.AuraSet then
        self.aura = container:AddAuraSlot("1", filterString, {
            maxFrameCount = 1,
            sortMethod = AuraContainerSortMethod.ExpirationOnly,
            sortDirection = AuraContainerSortDirection.Reverse,
            showIcon = true,

            initializeFrame = function(button) self:ConfigureAuraContainer(button) end,

            layout = {
                elementWidth = 20,
                elementHeight = 20,
                elementSpacingX = 0,
                elementSpacingY = 0,
            },
            candidateFilters = {
                includeSpellIDs = IsElemHackNeeded and elemEB or spellIDs
            }
        })
        self.AuraSet = true
    end
    container:SetAuraSlotFilterString("1", filterString)
    container:SetAuraSlotCandidateFilters("1", candidateFilters)
    container:SetAuraSlotSortMethod("1", AuraContainerSortMethod.ExpirationOnly, AuraContainerSortDirection.Reverse)
    container:SetEnabled(true)
    container:Show()
end

function HUI_CDMCustomItemMixin:ResetAuraContainerAfterMovie()
    local container = self:GetAuraContainer()
    if not container then return end

    container:SetEnabled(false)

    self.auraResetTimer = C_Timer.After(0.4, function()
        local spellIDsRaw = self:GetRealAura()
        local spellIDs = {}
        if spellIDsRaw then
            for _, spellID in ipairs(spellIDsRaw) do
                spellIDs[tonumber(spellID)] = true
            end
        end

        local auraUnit = self:GetAuraUnit()
        local filterString = auraUnit == "player" and "HELPFUL" or "HARMFUL|PLAYER"
        local candidateFilters = {includeSpellIDs = self:IsElemHackNeeded() and elemEB or spellIDs}

        container:SetAuraSlotFilterString("1", filterString)
        container:SetAuraSlotCandidateFilters("1", candidateFilters)
        container:SetEnabled(true)
        --container:UpdateAllAuras()

        self.auraResetTimer = nil
    end)
end

function HUI_CDMCustomItemMixin:GetAuraUnit()

    local auraTbl = self:GetRealAura()
    self.auraSpellID = auraTbl and tonumber(auraTbl[1]) or self.auraSpellID or self.spellID

    local tbl = self.auraSpellID and Addon.SPELLID_TO_AURASPELLID[self.auraSpellID]
    local auraUnit
    if tbl then
        auraUnit = tbl.auraUnit
    end
    auraUnit = auraUnit or (C_Spell.IsSpellHelpful(self.auraSpellID) and "player" or "target")
    self.auraUnit = auraUnit

    return auraUnit
end

function HUI_CDMCustomItemMixin:IsElemHackNeeded()
    local auraSpellIDs = self:GetRealAura()
    if not self.elemShamHack then
        for i, auraSpellID in ipairs(auraSpellIDs or {}) do
            if elemEB[auraSpellID] then
                self.elemShamHack = true
            end
        end
    end
    return self.elemShamHack
end

function HUI_CDMCustomItemMixin:FindAuraSpellID()
    if self.type ~= "spell" then return end

    local spellID = self.baseSpellID or self.spellID

    local tbl = Addon.SPELLID_TO_AURASPELLID[spellID]
    if tbl then
        self:SaveRealAuraInit(tbl.linkedSpellIDs)
    end
end
-----------------------------
HUI_CDMCustomItemProcGlow = {}

function HUI_CDMCustomItemProcGlow:OnLoad()
    self.ProcStartAnim:SetScript("OnFinished", function()
        self.ProcLoop:Play()
    end)
end

function HUI_CDMCustomItemProcGlow:OnHide()
    if self.ProcLoop:IsPlaying() then
        self.ProcLoop:Stop()
    end
end
------------------------------

-----------------------------
HUI_CDMCustomFrameMixin = {}

function HUI_CDMCustomFrameMixin:OnLoad()

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
        if itemFrame.rangeCheckSpellID then
            C_Spell.EnableSpellRangeCheck(itemFrame.rangeCheckSpellID, false)
            itemFrame.rangeCheckSpellID = nil
        end
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
        itemFrame.registeredEvents = nil
        itemFrame.auraUnit = nil
        itemFrame.elemShamHack = nil
        itemFrame.AuraFrameCreated = nil
        itemFrame.spellOutOfRange = nil
        itemFrame:ClearAuraSlots()
	end

    self.itemPool = CreateFramePool("Frame", self.Container, self.itemTemplate, itemResetCallback)

    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.EndOrderChange", self.OnCustomItemListReorderEnded)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemAdded", self.OnCustomItemListItemUpdate)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemRemoved", self.OnCustomItemListItemUpdate)
    self:AddDynamicEventMethod(EventRegistry, "EditMode.Enter", self.OnEditModeEnter)
    self:AddDynamicEventMethod(EventRegistry, "EditMode.Exit", self.OnEditModeExit)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.FakeAuraAdded", self.OnFakeAuraAdded)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.FakeAuraTypeChanged", self.OnFakeAuraTypeChanged)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.UpdateFrame", self.OnFrameUpdate)

    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.RealAuraAdded", self.OnRealAuraAdded)

    for _, data in ipairs(self.itemList) do
        if data.type == "item" and not C_Item.IsItemDataCachedByID(tonumber(data.id)) then
            C_Item.RequestLoadItemDataByID(tonumber(data.id))
        end
    end
    self:RefreshLayout()

    self:SetMouseClickEnabled(false)

    Addon:BarsFadeAnim(self)

    self.lastRunTime = 0
end

function HUI_CDMCustomFrameMixin:OnFrameUpdate(frameName)
    if self:GetName() ~= frameName then return end
    self:RefreshLayout()
end

function HUI_CDMCustomFrameMixin:OnFakeAuraTypeChanged(spellID, newType)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.itemID == spellID or itemFrame.spellID == spellID then
            if itemFrame.fakeAura then
                itemFrame.fakeAura.type = newType
            else
                itemFrame.fakeAura = {
                    duration = 0,
                    type = newType,
                }
            end
        end
    end
end

function HUI_CDMCustomFrameMixin:OnFakeAuraAdded(spellID, newDuration)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.itemID == spellID or itemFrame.spellID == spellID then
            if itemFrame.fakeAura then
                itemFrame.fakeAura.duration = newDuration
            else
                itemFrame.fakeAura = {
                    duration = newDuration,
                    type = 1
                }
            end
            local auraContainer = itemFrame:GetAuraContainer()
            if auraContainer then
                auraContainer:SetEnabled(false)
            end
        end
    end
end

function HUI_CDMCustomFrameMixin:OnRealAuraAdded(spellID, auraSpellIDs)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.itemID == spellID or itemFrame.spellID == spellID then
            itemFrame:AddAuraSlot()
        end
    end
end

function HUI_CDMCustomFrameMixin:GetDisplayName()
    return self.displayName
end

function HUI_CDMCustomFrameMixin:SetDisplayName(name)
    self.displayName = name
end

function HUI_CDMCustomFrameMixin:GetFrameIndexByName(frameName)
    if profileTable["CDMCustomFrames"] then
        for index, data in ipairs(profileTable["CDMCustomFrames"]) do
            if data.label == frameName then
                return index
            end
        end
    end

    return false
end

function HUI_CDMCustomFrameMixin:SaveDisplayName(name)
    local frameName = self.frameName
    local frameIndex = self:GetFrameIndexByName(frameName)
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        frameTbl.name = name
    end
end

function HUI_CDMCustomFrameMixin:OnEditModeEnter()
    self.HUISelection:Show()
end

function HUI_CDMCustomFrameMixin:OnEditModeExit()
    self.HUISelection:Hide()
    self.HUISelection:SetSelected(false)
end

function HUI_CDMCustomFrameMixin:OnCustomItemListReorderEnded(itemList, frameName)
    if self:GetName() ~= frameName then return end
    self.itemList = CopyTable(itemList)
    self:RefreshLayout()
end
function HUI_CDMCustomFrameMixin:OnCustomItemListItemUpdate(itemList, frameName)
    if self:GetName() ~= frameName then return end
    self.itemList = CopyTable(itemList)
    self:RefreshLayout()
end
function HUI_CDMCustomFrameMixin:RegisterUnitAura()
    if self.hasSpellElement then
        --self:RegisterUnitEvent("UNIT_AURA", "player")
        self:RegisterUnitEvent("UNIT_AURA", "player", "target")
    else
        self:UnregisterEvent("UNIT_AURA")
    end
end


function HUI_CDMCustomFrameMixin:OnShow()
    --self:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
	self:RegisterEvent("PLAYER_LEVEL_CHANGED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_TALENT_UPDATE")
    self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("FIRST_FRAME_RENDERED")
    self:RegisterEvent("UNIT_DIED")
    --self:RegisterUnitAura()
    self:RegisterUnitEvent("UNIT_PET", "player")
    --self:RegisterEvent("PLAYER_TOTEM_UPDATE")
    self:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
end

function HUI_CDMCustomFrameMixin:OnHide()
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

function HUI_CDMCustomFrameMixin:UpdateAllTrinkets(usedSlot)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.slotID and itemFrame.slotID ~= usedSlot and itemFrame.slotID < 16 then
            itemFrame:RefreshData()
        end
    end
end

function HUI_CDMCustomFrameMixin:OnEvent(event, ...)
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
    elseif event == "PLAYER_TARGET_CHANGED" then
        local unit = ...
        for itemFrame in self.itemPool:EnumerateActive() do
            if itemFrame.auraUnit == "target" then
                local container = itemFrame:GetAuraContainer()
                if container then
                    container:UpdateAllAuras()
                end
            end
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
    
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" 
    or event == "CHALLENGE_MODE_START"
    or event == "UNIT_PET" then
        local currentTime = GetTime()
        if self.lastRunTime and currentTime - self.lastRunTime > 0.1 then
            self:RefreshLayout()
        end
        self.lastRunTime = currentTime
    end
    if event == "FIRST_FRAME_RENDERED" then
        HUI_CDMCustomFrameCustomized:RefreshAnchors(self, self.frameName)
    end
end

function HUI_CDMCustomFrameMixin:OnUpdate()

end

function HUI_CDMCustomFrameMixin:SetGridPadding(padding)
    padding = padding or (Addon:GetValue("CDMCustomIconPadding", nil, self.frameName) or 2)
    self.Container.childXPadding = padding
    self.Container.childYPadding = padding
end

function HUI_CDMCustomFrameMixin:SetGridDirection()
    local isHorizontal = Addon:GetValue("CDMCustomGridDirection", nil, self.frameName) == 1
    self.Container.isHorizontal = isHorizontal
end

function HUI_CDMCustomFrameMixin:SetGridStride()
    local stride = Addon:GetValue("CDMCustomStride", nil, self.frameName) or 7
    self.Container.stride = stride
end
    -- true - grows UP, false - grows DOWN
function HUI_CDMCustomFrameMixin:SetGridVerticalGrowth()

    local goingUp = Addon:GetValue("CDMVerticalGrowth", nil, self.frameName)
    self.Container.__layoutFramesGoingUp = goingUp
end
    -- true - grows LEFT, false - grows RIGHT
function HUI_CDMCustomFrameMixin:SetGridHorizontalGrowth()
    local goingRight = Addon:GetValue("CDMHorizontalGrowth", nil, self.frameName) == 1
    self.Container.layoutFramesGoingRight = goingRight
end

function HUI_CDMCustomFrameMixin:SetGridCentered(isCentered)
    self.Container.isCentered = isCentered
end

function HUI_CDMCustomFrameMixin:SetupGridLayoutParams()
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

function HUI_CDMCustomFrameMixin:OnAcquireItemFrame(itemFrame)
    itemFrame.wasAuraShown = itemFrame.wasAuraShown or false
    itemFrame.isOnActualCooldown = itemFrame.isOnActualCooldown or false
    local applications = itemFrame.Icon.Applications or itemFrame.Applications
    applications.Applications:SetText("")
    itemFrame.fakeAura = itemFrame:GetFakeAura()
    itemFrame.stages = nil
    itemFrame:FindAuraSpellID()
    --itemFrame:RefreshVisibility()
    --itemFrame:RefreshCount()
    itemFrame:RefreshData()
	--itemFrame:SetHideWhenInactive(self.hideWhenInactive);
end

function HUI_CDMCustomFrameMixin:FindKnownInCDM(spellID)
    for cdID, data in pairs(CooldownViewerSettings:GetDataProvider():GetDisplayData().cooldownInfoByID) do
        local itemSpellID = data.spellID
        if itemSpellID == spellID and data.isKnown then
            local auraSpellID = data.hasAura and data.linkedSpellIDs[1] or data.selfAura and data.spellID
            return true
        end
    end
    return false
end

function HUI_CDMCustomFrameMixin:GetVisibleChildren()

    self.visibleChildren = {}
    self.hasSpellElement = false

    for index, data in ipairs(self.itemList) do
        local isKnown = false
        local isRacial = false
        if data.type == "spell" and (data.baseID or data.id) then
            if Addon:IsRacialSpell(data.id) then
                Addon:LoadRacialTable()
                isRacial = true
                data.id = Addon:GetRacialSpell() or data.id
            end
            
            isKnown = self:FindKnownInCDM(data.baseID or data.id)

            if not isKnown then
                for i=1, 0, -1 do
                    if not isKnown then
                        isKnown = C_SpellBook.IsSpellKnownOrInSpellBook(data.baseID or data.id, i)
                    end
                end
            end

            if isRacial then
                local currentProfile = Addon:GetCurrentProfile()
                local trackedTable = HUIDB.Profiles.profilesList[currentProfile]["GlobalSettings"].RacialSpellsTracked
                local raceID = select(3, UnitRace("player"))
                
                if raceID == 25 or raceID == 26 then
                    raceID = 24
                elseif raceID == 70 then
                    raceID = 52
                elseif raceID == 85 then
                    raceID = 84
                elseif raceID == 91 then
                    raceID = 86
                end

                if trackedTable and not trackedTable[raceID] then
                    isKnown = false
                end
            end
        end
        local slotItemID
        if data.type == "slot" then
            local itemInfo = C_TooltipInfo.GetInventoryItem("player", data.id)
            local itemID = itemInfo and itemInfo.id or GetInventoryItemID("player", data.id) or data.baseID
            slotItemID = itemID
            if itemID and not C_Item.IsItemDataCachedByID(itemID) and C_Item.DoesItemExistByID(itemID) then
                C_Item.RequestLoadItemDataByID(itemID)
                Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                    self:RefreshLayout()
                end)
                return
            end
            local spellName, spellID
            if itemID then
                spellName, spellID = C_Item.GetItemSpell(itemID)
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
            --[[ local hideEmpty = Addon:GetValue("CDMCustomHideEmpty", nil, self.frameName)
            if not spellID or ( count == 0 and hideEmpty ) then
                isKnown = false
            end ]]
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
                item:SetSlotID(data.id, slotItemID)
            end
            
            item.type = data.type

            item:Show()
            table.insert(self.visibleChildren, item)
            item.parentName = self.frameName
            self:OnAcquireItemFrame(item)
        end
	end
    --self:RegisterUnitAura()
    return self.visibleChildren

end

function HUI_CDMCustomFrameMixin:RefreshLayout()
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

    HUI_CDMCustomFrameCustomized:RefreshSkin(self, self.frameName)

    self.Container.__wasVisibleChildren = nil

    if self.Container.isCentered then
        --self.Container:SetCollapsesLayout(true)
        Addon:ApplyCenteredGridLayout(self.Container, visibleChildren, self.Container.stride, self.Container.childXPadding)
    else
        Addon:ApplyStandardGridLayout(self.Container, visibleChildren, self.Container.stride, self.Container.childXPadding)
    end
	--self.Container:Layout()
    self:ResizeFrame(self, visibleChildren)
end

function HUI_CDMCustomFrameMixin:RefreshVisibileOnCD()
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

function HUI_CDMCustomFrameMixin:ResizeFrame(frame, visibleChildren)
    local layoutChildren = visibleChildren or self.Container:GetLayoutChildren()

    Addon.PP.Size(frame, 1)

    if #layoutChildren == 0 then
        Addon.PP.Size(self.Container, 38)
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
    local padding = Addon.PP.Scale(self.Container.childXPadding or 0)
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

    Addon.PP.Size(frame, width, height)
    Addon.PP.Size(self.Container, totalWidth, totalHeight)
    self:UpdateContainerAnchor()
end

function HUI_CDMCustomFrameMixin:UpdateContainerAnchor()
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

function HUI_CDMCustomFrameMixin:CreateFrame(name, parent, point, relativePoint, offsetX, offsetY, template)
    parent = parent or _G["UIParent"]
    point = point or "CENTER"
    relativePoint = relativePoint or "CENTER"
    template = template or "HUI_CDMCustomFrame"

    local frame = CreateFrame("Frame", name, UIParent, template)
    frame:Show()
    frame:SetPoint(point, UIParent, relativePoint, Addon.PP.Snap(offsetX) or 0, Addon.PP.Snap(offsetY) or 0)
    frame:SetFrameLevel(2)
    frame.template = template
    
    self.template = template

    return frame, { x = offsetX, y = offsetY }
end

function HUI_CDMCustomFrameMixin:DeleteFrame()
    
end

function HUI_CDMCustomFrameMixin:IsBarFrame()
    return self.template == "HUI_CDMCustomBarFrame"
end

function HUI_CDMCustomFrameMixin:GetTemplate()
    return self.template
end
--------------------------------

local HUI_CDMCustomFrameSelectionLayout =
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


HUI_CDMCustomFrameSelectionMixin = {}

HUI_CDMCustomFrameSelectionManager = {}

function HUI_CDMCustomFrameSelectionMixin:OnLoad()
    self:SetSelected(false)
    NineSliceUtil.ApplyLayout(self.MouseOverHighlight, HUI_CDMCustomFrameSelectionLayout, self.highlightTextureKit)
    self.MouseOverHighlight:SetBlendMode("ADD")
end

function HUI_CDMCustomFrameSelectionMixin:OnShow()
    local parent = self:GetParent()
    parent.PulseAnim:Play()

    parent.isEditing = true
    if parent.RefreshVisibileOnCD then
        parent:RefreshVisibileOnCD()
    end
    if parent.UpdatePlaceholders then
        parent:UpdatePlaceholders(true)
    end
end
function HUI_CDMCustomFrameSelectionMixin:OnHide()
    local parent = self:GetParent()
    parent.PulseAnim:Stop()

    parent.isEditing = false
    if parent.RefreshVisibileOnCD then
        parent:RefreshVisibileOnCD()
    end
    if parent.UpdatePlaceholders then
        parent:UpdatePlaceholders()
    end
end

function HUI_CDMCustomFrameSelectionMixin:OnDragStart()
    self:GetParent().moving = true
    self:GetParent():StartMoving()
end

function HUI_CDMCustomFrameSelectionMixin:OnDragStop()
    local frame = self:GetParent()
    frame.moving = nil
    frame:StopMovingOrSizing()

    local frameName = frame:GetName()
    local centerX, centerY = frame:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()
    local offsetX = Addon.PP.SnapCenterForDim(centerX - uiCenterX, frame:GetWidth())
    local offsetY = Addon.PP.SnapCenterForDim(centerY - uiCenterY, frame:GetHeight())

    frame:ClearAllPoints()
    Addon.PP.Point(frame, "CENTER", UIParent, "CENTER", offsetX, offsetY)

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

function HUI_CDMCustomFrameSelectionMixin:OnKeyDown(key)
    if not self.isSelected then return end

	if movementKeys[key] then
		self:ProcessMovementKey(key)
    elseif key == "ESCAPE" then
        self:SetSelected(false)
    end
end

function HUI_CDMCustomFrameSelectionMixin:OnMouseDown(button)
    if not self.isSelected then
        self:SetSelected(true)
    end
end

function HUI_CDMCustomFrameSelectionMixin:ProcessMovementKey(key)
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

function HUI_CDMCustomFrameSelectionMixin:OnPositionChange(deltaX, deltaY)
   
    local frame = self:GetParent()
    local frameName = frame:GetName()

    local centerX, centerY = frame:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()
    local offsetX = Addon.PP.SnapCenterForDim((centerX - uiCenterX) + deltaX, frame:GetWidth())
    local offsetY = Addon.PP.SnapCenterForDim((centerY - uiCenterY) + deltaY, frame:GetHeight())

    frame:ClearAllPoints()
    Addon.PP.Point(frame, "CENTER", UIParent, "CENTER", offsetX, offsetY)

    if profileTable["CDMCustomFrames"] then
        for index, data in ipairs(profileTable["CDMCustomFrames"]) do
            if data.label == frameName then
                data.point.x = offsetX
                data.point.y = offsetY
            end
        end
    end
end

function HUI_CDMCustomFrameSelectionMixin:OnEnter()
    self.MouseOverHighlight:SetShown(true)
    self.Label:SetFontObjectsToTry("GameFontHighlightLarge", "GameFontHighlightMedium", "GameFontHighlightSmall", "GameFontWhiteTiny2")
    self.Label:SetText(self:GetParent():GetDisplayName())
    self.Label:Show()
    self.Label:SetIgnoreParentAlpha(true)
end

function HUI_CDMCustomFrameSelectionMixin:OnLeave()
    self.MouseOverHighlight:SetShown(false)
    self.Label:Hide()
end

function HUI_CDMCustomFrameSelectionMixin:SetSelected(selected)
    local selectionManager = HUI_CDMCustomFrameSelectionManager
    self.isSelected = selected
    if self.isSelected then
        if selectionManager.currentlySelected and selectionManager.currentlySelected ~= self then
            selectionManager.currentlySelected:SetSelected(false)
        end
        selectionManager.currentlySelected = self
        
        self:EnableKeyboard(true)
		NineSliceUtil.ApplyLayout(self, HUI_CDMCustomFrameSelectionLayout, self.selectedTextureKit)

        self.FrameGrid:Show()
	else
        if selectionManager.currentlySelected == self then
            selectionManager.currentlySelected = nil
        end

        self:EnableKeyboard(false)
        NineSliceUtil.ApplyLayout(self, HUI_CDMCustomFrameSelectionLayout, self.highlightTextureKit)

        self.FrameGrid:Hide()
    end
end

-----------------------------------------------


local function OnCreateNewMenuFrame(self, frameLabel, displayName, template)
    local frame = HUI_CDMCustomFrameMixin:CreateFrame(frameLabel, nil, nil, nil, 0, 0, template)
    frame:SetDisplayName(displayName)
end

local function OnDeleteMenuFrame(self, frameLabel)
    local frame = _G[frameLabel]
    if frame then
        if frame.itemPool then
            frame.itemPool:ReleaseAll()
        end
        frame:UnregisterAllEvents()
        frame:Hide()
        _G[frameLabel] = nil
    end

    local frameIndex = HUI_CDMCustomFrameMixin:GetFrameIndexByName(frameLabel)
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

local function CreateProfileCustomFrames()
    if not profileTable or not profileTable["CDMCustomFrames"] then return end

    for _, data in ipairs(profileTable["CDMCustomFrames"]) do
        if data then
            local frame = HUI_CDMCustomFrameMixin:CreateFrame(data.label, nil, nil, nil, data.point and data.point.x or 0, data.point and data.point.y or 0, data.template)
            frame:SetDisplayName(data.name)
        end
    end
end

local function DestroyProfileCustomFrames()
    HUI_CDMCustomFrameSelectionManager.currentlySelected = nil

    if not profileTable or not profileTable["CDMCustomFrames"] then return end

    for _, data in ipairs(profileTable["CDMCustomFrames"]) do
        if data and data.label then
            local frame = _G[data.label]
            if frame then
                if frame.itemPool then
                    frame.itemPool:ReleaseAll()
                end
                frame:UnregisterAllEvents()
                frame:Hide()
                _G[data.label] = nil
            end
        end
    end
end

local function OnProfileChanged(self)
    DestroyProfileCustomFrames()
    profileTable = Addon:GetCurrentProfileTable()
    CreateProfileCustomFrames()
end

local eventHandlerFrame = CreateFrame('Frame')

local function OnFramePickerEnter()
    if not profileTable or not profileTable["CDMCustomFrames"] then return end
    for _, data in ipairs(profileTable["CDMCustomFrames"]) do
        local frame = data and data.label and _G[data.label]
        if frame and not frame.__pickerMode then
            frame.__pickerMode = {
                shown = frame:IsShown(),
                alpha = frame:GetAlpha(),
                mouseClicks = frame:IsMouseClickEnabled(),
                mouseMotion = frame:IsMouseMotionEnabled(),
            }
            if not frame:IsShown() then frame:Show() end
            frame:SetAlpha(1)
            frame:SetMouseClickEnabled(true)
            frame:SetMouseMotionEnabled(true)
        end
    end
end

local function OnFramePickerExit()
    if not profileTable or not profileTable["CDMCustomFrames"] then return end
    for _, data in ipairs(profileTable["CDMCustomFrames"]) do
        local frame = data and data.label and _G[data.label]
        if frame and frame.__pickerMode then
            local state = frame.__pickerMode
            frame.__pickerMode = nil
            frame:SetAlpha(state.alpha)
            frame:SetMouseClickEnabled(state.mouseClicks)
            frame:SetMouseMotionEnabled(state.mouseMotion)
            if not state.shown then frame:Hide() end
        end
    end
end

Addon:RegisterEvent("PLAYER_LOGIN", function()
    BuildSpellIDToAuraSpellID()

    if not HUI_FAKE_AURAS then
        HUI_FAKE_AURAS = {}
    end

    profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()

    EventRegistry:RegisterCallback("CDMCustomItemList.CreateNewFrame", OnCreateNewMenuFrame, eventHandlerFrame)
    EventRegistry:RegisterCallback("CDMCustomItemList.DeleteFrame", OnDeleteMenuFrame, eventHandlerFrame)
    EventRegistry:RegisterCallback("CDMCustomItemList.ProfileChanged", OnProfileChanged, eventHandlerFrame)
    EventRegistry:RegisterCallback("HUI.FramePicker.Enter", OnFramePickerEnter, eventHandlerFrame)
    EventRegistry:RegisterCallback("HUI.FramePicker.Exit", OnFramePickerExit, eventHandlerFrame)

    CreateProfileCustomFrames()
end, "CooldownManagerCustom")