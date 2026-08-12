local AddonName, Addon = ...

ABE_CDMCustomAuraMixin = {}

local ElemBlastSpellIDs = {
	[173184] = true,
	[118522] = true,
	[173183] = true,
}

function ABE_CDMCustomAuraMixin:GetProfileTable()
	return Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()
end

function ABE_CDMCustomAuraMixin:OnLoad()
	self:SetFrameLevel(2)
	self.frameName = self:GetName()

	self:SetMovable(true)

	local profileTable = self:GetProfileTable()
	local frameTbl
	if profileTable["CDMCustomFrames"] then
		frameTbl = profileTable["CDMCustomFrames"][self:GetFrameIndexByName(self.frameName)]
	end
	if frameTbl then
		self.itemList = frameTbl.trackedIDs or {}
		self.displayName = frameTbl.name
	end

	self.hideInactive = false

	self:SetMouseClickEnabled(false)

	self:SetupAppearance()
	self:CreateAuraContainer()
	self:RefreshAuraList()

	self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.EndOrderChange", self.OnCustomItemListReorderEnded)
	self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemAdded", self.OnCustomItemListItemUpdate)
	self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.ItemRemoved", self.OnCustomItemListItemUpdate)
	self:AddDynamicEventMethod(EventRegistry, "EditMode.Enter", self.OnEditModeEnter)
	self:AddDynamicEventMethod(EventRegistry, "EditMode.Exit", self.OnEditModeExit)

	Addon:BarsFadeAnim(self)

	C_Timer.After(0.5, function()
		self:RefreshAuraList()
	end)
end

function ABE_CDMCustomAuraMixin:GetDisplayName()
	return self.displayName
end

function ABE_CDMCustomAuraMixin:SetDisplayName(name)
	self.displayName = name
end

function ABE_CDMCustomAuraMixin:GetFrameIndexByName(frameName)
	local profileTable = self:GetProfileTable()
	if profileTable["CDMCustomFrames"] then
		for index, data in ipairs(profileTable["CDMCustomFrames"]) do
			if data.label == frameName then
				return index
			end
		end
	end

	return false
end

function ABE_CDMCustomAuraMixin:SaveDisplayName(name)
	local profileTable = self:GetProfileTable()
	local frameTbl = profileTable["CDMCustomFrames"] and profileTable["CDMCustomFrames"][self:GetFrameIndexByName(self.frameName)]
	if frameTbl then
		frameTbl.name = name
	end
end

function ABE_CDMCustomAuraMixin:OnEditModeEnter()
	self.ABESelection:Show()

	self.isEditing = true
end

function ABE_CDMCustomAuraMixin:OnEditModeExit()
	self.ABESelection:Hide()
	self.ABESelection:SetSelected(false)

	self.isEditing = false
end

function ABE_CDMCustomAuraMixin:OnCustomItemListReorderEnded(itemList, frameName)
	if self:GetName() ~= frameName then return end
	self.itemList = CopyTable(itemList)
	self:RefreshAuraList()
    self:RefreshAuraButtons()
end

function ABE_CDMCustomAuraMixin:OnCustomItemListItemUpdate(itemList, frameName)
	if self:GetName() ~= frameName then return end
	self.itemList = CopyTable(itemList)
	self:RefreshAuraList()
    self:RefreshAuraButtons()
end

function ABE_CDMCustomAuraMixin:SetupAppearance()
	local frameName = self.frameName

	self.iconSize = 38
	if Addon:GetValue("UseCDMCustomItemSize", nil, frameName) then
		self.iconSize = Addon:GetValue("CDMCustomItemSize", nil, frameName) or 38
	end

	self.spacing = 2
	if Addon:GetValue("UseCDMCustomIconPadding", nil, frameName) then
		self.spacing = Addon:GetValue("CDMCustomIconPadding", nil, frameName) or 2
	end

	self.stride = 7
	if Addon:GetValue("UseCDMCustomStride", nil, frameName) then
		self.stride = Addon:GetValue("CDMCustomStride", nil, frameName) or 7
	end

	self.gridLayoutType = tonumber(Addon:GetValue("CDMGridLayoutType", nil, frameName)) or 2
	if self.gridLayoutType == 1 then
		self.gridLayoutType = 2
	end

	self.goingRight = Addon:GetValue("CDMHorizontalGrowth", nil, frameName) == 1
	self.goingUp = Addon:GetValue("CDMVerticalGrowth", nil, frameName) == 1

	self.hideInactiveType = tonumber(Addon:GetValue("CurrentHideWhenInactive", nil, frameName)) or 1
	self.isHorizontal = Addon:GetValue("CDMCustomGridDirection", nil, frameName) == 1
	self.useFixedSlots = self.hideInactiveType == 1 or self.gridLayoutType == 3
end

function ABE_CDMCustomAuraMixin:GetElementSize()
	return self.iconSize, self.iconSize
end

function ABE_CDMCustomAuraMixin:GetFlowLayoutGrowthDirection()
	if self.isHorizontal then
		return self.goingRight and AnchorUtil.FlowDirection.Right or AnchorUtil.FlowDirection.Left,
			self.goingUp and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down
	else
		return self.goingUp and AnchorUtil.FlowDirection.Up or AnchorUtil.FlowDirection.Down,
			self.goingRight and AnchorUtil.FlowDirection.Right or AnchorUtil.FlowDirection.Left
	end
end

function ABE_CDMCustomAuraMixin:GetFlowAnchorPoint()
	if self.goingUp then
		return self.goingRight and "BOTTOMLEFT" or "BOTTOMRIGHT"
	else
		return self.goingRight and "TOPLEFT" or "TOPRIGHT"
	end
end

function ABE_CDMCustomAuraMixin:CreateAuraContainer()
	self.AuraContainer = CreateFrame("AuraContainer", nil, self, "ABE_CDMAuraContainer")

	self.AuraContainer:SetUnit("player")
	self.AuraContainer:SetEnabled(true)

	self.anchorPoint = self:GetFlowAnchorPoint()

	local elementWidth, elementHeight = self:GetElementSize()

	local maxLineSize = (self.stride * elementWidth) + ((self.stride - 1) * self.spacing)
	self.AuraContainer:SetFlowLayoutMaximumLineSize(maxLineSize)
	self.AuraContainer:SetFlowLayoutAnchorPoint(self.anchorPoint)
	local primaryDirection, secondaryDirection = self:GetFlowLayoutGrowthDirection()
	self.AuraContainer:SetFlowLayoutGrowthDirection(primaryDirection, secondaryDirection)

	self.AuraContainer:SetPoint(self.anchorPoint, self, self.anchorPoint, 0, 0)
	self.AuraContainer:Show()

	self.auraGroupCount = 0
	self.auraSlotCount = 0
	self.placeholders = {}
	self.auraSlotFrames = {}
end

function ABE_CDMCustomAuraMixin:EnsureAuraGroups(count)
	local elementWidth, elementHeight = self:GetElementSize()

	while self.auraGroupCount < count do
		self.auraGroupCount = self.auraGroupCount + 1
		local groupIndex = self.auraGroupCount
		self.AuraContainer:AddAuraGroup("aura" .. groupIndex, "HELPFUL", {
			maxFrameCount = 1,
			sortMethod = AuraContainerSortMethod.ExpirationOnly,
			sortDirection = AuraContainerSortDirection.Reverse,
			candidateFilters = { includeSpellIDs = {} },
			initializeFrame = function(auraButton)
				self:ConfigureAuraButton(auraButton, self.trackedSpellIDs[groupIndex])
			end,
			layout = {
				elementWidth = elementWidth,
				elementHeight = elementHeight,
				elementSpacing = self.spacing,
				lineSpacing = self.spacing,
				layoutIndex = groupIndex,
			},
		})
	end
end

function ABE_CDMCustomAuraMixin:EnsureAuraSlots(count)
	local elementWidth, elementHeight = self:GetElementSize()
	local stepX = elementWidth + self.spacing
	local stepY = elementHeight + self.spacing
	local xDirection = self.goingRight and 1 or -1
	local yDirection = self.goingUp and 1 or -1

	while self.auraSlotCount < count do
		self.auraSlotCount = self.auraSlotCount + 1
		local slotIndex = self.auraSlotCount
		local col, row
		if self.isHorizontal then
			col = (slotIndex - 1) % self.stride
			row = math.floor((slotIndex - 1) / self.stride)
		else
			col = math.floor((slotIndex - 1) / self.stride)
			row = (slotIndex - 1) % self.stride
		end
		local slotFrame = self.AuraContainer:AddAuraSlot("aura" .. slotIndex, "HELPFUL", {
			sortMethod = AuraContainerSortMethod.ExpirationOnly,
			sortDirection = AuraContainerSortDirection.Reverse,
			candidateFilters = { includeSpellIDs = {} },
			initializeFrame = function(auraButton)
				self:ConfigureAuraButton(auraButton, self.trackedSpellIDs[slotIndex])
				if auraButton:CanBeAccessedInContext() then
					auraButton:ClearAllPoints()
					auraButton:SetPoint(self.anchorPoint, self.AuraContainer, self.anchorPoint, col * stepX * xDirection, row * stepY * yDirection)
				end
			end,
		})
		self.auraSlotFrames[slotIndex] = slotFrame
	end
end

function ABE_CDMCustomAuraMixin:RefreshSettings()
	local prevUseFixedSlots = self.useFixedSlots

	self:SetupAppearance()

	if self.useFixedSlots ~= prevUseFixedSlots then
		self:RebuildAuraContainer()
		return
	end

	self:ApplyAuraLayout()
	self:RefreshAuraButtons()
	self:ResizeFrame(self.visibleCount or 0)
	self:UpdatePlaceholders(self.isEditing)
end

function ABE_CDMCustomAuraMixin:ApplyAuraLayout()
	local container = self.AuraContainer
	if not container then return end

	self.anchorPoint = self:GetFlowAnchorPoint()

	local elementWidth, elementHeight = self:GetElementSize()

	local maxLineSize = (self.stride * elementWidth) + ((self.stride - 1) * self.spacing)
	container:SetFlowLayoutMaximumLineSize(maxLineSize)
	container:SetFlowLayoutAnchorPoint(self.anchorPoint)
	local primaryDirection, secondaryDirection = self:GetFlowLayoutGrowthDirection()
	container:SetFlowLayoutGrowthDirection(primaryDirection, secondaryDirection)

	container:ClearAllPoints()
	container:SetPoint(self.anchorPoint, self, self.anchorPoint, 0, 0)

	if self.useFixedSlots then
		local stepX = elementWidth + self.spacing
		local stepY = elementHeight + self.spacing
		local xDirection = self.goingRight and 1 or -1
		local yDirection = self.goingUp and 1 or -1

		for slotIndex, slotFrame in ipairs(self.auraSlotFrames) do
			if slotFrame then
				local col, row
				if self.isHorizontal then
					col = (slotIndex - 1) % self.stride
					row = math.floor((slotIndex - 1) / self.stride)
				else
					col = math.floor((slotIndex - 1) / self.stride)
					row = (slotIndex - 1) % self.stride
				end
                if slotFrame:CanBeAccessedInContext() then
                    slotFrame:ClearAllPoints()
                    slotFrame:SetPoint(self.anchorPoint, container, self.anchorPoint, col * stepX * xDirection, row * stepY * yDirection)
                end
			end
		end
	end
end

function ABE_CDMCustomAuraMixin:RefreshAuraButtons()
	local container = self.AuraContainer
	if not container then return end

	if self.useFixedSlots then
		for slotIndex, button in ipairs(self.auraSlotFrames) do
			if button then
				self:ConfigureAuraButton(button, self.trackedSpellIDs[slotIndex])
			end
		end
	else
		for groupIndex = 1, self.auraGroupCount do
			local frameCount = container:GetAuraGroupFrameCount("aura" .. groupIndex)
			for frameIndex = 1, frameCount do
				local button = container:GetAuraGroupFrame("aura" .. groupIndex, frameIndex)
				if button then
					self:ConfigureAuraButton(button, self.trackedSpellIDs[groupIndex])
				end
			end
		end
	end
end

function ABE_CDMCustomAuraMixin:RefreshBackdrop(backdrop, color)
	if not backdrop then return end

	ABE_CDMCustomFrameCustomized:SetupBackdrop(backdrop, self.frameName, color)
end

function ABE_CDMCustomAuraMixin:RebuildAuraContainer()
	if self.AuraContainer then
		self.AuraContainer:Hide()
		self.AuraContainer:SetEnabled(false)
	end

	for _, placeholder in ipairs(self.placeholders or {}) do
		placeholder:Hide()
	end

	self.auraGroupCount = 0
	self.auraSlotCount = 0

	self:CreateAuraContainer()
	self:RefreshAuraList()
end

function ABE_CDMCustomAuraMixin:RefreshAuraList()
	if not self.AuraContainer then return end

	local trackedSpellIDs = {}
	local auraCount = 0

	for index, data in ipairs(self.itemList or {}) do
		if data.type == "spell" then
			local auraSpellID = tonumber(data.id)
			if auraSpellID and C_Spell.IsSpellHelpful(auraSpellID) then
				trackedSpellIDs[#trackedSpellIDs + 1] = auraSpellID
				auraCount = auraCount + 1
			end
		end
	end

	self.trackedSpellIDs = trackedSpellIDs
	self.visibleCount = auraCount

	if self.useFixedSlots then
		self:EnsureAuraSlots(auraCount)

		for slotIndex = 1, self.auraSlotCount do
			local includeSpellIDs = {}
			if trackedSpellIDs[slotIndex] then
				if ElemBlastSpellIDs[trackedSpellIDs[slotIndex]] then
					includeSpellIDs = ElemBlastSpellIDs
				else
					includeSpellIDs[trackedSpellIDs[slotIndex]] = true
				end
			end
			self.AuraContainer:SetAuraSlotCandidateFilters("aura" .. slotIndex, { includeSpellIDs = includeSpellIDs })
		end
	else
		self:EnsureAuraGroups(auraCount)

		for groupIndex = 1, self.auraGroupCount do
			local includeSpellIDs = {}
			if trackedSpellIDs[groupIndex] then
				if ElemBlastSpellIDs[trackedSpellIDs[groupIndex]] then
					includeSpellIDs = ElemBlastSpellIDs
				else
					includeSpellIDs[trackedSpellIDs[groupIndex]] = true
				end
			end
			self.AuraContainer:SetAuraGroupCandidateFilters("aura" .. groupIndex, { includeSpellIDs = includeSpellIDs })
		end
	end

	self:ResizeFrame(self.visibleCount)
	self:UpdatePlaceholders(self.isEditing)
end

function ABE_CDMCustomAuraMixin:UpdatePlaceholders(showAll)
	if not self.placeholders then return end

	local elementWidth, elementHeight = self:GetElementSize()
	local stepX = elementWidth + self.spacing
	local stepY = elementHeight + self.spacing
	local xDirection = self.goingRight and 1 or -1
	local yDirection = self.goingUp and 1 or -1

	local placeholderIndex = 0
	for index, spellID in ipairs(self.trackedSpellIDs or {}) do
		local shouldShow = showAll or self.hideInactiveType == 1
		if shouldShow then
			placeholderIndex = placeholderIndex + 1
			local slot = index - 1
			local col, row
			if self.isHorizontal then
				col = slot % self.stride
				row = math.floor(slot / self.stride)
			else
				col = math.floor(slot / self.stride)
				row = slot % self.stride
			end
			local placeholder = self:GetPlaceholder(placeholderIndex)
			self:UpdatePlaceholder(placeholder, spellID)
			placeholder:ClearAllPoints()
			placeholder:SetPoint(self.anchorPoint, self, self.anchorPoint, col * stepX * xDirection, row * stepY * yDirection)
			placeholder:Show()
		end
	end

	for index = placeholderIndex + 1, #self.placeholders do
		self.placeholders[index]:Hide()
	end

	if showAll or placeholderIndex > 0 then
		self:ResizeFrame(placeholderIndex)
	else
		self:ResizeFrame(#(self.trackedSpellIDs or {}))
	end
end

function ABE_CDMCustomAuraMixin:ResizeFrame(auraCount)
	auraCount = auraCount or 0

	local elementWidth, elementHeight = self:GetElementSize()

	if auraCount == 0 then
		self:SetSize(elementWidth, elementHeight)
		return
	end

	local stride = math.min(self.stride, auraCount)
	local numRows = math.ceil(auraCount / stride)

	local lineSize = (stride * elementWidth) + ((stride - 1) * self.spacing)
	local wrapSize = (numRows * elementHeight) + ((numRows - 1) * self.spacing)

	local width, height
	if self.isHorizontal then
		width, height = lineSize, wrapSize
	else
		width, height = wrapSize, lineSize
	end

	self:SetSize(width, height)
end

function ABE_CDMCustomAuraMixin:OnShow()
	self:RegisterEvent("FIRST_FRAME_RENDERED")
end

function ABE_CDMCustomAuraMixin:OnHide()

end

function ABE_CDMCustomAuraMixin:OnEvent(event, ...)
	if event == "FIRST_FRAME_RENDERED" then
		ABE_CDMCustomFrameCustomized:RefreshAnchors(self, self.frameName)
	end
end

function ABE_CDMCustomAuraMixin:OnUpdate()

end
