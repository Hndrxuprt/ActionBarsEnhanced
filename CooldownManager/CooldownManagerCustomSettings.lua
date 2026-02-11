local AddonName, Addon = ...

local L = Addon.L

local REORDER_MARKER_BEFORE_TARGET = false
local REORDER_MARKER_AFTER_TARGET = true

local function tblContains(tbl, item)
    for index, data in ipairs(tbl) do
        if item.type == data.type and item.id == data.id then
            return index
        end
    end
    return false
end

CDMCustomDraggedItemMixin = {}
function CDMCustomDraggedItemMixin:SetToCursor(cooldownItem)
	self.Icon:SetTexture(cooldownItem:GetIconTexture());
	self:Show();
end

function CDMCustomDraggedItemMixin:OnUpdate()
	local topLevel = GetAppropriateTopLevelParent();
	local x, y = GetScaledCursorPositionForFrame(topLevel);
	self:SetPoint("TOPLEFT", topLevel, "BOTTOMLEFT", x, y);
end

local cooldownItemDragCursor;
local function PickupCooldownItemCursor(cooldownItem)
	if not cooldownItemDragCursor then
		cooldownItemDragCursor = CreateFrame("Frame", nil, GetAppropriateTopLevelParent(), "CDMCustomDraggedItemTemplate");
	end

	cooldownItemDragCursor:SetToCursor(cooldownItem);
end

local function ClearCooldownItemCursor()
	if cooldownItemDragCursor then
		cooldownItemDragCursor:StopMovingOrSizing();
		cooldownItemDragCursor:Hide();
	end
end

OptionsCDMCustomItemListMixin = {}

function OptionsCDMCustomItemListMixin:OnLoad()
    self.frameName = ABE_BarsListMixin:GetFrameLebel()
    local index = ABE_BarsListMixin:GetFrameIndex()

    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]
    if profileTable["CDMCustomFrames"] then
        self.itemList = profileTable["CDMCustomFrames"][index].trackedIDs
    end
    self.itemPool = CreateFramePool("Frame", self.ItemListScroll.GridContainer, "OptionsCDMCustomItemTemplate")
    self.ItemListScroll.GridContainer:EnableMouse(true)

    self.ItemListScroll.GridContainer.DropText:SetText(L.DragNDropContainer)

    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.AddItemByID", self.OnAddItemByID)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.AddSpellByID", self.OnAddSpellByID)
    self:AddDynamicEventMethod(EventRegistry, "CDMCustomItemList.AddItemBySlot", self.OnAddItemBySlot)

    self.FakeAuraFrame.Label:SetText(L.SetFakeAura)
    self.FakeAuraFrame.Desc:SetText(L.SetFakeAuraDesc)
end

function OptionsCDMCustomItemListMixin:OnAddItemBySlot(slotID, frameName, track)
    if self.frameName ~= frameName then return end
    if not slotID then return end

    slotID = tonumber(slotID)

    

    local item = C_TooltipInfo.GetInventoryItem("player", slotID)

    if not item then return end

    local newItem = {
        type = "slot",
        id = slotID,
        baseID = item.id
    }

    if track then
        if not tblContains(self.itemList, newItem) then
            table.insert(self.itemList, newItem)
            self:OnShow()
            EventRegistry:TriggerEvent("CDMCustomItemList.ItemAdded", self.itemList, self.frameName)
        end
    else
        local index = tblContains(self.itemList, newItem)
        if index then
            table.remove(self.itemList, index)
            self:OnShow()
            EventRegistry:TriggerEvent("CDMCustomItemList.ItemRemoved", self.itemList, self.frameName)
        end
    end
end

function OptionsCDMCustomItemListMixin:OnAddItemByID(id, frameName)
    if self.frameName ~= frameName then return end

    if not id then return end
    
    id = tonumber(id)

    if not C_Item.DoesItemExistByID(id) then 
        Addon.Print("Item with this ID doesn't exist.")
        return
    end

    local newItem = {
        type = "item",
        id = id,
    }

    if not tblContains(self.itemList, newItem) then
        table.insert(self.itemList, newItem)
        self:OnShow()
        EventRegistry:TriggerEvent("CDMCustomItemList.ItemAdded", self.itemList, self.frameName)
    end
end
function OptionsCDMCustomItemListMixin:OnAddSpellByID(id, frameName)
    if self.frameName ~= frameName then return end

    if not id then return end

    id = tonumber(id)

    if not C_Spell.DoesSpellExist(id) then
        Addon.Print("Spell with this ID doesn't exist.")
        return
    end
    local baseID = C_Spell.GetBaseSpell(id)

    baseID = baseID ~= id and baseID or nil

    local newItem = {
        type = "spell",
        id = id,
        baseID = baseID,
    }

    if not tblContains(self.itemList, newItem) then
        table.insert(self.itemList, newItem)
        self:OnShow()
        EventRegistry:TriggerEvent("CDMCustomItemList.ItemAdded", self.itemList, self.frameName)
    end
end

function OptionsCDMCustomItemListMixin:OnShow()
    if not self.itemList then return end

    local gridFrame = self.ItemListScroll.GridContainer

    self.itemPool:ReleaseAll()

    for index, data in ipairs(self.itemList) do
        local item = self.itemPool:Acquire()
        item.layoutIndex = index
        item.type = data.type

        if data.type == "item" then
            item.itemID = data.id
            item.spellID = nil
            item.baseSpellID = data.baseID
        elseif data.type == "slot" then
            local inventoryItem = C_TooltipInfo.GetInventoryItem("player", data.id)
            if not inventoryItem then break end
            item.itemID = inventoryItem.id
            item.spellID = nil
            item.baseSpellID = data.baseID
        else
            item.spellID = data.id
            item.baseSpellID = data.baseID
            item.itemID = nil
        end
        
        item.fakeAura = item:GetFakeAura()
        item.stages = item:GetStages()
        item.color = item:GetCustomColor()

        item:SetParent(gridFrame)
        item:Show()

        item.parentFrame = self
    end

    gridFrame:Layout()

    local scrollChild = self.ItemListScroll
    scrollChild:SetSize(gridFrame:GetSize())
    gridFrame.parentListFrame = self

    gridFrame:SetAllPoints()
end

function OptionsCDMCustomItemListMixin:SetupItemList()
    --[[ self.itemList = CopyTable(trackedIDs)
    
    local gridFrame = self.ItemListScroll.GridContainer

    self.itemPool:ReleaseAll()

    for index, data in ipairs(self.itemList) do
        local item = self.itemPool:Acquire()
        item:SetParent(gridFrame)
        item:Show()
    end

    gridFrame:Layout()

    local scrollChild = self.ItemListScroll
    scrollChild:SetSize(gridFrame:GetSize()) ]]
end

function OptionsCDMCustomItemListMixin:IsReordering()
	return self:GetReorderSourceItem() ~= nil
end

function OptionsCDMCustomItemListMixin:GetReorderSourceItem()
    return self.reorderSourceItem
end

function OptionsCDMCustomItemListMixin:SetReorderSourceItem(item)
	self.reorderSourceItem = item
end

function OptionsCDMCustomItemListMixin:GetReorderTarget()
	return self.reorderTarget
end

function OptionsCDMCustomItemListMixin:SetReorderTarget(element)
	if self:IsReordering() then
		self.reorderTarget = element
	end
end

function OptionsCDMCustomItemListMixin:SetReorderTargetItem(item)
	if self:IsReordering() then
		self.reorderTargetItem = item
	end
end

function OptionsCDMCustomItemListMixin:GetReorderTargetItem()
	return self.reorderTargetItem
end

function OptionsCDMCustomItemListMixin:ClearReorderTargets()
	self.reorderTarget = nil
	self.reorderTargetItem = nil
	self.reorderSourceItem = nil
end

function OptionsCDMCustomItemListMixin:OnUpdate(_elapsed)
	assertsafe(self:IsReordering())
	self:UpdateReorderMarker()
end

function OptionsCDMCustomItemListMixin:UpdateReorderMarker()
	local target = self:GetReorderTarget()
	self.ReorderMarker:SetShown(target ~= nil)
    
	if not target then
		return
	end

	local cursorX, cursorY = GetCursorPosition()
	local scale = GetAppropriateTopLevelParent():GetScale()
	cursorX, cursorY = cursorX / scale, cursorY / scale;

	-- TODO: This needs to handle dragging over collapsed headers where there are no item targets, but there's still enough info to know to change categories.
	-- For now just leaving the marker alone...
	local nearestItemTarget = self:GetNearestItemToCursorWeighted(cursorX, cursorY)
	self:SetReorderTargetItem(nearestItemTarget)
	if nearestItemTarget then
		self.ReorderMarker:ClearAllPoints()
		local isMarkerAfterTarget = nearestItemTarget:UpdateReorderMarkerPosition(self.ReorderMarker, cursorX, cursorY);
		if isMarkerAfterTarget then
			self.reorderOffset = 1;
		else
			self.reorderOffset = 0;
		end
	end
end

function OptionsCDMCustomItemListMixin:GetInsertIndexAtCursor(cursorX, cursorY)
    local nearestItem = self:GetNearestItemToCursorWeighted(cursorX, cursorY)
    if not nearestItem then
        return #self.itemList + 1
    end

    local centerX = nearestItem:GetCenter()
    local isAfter = (cursorX >= centerX)
    local targetIndex = nearestItem.layoutIndex
    return isAfter and (targetIndex + 1) or targetIndex
end

function OptionsCDMCustomItemListMixin:GetNearestItemToCursorWeighted(cursorX, cursorY)
	local nearestItem = nil
	local nearestVertical = math.huge
	local nearestHorizontal = math.huge

	for item in self.itemPool:EnumerateActive() do
		local itemLeft, itemRight, itemBottom, itemTop = RegionUtil.GetSides(item)
		local itemCenterX = (itemLeft + itemRight) / 2
		local itemCenterY = (itemBottom + itemTop) / 2
		local horizontalDistance = math.abs(itemCenterX - cursorX)
		local verticalDistance = math.abs(itemCenterY - cursorY)
		if cursorY > itemBottom and cursorY < itemTop then
			verticalDistance = 0
		end

		if verticalDistance < nearestVertical or (nearestVertical == verticalDistance and horizontalDistance < nearestHorizontal) then
			nearestItem = item
			nearestVertical = verticalDistance
			nearestHorizontal = horizontalDistance
		end
	end

	return nearestItem
end

function OptionsCDMCustomItemListMixin:BeginOrderChange(element, eatNextGlobalMouseUp)
    if self:GetReorderSourceItem() then
        return
    end

    self:SetReorderSourceItem(element)
    self:SetReorderTarget(element)
    self.reorderOffset = 0
    self.eatNextGlobalMouseUp = eatNextGlobalMouseUp

    element:SetReorderLocked(true)
    PickupCooldownItemCursor(element)

    self:SetScript("OnUpdate", self.OnUpdate)

    self:RegisterEvent("GLOBAL_MOUSE_UP")
end

function OptionsCDMCustomItemListMixin:EndOrderChange()
    local sourceItem = self:GetReorderSourceItem()
    local targetItem = self:GetReorderTargetItem()
    if not sourceItem or not targetItem or sourceItem == targetItem then
        self:CancelOrderChange()
        return
    end

    local sourceIndex = sourceItem.layoutIndex
    local targetIndex = targetItem.layoutIndex
    local itemCount = #self.itemList

    local newIndex = targetIndex + self.reorderOffset
    newIndex = math.max(1, math.min(newIndex, itemCount + 1))

    if (newIndex == sourceIndex) or 
       (self.reorderOffset == 1 and newIndex - 1 == sourceIndex) then
        self:CancelOrderChange()
        return
    end

    local movedData = table.remove(self.itemList, sourceIndex)

    if newIndex > sourceIndex then
        newIndex = newIndex - 1
    end

    table.insert(self.itemList, newIndex, movedData)

    self:CancelOrderChange()
    self:OnShow()

    EventRegistry:TriggerEvent("CDMCustomItemList.EndOrderChange", self.itemList, self.frameName)
end

function OptionsCDMCustomItemListMixin:CancelOrderChange(element, ...)
	self:GetReorderSourceItem():SetReorderLocked(false)
	self.ReorderMarker:Hide()
	self:ClearReorderTargets()

	ClearCooldownItemCursor()

	self:SetScript("OnUpdate", nil)

	self:UnregisterEvent("GLOBAL_MOUSE_UP")
end



function OptionsCDMCustomItemListMixin:OnEvent(event, ...)
    if event == "GLOBAL_MOUSE_UP" then
		local button = ...
		self:OnGlobalMouseUp(button)
	end
end

function OptionsCDMCustomItemListMixin:OnGlobalMouseUp(button)
	if self.eatNextGlobalMouseUp == button then
		self.eatNextGlobalMouseUp = nil
	else
		PlaySound(SOUNDKIT.UI_CURSOR_DROP_OBJECT)

		if button == "LeftButton" then
			self:EndOrderChange()
		elseif button == "RightButton" then
			self:CancelOrderChange()
		end
	end
end

function OptionsCDMCustomItemListMixin:OpenFakeAuraSettings(item)
    local itemID = item:GetSpellID()
    self.FakeAuraFrame.Label:SetText(L.SetFakeAura)
    self.FakeAuraFrame.Desc:SetText(L.SetFakeAuraDesc)

    self.FakeAuraFrame.EditBox:SetText((item.fakeAura and item.fakeAura > 0) and item.fakeAura or "")
    self.FakeAuraFrame:Show()
    self.FakeAuraFrame.Button:SetScript("OnClick", function()
        local newDuration = tonumber(self.FakeAuraFrame.EditBox:GetText())
        newDuration = (newDuration and newDuration > 0) and newDuration or nil
        local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
        local profileTable = Addon.P.profilesList[profileName]
        local index = ABE_BarsListMixin:GetFrameIndex()
        if profileTable["CDMCustomFrames"] then
            local frameTbl = profileTable["CDMCustomFrames"][index]
            if not frameTbl.fakeAuras then
                frameTbl.fakeAuras = {}
            end
            frameTbl.fakeAuras[itemID] = newDuration
            EventRegistry:TriggerEvent("CDMCustomItemList.FakeAuraAdded", itemID, newDuration)
        end
        self.FakeAuraFrame:Hide()
        self:OnShow()
    end)
end

function OptionsCDMCustomItemListMixin:OpenStagesSettings(item)
    local itemID = item:GetSpellID()
    self.FakeAuraFrame.Label:SetText(L.SetStages)
    self.FakeAuraFrame.Desc:SetText(L.SetStagesDesc)

    self.FakeAuraFrame.EditBox:SetText((item.stages and item.stages > 0) and item.stages or "")
    self.FakeAuraFrame:Show()
    self.FakeAuraFrame.Button:SetScript("OnClick", function()
        local newStages = tonumber(self.FakeAuraFrame.EditBox:GetText())
        newStages = (newStages and newStages > 0) and newStages or nil
        local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
        local profileTable = Addon.P.profilesList[profileName]
        local index = ABE_BarsListMixin:GetFrameIndex()
        if profileTable["CDMCustomFrames"] then
            local frameTbl = profileTable["CDMCustomFrames"][index]
            if not frameTbl.stages then
                frameTbl.stages = {}
            end
            frameTbl.stages[itemID] = newStages
            EventRegistry:TriggerEvent("CDMCustomItemList.StagesAdded", itemID, newStages)
        end
        self.FakeAuraFrame:Hide()
        self:OnShow()
    end)
end



OptionsCDMCustomItemListContentMixin = {}

function OptionsCDMCustomItemListContentMixin:OnReceiveDrag()
    local cursorInfo = { GetCursorInfo() }
    local cursorType = cursorInfo[1]
    if not cursorType then
        ClearCursor()
        return
    end

    local newItem = self:CreateNewItemFromCursor(cursorType, unpack(cursorInfo, 2))
    if not newItem then
        ClearCursor()
        return
    end

    local parentList = self.parentListFrame
    
    local cursorX, cursorY = GetCursorPosition()
    local scale = GetAppropriateTopLevelParent():GetScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local insertIndex = parentList:GetInsertIndexAtCursor(cursorX, cursorY)
    insertIndex = math.min(insertIndex, #parentList.itemList + 1)

    if not tblContains(parentList.itemList, newItem) then
        table.insert(parentList.itemList, insertIndex, newItem)
        --parentList.itemList = CopyTable(Addon.trackedIDs)
        parentList:OnShow()
        EventRegistry:TriggerEvent("CDMCustomItemList.ItemAdded", parentList.itemList, parentList.frameName)
    end

    if self.parentListFrame then
        self.parentListFrame.ReorderMarker:Hide()
    end

    PlaySound(SOUNDKIT.UI_CURSOR_DROP_OBJECT)
    ClearCursor()
end

function OptionsCDMCustomItemListContentMixin:OnMouseEnter()
    if not GetCursorInfo() then return end
    if not self.parentListFrame then return end

    local cursorX, cursorY = GetCursorPosition()
    local scale = GetAppropriateTopLevelParent():GetScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local parentList = self.parentListFrame
    local nearestItem = parentList:GetNearestItemToCursorWeighted(cursorX, cursorY)

    if nearestItem then
        local centerX = nearestItem:GetCenter()
        local isAfter = (cursorX >= centerX)

        parentList.ReorderMarker:ClearAllPoints()
        if isAfter then
            parentList.ReorderMarker:SetPoint("CENTER", nearestItem, "RIGHT", 4, 0)
        else
            parentList.ReorderMarker:SetPoint("CENTER", nearestItem, "LEFT", -4, 0)
        end
        parentList.ReorderMarker:Show()
    else
        parentList.ReorderMarker:Hide()
    end
end

function OptionsCDMCustomItemListContentMixin:CreateNewItemFromCursor(cursorType, ...)
    if cursorType == "spell" then
        local spellID = select(3, ...)
        local baseSpellID = select(4, ...)
        return { type = "spell", id = spellID, baseID = baseSpellID}
    elseif cursorType == "item" then
        local itemID = select(1, ...)
        if itemID then
            local spellName, spellID = C_Item.GetItemSpell(itemID)
            if spellID then
                return { type = "item", id = itemID }
            else
                Addon.Print("This is unusable item.")
            end
        end
    end
    return nil
end

--[[ function OptionsCDMCustomItemListContentMixin:OnMouseEnter()
end ]]
function OptionsCDMCustomItemListContentMixin:OnMouseLeave()
    if self.parentListFrame then
        self.parentListFrame.ReorderMarker:Hide()
    end
end

OptionsCDMCustomItemListReorderMarkerMixin = {}

OptionsCDMCustomItemMixin = {}

function OptionsCDMCustomItemMixin:OnShow()
    self.Icon:SetTexture(self:GetIconTexture())
    self.Icon:SetDesaturated(not self.isKnown)

    if self.fakeAura then
        self.HasAura:Show()
    else
        self.HasAura:Hide()
    end


    local frameName = ABE_BarsListMixin:GetFrameLebel()
    local frame = _G[frameName]
    if frame then
        self.frameTemplate = frame.template

        if self:IsBarFrame() then
            if self.stages then
                self.HasCharges:Show()
            else
                self.HasCharges:Hide()
            end
            if self.color then
                self.HasColor:Show()
                self.HasColor:SetVertexColor(self.color.r, self.color.g, self.color.b, 1)
            else
                self.HasColor:Hide()
            end
        end
    end
end

function OptionsCDMCustomItemMixin:IsBarFrame()
    return self.frameTemplate == "ABE_CDMCustomBarFrame"
end

function OptionsCDMCustomItemMixin:GetIconTexture()
    local texture = 136243
    local isKnown = false
    local spellID = self:GetSpellID()
    if self.type ~= "spell" and spellID then
        isKnown = true
        texture = C_Item.GetItemIconByID(spellID)
    elseif spellID then
        texture = C_Spell.GetSpellTexture(spellID)
        for i=1, 0, -1 do
            if not isKnown then
                isKnown = C_SpellBook.IsSpellKnown(spellID, i)
            end
        end
        if not isKnown then
            isKnown = ABE_CDMCustomFrameMixin:FindAuraForCurrentSpellID(spellID)
        end
    end
    self.isKnown = isKnown

	return texture
end

function OptionsCDMCustomItemMixin:OnEnter()
    --CooldownViewerBaseReorderTargetMixin.OnEnter(self)
    local tooltip = GetAppropriateTooltip()
    tooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
    if self.itemID then
        tooltip:SetItemByID(self.itemID)
    else
        tooltip:SetSpellByID(self.spellID, false)
    end
    tooltip:Show()
end
function OptionsCDMCustomItemMixin:OnLeave()
    GetAppropriateTooltip():Hide()
end

function OptionsCDMCustomItemMixin:GetSpellID()
    if self.itemID then
        return self.itemID
    end
    if self.baseSpellID then
        return self.baseSpellID
    end
    return self.spellID
end

function OptionsCDMCustomItemMixin:RemoveItem()
    local parentFrame = self.parentFrame
    local itemList = parentFrame.itemList
    local index = self.layoutIndex

    tremove(itemList, index)
    --tremove(Addon.trackedIDs, index)
    parentFrame:OnShow()
    EventRegistry:TriggerEvent("CDMCustomItemList.ItemRemoved", itemList, parentFrame.frameName)
end

function OptionsCDMCustomItemMixin:OnDragStart()
    PlaySound(SOUNDKIT.UI_CURSOR_PICKUP_OBJECT)
    self:BeginOrderChange()
end
function OptionsCDMCustomItemMixin:SaveCustomColor(newColor)
    local itemID = self:GetSpellID()
    if not itemID then return end
    local frameIndex = ABE_BarsListMixin:GetFrameIndex()
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]

    newColor.r = newColor.r or 1
    newColor.g = newColor.g or 1
    newColor.b = newColor.b or 1
    newColor.a = newColor.a or 1

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if not frameTbl.color then
            frameTbl.color = {}
        end
        frameTbl.color[itemID] = newColor
    end
end

function OptionsCDMCustomItemMixin:GetCustomColor()
    local itemID = self:GetSpellID()
    if not itemID then return end
    local frameIndex = ABE_BarsListMixin:GetFrameIndex()
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]
    local color

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.color then
            color = frameTbl.color[itemID]
        end
    end
    if color then
        color.r = color.r or 1
        color.g = color.g or 1
        color.b = color.b or 1
        color.a = color.a or 1
    end
    return color or { r=1, g=1, b=1, a=1 }
end

function OptionsCDMCustomItemMixin:DisplayContextMenu()
    MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
        rootDescription:SetTag("CDMCustom ContextMenu")

        rootDescription:CreateButton(L.FakeAura, function()
            self.parentFrame:OpenFakeAuraSettings(self)
        end)
        if self:IsBarFrame() then
            rootDescription:CreateButton(L.Stages, function()
                self.parentFrame:OpenStagesSettings(self)
            end)
            local color = self.color
            local colorInfo = {
                r=color.r, g=color.g, b=color.b, opacity=color.a,
                swatchFunc = function()
                    local r,g,b = ColorPickerFrame:GetColorRGB()
                    local a = ColorPickerFrame:GetColorAlpha()
                    self:SaveCustomColor({r=r, g=g, b=b, a=a})
                    self.color = {r=r, g=g, b=b, a=a}
                    self.HasColor:SetVertexColor(r, g, b, 1)
                end,
                cancelFunc = function()
                    local r,g,b = ColorPickerFrame:GetColorRGB()
                    local a = ColorPickerFrame:GetColorAlpha()
                    self:SaveCustomColor({r=r, g=g, b=b, a=a})
                    self.color = {r=r, g=g, b=b, a=a}
                    self.HasColor:SetVertexColor(r, g, b, 1)
                end,
                hasOpacity = 1,
            }
            rootDescription:CreateColorSwatch(L.UseCustomColor, function()
                ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
            end,
            colorInfo
            )
        end
        rootDescription:CreateDivider()
        rootDescription:CreateButton(L.Delete, function()
            self:RemoveItem()
        end)
    end)
end

function OptionsCDMCustomItemMixin:OnMouseUp(button, upInside)
    if upInside then
        if button == "LeftButton" then
            local eatNextGlobalMouseUp = button
            PlaySound(SOUNDKIT.UI_CURSOR_PICKUP_OBJECT)
            self:BeginOrderChange(eatNextGlobalMouseUp)
        elseif button == "RightButton" then
            if IsLeftShiftKeyDown() and not self:GetReorderLocked() then
                self:RemoveItem()
            elseif not self:GetReorderLocked() then
                self:DisplayContextMenu()
            end
        end
    end
end

function OptionsCDMCustomItemMixin:BeginOrderChange(eatNextGlobalMouseUp)
    if self.parentFrame then
        self.parentFrame:BeginOrderChange(self, eatNextGlobalMouseUp)
    end
end

function OptionsCDMCustomItemMixin:UpdateReorderMarkerPosition(marker, cursorX, _cursorY)
	local centerX = self:GetCenter()
	if cursorX < centerX then
		marker:SetPoint("CENTER", self, "LEFT", -4, 0)
		return REORDER_MARKER_BEFORE_TARGET
	else
		marker:SetPoint("CENTER", self, "RIGHT", 4, 0);
		return REORDER_MARKER_AFTER_TARGET
	end
end

function OptionsCDMCustomItemMixin:GetReorderLocked()
	return self.reorderLocked
end

function OptionsCDMCustomItemMixin:SetReorderLocked(locked)

	self.reorderLocked = locked
	--self:RefreshData()
end

function OptionsCDMCustomItemMixin:GetFakeAura()
    local itemID = self:GetSpellID()
    if not itemID then return end
    local frameIndex = ABE_BarsListMixin:GetFrameIndex()
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.fakeAuras then
            return frameTbl.fakeAuras[itemID]
        end
    end
end

function OptionsCDMCustomItemMixin:GetStages()
    local itemID = self:GetSpellID()
    if not itemID then return end
    local frameIndex = ABE_BarsListMixin:GetFrameIndex()
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]

    if profileTable["CDMCustomFrames"] then
        local frameTbl = profileTable["CDMCustomFrames"][frameIndex]
        if frameTbl and frameTbl.stages then
            return frameTbl.stages[itemID]
        end
    end
end

----------------------------------------
ABE_FakeAuraEditBoxMixin = {}

function ABE_FakeAuraEditBoxMixin:OnShow()
        
end

function ABE_FakeAuraEditBoxMixin:OnEnterPressed()
        
end
function ABE_FakeAuraEditBoxMixin:OnEditFocusLost()
    
end
function ABE_FakeAuraEditBoxMixin:OnEditFocusGained()
    
end

ABE_FakeAuraConfirmButtonMixin = {}

function ABE_FakeAuraConfirmButtonMixin:OnLoad()
    self:SetText(L.Confirm)
end
function ABE_FakeAuraConfirmButtonMixin:OnShow()
    
end

function ABE_FakeAuraConfirmButtonMixin:OnHide()

end

function ABE_FakeAuraConfirmButtonMixin:OnClick()
    local fakeAuraFrame = self:GetParent()
    local editBox = fakeAuraFrame.EditBox
    local newDuration = tonumber(editBox:GetText())
    self:GetParent():Hide()
end