local AddonName, Addon = ...

local T = Addon.Templates

local ACTION_BARS = {
	"MultiActionBar",
	"StanceBar",
	"PetActionBar",
	"PossessActionBar",
	"BonusBar",
	"VehicleBar",
	"TempShapeshiftBar",
	"OverrideBar",
    "MainMenuBar",
    "MainActionBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
}

local function GetFlipBook(...)
    local Animations = {...}

    for _, Animation in ipairs(Animations) do
        if Animation:GetObjectType() == "FlipBook" then
            Animation:SetParentKey("FlipAnim")
            return Animation
        end
    end
end
function Addon:ProcessButtons(actionBar, updateFunc, value)
    local function UpdateSingleButton(button, isStanceBar, value)
        if button and button:IsVisible() then
            updateFunc(button, isStanceBar, value)
        end
    end
    
    local ActionBarButtonNames = {
        "ActionButton",
        "MultiBarBottomLeftButton", 
        "MultiBarBottomRightButton",
        "MultiBarLeftButton",
        "MultiBarRightButton",
        "MultiBar5Button",
        "MultiBar6Button",
        "MultiBar7Button",
    }
    
    if not actionBar then
        for _, barName in ipairs(ActionBarButtonNames) do
            for i = 1, NUM_ACTIONBAR_BUTTONS do
                UpdateSingleButton(_G[barName..i], false, value)
            end
        end
    else
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            UpdateSingleButton(_G[actionBar.."Button"..i], false, value)
        end
    end
    
    for i = 1, NUM_SPECIAL_BUTTONS do
        UpdateSingleButton(PetActionBar.actionButtons[i], true, value)
        UpdateSingleButton(StanceBar.actionButtons[i], true, value)
    end
end

function Addon:PreviewButtons(previewType, value)
    local selectedBar = ABE_BarsListMixin:GetFrameLebel()
    local actionBar = selectedBar ~= "GlobalSettings" and selectedBar or nil
    
    local updateFunc
    if previewType == "LoopGlow" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateFlipbook(button, value)
        end
    elseif previewType == "NormalTexture" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateNormalTexture(button, isStanceBar, value)
        end
    elseif previewType == "BackdropTexture" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateBackdropTexture(button, isStanceBar, value)
        end
    elseif previewType == "PushedTexture" then
        updateFunc = function(button, isStanceBar, value)
            button.NormalTexture:Hide()
            button.PushedTexture:Show()
            Addon:UpdatePushedTexture(button, isStanceBar, value)
        end
    elseif previewType == "HighlightTexture" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateHighlightTexture(button, isStanceBar, value)
            button:LockHighlight()
        end
    elseif previewType == "CheckedTexture" then
        updateFunc = function(button, isStanceBar, value)
            button.CheckedTexture:Show()
            Addon:UpdateCheckedTexture(button, isStanceBar, value)
        end
    elseif previewType == "IconMaskTexture" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateIconMask(button, isStanceBar, value)
        end
    elseif previewType == "Cooldown" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateCooldown(button, isStanceBar, value)
        end
    elseif previewType == "Font" then
        updateFunc = function(button, isStanceBar, value)
            Addon:UpdateButtonFont(button, isStanceBar, value)
        end
    end
    
    if not updateFunc then return end
    
    Addon:ProcessButtons(actionBar, updateFunc, value)
end

function Addon:RefreshButtons(button)
    local selectedBar = ABE_BarsListMixin:GetFrameLebel()
    local actionBar = selectedBar ~= "GlobalSettings" and selectedBar or nil
    
    local function UpdateAll(button, isStanceBar)
        Addon:UpdateNormalTexture(button, isStanceBar)
        Addon:UpdateBackdropTexture(button, isStanceBar)
        Addon:UpdatePushedTexture(button, isStanceBar)
        Addon:UpdateHighlightTexture(button, isStanceBar)
        Addon:UpdateCheckedTexture(button, isStanceBar)
        if button.IconMask then
            Addon:UpdateIconMask(button, isStanceBar)
        end
        if button.icon then
            Addon:UpdateIcon(button, isStanceBar)
        end
        if button.cooldown then
            Addon:UpdateCooldown(button, isStanceBar)
        end
        Addon:UpdateButtonFont(button, isStanceBar)
    end
    
    if button then
        UpdateAll(button)
    else
        Addon:ProcessButtons(actionBar, UpdateAll)
    end
end

function Addon:GetConfig(button)
    local config, configName
    local actionBar, barName

    if button then
        actionBar = button.bar
        if not actionBar then
            actionBar = button:GetParent()
        end
        
        if actionBar and actionBar:GetName() then
            barName = actionBar:GetName()
            if Addon.C[barName] then
                config = Addon.C[barName]
                configName = barName
            end
        end
    end

    if not config then
        config = Addon.C["GlobalSettings"]
        configName = "GlobalSettings"
    end

    return config, configName
end

function Addon:UpdateActionBarGrid(frame, padding, equal)

    if not frame then return end

    local frameName = frame:GetName()

    if frameName == "StanceBar" then return end

    padding = padding or Addon:GetValue("CurrentBarPadding", nil, frameName)

    if equal then
        local scale = frame.shownButtonContainers[1]:GetScale()
        if scale < 1 then
            padding = padding / scale
        end
    end

    --[[ if Addon:GetValue("UseButtonsNumber", nil, frameName) then
        if not InCombatLockdown() then
            frame.numButtonsShowable = Addon:GetValue("ButtonsNumber", nil, frameName)
            frame:UpdateShownButtons()
        end
    end ]]

    frame.addButtonsToTop = Addon:GetValue("CurrentBarGrow", nil, frameName) == 1


    --frame.numRows = Addon:GetValue("UseRowsNumber", nil, frameName) and Addon:GetValue("RowsNumber", nil, frameName) or frame.numRows
    
    -- Stride is the number of buttons per row (or column if we are vertical)
    -- Set stride so that if we can have the same number of icons per row we do

    local stride = math.ceil(#frame.shownButtonContainers / frame.numRows)

    --local stride = Addon:GetValue("UseColumnsNumber", nil, frameName) and Addon:GetValue("ColumnsNumber", nil, frameName) or math.ceil(#frame.shownButtonContainers / frame.numRows)

    if Addon:GetValue("GridCentered", nil, frameName) then
        Addon:ApplyActionBarsCenteredGrid(frame, frame.shownButtonContainers, stride, padding)
        frame:Layout()
        frame:UpdateSpellFlyoutDirection()
        frame:CacheGridSettings()
        frame:MarkClean()
        return
    end

    -- Multipliers determine the direction the bar grows for grid layouts 
    -- Positive means right/up
    -- Negative means left/down
    local xMultiplier = frame.addButtonsToRight and 1 or -1;
    local yMultiplier = frame.addButtonsToTop and 1 or -1;

    local anchorPoint;
	if frame.addButtonsToLeft then 
		  anchorPoint = "LEFT"
    elseif frame.addButtonsToTop then
        if frame.addButtonsToRight then
            anchorPoint = "BOTTOMLEFT"
        else
            anchorPoint = "BOTTOMRIGHT"
        end
    else
        if frame.addButtonsToRight then
            anchorPoint = "TOPLEFT"
        else
            anchorPoint = "TOPRIGHT"
        end
    end
    
    -- Create the grid layout according to whether we are horizontal or vertical
    local layout
    if frame.isHorizontal then
        layout = GridLayoutUtil.CreateStandardGridLayout(stride, padding, padding, xMultiplier, yMultiplier)
    else
        layout = GridLayoutUtil.CreateVerticalGridLayout(stride, padding, padding, xMultiplier, yMultiplier)
    end

    GridLayoutUtil.ApplyGridLayout(frame.shownButtonContainers, AnchorUtil.CreateAnchor(anchorPoint, frame, anchorPoint), layout)
    frame:Layout()
    frame:UpdateSpellFlyoutDirection()
    frame:CacheGridSettings()
end

function Addon:HookActionBarGrid()
    for _, frameName in ipairs(ACTION_BARS) do
        local frame = _G[frameName]
        if frame then
            if frame.UpdateGridLayout and not frame.__gridHooked then
                hooksecurefunc(frame, "UpdateGridLayout", function(self) Addon:UpdateActionBarGrid(self) end)
                frame.__gridHooked = true
            end
            Addon:UpdateActionBarGrid(frame)
        end
    end
end

function Addon:UpdateAllActionBarGrid()
    for _, frameName in ipairs(ACTION_BARS) do
        local frame = _G[frameName]
        if frame then
            Addon:UpdateActionBarGrid(frame)
        end
    end
end

function Addon:UpdateAssistFlipbook(region)

    local button = region:GetParent()

    local config, configName = Addon:GetConfig(button)

    local loopAnim = T.LoopGlow[Addon:GetValue("CurrentAssistType", nil, configName)] or nil

    local flipAnim = GetFlipBook(region.Anim:GetAnimations())

    if loopAnim.atlas then
        region:SetAtlas(loopAnim.atlas)  
    elseif loopAnim.texture then
        region:SetTexture(loopAnim.texture)
    end

   if loopAnim then
        region:ClearAllPoints()
        region:SetSize(region:GetSize())
        region:SetPoint("CENTER", region:GetParent(), "CENTER", -1.5, 1)
        flipAnim:SetFlipBookRows(loopAnim.rows or 6)
        flipAnim:SetFlipBookColumns(loopAnim.columns or 5)
        flipAnim:SetFlipBookFrames(loopAnim.frames or 30)
        flipAnim:SetDuration(loopAnim.duration or 1.0)
        flipAnim:SetFlipBookFrameWidth(loopAnim.frameW or 0.0)
        flipAnim:SetFlipBookFrameHeight(loopAnim.frameH or 0.0)
        region:SetScale(loopAnim.scale or 1)
    end
    --region.ProcLoopFlipbook:SetTexCoords(333, 400, 0.412598, 0.575195, 0.393555, 0.78418, false, false)
    region:SetDesaturated(Addon:GetValue("DesaturateAssist", nil, configName))
    if Addon:GetValue("UseAssistGlowColor", nil, configName) then
        region:SetVertexColor(Addon:GetRGB("AssistGlowColor", nil, configName))
    else
        region:SetVertexColor(1.0, 1.0, 1.0)
    end
	region.Anim:Stop()
    region.Anim:Play()
end

local BUTTON_REF_SIZES = {
    ["EssentialCooldownViewer"] = 50,
    ["UtilityCooldownViewer"] = 30,
    ["BuffIconCooldownViewer"] = 40,
    ["StanceBar"] = 30,
    ["PetActionBar"] = 38,
}

local function GetButtonScaleForBar(barName)
    local actionButtonSize = 42
    local refButtonSize = BUTTON_REF_SIZES[barName] or actionButtonSize
    local scaleMult = refButtonSize / actionButtonSize
    return scaleMult
end
local function GetTextureScaleForButton(button)
    local actionButtonSize = 42
    local size = button:GetHeight()
    local scaleMult = size / actionButtonSize
    local frameName = button:GetParent():GetName()
    if not frameName then
        frameName = button:GetParent():GetParent():GetName()
    end
    return scaleMult
end

function Addon:UpdateFlipbook(Button)
    if not Button:IsVisible() then return end
    
	local region = Button.SpellActivationAlert

	if (not region) or (not region.ProcStartAnim) then return end

    local config, configName = Addon:GetConfig(Button)

    local loopAnim = T.LoopGlow[Addon:GetValue("CurrentLoopGlow", nil, configName)] or nil
    local procAnim = T.ProcGlow[Addon:GetValue("CurrentProcGlow", nil, configName)] or nil
    local altGlowAtlas = T.PushedTextures[Addon:GetValue("CurrentAssistAltType", nil, configName)] or nil

    if altGlowAtlas then
        region.ProcAltGlow:SetAtlas(altGlowAtlas.atlas)
    end
    region.ProcAltGlow:SetDesaturated(Addon:GetValue("DesaturateAssistAlt", nil, configName))
    if Addon:GetValue("UseAssistAltColor", nil, configName) then
        region.ProcAltGlow:SetVertexColor(Addon:GetRGB("AssistAltColor", nil, configName))
    else
        region.ProcAltGlow:SetVertexColor(1.0, 1.0, 1.0)
    end
        
    local startProc = region.ProcStartAnim.FlipAnim or GetFlipBook(region.ProcStartAnim:GetAnimations())
    
    if startProc then
        
        if Addon:GetValue("HideProc", nil, configName) then
            startProc:SetDuration(0)
            region.ProcStartFlipbook:Hide()
        else
            region.ProcStartFlipbook:Show()
            if procAnim.atlas then
                region.ProcStartFlipbook:SetAtlas(procAnim.atlas)
            elseif procAnim.texture then
                region.ProcStartFlipbook:SetTexture(procAnim.texture)
            end
            if procAnim then
                startProc:SetFlipBookRows(procAnim.rows or 6)
                startProc:SetFlipBookColumns(procAnim.columns or 5)
                startProc:SetFlipBookFrames(procAnim.frames or 30)
                startProc:SetDuration(procAnim.duration or 0.702)
                startProc:SetFlipBookFrameWidth(procAnim.frameW or 0.0)
                startProc:SetFlipBookFrameHeight(procAnim.frameH or 0.0)
                region.ProcStartFlipbook:SetScale((procAnim.scale or 1) * GetTextureScaleForButton(Button))
            end
            region.ProcStartFlipbook:SetDesaturated(Addon:GetValue("DesaturateProc", nil, configName))

            if Addon:GetValue("UseProcColor", nil, configName) then
                region.ProcStartFlipbook:SetVertexColor(Addon:GetRGB("ProcColor", nil, configName))
            else
                region.ProcStartFlipbook:SetVertexColor(1.0, 1.0, 1.0)
            end
        end
    end

    if loopAnim.atlas then
        region.ProcLoopFlipbook:SetAtlas(loopAnim.atlas)    
    elseif loopAnim.texture then
        region.ProcLoopFlipbook:SetTexture(loopAnim.texture)
    end
    if loopAnim then
        region.ProcLoopFlipbook:ClearAllPoints()
        region.ProcLoopFlipbook:SetSize(region:GetSize())
        region.ProcLoopFlipbook:SetPoint("CENTER", region, "CENTER", -1.5, 1)
        region.ProcLoop.FlipAnim:SetFlipBookRows(loopAnim.rows or 6)
        region.ProcLoop.FlipAnim:SetFlipBookColumns(loopAnim.columns or 5)
        region.ProcLoop.FlipAnim:SetFlipBookFrames(loopAnim.frames or 30)
        region.ProcLoop.FlipAnim:SetDuration(loopAnim.duration or 1.0)
        region.ProcLoop.FlipAnim:SetFlipBookFrameWidth(loopAnim.frameW or 0.0)
        region.ProcLoop.FlipAnim:SetFlipBookFrameHeight(loopAnim.frameH or 0.0)
        region.ProcLoopFlipbook:SetScale((loopAnim.scale or 1))
    end
    region.ProcLoopFlipbook:SetDesaturated(Addon:GetValue("DesaturateGlow", nil, configName))
    if Addon:GetValue("UseLoopGlowColor", nil, configName) then
        region.ProcLoopFlipbook:SetVertexColor(Addon:GetRGB("LoopGlowColor", nil, configName))
    else
        region.ProcLoopFlipbook:SetVertexColor(1.0, 1.0, 1.0)
    end
end

local function Hook_UpdateFlipbook(Frame, Button)
    if type(Button) ~= "table" then
		Button = Frame
	end

	Addon:UpdateFlipbook(Button)
end

local function FixKeyBindText(text)
    local function escapePattern(text)
        return text:gsub("([%-%.%+%*%?%^%$%(%)%[%]%%])", "%%%1")
    end
    if text and text ~= _G.RANGE_INDICATOR then
        text = gsub(text, "(s%-)", "s")
		text = gsub(text, "(a%-)", "a")
		text = gsub(text, "(а%-)", "a")
		text = gsub(text, "(c%-)", "c")
		text = gsub(text, "Capslock", "CL")
		text = gsub(text, KEY_BUTTON4, "M4")
		text = gsub(text, KEY_BUTTON5, "M5")
		text = gsub(text, KEY_BUTTON3, "MMB")
        text = gsub(text, KEY_MOUSEWHEELUP, "MU")
	    text = gsub(text, KEY_MOUSEWHEELDOWN, "MD")
		text = gsub(text, KEY_NUMLOCK, "NL")
		text = gsub(text, KEY_PAGEUP, "PU")
		text = gsub(text, KEY_PAGEDOWN, "PD")
		text = gsub(text, KEY_SPACE, "SpB")
		text = gsub(text, KEY_INSERT, "Ins")
		text = gsub(text, KEY_HOME, "Hm")
		text = gsub(text, KEY_DELETE, "Del")
		text = gsub(text, KEY_DELETE, "Del")
		text = gsub(text, escapePattern(KEY_NUMPAD0), "N0")
		text = gsub(text, escapePattern(KEY_NUMPAD1), "N1")
		text = gsub(text, escapePattern(KEY_NUMPAD2), "N2")
		text = gsub(text, escapePattern(KEY_NUMPAD3), "N3")
		text = gsub(text, escapePattern(KEY_NUMPAD4), "N4")
		text = gsub(text, escapePattern(KEY_NUMPAD5), "N5")
		text = gsub(text, escapePattern(KEY_NUMPAD6), "N6")
		text = gsub(text, escapePattern(KEY_NUMPAD7), "N7")
		text = gsub(text, escapePattern(KEY_NUMPAD8), "N8")
		text = gsub(text, escapePattern(KEY_NUMPAD9), "N9")
		text = gsub(text, escapePattern(KEY_NUMPADDIVIDE), "N/")
		text = gsub(text, escapePattern(KEY_NUMPADMULTIPLY), "N*")
		text = gsub(text, escapePattern(KEY_NUMPADMINUS), "N-")
		text = gsub(text, escapePattern(KEY_NUMPADPLUS), "N+")
		text = gsub(text, escapePattern(KEY_NUMPADDECIMAL), "N.")
    end
    return text or ""
end

function Addon:UpdateButtonFont(button, isStanceBar)
    if not button.TextOverlayContainer then return end

    local config, configName = Addon:GetConfig(button)
    
    local mult = math.min(button:GetParent():GetScale(), 1.0)

    local hotKey = button.TextOverlayContainer.HotKey:GetText()
    if hotKey and hotKey ~= _G.RANGE_INDICATOR then
        hotKey = FixKeyBindText(hotKey)
        button.TextOverlayContainer.HotKey:SetText(hotKey)
        if Addon:GetValue("CurrentHotkeyFont", nil, configName) ~= "Default" then
            button.TextOverlayContainer.HotKey:SetFont(
                LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentHotkeyFont", nil, configName)),
                (Addon:GetValue("UseHotkeyFontSize", nil, configName) and Addon:GetValue("HotkeyFontSize", nil, configName) or 11),
                Addon:GetValue("CurrentHotkeyOutline", nil, configName) > 1 and Addon.FontOutlines[Addon:GetValue("CurrentHotkeyOutline", nil, configName)] or ""
            )
        end
        button.TextOverlayContainer.HotKey:ClearAllPoints()
        local fontSize = Addon:GetValue("UseHotkeyFontSize", nil, configName) and Addon:GetValue("HotkeyFontSize", nil, configName) or 11
        button.TextOverlayContainer.HotKey:SetFontHeight(fontSize)
        button.TextOverlayContainer.HotKey:SetWidth(0)
        button.TextOverlayContainer.HotKey:SetPoint(
            Addon.AttachPoints[Addon:GetValue("CurrentHotkeyPoint", nil, configName)],
            button.TextOverlayContainer,
            Addon.AttachPoints[Addon:GetValue("CurrentHotkeyRelativePoint", nil, configName)],
            Addon:GetValue("UseHotkeyOffset", nil, configName) and Addon:GetValue("HotkeyOffsetX", nil, configName) or -5,
            Addon:GetValue("UseHotkeyOffset", nil, configName) and Addon:GetValue("HotkeyOffsetY", nil, configName) or -5
        )
        if Addon:GetValue("UseHotkeyShadow", nil, configName) then
            button.TextOverlayContainer.HotKey:SetShadowColor(Addon:GetRGBA("HotkeyShadow", nil, configName))
        else
            button.TextOverlayContainer.HotKey:SetShadowColor(0,0,0,0)
        end
        if Addon:GetValue("UseHotkeyShadowOffset", nil, configName) then
            button.TextOverlayContainer.HotKey:SetShadowOffset(Addon:GetValue("HotkeyShadowOffsetX", nil, configName)*mult, Addon:GetValue("HotkeyShadowOffsetY", nil, configName)*mult)
        else
            button.TextOverlayContainer.HotKey:SetShadowOffset(0,0)
        end
    end

    if Addon:GetValue("CurrentStacksFont", nil, configName) ~= "Default" then
        button.TextOverlayContainer.Count:SetFont(
            LibStub("LibSharedMedia-3.0"):Fetch("font", Addon:GetValue("CurrentStacksFont", nil, configName)),
            (Addon:GetValue("UseStacksFontSize", nil, configName) and Addon:GetValue("StacksFontSize", nil, configName) or 16),
            Addon:GetValue("CurrentStacksOutline", nil, configName) > 1 and Addon.FontOutlines[Addon:GetValue("CurrentStacksOutline", nil, configName)] or ""
        )
    end
    button.TextOverlayContainer.Count:ClearAllPoints()
    local fontSize = Addon:GetValue("UseStacksFontSize", nil, configName) and Addon:GetValue("StacksFontSize", nil, configName) or 16
    button.TextOverlayContainer.Count:SetFontHeight(fontSize)
    button.TextOverlayContainer.Count:SetPoint(
        Addon.AttachPoints[Addon:GetValue("CurrentStacksPoint", nil, configName)],
        button.TextOverlayContainer,
        Addon.AttachPoints[Addon:GetValue("CurrentStacksRelativePoint", nil, configName)],
        Addon:GetValue("UseStacksOffset", nil, configName) and Addon:GetValue("StacksOffsetX", nil, configName) or -5,
        Addon:GetValue("UseStacksOffset", nil, configName) and Addon:GetValue("StacksOffsetY", nil, configName) or 5
    )
    if Addon:GetValue("UseStacksShadow", nil, configName) then
        button.TextOverlayContainer.Count:SetShadowColor(Addon:GetRGBA("StacksShadow", nil, configName))
    else
        button.TextOverlayContainer.Count:SetShadowColor(0,0,0,0)
    end
    if Addon:GetValue("UseStacksShadowOffset", nil, configName) then
        button.TextOverlayContainer.Count:SetShadowOffset(Addon:GetValue("StacksShadowOffsetX", nil, configName)*mult, Addon:GetValue("StacksShadowOffsetY", nil, configName)*mult)
    else
        button.TextOverlayContainer.Count:SetShadowOffset(0,0)
    end
    if Addon:GetValue("UseStacksColor", nil, configName) then
        button.TextOverlayContainer.Count:SetVertexColor(Addon:GetRGBA("StacksColor", nil, configName))
    end

    if mult < 1 then
        button.TextOverlayContainer.HotKey:SetScale((Addon:GetValue("FontHotKey", nil, configName) and not isStanceBar) and Addon:GetValue("FontHotKeyScale", nil, configName) or 1.0)
        button.TextOverlayContainer.Count:SetScale((Addon:GetValue("FontStacks", nil, configName) and not isStanceBar) and Addon:GetValue("FontStacksScale", nil, configName) or 1.0)
        button.Name:SetScale(Addon:GetValue("FontName", nil, configName) and Addon:GetValue("FontNameScale", nil, configName) or 1.0)
    end
end

local function Hook_UpdateHotkeys(self, actionButtonType)
    local button = self:GetParent()
    local hotKey = self.HotKey
	local text = hotKey:GetText()
    hotKey:SetText(FixKeyBindText(text))
    Addon:UpdateButtonFont(self)    
end

local function RefreshDesaturated(icon, desaturated)
    local button = icon:GetParent()
    icon:SetDesaturated(desaturated)
end
function Addon:RefreshHotkeyColor(button)
    if not button.TextOverlayContainer or not button.TextOverlayContainer.HotKey then return end

    local config, configName = Addon:GetConfig(button)

    if Addon:GetValue("UseHotkeyColor", nil, configName) then
        button.TextOverlayContainer.HotKey:SetVertexColor(Addon:GetRGBA("HotkeyColor", nil, configName))
    end
end
function Addon:RefreshIconColor(button)

    local config, configName = Addon:GetConfig(button)

    local icon = button.icon
    local action = button.action
    if not action then return end

    local type, spellID = GetActionInfo(action)
    local desaturated = false

    local isUsable, notEnoughMana = IsUsableAction(action)
    button.needsRangeCheck = spellID and C_Spell.SpellHasRange(spellID)
    button.spellOutOfRange = button.needsRangeCheck and C_Spell.IsSpellInRange(spellID) == false
    if button.__isOnActualCooldown and Addon:GetValue("UseCDColor", nil, configName) then
        icon:SetVertexColor(Addon:GetRGBA("CDColor", nil, configName))
        desaturated = Addon:GetValue("CDColorDesaturate", nil, configName)
    elseif (button.spellOutOfRange and Addon:GetValue("UseOORColor", nil, configName)) then
        desaturated = Addon:GetValue("OORDesaturate", nil, configName)
        icon:SetVertexColor(Addon:GetRGBA("OORColor", nil, configName))       
    elseif isUsable then
        desaturated = false
        icon:SetVertexColor(1.0, 1.0, 1.0)
    elseif (notEnoughMana and Addon:GetValue("UseOOMColor", nil, configName)) then
        desaturated = Addon:GetValue("OOMDesaturate", nil, configName)
        icon:SetVertexColor(Addon:GetRGBA("OOMColor", nil, configName))
    elseif Addon:GetValue("UseNoUseColor", nil, configName) then
        desaturated = Addon:GetValue("NoUseDesaturate", nil, configName)
        icon:SetVertexColor(Addon:GetRGBA("NoUseColor", nil, configName))
    end
    if not button.spellOutOfRange then
        Addon:RefreshHotkeyColor(button)
    end

    RefreshDesaturated(icon, desaturated)
end

local function HoverHook(button, isHover)
    local frame = button.bar
    if not frame then
        frame = button:GetParent()
    end
    
    if frame.fade then
        Addon:Fade(frame, isHover)
    end
end

local function Hook_Update(self)
    Addon:RefreshIconColor(self)
    --Addon:RefreshHotkeyColor(self)
end
local function Hook_UpdateUsable(self, action, usable, noMana)
    Addon:RefreshIconColor(self)
end

function Addon:UpdateNormalTexture(button, isStanceBar, previewValue)
    local config, configName = Addon:GetConfig(button, true)
    local normalAtlas
    if previewValue then
        normalAtlas = T.NormalTextures[previewValue]
    else
        normalAtlas = T.NormalTextures[Addon:GetValue("CurrentNormalTexture", nil, configName)] or nil
    end

    if button.NormalTexture then
        if normalAtlas then
            Addon:SetTexture(button.NormalTexture, normalAtlas.texture)
            if normalAtlas.point then
                button.NormalTexture:ClearAllPoints()
                button.NormalTexture:SetPoint(normalAtlas.point, button, normalAtlas.point)
            end
            if normalAtlas.padding then
                button.NormalTexture:SetPointsOffset(normalAtlas.padding[1], normalAtlas.padding[2])
            end
            if normalAtlas.size then
                button.NormalTexture:SetSize(normalAtlas.size[1], normalAtlas.size[2])
            end
            if normalAtlas.coords then
                button.NormalTexture:SetTexCoord(normalAtlas.coords[1], normalAtlas.coords[2], normalAtlas.coords[3], normalAtlas.coords[4])
            end
            button.NormalTexture:SetDrawLayer("OVERLAY")
            button.NormalTexture:SetScale(isStanceBar and 0.69 or 1.0)
        end
        button.NormalTexture:SetDesaturated(Addon:GetValue("DesaturateNormal", nil, configName))
        if Addon:GetValue("UseNormalTextureColor", nil, configName) then
            button.NormalTexture:SetVertexColor(Addon:GetRGBA("NormalTextureColor", nil, configName))
        end
    end
end
function Addon:UpdateBackdropTexture(button, isStanceBar, previewValue)
    local config, configName = Addon:GetConfig(button)
    local backdropAtlas
    if previewValue then
        backdropAtlas = T.BackdropTextures[previewValue]
    else
        backdropAtlas = T.BackdropTextures[Addon:GetValue("CurrentBackdropTexture", nil, configName)] or nil
    end

    if button.SlotBackground then
        if backdropAtlas then
            if backdropAtlas.atlas then
                button.SlotBackground:SetAtlas(backdropAtlas.atlas)
            end
            if backdropAtlas.texture then
                button.SlotBackground:SetTexture(backdropAtlas.texture)
            end
            if backdropAtlas.point then
                button.SlotBackground:ClearAllPoints()
                button.SlotBackground:SetPoint(backdropAtlas.point, button, backdropAtlas.point)
            end
            if backdropAtlas.padding then
                button.SlotBackground:SetPointsOffset(backdropAtlas.padding[1], backdropAtlas.padding[2])
            end
            if backdropAtlas.size then
                button.SlotBackground:SetSize(backdropAtlas.size[1], backdropAtlas.size[2])
            end
            if backdropAtlas.coords then
                button.SlotBackground:SetTexCoord(backdropAtlas.coords[1], backdropAtlas.coords[2], backdropAtlas.coords[3], backdropAtlas.coords[4])
            end
            button.SlotBackground:SetScale(isStanceBar and 0.69 or 1.0)
        end
        button.SlotBackground:SetDesaturated(Addon:GetValue("DesaturateBackdrop", nil, configName))
        if Addon:GetValue("UseBackdropColor", nil, configName) then
            button.SlotBackground:SetVertexColor(Addon:GetRGBA("BackdropColor", nil, configName))
        end
    end
end
function Addon:UpdatePushedTexture(button, isStanceBar, previewValue)
    local config, configName = Addon:GetConfig(button)
    local pushedAtlas
    if previewValue then
        pushedAtlas = T.PushedTextures[previewValue]
    else
        pushedAtlas = T.PushedTextures[Addon:GetValue("CurrentPushedTexture", nil, configName)] or nil
    end

    if button.PushedTexture then
        if pushedAtlas then
            if pushedAtlas.atlas then
                button:SetPushedAtlas(pushedAtlas.atlas)
            elseif pushedAtlas.texture then
                button.PushedTexture:SetTexture(pushedAtlas.texture)
            end
            if pushedAtlas.point then
                button.PushedTexture:ClearAllPoints()
                button.PushedTexture:SetPoint(pushedAtlas.point, button, pushedAtlas.point)
            end
            if pushedAtlas.size then
                button.PushedTexture:SetSize(pushedAtlas.size[1], pushedAtlas.size[2])
            end
            if pushedAtlas.coords then
                button.PushedTexture:SetTexCoord(pushedAtlas.coords[1], pushedAtlas.coords[2], pushedAtlas.coords[3], pushedAtlas.coords[4])
            end
            button.PushedTexture:SetDrawLayer("OVERLAY")
            button.PushedTexture:SetScale(isStanceBar and 0.69 or 1.0)
        end

        button.PushedTexture:SetDesaturated(Addon:GetValue("DesaturatePushed", nil, configName))
        if Addon:GetValue("UsePushedColor", nil, configName) then
            button.PushedTexture:SetVertexColor(Addon:GetRGBA("PushedColor", nil, configName))
        end
    end
end
function Addon:UpdateHighlightTexture(button, isStanceBar, previewValue)
    local config, configName = Addon:GetConfig(button)
    local highlightAtlas
    if previewValue then
        highlightAtlas = T.HighlightTextures[previewValue]
    else
        highlightAtlas = T.HighlightTextures[Addon:GetValue("CurrentHighlightTexture", nil, configName)] or nil
    end

    if highlightAtlas and highlightAtlas.hide then
        button.HighlightTexture:Hide()
    else
        if highlightAtlas and Addon:GetValue("CurrentHighlightTexture", nil, configName) > 1 then
            if highlightAtlas.atlas then
                button.HighlightTexture:SetAtlas(highlightAtlas.atlas)
            elseif highlightAtlas.texture then
                button.HighlightTexture:SetTexture(highlightAtlas.texture)
            end
            if highlightAtlas.point then
                button.HighlightTexture:ClearAllPoints()
                button.HighlightTexture:SetPoint(highlightAtlas.point, button, highlightAtlas.point)
            end
            if highlightAtlas.padding then
                button.HighlightTexture:SetPointsOffset(highlightAtlas.padding[1], highlightAtlas.padding[2])
            end
            if highlightAtlas.size then
                button.HighlightTexture:SetSize(highlightAtlas.size[1], highlightAtlas.size[2])
            end
            if highlightAtlas.coords then
                button.HighlightTexture:SetTexCoord(highlightAtlas.coords[1], highlightAtlas.coords[2], highlightAtlas.coords[3], highlightAtlas.coords[4])
            end
            if highlightAtlas and Addon:GetValue("CurrentHighlightTexture", nil, configName) > 2 then
                button.HighlightTexture:SetScale(isStanceBar and 0.69 or 1.0)
            end
        end

        button.HighlightTexture:SetDesaturated(Addon:GetValue("DesaturateHighlight", nil, configName))
        if Addon:GetValue("UseHighlightColor", nil, configName) then
            button.HighlightTexture:SetVertexColor(Addon:GetRGBA("HighlightColor", nil, configName))
        end
    end
end
function Addon:UpdateCheckedTexture(button, isStanceBar, previewValue)
    local config, configName = Addon:GetConfig(button)
    if button.CheckedTexture then
        local checkedAtlas
        if previewValue then
            checkedAtlas = T.HighlightTextures[previewValue]
        else
            checkedAtlas = T.HighlightTextures[Addon:GetValue("CurrentCheckedTexture", nil, configName)] or nil
        end

        if checkedAtlas then
            if Addon:GetValue("CurrentCheckedTexture", nil, configName) > 1 then
                if checkedAtlas.atlas then
                    button.CheckedTexture:SetAtlas(checkedAtlas.atlas)
                elseif checkedAtlas.texture then
                    button.CheckedTexture:SetTexture(checkedAtlas.texture)
                end
                if checkedAtlas.point then
                    button.CheckedTexture:ClearAllPoints()
                    button.CheckedTexture:SetPoint(checkedAtlas.point, button, checkedAtlas.point)
                end
                if checkedAtlas.size then
                    button.CheckedTexture:SetSize(checkedAtlas.size[1], checkedAtlas.size[2])
                end
                if checkedAtlas.coords then
                    button.CheckedTexture:SetTexCoord(checkedAtlas.coords[1], checkedAtlas.coords[2], checkedAtlas.coords[3], checkedAtlas.coords[4])
                end
                if Addon:GetValue("CurrentCheckedTexture", nil, configName) > 2 then
                    button.CheckedTexture:SetScale(isStanceBar and 0.69 or 1.0)
                end
            end

            button.CheckedTexture:SetDesaturated(Addon:GetValue("DesaturateChecked", nil, configName))
            if Addon:GetValue("UseCheckedColor", nil, configName) then
                button.CheckedTexture:SetVertexColor(Addon:GetRGBA("CheckedColor", nil, configName))
            end
        end
    end
end
function Addon:UpdateIconMask(button, isStanceBar, previewValue)
    local config, configName = Addon:GetConfig(button)
    local iconMaskAtlas
    if previewValue then
        iconMaskAtlas = T.IconMaskTextures[previewValue]
    else
        iconMaskAtlas = T.IconMaskTextures[Addon:GetValue("CurrentIconMaskTexture", nil, configName)] or nil
    end

    if iconMaskAtlas then
        if Addon:GetValue("CurrentIconMaskTexture", nil, configName) > 1 then
            button.IconMask:SetHorizTile(false)
            button.IconMask:SetVertTile(false)

            Addon:SetTexture(button.IconMask,iconMaskAtlas.texture)
            
            if iconMaskAtlas.point then
                button.IconMask:ClearAllPoints()
                button.IconMask:SetPoint(iconMaskAtlas.point, button.icon, iconMaskAtlas.point)
            end
            if iconMaskAtlas.size then
                button.IconMask:SetSize(iconMaskAtlas.size[1], iconMaskAtlas.size[2])
            end
            if iconMaskAtlas.coords then
                button.IconMask:SetTexCoord(iconMaskAtlas.coords[1], iconMaskAtlas.coords[2], iconMaskAtlas.coords[3], iconMaskAtlas.coords[4])
            end
        end
        if isStanceBar then
            button.IconMask:SetScale(Addon:GetValue("UseIconMaskScale", nil, configName) and Addon:GetValue("IconMaskScale", nil, configName) * 0.69 or 1.0)
        else
            button.IconMask:SetScale(Addon:GetValue("UseIconMaskScale", nil, configName) and Addon:GetValue("IconMaskScale", nil, configName) or 1.0)
        end
    end
end
function Addon:UpdateIcon(button, isStanceBar, previewValue)
    local scale = previewValue or ((Addon:GetValue("UseIconScale", nil, configName) and Addon:GetValue("IconScale", nil, configName) or 1.0))
    button.icon:ClearAllPoints()
    button.icon:SetPoint("CENTER", button, "CENTER", -0.5, 0.5)
    if isStanceBar then
        button.icon:SetSize(31,31)
    else
        button.icon:SetSize(45,45)
    end
    button.icon:SetScale(scale)
end

function Addon:UpdateCooldown(button, isStanceBar, previewValue)

    local config, configName = Addon:GetConfig(button)

    if Addon:GetValue("UseSwipeSize", nil, configName) then
        button.cooldown:ClearAllPoints()
        local size = isStanceBar and Addon:GetValue("SwipeSize", nil, configName)*0.69 or Addon:GetValue("SwipeSize", nil, configName)
        button.cooldown:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
        button.cooldown:SetSize(size, size)

        button.lossOfControlCooldown:ClearAllPoints()
        local size = isStanceBar and Addon:GetValue("SwipeSize", nil, configName)*0.69 or Addon:GetValue("SwipeSize", nil, configName)
        button.lossOfControlCooldown:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
        button.lossOfControlCooldown:SetSize(size, size)
    end

    local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
    local bar = button.bar

    if Addon:GetValue("UseCooldownFontColor", nil, configName) then
        color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownFontColor", nil, configName)
        if bar and not bar.cooldownColorCurve then
            bar.cooldownColorCurve = C_CurveUtil.CreateColorCurve()
            bar.cooldownColorCurve:SetType(Enum.LuaCurveType.Linear)
            bar.cooldownColorCurve:AddPoint(0, CreateColor(1, 1, 1, color.a))
            bar.cooldownColorCurve:AddPoint(0.01, CreateColor(1, 0, 0, color.a))
            bar.cooldownColorCurve:AddPoint(5, CreateColor(1, 0, 0, color.a))
            bar.cooldownColorCurve:AddPoint(5.2, CreateColor(1, 1, 0, color.a))
            bar.cooldownColorCurve:AddPoint(10, CreateColor(1, 1, 0, color.a))
            bar.cooldownColorCurve:AddPoint(10.2, CreateColor(color.r, color.g, color.b, color.a))
        end
    elseif bar then
        bar.cooldownColorCurve = Addon.cooldownColorCurve
    end

    local fontSize = Addon:GetValue("UseCooldownFontSize", nil, configName) and Addon:GetValue("CooldownFontSize", nil, configName) or 17
    local _, fontName = Addon:GetFontObject(
        Addon:GetValue("CurrentCooldownFont", nil, configName),
        "OUTLINE, SLUG",
        color,
        fontSize,
        isStanceBar
    )

    local fontString = button.cooldown:GetCountdownFontString()
    local fontStringCharges = button.chargeCooldown:GetCountdownFontString()
    if Addon:GetValue("UseCooldownFontOffset", nil, configName) then
        local offsetX = Addon:GetValue("CooldownFontOffsetX", nil, configName)
        local offsetY = Addon:GetValue("CooldownFontOffsetY", nil, configName)

        fontString:SetPointsOffset(offsetX, offsetY)
        if fontStringCharges then
            fontStringCharges:SetPointsOffset(offsetX, offsetY)
        end
        
    else
        fontString:SetPointsOffset(0, 0)
        if fontStringCharges then
            fontStringCharges:SetPointsOffset(0, 0)
        end
    end

    button.cooldown:SetCountdownFont(fontName)
    if button.chargeCooldown then
        button.chargeCooldown:SetCountdownFont(fontName)
    end
    button.cooldown:SetCountdownAbbrevThreshold(920)

    if button.cooldown:IsUsingParentLevel() then
        button.cooldown:SetUsingParentLevel(false)
    end
    if button.chargeCooldown and button.chargeCooldown:IsUsingParentLevel() then
        button.chargeCooldown:SetUsingParentLevel(false)
    end

    button.cooldown:SetFrameLevel(510)
    button.chargeCooldown:SetFrameLevel(510)

end

local function Hook_ButtonOnUpdate(button)
    local action = button.action
    if not action or not C_ActionBar.HasAction(action) then return end

    local actionType, actionID = GetActionInfo(button.action)

    if not actionID then return end

    local cooldownFrame = button.cooldown

    if not cooldownFrame:IsVisible() then return end

    local fontString = cooldownFrame:GetCountdownFontString()

    if not fontString or not fontString:IsVisible() then return end

    local bar = button.bar

    if not bar then return end

    local durationObj = C_Spell.GetSpellChargeDuration(actionID) or C_Spell.GetSpellCooldownDuration(actionID)
    if durationObj then
        local EvaluateDuration = durationObj.EvaluateRemainingDuration and durationObj:EvaluateRemainingDuration(bar.cooldownColorCurve) or nil

        if EvaluateDuration then
            fontString:SetVertexColor(EvaluateDuration:GetRGBA())
        end
        
    end
end

local function Hook_UpdateButton(button, isStanceBar)
    if button == ExtraActionButton1 then return end
    
    local config, configName = Addon:GetConfig(button)

    if Addon:GetValue("FadeBars", nil, configName) and not button.__hookedFade then
        button:HookScript("OnEnter", function(self) 
            HoverHook(self, true)
        end)
        button:HookScript("OnLeave", function(self)
            HoverHook(self, false)
        end)
        button.__hookedFade = true
    end

    local frame = button:GetParent():GetName()
    if frame == "MicroMenu" or frame == "BagsBar" then
        return
    end

    if button.NormalTexture then
        Addon:UpdateNormalTexture(button, isStanceBar)
    end
    if button.SlotBackground then
        Addon:UpdateBackdropTexture(button, isStanceBar)
    end
    if button.PushedTexture then
        Addon:UpdatePushedTexture(button, isStanceBar)
    end
    if button.HighlightTexture then
        Addon:UpdateHighlightTexture(button, isStanceBar)
    end
    if button.CheckedTexture then
        Addon:UpdateCheckedTexture(button, isStanceBar)
    end

    if Addon:GetValue("UseButtonSize", nil, configName) then
        button:SetSize(Addon:GetValue("ButtonSizeX", nil, configName), Addon:GetValue("ButtonSizeY", nil, configName))
    else
        button:SetSize(42, 42)
    end

    if button.IconMask then
        Addon:UpdateIconMask(button, isStanceBar)
    end

    if button.icon then
        Addon:UpdateIcon(button, isStanceBar)
    end

    if button.cooldown then
        Addon:UpdateCooldown(button, isStanceBar)
    end

    if button.Flash then
        button.Flash:ClearAllPoints()
        button.Flash:SetPoint("CENTER", button, "CENTER")
    end

    if button.Name then
        if Addon:GetValue("FontHideName", nil, configName) then
            button.Name:Hide()
        else
            button.Name:Show()
        end
    end
    if button.Border then
        button.Border:SetTexture("")
        button.Border:Hide()
    end
    Addon:UpdateButtonFont(button, isStanceBar)

    local eventFrame = ActionBarActionEventsFrame
    if eventFrame and Addon:GetValue("HideInterrupt", nil, configName) then
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
    if eventFrame and Addon:GetValue("HideCasting", nil, configName) then
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_START")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_START")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
    end
    if eventFrame and Addon:GetValue("HideReticle", nil, configName) then
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_RETICLE_CLEAR")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_RETICLE_TARGET")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
    end
    if button.Update and not button.__hookedUpdate then
        hooksecurefunc(button, "Update", Hook_Update)
        button.__hookedUpdate = true
    end
    if button.UpdateUsable and not button.__hookedUpdateUsable then
        hooksecurefunc(button, "UpdateUsable", Hook_UpdateUsable)
        button.__hookedUpdateUsable = true
    end
    if button.UpdateHotkeys and not button.__hookedUpdateHotkeys then
        hooksecurefunc(button, "UpdateHotkeys", Hook_UpdateHotkeys)
        button.__hookedUpdateHotkeys = true
    end

    if Addon:GetValue("ColorizedCooldownFont", nil, configName) and not button.__hookedOnUpdate then
        if button.OnUpdate then
            button:HookScript("OnUpdate", Hook_ButtonOnUpdate)
        end
        button.__hookedOnUpdate = true
    end
end

local function Hook_RangeCheckButton(slot, inRange, checksRange)
    
    local buttons = ActionBarButtonRangeCheckFrame.actions[slot]
    if buttons then
        for _, button in pairs(buttons) do
            Addon:RefreshIconColor(button)
            --Addon:RefreshHotkeyColor(button)
        end
    end
end
function Addon:RefreshCooldown(button, isStanceBar, barName)
    local config, configName = Addon:GetConfig(button)
    local function RefreshEdgeTexture(cooldown, isStanceBar)
        cooldown:SetEdgeTexture(T.EdgeTextures[Addon:GetValue("CurrentEdgeTexture", nil, configName)].texture)
        if Addon:GetValue("UseEdgeSize", nil, configName) then
            local size = Addon:GetValue("EdgeSize", nil, configName)
            if size > 2 then
                Addon:SetValue("EdgeSize", 1, nil, configName)
            end
            size = isStanceBar and size * 0.69 or size
            cooldown:SetEdgeScale(size)
        end
        if Addon:GetValue("UseEdgeColor", nil, configName) then
            cooldown:SetEdgeColor(Addon:GetRGBA("EdgeColor", nil, configName))
        end
    end
    local function RefreshSwipeTexture(button, cooldown, isStanceBar)
        if Addon:GetValue("CurrentSwipeTexture", nil, configName) and Addon:GetValue("CurrentSwipeTexture", nil, configName) > 1 then
            cooldown:SetSwipeTexture(T.SwipeTextures[Addon:GetValue("CurrentSwipeTexture", nil, configName)].texture)
            button.lossOfControlCooldown:SetSwipeTexture(T.SwipeTextures[Addon:GetValue("CurrentSwipeTexture", nil, configName)].texture)
        end
        if Addon:GetValue("UseCooldownColor", nil, configName) then
            cooldown:SetSwipeColor(Addon:GetRGBA("CooldownColor", nil, configName))
            button.lossOfControlCooldown:SetSwipeColor(Addon:GetRGBA("CooldownColor", nil, configName))
            
        end
    end
    if button.cooldown then
        RefreshSwipeTexture(button, button.cooldown, isStanceBar)

        button.cooldown:SetDrawEdge(Addon:GetValue("EdgeAlwaysShow", nil, configName))
        if button.cooldown:GetDrawEdge() then
            RefreshEdgeTexture(button.cooldown, isStanceBar)
        end
    end
    if button.chargeCooldown then
        RefreshEdgeTexture(button.chargeCooldown, isStanceBar)
        RefreshSwipeTexture(button, button.chargeCooldown, isStanceBar)
        local showCountdonwNumbers = Addon:GetValue("ShowCountdownNumbersForCharges", nil, configName)
        button.chargeCooldown:SetHideCountdownNumbers(not showCountdonwNumbers)
    end
    Addon:RefreshIconColor(button)
end

local function Hook_OnCooldownDone(self)
    local button = self:GetParent()

    if not button.__cooldownSet then return end

    button.__cooldownSet = nil
    button.__isOnActualCooldown = false
    C_Timer.After(0, function()
        Addon:RefreshIconColor(button)
    end)
end

local function Hook_OnChargeDone(self)
    local button = self:GetParent()
    
    if not button.__cooldownSet then return end


    button.__isOnChargeCooldown = false

    C_Timer.After(0, function()
        Addon:RefreshIconColor(button)
    end)
end

local function Hook_Assist(self, actionButton, shown)
    local highlightFrame = actionButton.AssistedCombatHighlightFrame
    if highlightFrame and highlightFrame:IsVisible() then
        if shown then
            Addon:UpdateAssistFlipbook(highlightFrame.Flipbook)
        end
    end
end

-- todo rewrite this for better hook because it used only for stance bar
--[[ local function Hook_CooldownFrame_Set(self)
    if not self then return end
    if not self.GetParent then return end

    local button = self:GetParent()
    if not button then return end

    local bar = button.bar
    if not bar then
        bar = button:GetParent()
    end

    local barName = bar and bar:GetName() or ""
    
    if barName == "" or not tContains(ACTION_BARS, barName) then
        return
    end

    local isStanceBar = (barName == "PetActionBar" or barName == "StanceBar")

    if isStanceBar then
        Addon:RefreshCooldown(button, isStanceBar, barName)
    end
end ]]
local function Hook_StanceBarOnCooldownSet(self)
    local button = self:GetParent()
    local bar = button.bar
    if not bar then
        bar = button:GetParent()
    end
    local barName = bar and bar:GetName() or false
    if not barName then return end
    
    local isStanceBar = true

    Addon:RefreshCooldown(button, isStanceBar, barName)
end

local function Hook_ActionButton_ApplyCooldown(cooldownFrame, cdInfo, chargeCooldown, crgInfo, losCooldown, losInfo)
    if not cooldownFrame then return end
    if not cooldownFrame.GetParent then return end

    local button = cooldownFrame:GetParent()
    if not button then return end

    local bar = button.bar
    if not bar then
        bar = button:GetParent()
    end

    local barName = bar and bar:GetName() or ""
    
    if barName == "" or not tContains(ACTION_BARS, barName) then
        return
    end

    local isStanceBar = (barName == "PetActionBar" or barName == "StanceBar")

    local cooldownTimerString = cooldownFrame:GetCountdownFontString()

    C_Timer.After(0, function()
        --[[ if cooldownTimerString:IsVisible() then
            button.__isOnActualCooldown = true
            button.__cooldownSet = true
        else
            button.__isOnActualCooldown = false
        end ]]
        
        -- for future workaround when IsVisible() wouldn't work
        --[[ if cooldownTimerString:GetWidth() > 1.1 then
            button.__isOnActualCooldown = true
            button.__cooldownSet = true
        else
            button.__isOnActualCooldown = false
        end ]]
        Addon:RefreshCooldown(button, isStanceBar, barName)

    end)

    --[[ local actionType, actionID = GetActionInfo(button.action)
    if not actionID then return end

    button.__spellID = actionID

    chargeInfo = C_Spell.GetSpellCharges(actionID)
    cooldownInfo = C_Spell.GetSpellCooldown(actionID)
    button.__isOnGCD = cooldownInfo.isOnGCD

    if chargeInfo and chargeInfo.cooldownStartTime and chargeInfo.cooldownDuration then

        if cooldownInfo.isOnGCD == false then
            button.__isOnActualCooldown = true
            button.__cooldownSet = true
        else
            button.__isOnActualCooldown = false
        end

        if chargeCooldown:IsVisible() then
            button.isOnChargeCooldown = true
        end

    elseif cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
        if not button.__isOnChargeCooldown then
            
            if cooldownInfo.isOnGCD == false then
                button.__isOnActualCooldown = true
                button.__cooldownSet = true
            end
        end
    end ]]

    if not cooldownFrame.__cooldownDoneHooked then
        if cooldownFrame.Clear then
            hooksecurefunc(cooldownFrame, "Clear", Hook_OnCooldownDone)
        end
        cooldownFrame:HookScript("OnCooldownDone", Hook_OnCooldownDone)
        cooldownFrame.__cooldownDoneHooked = true
    end
    if not chargeCooldown.__cooldownDoneHooked then
        if chargeCooldown.Clear then
            hooksecurefunc(chargeCooldown, "Clear", Hook_OnChargeDone)
        end
        chargeCooldown:SetScript("OnCooldownDone", Hook_OnChargeDone)
        
        chargeCooldown.__cooldownDoneHooked = true
    end
    --[[ if not losCooldown.__cooldownDoneHooked then
        --losCooldown:HookScript("OnCooldownDone", Hook_OnLosCooldownDone)
        losCooldown.__cooldownDoneHooked = true
    end ]]
    
end

local function InitializeSavedVariables()
    ABDB = ABDB or {}

    for key, defaultValue in pairs(Addon.Defaults) do
        if ABDB[key] ~= nil then
            Addon.Options[key] = ABDB[key]
        else
            Addon.Options[key] = type(Addon.Options[key]) == "table" and CopyTable(defaultValue) or defaultValue
            ABDB[key] = Addon.Options[key]
        end
    end
end
local function ApplyProfile()
    ABDB = ABDB or {}
    ABDB.Profiles = ABDB.Profiles or {}
    Addon.P = ABDB.Profiles

    if next(ABDB) then
        local migrate, table = ActionBarsEnhancedProfilesMixin:NeedMigrateProfile()
        if migrate then
            local playerID = Addon:GetPlayerID()
            ABDB.Profiles.mapping = ABDB.Profiles.mapping or {}
            ABDB.Profiles.mapping[playerID] = "Default"
            ABDB.Profiles.profilesList = ABDB.Profiles.profilesList or {}
            ABDB.Profiles.profilesList["Default"] = CopyTable(table)
        end
    end

    local currentProfile = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()

    if not ActionBarsEnhancedImportDialogMixin:HasDefaultProfiles() then
        ActionBarsEnhancedProfilesMixin:InstallDefaultPresets()
    end

    ActionBarsEnhancedProfilesMixin:CheckProfiles15()

    ActionBarsEnhancedProfilesMixin:SetProfile(currentProfile)
end
local function flyoutButtonOnEnter(self, isHover)
    local parent = self:GetParent()

    local frame = parent.flyoutButton.bar
    if not frame then
        return
    end
    
    if frame.fade then
        Addon:Fade(frame, isHover)
    end
end
local function OnSpellFlyoutSizeChanged(...)
    for i, button in ipairs(SpellFlyout:GetLayoutChildren()) do
        if (button.OnEnter and button.OnLeave) and not button.__OnEnterHooked then
            button:HookScript("OnEnter", function(self)
                flyoutButtonOnEnter(self, true)
            end)
            button:HookScript("OnLeave", function(self)
                flyoutButtonOnEnter(self, false)
            end)
            button.__OnEnterHooked = true
        end
    end
end

local function UpdateStanceAndPetBars()
    if StanceBar then
        for i, button in pairs(StanceBar.actionButtons) do
            Hook_UpdateButton(button, true)
            local cdFrame = button.cooldown or button.Cooldown
            if cdFrame and cdFrame.SetCooldown then
                hooksecurefunc(cdFrame, "SetCooldown", Hook_StanceBarOnCooldownSet)
            end
        end
    end
    if PetActionBar then
        for i, button in pairs(PetActionBar.actionButtons) do
            Hook_UpdateButton(button, true)
            local cdFrame = button.cooldown or button.Cooldown
            if cdFrame and cdFrame.SetCooldown then
                hooksecurefunc(cdFrame, "SetCooldown", Hook_StanceBarOnCooldownSet)
            end
        end
    end
    if MicroMenu then
        for i, button in ipairs(MicroMenu:GetLayoutChildren()) do
            Hook_UpdateButton(button, true)
        end
    end
    if BagsBar then
        for i, button in MainMenuBarBagManager:EnumerateBagButtons() do
            Hook_UpdateButton(button, true)
        end
    end
    if SpellFlyout and not SpellFlyout.__hooked then
        SpellFlyout:HookScript("OnSizeChanged", OnSpellFlyoutSizeChanged)
    end
    -- todo find better place
    if MainMenuBarVehicleLeaveButton then
        MainMenuBarVehicleLeaveButton:SetIgnoreParentAlpha(true)
    end
end

local function DisableTalkingHeadFrame()
    TalkingHeadFrame:Hide()
end

local function ProcessEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", Hook_UpdateFlipbook)
        --hooksecurefunc("CooldownFrame_Set", Hook_CooldownFrame_Set)
        if ActionButton_ApplyCooldown then
            hooksecurefunc("ActionButton_ApplyCooldown", Hook_ActionButton_ApplyCooldown)
        end

        hooksecurefunc(AssistedCombatManager, "SetAssistedHighlightFrameShown", Hook_Assist)

        --UIParent:SetScale(0.53333)
        ApplyProfile()

        --Addon:UpdateAllActionBarGrid()
        Addon:HookActionBarGrid()

        Addon.ClassColor = {PlayerUtil.GetClassColor():GetRGB()}

        local f = EnumerateFrames()

		while f do
			if f.OnLoad == ActionBarActionButtonMixin.OnLoad then
				Hook_UpdateButton(f)
			end

			f = EnumerateFrames(f)
		end

        hooksecurefunc(ActionBarActionButtonMixin, "OnLoad", Hook_UpdateButton)
        UpdateStanceAndPetBars()

        Addon:Welcome()

        if not next(Addon.Fonts) then
            Addon.Fonts = Addon:GetFontsList()
        end
        if not next(T.StatusBarTextures) then
            T.StatusBarTextures = Addon:GetStatusBarTextures()
        end

        if Addon.C.HideTalkingHead then
            Addon.eventHandlerFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
        else
            Addon.eventHandlerFrame:UnregisterEvent("TALKINGHEAD_REQUESTED")
        end

        Addon.CurrentProfileTbl = Addon.CurrentProfileTbl or Addon:GetCurrentProfileTable()
        Addon:BarsFadeAnim()
    end
    if event == "TALKINGHEAD_REQUESTED" then
        DisableTalkingHeadFrame()
    end
    if event == "ACTION_RANGE_CHECK_UPDATE" then
        local slot, inRange, checksRange = ...
        Hook_RangeCheckButton(slot, inRange, checksRange)
    end
    if event == "PLAYER_REGEN_DISABLED"
    or event == "PLAYER_REGEN_ENABLED"
    or event == "PLAYER_TARGET_CHANGED"
    or event == "UNIT_SPELLCAST_START"
    or event == "UNIT_SPELLCAST_STOP" then
        Addon:BarsFadeAnim()
    end
end

Addon.eventHandlerFrame = CreateFrame('Frame')
Addon.eventHandlerFrame:SetScript('OnEvent', ProcessEvent)
Addon.eventHandlerFrame:RegisterEvent('PLAYER_LOGIN')
Addon.eventHandlerFrame:RegisterEvent('ACTION_RANGE_CHECK_UPDATE')
Addon.eventHandlerFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
Addon.eventHandlerFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
Addon.eventHandlerFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
Addon.eventHandlerFrame:RegisterUnitEvent('UNIT_SPELLCAST_START', "player")
Addon.eventHandlerFrame:RegisterUnitEvent('UNIT_SPELLCAST_STOP', "player")
Addon.eventHandlerFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
