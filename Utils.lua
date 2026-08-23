local AddonName, Addon = ...

function Addon:DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = self:DeepCopy(v)
    end
    return copy
end

function Addon:GetFlipBook(...)
    local animations = {...}
    for _, animation in ipairs(animations) do
        if animation:GetObjectType() == "FlipBook" then
            animation:SetParentKey("FlipAnim")
            return animation
        end
    end
end

local T = Addon.Templates

function Addon:GetConfig(button)
    local config, configName
    local actionBar, barName

    if button then
        if button.parentName then
            barName = button.parentName
        else
            actionBar = button.bar or button:GetParent()
            barName = actionBar:GetName()
        end
        
        if barName then
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
        
    local startProc = region.ProcStartAnim.FlipAnim or Addon:GetFlipBook(region.ProcStartAnim:GetAnimations())
    
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

Addon:RegisterEvent("PLAYER_LOGIN", function()
    hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", Hook_UpdateFlipbook)
end, "Core")
