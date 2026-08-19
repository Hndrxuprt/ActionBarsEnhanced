local Addon = _G.HUI

local L = Addon.L
local T = Addon.Templates

local function GetStartOffset(castBar, pip)
    if not castBar or not pip then
        return
    end

    local barLeft = castBar:GetLeft()
    local barRight = castBar:GetRight()
    local pipStart = pip:GetCenter()

    local barWidth = barRight - barLeft

    local pipRel = pipStart - barLeft

    return pipRel
end


local function Hook_UpdateShownState(self)
    if not self then return end
    local frameName = self.boss and "BossTargetFrames" or self:GetName()
    --self:SetWidth(200)
    --self:SetHeight(20)

    HUI_CastingBarMixin.ProcessShieldBorder(self)
    HUI_CastingBarMixin.AdjustPosition(self)
end

Addon:RegisterEvent("PLAYER_LOGIN", function()
    local CastBarFrames = {
        "TargetFrameSpellBar",
        "FocusFrameSpellBar",
    }

    for _, framName in ipairs(CastBarFrames) do
        if Addon:GetValue("CastBarEnable", nil, framName) then
            local frame = _G[framName]
            if frame then
                if frame.UpdateShownState then
                    hooksecurefunc(frame, "UpdateShownState", Hook_UpdateShownState)
                end
                HUI_CastingBarMixin.SetHooks(frame)
            end
        end
    end
end, "CastingBar")