local AddonName, Addon = ...

local C = Addon.Options
local T = Addon.Templates

local function GetFlipBook(...)
    local Animations = {...}

    for _, Animation in ipairs(Animations) do
        if Animation:GetObjectType() == "FlipBook" then
            Animation:SetParentKey("FlipAnim")
            return Animation
        end
    end
end

function Addon:UpdateAssistFlipbook(region)

    local loopAnim = T.LoopGlow[C.CurrentAssistType] or nil

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
    region:SetDesaturated(C.DesaturateAssist)
    if C.UseAssistGlowColor then
        region:SetVertexColor(Addon:GetRGB("LoopGlowColor"))
    else
        region:SetVertexColor(1.0, 1.0, 1.0)
    end
	region.Anim:Stop()
    region.Anim:Play()
end

function Addon:UpdateFlipbook(Button)
    if not Button:IsVisible() then return end
    
	local region = Button.SpellActivationAlert

	if (not region) or (not region.ProcStartAnim) then return end

    local loopAnim = T.LoopGlow[C.CurrentLoopGlow] or nil
    local procAnim = T.ProcGlow[C.CurrentProcGlow] or nil
    local altGlowAtlas = T.PushedTextures[C.CurrentAssistAltType] or nil

    if altGlowAtlas then
        region.ProcAltGlow:SetAtlas(altGlowAtlas.atlas)
    end
    region.ProcAltGlow:SetDesaturated(C.DesaturateAssistAlt)
    if C.UseAssistAltColor then
        region.ProcAltGlow:SetVertexColor(Addon:GetRGB("AssistAltColor"))
    else
        region.ProcAltGlow:SetVertexColor(1.0, 1.0, 1.0)
    end
        
    local startProc = region.ProcStartAnim.FlipAnim or GetFlipBook(region.ProcStartAnim:GetAnimations())
    
    if startProc then
        
        if C.HideProc then
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
                region.ProcStartFlipbook:SetScale(procAnim.scale or 1)
            end
            region.ProcStartFlipbook:SetDesaturated(C.DesaturateProc)

            if C.UseProcColor then
                region.ProcStartFlipbook:SetVertexColor(Addon:GetRGB("ProcColor"))
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
        region.ProcLoopFlipbook:SetScale(loopAnim.scale or 1)
    end
    --region.ProcLoopFlipbook:SetTexCoords(333, 400, 0.412598, 0.575195, 0.393555, 0.78418, false, false)
    region.ProcLoopFlipbook:SetDesaturated(C.DesaturateGlow)
    if C.UseLoopGlowColor then
        region.ProcLoopFlipbook:SetVertexColor(Addon:GetRGB("LoopGlowColor"))
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



-----------------------------------------
-- forked from ElvUI
-----------------------------------------

local Fader = CreateFrame('Frame')
Fader.Frames = {}
Fader.interval = 0.025

local function Fading(_, elapsed)
    Fader.timer = (Fader.timer or 0) + elapsed
    if Fader.timer > Fader.interval then
        Fader.timer = 0

        for frame, data in next, Fader.Frames do
            if frame:IsVisible() then
                data.fadeTimer = (data.fadeTimer or 0) + (elapsed + Fader.interval)
            else
                data.fadeTimer = (data.fadeTimer or 0) + 1
            end

            if data.fadeTimer < data.duration then
                if data.mode == "IN" then
                    frame:SetAlpha((data.fadeTimer / data.duration) * data.diffAlpha + data.fromAlpha)
                else
                    frame:SetAlpha(((data.duration - data.fadeTimer) / data.duration) * data.diffAlpha + data.toAlpha)
                end
            else
                frame:SetAlpha(data.toAlpha)
                if frame and Fader.Frames[frame] then
                    if frame.fade then
                        frame.fade.fadeTimer = nil
                    end
                    Fader.Frames[frame] = nil
                end
            end
        end
        if not next(Fader.Frames) then
            Fader:SetScript("OnUpdate", nil)
        end
    end
end

local function FrameFade(frame)
    local fade = frame.fade
    frame:SetAlpha(fade.fromAlpha)

    if not Fader.Frames[frame] then
        Fader.Frames[frame] = fade
        Fader:SetScript("OnUpdate", Fading)
    else
        Fader.Frames[frame] = fade
    end
end

local function FrameFadeIn(frame, duration, fromAlpha, toAlpha)
    if frame.fade then
        frame.fade.fadeTimer = nil
    else
        frame.fade = {}
    end

    frame.fade.mode = "IN"
    frame.fade.duration = duration
    frame.fade.fromAlpha = fromAlpha
    frame.fade.toAlpha = toAlpha
    frame.fade.diffAlpha = toAlpha - fromAlpha

    FrameFade(frame)
end

local function FrameFadeOut(frame, duration, fromAlpha, toAlpha)
    if frame.fade then
        frame.fade.fadeTimer = nil
    else
        frame.fade = {}
    end

    frame.fade.mode = "OUT"
    frame.fade.duration = duration
    frame.fade.fromAlpha = fromAlpha
    frame.fade.toAlpha = toAlpha
    frame.fade.diffAlpha = fromAlpha - toAlpha

    FrameFade(frame)
end

local bars = {
    
	"MultiActionBar",
	"StanceBar",
	"PetBar",
	"PossessActionBar",
	"BonusBar",
	"VehicleBar",
	"TempShapeshiftBar",
	"OverrideBar",
    "MainMenuBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
}

local animBars = {}

local function IsFrameFocused(frame)
    local focusedFrames = GetMouseFoci()
    local focusedFrame
    if focusedFrames then
        if focusedFrames[1] then
            if focusedFrames[1]:GetParent() and focusedFrames[1]:GetParent():GetParent() then
                focusedFrame = focusedFrames[1]:GetParent():GetParent()
            end
        end
    end
    return focusedFrames and focusedFrame == frame
end

local function ShouldFadeIn(frame)
    return (C.FadeInOnCombat and UnitAffectingCombat("player"))
    or (C.FadeInOnTarget and UnitExists("target"))
    or (C.FadeInOnCasting and UnitCastingInfo("player"))
    or (C.FadeInOnHover and IsFrameFocused(frame))
end

function Addon:BarsFadeAnim()
    if not C.FadeBars then return end
    for _, barName in ipairs(animBars) do
        local frame = _G[barName]
        if frame then
            if C.FadeBars and ShouldFadeIn(frame) then
                FrameFadeIn(frame, 0.25, frame:GetAlpha(), 1)
            else
                FrameFadeOut(frame, 0.25, frame:GetAlpha(), C.FadeBarsAlpha)
            end
        end
    end
end

function Addon:RefreshIconColor(button)
    local icon = button.icon
    local action = button.action
    local type, spellID = GetActionInfo(action)

    local isUsable, notEnoughMana = IsUsableAction(button.action)
    button.needsRangeCheck = spellID and C_Spell.SpellHasRange(spellID)
    button.spellOutOfRange = button.needsRangeCheck and C_Spell.IsSpellInRange(spellID) == false
    if (button.spellOutOfRange and C.UseOORColor) then
        icon:SetDesaturated(C.OORDesaturate)
        icon:SetVertexColor(Addon:GetRGBA("OORColor"))       
    elseif isUsable then
        icon:SetDesaturated(false)
        icon:SetVertexColor(1.0, 1.0, 1.0)
    elseif (notEnoughMana and C.UseOOMColor) then
        icon:SetDesaturated(C.OOMDesaturate)
        icon:SetVertexColor(Addon:GetRGBA("OOMColor"))
    elseif C.UseNoUseColor then
        icon:SetDesaturated(C.NoUseDesaturate)
        icon:SetVertexColor(Addon:GetRGBA("NoUseColor"))
    end
end

local function HoverHook(button)
    local frame = button:GetParent():GetParent()
    local fader = frame.fade
    if fader then
        Addon:BarsFadeAnim()
    end
end

local function Hook_Update(self)
    Addon:RefreshIconColor(self)
end
local function Hook_UpdateUsable(self, action, usable, noMana)
    Addon:RefreshIconColor(self)
end

local function Hook_UpdateButton(button)
    local pushedAtlas = T.PushedTextures[C.CurrentPushedTexture] or nil
    if pushedAtlas and pushedAtlas.atlas then
        button:SetPushedAtlas(pushedAtlas.atlas)
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
    end

    button.PushedTexture:SetDesaturated(C.DesaturatePushed)
    if C.UsePushedColor then
        button.PushedTexture:SetVertexColor(Addon:GetRGBA("PushedColor"))
    end

    --button.PushedTexture:SetDesaturated(true)
    --button.PushedTexture:SetVertexColor(r, g, b)

    local highlightAtlas = T.HighlightTextures[C.CurrentHighlightTexture] or nil
    if highlightAtlas and highlightAtlas.hide then
        button.HighlightTexture:Hide()
    else
        if highlightAtlas and highlightAtlas.atlas then
            button.HighlightTexture:SetAtlas(highlightAtlas.atlas)
            if highlightAtlas.point then
                button.HighlightTexture:ClearAllPoints()
                button.HighlightTexture:SetPoint(highlightAtlas.point, button, highlightAtlas.point)
            end
            if highlightAtlas.size then
                button.HighlightTexture:SetSize(highlightAtlas.size[1], highlightAtlas.size[2])
            end
            if highlightAtlas.coords then
                button.HighlightTexture:SetTexCoord(highlightAtlas.coords[1], highlightAtlas.coords[2], highlightAtlas.coords[3], highlightAtlas.coords[4])
            end
        end

        button.HighlightTexture:SetDesaturated(C.DesaturateHighlight)
        if C.UseHighlightColor then
            button.HighlightTexture:SetVertexColor(Addon:GetRGBA("HighlightColor"))
        end
    end

    if button.CheckedTexture then
        local checkedAtlas = T.CheckedTextures[C.CurrentCheckedTexture] or nil
        if checkedAtlas and checkedAtlas.hide then
            button.CheckedTexture:Hide()
        else
            if checkedAtlas and checkedAtlas.atlas then
                button.CheckedTexture:SetAtlas(checkedAtlas.atlas)
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
            end

            button.CheckedTexture:SetDesaturated(C.DesaturateChecked)
            if C.UseCheckedColor then
                button.CheckedTexture:SetVertexColor(Addon:GetRGBA("CheckedColor"))
            end
        end
    end
    
    if button.TextOverlayContainer then
        local mult = button:GetParent():GetScale()
        if mult < 1 then
            button.TextOverlayContainer.HotKey:SetScale(C.FontHotKey and mult + C.FontHotKeyScale or 1.0)
            button.TextOverlayContainer.Count:SetScale(C.FontStacks and mult + C.FontStacksScale or 1.0)
        end

        if shortHotKey then
            local hotKey = button.TextOverlayContainer.HotKey:GetText()

            if hotKey:match("Mouse Button") then
                local buttonNum = hotKey:match("Mouse Button (%d+)")
                if buttonNum then
                    button.TextOverlayContainer.HotKey:SetText("MB-" .. buttonNum)
                end
            elseif hotKey == "Middle Mouse" then
                button.TextOverlayContainer.HotKey:SetText("MMB")
            end
        end

    end
    local eventFrame = ActionBarActionEventsFrame
    if C.HideInterrupt then
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
    if C.HideCasting then
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_START")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_START")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_STOP")
    end
    if C.HideReticle then
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_RETICLE_CLEAR")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_RETICLE_TARGET")
        eventFrame:UnregisterEvent("UNIT_SPELLCAST_SENT")
    end
    if C.FadeBars then
        button:HookScript("OnEnter", HoverHook)
        button:HookScript("OnLeave", HoverHook)
    end

    hooksecurefunc(button, "Update", Hook_Update)
    hooksecurefunc(button, "UpdateUsable", Hook_UpdateUsable)
end

local function Hook_RangeCheckButton(slot, inRange, checksRange)
    
    local buttons = ActionBarButtonRangeCheckFrame.actions[slot]
    if buttons then
        for _, button in pairs(buttons) do
            Addon:RefreshIconColor(button)
        end
    end
end
local function Hook_UpdateCooldown(self)
    local actionType, actionID
    if self.action then
        actionType, actionID = GetActionInfo(self.action)
    end

    --[[ if actionID then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(actionID)
        if spellCooldownInfo then
            if spellCooldownInfo.activeCategory and spellCooldownInfo.activeCategory ~= Constants.SpellCooldownConsts.GLOBAL_RECOVERY_CATEGORY then
                self.icon:SetDesaturated(true)
            else
                self.icon:SetDesaturated(false)
            end

        end
    end ]]
    if self.cooldown and C.UseCooldownColor then
        self.cooldown:SetSwipeColor(Addon:GetRGBA("CooldownColor"))
        self.cooldown:SetSwipeTexture("Interface/HUD/UI-HUD-CoolDownManager-Icon-Swipe")
        self.cooldown:ClearAllPoints()
        self.cooldown:SetPoint("CENTER", self.icon, "CENTER")
        self.cooldown:SetSize(46,45)
    end
    
end

local function Hook_Assist(self, actionButton, shown)
    local highlightFrame = actionButton.AssistedCombatHighlightFrame
    if highlightFrame and highlightFrame:IsVisible() then
        if shown then
            Addon:UpdateAssistFlipbook(highlightFrame.Flipbook)
        end
    end
end

hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", Hook_UpdateFlipbook)
hooksecurefunc("ActionButton_UpdateCooldown", Hook_UpdateCooldown)

hooksecurefunc(AssistedCombatManager, "SetAssistedHighlightFrameShown", Hook_Assist)

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


local function ProcessEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeSavedVariables()
        
        for _, barName in pairs(bars) do
            local frame = _G[barName]
            if frame then
                table.insert(animBars, barName)
            end
        end

        for _, barName in pairs(Addon.BarsToHide) do
            Addon:HideBars(barName)
        end

        Addon:BarsFadeAnim()

        Addon.ClassColor = {PlayerUtil.GetClassColor():GetRGB()}

        local f = EnumerateFrames()

		while f do
			if f.OnLoad == ActionBarActionButtonMixin.OnLoad then
				Hook_UpdateButton(f)
			end

			f = EnumerateFrames(f)
		end

        hooksecurefunc(ActionBarActionButtonMixin, "OnLoad", Hook_UpdateButton)

        Addon:Welcome()
    end
    if event == "ACTION_RANGE_CHECK_UPDATE" then
        local slot, inRange, checksRange = ...
        if C.UseOORColor then
            Hook_RangeCheckButton(slot, inRange, checksRange)
        end
    end
    if event == "PLAYER_REGEN_DISABLED"
    or event == "PLAYER_REGEN_ENABLED"
    or event == "PLAYER_TARGET_CHANGED"
    or event == "UNIT_SPELLCAST_START"
    or event == "UNIT_SPELLCAST_STOP" then
        Addon:BarsFadeAnim()
    end
end

eventHandlerFrame = CreateFrame('Frame')
eventHandlerFrame:SetScript('OnEvent', ProcessEvent)
eventHandlerFrame:RegisterEvent('PLAYER_LOGIN')
eventHandlerFrame:RegisterEvent('ACTION_RANGE_CHECK_UPDATE')
eventHandlerFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
eventHandlerFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
eventHandlerFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
eventHandlerFrame:RegisterEvent('UNIT_SPELLCAST_START')
eventHandlerFrame:RegisterEvent('UNIT_SPELLCAST_STOP')
