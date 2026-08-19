local Addon = _G.HUI

local L = Addon.L
local T = Addon.Templates

local function Hook_UpdateShownState(self)
    if not self then return end
    
    HUI_CastingBarMixin.ProcessShieldBorder(self)
    
    HUI_CastingBarMixin.AdjustPosition(self)
end

Addon:RegisterEvent("PLAYER_LOGIN", function()
    if BossTargetFrameContainer and Addon:GetValue("CastBarEnable", nil, "BossTargetFrames") then
        for _, bossFrame in ipairs(BossTargetFrameContainer.BossTargetFrames) do
            if bossFrame.spellbar.UpdateShownState then
                hooksecurefunc(bossFrame.spellbar, "UpdateShownState", Hook_UpdateShownState)
            end
            HUI_CastingBarMixin.SetHooks(bossFrame.spellbar)
        end
    end
end, "CastingBar")