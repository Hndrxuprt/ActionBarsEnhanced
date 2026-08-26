local Addon = _G.HUI

local L = Addon.L

HUISpecVisibilityDialogMixin = {}

function HUISpecVisibilityDialogMixin.Open(itemListWidget)
	if not HUISpecVisibilityDialogFrame then
		local frame = CreateFrame("Frame", "HUISpecVisibilityDialogFrame", HUIOptionsFrame, "HUISpecVisibilityDialog")
		frame:SetPoint("CENTER", HUIOptionsFrame, "CENTER", 0, 0)
	end

	local borderPath = "Interface/AddOns/HUI/assets/custom_borders/border_rounded_shadowed.png"
	local borderColor = {0.419, 0.364, 0.29, 1 }
	Addon.CreateCustomBorder(HUISpecVisibilityDialogFrame, borderPath, 32, borderColor )
	HUISpecVisibilityDialogFrame.itemListWidget = itemListWidget
	HUISpecVisibilityDialogFrame.Title:SetText(L.SpecVisibilityDialogTitle)
	HUISpecVisibilityDialogFrame.SaveButton:SetText(L.SpecVisibilitySave)
	HUISpecVisibilityDialogFrame.CancelButton:SetText(L.SpecVisibilityCancel)
	HUISpecVisibilityDialogFrame:Show()
	HUISpecVisibilityDialogFrame:PopulateSpecCheckboxes()
	HUISpecVisibilityDialogFrame:LoadSpecs()
end

local MIN_COL_WIDTH = 130
local H_GAP = 12
local V_GAP = 10
local HEADER_H = 20
local SPEC_ROW_H = 26
local CONTAINER_PAD = 4

function HUISpecVisibilityDialogMixin:PopulateSpecCheckboxes()
	local grid = self.EditorContainer
	if not self.specChecks then
		self.specChecks = {}
	end

	for _, specCheck in pairs(self.specChecks) do
		specCheck:Hide()
	end
	wipe(self.specChecks)

	if self._classContainers then
		for _, container in ipairs(self._classContainers) do
			container:Hide()
		end
		wipe(self._classContainers)
	else
		self._classContainers = {}
	end

	local classOptions = Addon:CDMGetClassSpecOptions()
	local numClasses = #classOptions
	if numClasses == 0 then return end

	local availableWidth = grid:GetWidth()
	local numCols = math.max(1, math.floor(availableWidth / MIN_COL_WIDTH))
	local colWidth = availableWidth / numCols
	local numRows = math.ceil(numClasses / numCols)

	for _, classData in ipairs(classOptions) do
		local classColor = RAID_CLASS_COLORS[classData.classFile]
		local containerHeight = HEADER_H + #classData.specs * SPEC_ROW_H + CONTAINER_PAD
		local containerWidth = math.max(1, colWidth - H_GAP)

		local container = CreateFrame("Frame", nil, grid)
		container:SetSize(containerWidth, containerHeight)
		container:Show()
		tinsert(self._classContainers, container)

		local header = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		header:SetText(classData.className)
		header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
		if classColor then
			header:SetTextColor(classColor:GetRGB())
		end
		header:Show()

		for specIndex, spec in ipairs(classData.specs) do
			local specCheck = CreateFrame("CheckButton", nil, container, "HUISpecVisibilityCheckTemplate")
			specCheck:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -HEADER_H - (specIndex - 1) * SPEC_ROW_H)
			specCheck.Name:SetText(spec.specName)
			specCheck:Show()
			self.specChecks[spec.specID] = specCheck
		end
	end

	local yOffset = 0
	for row = 1, numRows do
		local rowMaxHeight = 0
		for col = 1, numCols do
			local index = (row - 1) * numCols + col
			if index > numClasses then break end
			local container = self._classContainers[index]
			local h = container:GetHeight()
			if h > rowMaxHeight then rowMaxHeight = h end
			container:SetPoint("TOPLEFT", grid, "TOPLEFT", (col - 1) * colWidth, -yOffset)
		end
		yOffset = yOffset + rowMaxHeight + V_GAP
	end
end

function HUISpecVisibilityDialogMixin:LoadSpecs()
	local frameTbl = self.itemListWidget and self.itemListWidget.frameTbl
	local visibleSpecs = frameTbl and frameTbl.visibleSpecs or {}

	for specID, specCheck in pairs(self.specChecks) do
		specCheck:SetChecked(visibleSpecs[specID] == true)
	end
end

function HUISpecVisibilityDialogMixin:Save()
	local frameTbl = self.itemListWidget and self.itemListWidget.frameTbl
	if not frameTbl then return end

	local visibleSpecs = {}
	for specID, specCheck in pairs(self.specChecks) do
		if specCheck:GetChecked() then
			visibleSpecs[specID] = true
		end
	end
	frameTbl.visibleSpecs = visibleSpecs

	self:Hide()
end