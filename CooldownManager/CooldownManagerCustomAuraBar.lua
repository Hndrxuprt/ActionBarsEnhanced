local AddonName, Addon = ...

ABE_CDMCustomAuraBarMixin = CreateFromMixins(ABE_CDMCustomAuraMixin)

function ABE_CDMCustomAuraBarMixin:OnLoad()
    ABE_CDMCustomAuraMixin.OnLoad(self)

    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.StagesAdded", self.OnStagesAdded)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.UpdateFrame", self.OnFrameUpdate)
end

function ABE_CDMCustomAuraBarMixin:OnFrameUpdate(frameName)
    if self:GetName() ~= frameName then return end
    self:RefreshAuraButtons()
end

function ABE_CDMCustomAuraBarMixin:OnStagesAdded(spellID, newStages)
    self:RefreshAuraButtons()
end

function ABE_CDMCustomAuraBarMixin:GetCustomColor(spellID)
    if not spellID then return end

    local frameName = self.frameName
    local frameIndex = _G[frameName]:GetFrameIndexByName(frameName)
    local profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()
    local color

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.color then
            color = frameTbl.color[spellID]
        end
    end
    return color or {r=1,g=1,b=1,a=1}
end

function ABE_CDMCustomAuraBarMixin:GetCustomAuraColor(spellID)
    if not spellID then return end

    local frameName = self.frameName
    local frameIndex = _G[frameName]:GetFrameIndexByName(frameName)
    local profileTable = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()
    local color

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.auraColor then
            color = frameTbl.auraColor[spellID]
        end
    end
    return color or {r=1,g=1,b=1,a=1}
end

function ABE_CDMCustomAuraBarMixin:GetStages(spellID)
    if not spellID then return end

    local frameIndex = self:GetFrameIndexByName(self.frameName)
    local profileTable = self:GetProfileTable()
    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.stages then
            return frameTbl.stages[spellID]
        end
    end
end

function ABE_CDMCustomAuraBarMixin:AddStages(numStages, parent)

    local barWidth, barHeight = self:GetBarSize()
    if not parent.StagePipPool then
        parent.StagePipPool = {}
    else
        for _, pip in pairs(parent.StagePipPool) do
            pip:Hide()
        end
    end

    if not numStages or numStages < 2 then return end

    for i=1, numStages-1, 1 do
        local x = barWidth * i / numStages
        local stagePipName = "StagePip"..i
        local stagePip = parent.StagePipPool[stagePipName]
        if not stagePip then
            stagePip = CreateFrame("FRAME", nil, parent, "ABE_CDMCustomBarStagePipTemplate")
            parent.StagePipPool[stagePipName] = stagePip
        end

        if stagePip then
            stagePip:ClearAllPoints()
            PixelUtil.SetPoint(stagePip, "TOPLEFT", parent, "TOPLEFT", x, -1, 1, 1)
            PixelUtil.SetPoint(stagePip, "BOTTOMLEFT", parent, "BOTTOMLEFT", x, 1, 1, 1)
            PixelUtil.SetSize(stagePip, 1, barHeight - 2, 1, 1)
            stagePip.BasePip:SetVertexColor(0, 0, 0, 1)
            stagePip:Show()
        end
    end
end

function ABE_CDMCustomAuraBarMixin:SetupAppearance()
    ABE_CDMCustomAuraMixin.SetupAppearance(self)

end

function ABE_CDMCustomAuraBarMixin:GetStatusbar()
    return self.auraStatusbar
end

function ABE_CDMCustomAuraBarMixin:GetBarSize()
    local frameName = self.frameName
    self.barWidth = Addon:GetValue("UseCDMCustomFrameBarWidth", nil, frameName) and Addon:GetValue("CDMCustomFrameBarWidth", nil, frameName) or 100
    self.barHeight = Addon:GetValue("UseCDMCustomFrameBarHeight", nil, frameName) and Addon:GetValue("CDMCustomFrameBarHeight", nil, frameName) or 10

    return self.barWidth, self.barHeight
end

function ABE_CDMCustomAuraBarMixin:GetElementSize()
    return self:GetBarSize()
end

function ABE_CDMCustomAuraBarMixin:GetDurationFormatter()
    local secondsFormatter = self.bindingTextFormatter or Addon.defaultDurationFormatter

    local properties = {}
    if self.timerFormat == 4 then
        tinsert(properties, "ElapsedDuration")
    elseif self.timerFormat == 3 then
        tinsert(properties, "RemainingDuration")
        tinsert(properties, "TotalDuration")
    elseif self.timerFormat == 2 then
        tinsert(properties, "TotalDuration")
    else
        tinsert(properties, "RemainingDuration")
    end
    local formatter = #properties > 1 and "{} / {}" or "{}"
    local components = {}
    do
        for i=1, #properties do
            tinsert(components, {
                property = Enum.DurationTextBindingProperty[properties[i] or "ElapsedDuration"],
                formatter = secondsFormatter,
            })
        end
    end

    return {formatString = formatter, components = components}
end

function ABE_CDMCustomAuraBarMixin:ConfigureAuraButton(auraButton, spellID)
	if not auraButton:CanBeAccessedInContext() then
		return
	end

    local frameName = self.frameName

	if not auraButton.Statusbar then
        auraButton.Statusbar = CreateFrame("StatusBar", nil, auraButton)
        auraButton.Statusbar:SetAllPoints(auraButton)
		auraButton.Statusbar:SetFrameLevel(self:GetFrameLevel() + 5)

		auraButton.Statusbar.BarBG = auraButton.Statusbar:CreateTexture(nil, "BACKGROUND")
        auraButton.Statusbar.BarBG:SetAllPoints(auraButton.Statusbar)

        auraButton.Statusbar.Pip = auraButton.Statusbar:CreateTexture(nil, "OVERLAY")

        auraButton.Statusbar.border = Addon.CreateBorder(auraButton.Statusbar, frameName)
        auraButton.Statusbar.border:SetFrameLevel(auraButton.Statusbar:GetFrameLevel() + 100)

        self.auraStatusbar = auraButton.Statusbar

		auraButton.Icon = auraButton:CreateTexture(nil, "OVERLAY")
		auraButton.Icon:SetPoint("RIGHT", auraButton.Statusbar, "LEFT", -2, 0)
        
		auraButton.Icon.iconBorder = Addon.CreateBorder(auraButton.Icon, frameName)
		auraButton.Icon.iconBorder:SetFrameLevel(auraButton:GetFrameLevel() + 100)
        local iconBorder = auraButton.Icon.iconBorder
        iconBorder:ClearAllPoints()
        iconBorder:SetPoint("TOPLEFT", auraButton.Icon, "TOPLEFT", 0, 0)
        iconBorder:SetPoint("BOTTOMRIGHT", auraButton.Icon, "BOTTOMRIGHT", 0, 0)

		auraButton.countFrame = CreateFrame("Frame", nil, auraButton)
		auraButton.countFrame:SetAllPoints(auraButton.Statusbar)
        auraButton.countFrame:SetFrameLevel(auraButton.Statusbar:GetFrameLevel() + 2)
		auraButton.countText = auraButton.countFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        auraButton.countText:SetPoint("CENTER", auraButton.Icon, "CENTER", 0, 0)

        auraButton.durationFrame = CreateFrame("Frame", nil, auraButton)
        auraButton.durationFrame:SetAllPoints(auraButton.Statusbar)
        auraButton.durationFrame:SetFrameLevel(auraButton.Statusbar:GetFrameLevel() + 2)
        auraButton.durationText = auraButton.durationFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        auraButton.durationText:SetPoint("RIGHT", auraButton.durationFrame, "RIGHT", -2, 0)

        auraButton.nameFrame = CreateFrame("Frame", nil, auraButton)
        auraButton.nameFrame:SetAllPoints(auraButton.Statusbar)
        auraButton.nameFrame:SetFrameLevel(auraButton.Statusbar:GetFrameLevel() + 1)
        auraButton.nameText = auraButton.nameFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        auraButton.nameText:SetPoint("LEFT", auraButton.nameFrame, "LEFT", 2, 0)
	end

	self:CustomizeAuraButton(auraButton, spellID)

	auraButton:SetApplicationCount(auraButton.countText, {formatter = Addon.defaultCountFormatter})
	auraButton:SetSpellName(auraButton.nameText)

	auraButton:SetMouseMotionEnabled(false)
end

function ABE_CDMCustomAuraBarMixin:CustomizeAuraButton(auraButton, spellID)
	local frameName = self.frameName

    ABE_CDMCustomFrameCustomized:ApplyBarSize(self, frameName)
    ABE_CDMCustomFrameCustomized:ApplyBarTexture(self, frameName, spellID)
    ABE_CDMCustomFrameCustomized:ApplyPipTexture(self, frameName)

	if auraButton:CanBeAccessedInContext() then
        ABE_CDMCustomFrameCustomized:ApplyBarIconSize(auraButton, frameName)
        ABE_CDMCustomFrameCustomized:ApplyBarName(auraButton, frameName)
        ABE_CDMCustomFrameCustomized:ApplyBarDuration(auraButton, frameName)
        ABE_CDMCustomFrameCustomized:ApplyStacks(auraButton, frameName)

		if Addon:GetValue("UseCDMBackdrop", nil, frameName) then
			if not auraButton.Icon.iconBorder:HasAnyForbiddenAspects() then
				self:RefreshBackdrop(auraButton.Icon.iconBorder)
			end
			auraButton.Icon.iconBorder:Show()

            if not auraButton.Statusbar.border:HasAnyForbiddenAspects() then
				self:RefreshBackdrop(auraButton.Statusbar.border)
			end
			auraButton.Statusbar.border:Show()
		else
			auraButton.Icon.iconBorder:Hide()
            auraButton.Statusbar.border:Hide()
		end

        local w, h = self:GetBarSize()
        PixelUtil.SetSize(auraButton, w, h, 1, 1)

        local iconPos = Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, frameName)

        if iconPos > 1 then
            auraButton:SetIcon(auraButton.Icon)
            auraButton.Icon.iconBorder:Show()
        else
            auraButton.Icon.iconBorder:Hide()
            auraButton:ClearIcon()
        end

        local stages = spellID and self:GetStages(spellID)
        if stages and type(stages) == "number" then
            self:AddStages(stages, auraButton.Statusbar)
            auraButton:ClearDurationBar()
            auraButton:ClearDurationText()
            auraButton:SetApplicationBar(auraButton.Statusbar, {maxApplications = stages})
        else
            self:AddStages(nil, auraButton.Statusbar)
            auraButton:ClearApplicationBar()
            auraButton:SetDurationBar(auraButton.Statusbar, {direction = Enum.StatusBarTimerDirection.RemainingTime})
            auraButton:SetDurationText(auraButton.durationText, {textFormat = self:GetDurationFormatter()})
        end

	end
end

function ABE_CDMCustomAuraBarMixin:GetPlaceholder(index)
    local frameName = self.frameName
	local placeholder = self.placeholders[index]
	if not placeholder then
		placeholder = CreateFrame("Frame", nil, self)
		placeholder:SetFrameLevel(self.AuraContainer:GetFrameLevel() - 1)
        
		placeholder:SetSize(self:GetBarSize())

        placeholder.BarBG = placeholder:CreateTexture(nil, "BACKGROUND")
        placeholder.BarBG:SetAllPoints(placeholder)
        placeholder.BarBG:SetVertexColor(Addon:GetRGBA("CDMCustomFrameBackgroundColor", nil, frameName))
        local background = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMCustomFrameBackgroundTexture", nil, frameName))
        Addon:SetTexture(placeholder.BarBG, background)

		placeholder.Icon = placeholder:CreateTexture(nil, "BACKGROUND")
        ABE_CDMCustomFrameCustomized:ApplyBarIconSize(placeholder, frameName)

        placeholder.borderFrame = CreateFrame("Frame", nil, placeholder)
        placeholder.borderFrame:SetAllPoints(placeholder)
        placeholder.borderFrame:SetFrameLevel(self.AuraContainer:GetFrameLevel() + 100)

        placeholder.borderIcon = CreateFrame("Frame", nil, placeholder)
        placeholder.borderIcon:SetAllPoints(placeholder.Icon)
        placeholder.borderIcon:SetFrameLevel(self.AuraContainer:GetFrameLevel() + 100)

        placeholder.border = Addon.CreateBorder(placeholder, frameName)
        placeholder.border:SetFrameLevel(self.AuraContainer:GetFrameLevel() + 100)
        ABE_CDMCustomFrameCustomized:SetupBackdrop(placeholder.border, frameName)

		placeholder.iconBorder = Addon.CreateBorder(placeholder.Icon, frameName)
        placeholder.iconBorder:SetFrameLevel(self.AuraContainer:GetFrameLevel() + 100)
		ABE_CDMCustomFrameCustomized:SetupBackdrop(placeholder.iconBorder, frameName)
        local iconBorder = placeholder.iconBorder
        iconBorder:ClearAllPoints()
        iconBorder:SetPoint("TOPLEFT", placeholder.Icon, "TOPLEFT", 0, 0)
        iconBorder:SetPoint("BOTTOMRIGHT", placeholder.Icon, "BOTTOMRIGHT", 0, 0)

        self.placeholders[index] = placeholder
	end
	return placeholder
end

function ABE_CDMCustomAuraBarMixin:UpdatePlaceholder(placeholder, spellID)
    local frameName = self.frameName
	placeholder:SetSize(self:GetBarSize())
	placeholder.Icon:SetTexture(C_Spell.GetSpellTexture(spellID))
    ABE_CDMCustomFrameCustomized:ApplyBarIconSize(placeholder, frameName)

    placeholder.BarBG:SetVertexColor(Addon:GetRGBA("CDMCustomFrameBackgroundColor", nil, frameName))
    local background = Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCDMCustomFrameBackgroundTexture", nil, frameName))
    Addon:SetTexture(placeholder.BarBG, background)

    self:RefreshBackdrop(placeholder.border)
    self:RefreshBackdrop(placeholder.iconBorder)

    if Addon:GetValue("UseCDMBackdrop", nil, frameName) then
        placeholder.border:Show()
        placeholder.iconBorder:Show()
    else
        placeholder.border:Hide()
        placeholder.iconBorder:Hide()
    end

    local iconPos = Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, frameName)
    if iconPos > 1 then
        placeholder.Icon:Show()
    else
        placeholder.Icon:Hide()
    end
end

function ABE_CDMCustomAuraBarMixin:ResizeFrame(auraCount)
	auraCount = auraCount or 0

    local barWidth, barHeight = self:GetBarSize()

	if auraCount == 0 then
		self:SetSize(barWidth, barHeight)
		return
	end

	local stride = math.min(self.stride, auraCount)
	local numRows = math.ceil(auraCount / stride)

	local lineSize = (stride * barWidth) + ((stride - 1) * self.spacing)
	local wrapSize = (numRows * barHeight) + ((numRows - 1) * self.spacing)

	local width, height
	if self.isHorizontal then
		width, height = lineSize, wrapSize
	else
		width, height = wrapSize, lineSize
	end

	self:SetSize(width, height)
end