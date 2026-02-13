local AddonName, Addon = ...

ABE_CDMCustomBarMixin = CreateFromMixins(ABE_CDMCustomItemMixin)

ABE_CDMCustomBarFrameMixin = CreateFromMixins(ABE_CDMCustomFrameMixin)

function ABE_CDMCustomBarMixin:OnLoad()

    local cooldownFrame = self:GetCooldownFrame()
    local auraCooldown = self:GetAuraFrame()

    cooldownFrame:SetScript("OnCooldownDone", GenerateClosure(self.OnCooldownDone, self))
    auraCooldown:SetScript("OnCooldownDone", GenerateClosure(self.OnAuraDone, self))
    self:SetMouseClickEnabled(false)

    self:SetMouseClickEnabled(false)
    self.Bar.Pip:ClearAllPoints()
    self.Bar.Pip:SetPoint("CENTER", self.Bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    self.spark = self.Bar.Pip
    self.spark:Hide()
    self.Bar:SetMinMaxValues(0, 0)
    self.Bar:SetValue(self.value or 0)

    self.color = self:GetCustomColor()
end

function ABE_CDMCustomBarFrameMixin:RefreshLayout()
    ABE_CDMCustomFrameMixin.RefreshLayout(self)

    ABE_CDMCustomFrameCustomized:RefreshItemSize(self, self.frameName)
    ABE_CDMCustomFrameCustomized:RefreshBarTextures(self, self.frameName)
    ABE_CDMCustomFrameCustomized:RefreshBarIconSize(self, self.frameName)
end

function ABE_CDMCustomBarMixin:RefreshData()
    --self:FindAuraInstanceIDForCurrentSpellID()

    ABE_CDMCustomItemMixin.RefreshData(self)
end
function ABE_CDMCustomBarMixin:GetStages()
    if not self.spellID then return end

    local spellID = self.itemID or self.baseSpellID or self.spellID
    local frameName = self.parentName
    local frameIndex = _G[frameName]:GetFrameIndexByName(frameName)
    local profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.stages then
            return frameTbl.stages[spellID]
        end
    end
end

function ABE_CDMCustomBarMixin:GetCustomColor()
    if not self.spellID then return end

    local spellID = self.itemID or self.baseSpellID or self.spellID
    local frameName = self.parentName
    local frameIndex = _G[frameName]:GetFrameIndexByName(frameName)
    local profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.color then
            return frameTbl.color[spellID]
        end
    end
end

function ABE_CDMCustomBarMixin:RefreshCount()
    ABE_CDMCustomItemMixin.RefreshCount(self)

    self:AddStages(self.stages)

    if self.stages then
        self:SetScript("OnUpdate", nil)
        
        local statusbar = self.Bar

        statusbar:SetMinMaxValues(0, self.stages)
        local count
        if self.auraData and not self.stages then
            count = self.auraData.applications
        else
            count = self.count
        end
        statusbar:SetValue(count or 0)
        self.spark:Hide()
    end
end

function ABE_CDMCustomBarMixin:OnCooldownDone()
    ABE_CDMCustomItemMixin.OnCooldownDone(self)

    self.Bar.Duration:Hide()
    self.Bar:SetMinMaxValues(0, 0)
    self.Bar:SetValue(self.value or 0)

    self.casting = false
    self.spark:Hide()
    self:SetScript("OnUpdate", nil)
end

function ABE_CDMCustomBarMixin:RefreshSpellCooldownInfo()
    ABE_CDMCustomItemMixin.RefreshSpellCooldownInfo(self)

    self.stages = self:GetStages()

    if not self.stages then
        if self.isOnAuraTimer or self.isOnActualCooldown or self.isOnChargeCooldown then
            if self:GetScript("OnUpdate") == nil then
                self:SetScript("OnUpdate", GenerateClosure(self.OnUpdate, self))
            end
        end

        if self.isOnAuraTimer then
            self.barType = "aura"
        elseif self.isOnActualCooldown or self.isOnChargeCooldown then
            
            self.barType = "cooldown"
            if self.type == "spell" then
                local durationObj = self:GetCooldownDurationObj()
                if durationObj then
                    self.maxValue = durationObj:GetTotalDuration()
                    self.casting = true
                end
            elseif self.type == "item" then
                self.maxValue = self.cooldownInfo.duration
                self.casting = true
            end
        elseif not self.isOnActualCooldown then 
            self.casting = false
        end
    end
end

function ABE_CDMCustomBarFrameMixin:OnAuraAddedEvent(spellID, overrideSpellID, auraData)
    ABE_CDMCustomFrameMixin.OnAuraAddedEvent(self, spellID, overrideSpellID, auraData)

    for itemFrame in self.itemPool:EnumerateActive() do
        if not itemFrame.__removeAura and ((itemFrame.spellID == spellID or itemFrame.baseSpellID == spellID)
        or (itemFrame.spellID == overrideSpellID or itemFrame.baseSpellID == overrideSpellID)) then
            if not itemFrame.stages then
                itemFrame.barType = "aura"
            end
        end
    end
end

function ABE_CDMCustomBarMixin:AddStages(numStages)

    local barWidth = self.Bar:GetWidth()
    if not self.StagePipPool then
        self.StagePipPool = {}
    else
        for _, pip in pairs(self.StagePipPool) do
            pip:Hide()
        end
    end

    if not numStages or numStages < 2 then return end

    for i=1, numStages-1, 1 do
        local offset = (barWidth / numStages) * i
        local stagePipName = "StagePip"..i
        local stagePip = self.StagePipPool[stagePipName]
        if not stagePip then
            stagePip = CreateFrame("FRAME", nil, self.Bar, "ABE_CDMCustomBarStagePipTemplate")
            self.StagePipPool[stagePipName] = stagePip
        end
        
        if stagePip then
            stagePip:ClearAllPoints()
            stagePip:SetPoint("CENTER", self.Bar, "LEFT", offset, 0)
            stagePip:SetSize(2, self:GetHeight())
            stagePip.BasePip:SetVertexColor(0, 0, 0, 1)
            stagePip:Show()
        end
    end
end

function ABE_CDMCustomBarMixin:OnUpdate(elapsed)
    local now = GetTime()

    if not self.casting then
        if self.__lastCheck and (now - self.__lastCheck <= 0.1) then return end

        self.__lastCheck = now
    end
    local statusbar = self.Bar
    self.spark:Hide()
    statusbar.Duration:Hide()
    statusbar:SetMinMaxValues(0, 0)
    statusbar:SetValue(self.value or 0)
    --Addon:DebugPrint(self.casting)
    if self.casting then
        if self.barType == "cooldown" then
            self.spark:Show()
            self.__isActive = true
            if self.type == "spell" then
                local durationObject = self:GetCooldownDurationObj()
                self.value = durationObject:GetRemainingDuration()
                self.maxValue = durationObject:GetTotalDuration()
                statusbar.Duration:SetAlpha(durationObject:EvaluateRemainingDuration(Addon.alphaCurve, 0))
            else
                local cooldownInfo = self:GetCooldownInfo()
                self.value = cooldownInfo.startTime > 0 and cooldownInfo.duration - (GetTime() - cooldownInfo.startTime) or 0
                statusbar.Duration:SetAlpha(self.value == 0 and 0 or 1)
            end
            statusbar:SetMinMaxValues(0, self.maxValue)
            statusbar:SetValue(self.value)
            statusbar.Duration:SetText(string.format("%.1f", self.value))
            statusbar.Duration:Show()
        elseif self.barType == "aura" then
            self.spark:Show()
            self.__isActive = true
            local auraDurationObject = C_UnitAuras.GetAuraDuration("player", self.auraInstanceID)
            if auraDurationObject then
                self.value = auraDurationObject:GetRemainingDuration()
                statusbar:SetMinMaxValues(0, auraDurationObject:GetTotalDuration())
                statusbar:SetValue(self.value)
                statusbar.Duration:SetText(string.format("%.1f", self.value))
                statusbar.Duration:Show()
                statusbar.Duration:SetAlpha(auraDurationObject:EvaluateRemainingDuration(Addon.alphaCurve, 0))
            end
        end
    end
end

function ABE_CDMCustomBarFrameMixin:OnLoad()
    self:SetMovable(true)

    self.frameName = self:GetName()

    local profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()

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
        itemFrame.stages = nil
        itemFrame.barType = nil 
        itemFrame:UnregisterAllEvents()
	end

    self.itemPool = CreateFramePool("Frame", self.Container, self.itemTemplate, itemResetCallback)

    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.EndOrderChange", self.OnCustomItemListReorderEnded)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemAdded", self.OnCustomItemListItemUpdate)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemRemoved", self.OnCustomItemListItemUpdate)
    self:AddDynamicEventMethod(EventRegistry, "EditMode.Enter", self.OnEditModeEnter)
    self:AddDynamicEventMethod(EventRegistry, "EditMode.Exit", self.OnEditModeExit)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.FakeAuraAdded", self.OnFakeAuraAdded)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.StagesAdded", self.OnStagesAdded)

    self:RefreshLayout()

    self:SetMouseClickEnabled(false)

    Addon:BarsFadeAnim(self)
end

function ABE_CDMCustomBarFrameMixin:OnStagesAdded(spellID, newStages)
    for itemFrame in self.itemPool:EnumerateActive() do
        if itemFrame.itemID == spellID or itemFrame.spellID == spellID then
            itemFrame.stages = newStages
            itemFrame:RefreshData()
        end
    end
end