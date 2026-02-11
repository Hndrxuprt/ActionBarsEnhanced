local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

local RightClickAtlasMarkup = CreateAtlasMarkup('NPE_RightClick', 18, 18);
local LeftClickAtlasMarkup = CreateAtlasMarkup('NPE_LeftClick', 18, 18);

local ActionBarNames = Addon.ActionBarNames
local miniBars = {
    "PetActionBar",
    "StanceBar",
}
local microBars = {
    "BagsBar",
    "MicroMenu",
}
local CDMFrames = Addon.CDMFrames

local function GetNextCustomFrameID()
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]

    local maxID = 0
    local frames = profileTable["CDMCustomFrames"]
    if frames then
        for index, frameData in ipairs(frames) do
            if frameData.index then
                maxID = frameData.index > maxID and frameData.index or maxID
            end
        end
    end
    return maxID + 1
end

local function BuildMenuList()
    local menuList = {
        {
            name = "Quick Presets",
            buttons = {
                {
                    name = "Presets",
                    layout = "layoutPresets",
                },
            },
        },
        {
            name = "Action Bars",
            buttons = {},
        },
        {
            name = "Cooldown Manager",
            buttons = {},
        },
        {
            name = "Custom Frames",
            buttons = {},
        },
        {
            name = "Cast Bars",
            buttons = {},
        },
    }

    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]
    for _, element in ipairs(menuList) do
        if element.name == "Action Bars" then
            for index, bar in ipairs(ActionBarNames) do
                table.insert(element.buttons, { 
                    label = bar,
                    name = L[bar] or bar,
                    category = 2,
                    index = index,
                    layout = (tContains(miniBars, bar) and "layoutMini")
                            or (tContains(microBars, bar) and "layoutMicro")
                            or "layout"
                })
            end
        elseif element.name == "Cooldown Manager" then
            for index, frame in ipairs(CDMFrames) do
                table.insert(element.buttons, { 
                    label = frame,
                    name = L[frame] or frame,
                    category = 1,
                    layout = frame ~= "UtilityCooldownViewer" and frame or "EssentialCooldownViewer",
                    index = index,
                })
            end
        elseif element.name == "Custom Frames" then
            if profileTable["CDMCustomFrames"] then
                for index, data in ipairs(profileTable["CDMCustomFrames"]) do
                    if data then
                        local displayName = data.name ~= "" and data.name or ("Custom Frame "..index)
                        table.insert(element.buttons, {
                            label = data.label,
                            name = displayName,
                            layout = data.layout,
                            index = index,
                            point = data.point,
                        })
                    end
                end
            end
            table.insert(element.buttons, {
                label = "AddCustomFrame",
                name = "",
                index = 99999,
            })
        elseif element.name == "Cast Bars" then
            for index, frame in ipairs(Addon.CASTBARS) do
                table.insert(element.buttons, {
                    label = frame,
                    name = L[frame] or frame,
                    category = 1,
                    layout = frame ~= "PlayerCastingBarFrame" and "TargetFrameSpellBar" or "PlayerCastingBarFrame",
                    index = index,
                })
            end
        end
    end

    return menuList
end


ABE_BarsFrameMixin = {}

function ABE_BarsFrameMixin:OnClick()
    self:Toggle()
end
function ABE_BarsFrameMixin:OnLoad()
    self:Collapse()
    if not ABE_BarsFrameMixin.selection then
        ABE_BarsFrameMixin.selection = CreateFrame("Frame", nil, UIParent, "ABE_BarsHighlightTemplate")
    end
end
function ABE_BarsFrameMixin:Toggle()
	if ABE_BarsFrameMixin.collapsed then
		self:Expand()
	else
		self:Collapse()
	end
end
function ABE_BarsFrameMixin:Expand()
    ABE_BarsFrameMixin.collapsed = false
    ActionBarEnhancedOptionsAdvancedFrame:SetPoint("LEFT", ActionBarEnhancedOptionsFrame, "RIGHT", -5, 0)
end
function ABE_BarsFrameMixin:Collapse()
    ABE_BarsFrameMixin.collapsed = true
    ActionBarEnhancedOptionsAdvancedFrame:SetPoint("LEFT", ActionBarEnhancedOptionsFrame, "RIGHT", -205, 0)
end
function ABE_BarsFrameMixin:Init()
    local optionsFrame = ActionBarEnhancedOptionsFrame
    optionsFrame.advanced = CreateFrame("Frame", "ActionBarEnhancedOptionsAdvancedFrame", optionsFrame, "ABE_BarsFrameTemplate")
    optionsFrame.advanced:ClearAllPoints()
    optionsFrame.advanced:SetParent(ActionBarEnhancedOptionsFrame)
    optionsFrame.advanced:SetPoint("LEFT", optionsFrame, "RIGHT", -205, 0)
    optionsFrame.advanced.NineSlice.Title:SetRotation(1.5708)

   local listFrame = CreateFrame("Frame", "ABE_ListFrame", optionsFrame.advanced, "ABE_BarsListTemplate")
   listFrame:SetParent(optionsFrame.advanced)
   listFrame:SetPoint("TOPLEFT", 5, -5)
   listFrame:SetPoint("BOTTOMRIGHT", -5, 5)

   ABE_BarsListMixin:Init()
end

ABE_BarsListMixin = {}

local function OnDeleteMenuFrame(self, frameLabel)
    if ABE_BarsListMixin.label == frameLabel then
        ABE_BarsListMixin.label = nil
        ABE_BarsListMixin.bar = nil
        ActionBarEnhancedMixin:InitData(nil)
    end

    ABE_BarsListMixin:RefreshMenu()
end

function ABE_BarsListMixin:GetDataProvider()
    return self.dataProvider
end

function ABE_BarsListMixin:OnLoad()
    EventRegistry:RegisterCallback("CDMCustomItemList.DeleteFrame", OnDeleteMenuFrame, self)
end

function ABE_BarsFrameMixin:OnHide()
    if ABE_BarsFrameMixin.selection then
        ABE_BarsFrameMixin.selection:Hide()
        if ABE_BarsListMixin.bar then
            if ABE_BarsListMixin.bar.ABESelection then
                ABE_BarsListMixin.bar.ABESelection:Hide()
                ABE_BarsListMixin.bar.ABESelection:SetSelected(false)
            end
            Addon:SetFrameAlpha(ABE_BarsListMixin.bar)
            if ABE_BarsListMixin.bar.ShouldHide then
                ABE_BarsListMixin.bar:Hide()
            end
        end
    end
end

function ABE_BarsListMixin:OnShow()
    if ABE_BarsListMixin.selected then
        if ABE_BarsListMixin.selected ~= "Presets" or ABE_BarsListMixin.selected ~= "Global Settings" then
            if not _G[ABE_BarsListMixin.selected.label] then

                return
            end
        end
        ABE_BarsListMixin.selected:Click()
    end
end

function ABE_BarsListMixin:OnHide()
    self.label = nil
end


ABE_BarsButtonMixin = {}

function ABE_BarsButtonMixin:OnShow()

end
function ABE_BarsButtonMixin:OnHide()
    self:SetSelected(false)
end

function ABE_BarsButtonMixin:SetButtonName(name)
    self.Label:SetText(name)
end

local function OnCreateNewMenuFrame(self, frameLabel, frameName)
    self:SetButtonName(frameName)
end

function ABE_BarsButtonMixin:OnRenameFrame(frameLabel, frameName)
    if self.frameLabel ~= frameLabel then return end
    self:SetButtonName(frameName)
end

function ABE_BarsButtonMixin:OnLoad()
    EventRegistry:RegisterCallback("CDMCustomItemList.CreateNewFrame", OnCreateNewMenuFrame, self)
    EventRegistry:RegisterCallback("CDMCustomItemList.RenameFrame", self.OnRenameFrame, self)
end

function ABE_BarsButtonMixin:SetSelected(selected)
    local bar = ABE_BarsListMixin.label ~= "GlobalSettings" and _G[ABE_BarsListMixin.label] or nil
    if not bar then return end
    local index = ABE_BarsListMixin:GetFrameIndex()

    local isCastBar
    if bar == PlayerCastingBarFrame or bar == TargetFrameSpellBar or bar == FocusFrameSpellBar then
        isCastBar = true
    end

    if bar.ABESelection then
        if selected then
            self.active = true
            self.Texture:Show()
            bar.ABESelection:Show()
        else
            self.active = false
            bar.ABESelection:Hide()
            bar.ABESelection:SetSelected(false)
            self.Texture:Hide()
        end
        return
    end
    if selected then
		self.Texture:Show()
        self.active = true
        if bar then
            ABE_BarsFrameMixin.selection:ClearAllPoints()
            ABE_BarsFrameMixin.selection:SetPoint("TOPLEFT", bar, "TOPLEFT", -4, 4)
            ABE_BarsFrameMixin.selection:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -4)
            ABE_BarsFrameMixin.selection:SetFrameLevel(bar:GetFrameLevel()-1)
            ABE_BarsFrameMixin.selection:Show()
            ABE_BarsFrameMixin.selection.PulseAnim:Play()

            if isCastBar then
                ABE_CastingBarMixin.OnOptionsSelected(bar, true)
            end
        else
            ABE_BarsFrameMixin.selection:Hide()
            ABE_BarsFrameMixin.selection.PulseAnim:Stop()
            if isCastBar then
                ABE_CastingBarMixin.OnOptionsSelected(bar, false)
            end
        end
	else
        if bar then
            ABE_BarsFrameMixin.selection:Hide()
            ABE_BarsFrameMixin.selection.PulseAnim:Stop()
            if isCastBar then
                ABE_CastingBarMixin.OnOptionsSelected(bar, false)
            end
        end
		self.Texture:Hide()
        self.active = false
	end
end

function ABE_BarsListMixin:ResetBarSettings(barName)
    ActionBarsEnhancedProfilesMixin:ResetCatOptions(barName)
end

function ABE_BarsListMixin:GetFrame()
    return self
end

function ABE_BarsListMixin:InitButtons(buttons, frame)
    local currentProfile = Addon:GetCurrentProfile()
    local parentFrame = self

    local frames = {}
    for i, buttonData in ipairs(buttons) do
        local template = "ABE_BarsListButtonTemplate"

        if buttonData.label == "AddNewGroup" or buttonData.label == "AddCustomFrame" then
            template = "ABE_BarsListCreateGroupFrameTemplate"
        end

        local button = CreateFrame("Button", nil, frame, template)
        table.insert(frames, button)
        if i == 1 then
            button:SetPoint("TOP", frame.Background, "BOTTOM", 0, -1)
        else
            button:SetPoint("TOP", frames[i-1], "BOTTOM", 0, -1)
        end
        if button.Label then
            button.Label:SetText(buttonData.name or "Button")
        end
        button.frameLabel = buttonData.label

        local hasConfig = Addon.P.profilesList[currentProfile][buttonData.label] and next(Addon.P.profilesList[currentProfile][buttonData.label])

        button:SetScript("OnEnter", function(self)
            if buttonData.label == "AddNewGroup" or buttonData.label == "AddCustomFrame" then
                return
            end

            if ABE_BarsListMixin.hoveredButton and ABE_BarsListMixin.hoveredButton ~= self then
                local prev = ABE_BarsListMixin.hoveredButton
                prev.Copy:Hide()
                prev.Paste:Hide()
            end

            ABE_BarsListMixin.hoveredButton = self

            local inCopypasteMode = ABE_BarsListMixin.copypaste

            if hasConfig and buttonData.label ~= "GlobalSettings" and buttonData.label ~= "BuffBarCooldownViewer" then
                if not inCopypasteMode then
                    self.Copy:Show()
                    self.Paste:Hide()
                elseif inCopypasteMode ~= buttonData.label and ABE_BarsListMixin.layout == buttonData.layout then
                    self.Copy:Hide()
                    self.Paste:Show()
                end
            elseif buttonData.label ~= "BuffBarCooldownViewer" then
                self.Copy:Hide()
                if inCopypasteMode and inCopypasteMode ~= buttonData.label and ABE_BarsListMixin.layout == buttonData.layout then
                    self.Paste:Show()
                else
                    self.Paste:Hide()
                end
            end

        end)

        button:SetScript("OnLeave", function(self)
            if buttonData.label == "AddNewGroup" or buttonData.label == "AddCustomFrame" then
                return
            end

            local focusedFrames = GetMouseFoci()
            if focusedFrames and focusedFrames[1] then
                local focus = focusedFrames[1]
                if focus == self or focus == self.Copy or focus == self.Paste then
                    return
                end
            end
            button.Copy:Hide()
            button.Paste:Hide()
        end)

        button:SetScript("OnClick", function(self, button, down)
            if buttonData.label == "AddNewGroup" then
                Addon.Print("New feature soon.")
                return
            end

            if ABE_BarsListMixin.selected then
                if ABE_BarsListMixin.selected.label == buttonData.label then
                    --return
                end
                ABE_BarsListMixin.selected:SetSelected(false)
                ABE_BarsListMixin.selected = nil
            end
            
            ABE_BarsListMixin.label = buttonData.label
            ABE_BarsListMixin.index = buttonData.index
            if ABE_BarsListMixin.bar then
                if ABE_BarsListMixin.bar.ShouldHide then
                    if not InCombatLockdown() then
                        ABE_BarsListMixin.bar:Hide()
                    end
                end
                Addon:SetFrameAlpha(ABE_BarsListMixin.bar)
            end

            ABE_BarsListMixin.bar = (buttonData.label ~= "GlobalSettings" and not tContains(CDMFrames, buttonData.label)) and _G[buttonData.label] or nil
            if ABE_BarsListMixin.bar then
                ABE_BarsListMixin.bar.ShouldHide = not ABE_BarsListMixin.bar:IsVisible()
                if not InCombatLockdown() then
                    ABE_BarsListMixin.bar:Show()
                end
                Addon:SetFrameAlpha(ABE_BarsListMixin.bar, 1)
            end

            ABE_BarsListMixin.selected = self
            ABE_BarsListMixin.selected.label = buttonData.label
            ABE_BarsListMixin.selected.layout = buttonData.layout
            self:SetSelected(true)
            ActionBarEnhancedMixin:InitData(Addon[buttonData.layout])
        end)

        if not button.Copy and not button.Paste and not button.Reset then
            return
        end

        if buttonData.label ~= "Presets" and hasConfig then
            button.Reset:Show()
        else
            button.Reset:Hide()
        end

        if buttonData.label ~= "Presets" then
            button.Reset:SetScript("OnClick", function(self, button, down)
                local barName = buttonData.label
                if not StaticPopup_Visible("ABE_RESET_CAT") then
                    StaticPopup_Show("ABE_RESET_CAT", nil, nil, barName)
                end
            end)
        end

        button.Copy:SetScript("OnClick", function(self)
            if hasConfig then
                ABE_BarsListMixin.copypaste = buttonData.label
                ABE_BarsListMixin.layout = buttonData.layout
                local panelName = ABE_BarsListMixin.copypaste
                Addon.Print(string.format(L["Copied: %s"], L[panelName] or panelName))
                self:Hide()
            end
        end)
        button.Copy:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip_AddColoredLine(GameTooltip, LeftClickAtlasMarkup .. L.CopyText, LIGHTYELLOW_FONT_COLOR)
            GameTooltip:SetScale(0.82)
            GameTooltip:Show()
        end)
        button.Copy:SetScript("OnLeave",function(self)
            GameTooltip:Hide()
        end)

        button.Paste:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button.Paste:SetScript("OnClick", function(self, pressed)
            if pressed == "RightButton" then
                ABE_BarsListMixin.copypaste = nil
                self:Hide()
                return
            elseif pressed == "LeftButton" then
                local fromCat = ABE_BarsListMixin.copypaste
                local toCat = buttonData.label
                Addon.Print(string.format(L["Pasted: %s → %s"], L[fromCat] or fromCat, L[toCat] or toCat))
                ActionBarsEnhancedProfilesMixin:CopyProfileCategory(fromCat, toCat, true)
                --ABE_BarsListMixin.copypaste = nil
                self:Hide()
            end
        end)
        button.Paste:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip_AddColoredLine(GameTooltip, LeftClickAtlasMarkup .. L.PasteText, NECROLORD_GREEN_COLOR)
            GameTooltip_AddColoredLine(GameTooltip, RightClickAtlasMarkup .. L.CancelText, WARNING_FONT_COLOR)
            GameTooltip:SetScale(0.82)
            GameTooltip:Show()
        end)
        button.Paste:SetScript("OnLeave",function(self)
            GameTooltip:Hide()
        end)
        
    end
end

function ABE_BarsListMixin:GetFrameLebel()
    return self.label
end

function ABE_BarsListMixin:GetFrameIndex()
    return self.index
end

function ABE_BarsListMixin:RefreshMenu()
    self.dataProvider:Flush()

    local menu = BuildMenuList()
    for _, element in ipairs(menu) do
        self.dataProvider:Insert({
            name = element.name,
            buttons = element.buttons,
        })
    end
end

function ABE_BarsListMixin:Init()
    if not self.dataProvider then
        self.dataProvider = CreateDataProvider()

        self.scrollBox = ABE_ListFrame.ScrollBox
        self.scrollBar = ABE_ListFrame.ScrollBar

        function self:ElementInitializer(frame, elementData)
            local containerName = elementData.name
            local buttons = elementData.buttons

            frame.Label:SetText(containerName)
            frame:Show()

            ABE_BarsListMixin:InitButtons(buttons, frame)
        end
    end

    if not self.view then
        self.view = CreateScrollBoxListLinearView()
        self.view:SetPadding(0, 0, 0, 0, 10) --top, bottom, left, right, spacing
        --view:SetElementExtent(200)
        self.view:SetElementExtentCalculator(function(dataIndex, elementData)
            local height = #elementData.buttons * 21
            return height + 31
        end)

        self.view:SetElementResetter(function(frame, elementData)
            local existing = { frame:GetChildren() }
            for _, child in ipairs(existing) do
                if child ~= frame.Label then
                    child:Hide()
                end
            end
        end)

        self.view:SetElementInitializer("ABE_BarsListHeaderTemplate", function(frame, elementData)
            self:ElementInitializer(frame, elementData)
        end)
        ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)
        self.scrollBox:Init(self.view)
        self.scrollBox:SetInterpolateScroll(true)
        self.scrollBox:SetDataProvider(self.dataProvider)
        self.scrollBox:SetPanExtent(40)
        self.scrollBar:Hide()
    end
    self:RefreshMenu()
end

ABE_BarsListHeaderMixin = {}

ABE_BarsGroupButtonMixin = {}

ABE_BarsGroupButtonIconMixin = {}

local function CreateCustomFrame(layout, template)
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]

    if not profileTable["CDMCustomFrames"] then
        profileTable["CDMCustomFrames"] = {}
    end

    local index = GetNextCustomFrameID()
    local frameLabel = "CDMCustomFrame_" .. index

    table.insert(profileTable["CDMCustomFrames"], {
        label = frameLabel,
        name = "",
        layout = layout,
        template = template,
        point = {},
        trackedIDs = {},
        index = index,
    })

    EventRegistry:TriggerEvent("CDMCustomItemList.CreateNewFrame", frameLabel, "Custom Frame "..index)

    local listFrame = ABE_BarsListMixin:GetFrame()
    listFrame:RefreshMenu()

end

function ABE_BarsGroupButtonIconMixin:OnClick()
    self:DisplayContextMenu()
end

function ABE_BarsGroupButtonIconMixin:DisplayContextMenu()
    MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
        rootDescription:SetTag("CDMCustom CreateMenu")

        rootDescription:CreateButton(L.CreateIconsFrame, function()
            CreateCustomFrame("CustomFrameCooldownViewer", "ABE_CDMCustomFrame")
        end)
        
        rootDescription:CreateDivider()
        
        rootDescription:CreateButton(L.CreateBarsFrame, function()
            Addon.Print("not ready yet :<")
            --CreateCustomFrame("CustomFrameBarsCooldownViewer", "ABE_CDMCustomBarFrame")
        end)
    end)
end