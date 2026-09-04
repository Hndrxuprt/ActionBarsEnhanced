local Addon = _G.HUI

HUI_CDMCustomPingMixin = CreateFromMixins()

local pendingPingableFrames = {}

local function FlushPendingPingableFrames()
    for frame in pairs(pendingPingableFrames) do
        pendingPingableFrames[frame] = nil
        frame:SetupPingable()
    end
end

Addon:RegisterEvent("PLAYER_REGEN_ENABLED", FlushPendingPingableFrames, "CooldownManagerCustomPing")

function HUI_CDMCustomPingMixin:IsPingEnabled()
    local frameName = self.huiPingFrameName or self.parentName
    return Addon:GetValue("CDMCustomPingEnabled", nil, frameName) and true or false
end

function HUI_CDMCustomPingMixin:GetIsPingable()
    return self:IsPingEnabled()
end

function HUI_CDMCustomPingMixin:GetAllowRadialWheel()
    return false
end

function HUI_CDMCustomPingMixin:SetupPingable()
    if self:GetAttribute("ping-receiver") then
        return
    end

    if InCombatLockdown() then
        pendingPingableFrames[self] = true
        return
    end

    self:SetAttribute("ping-receiver", true)
end

Mixin(HUI_CDMCustomItemMixin, HUI_CDMCustomPingMixin)

function HUI_CDMCustomItemMixin:GetTargetInfo()
    if self.slotID then
        local itemID = GetInventoryItemID("player", self.slotID)
        if itemID then
            return { itemID = itemID }
        end
    end

    if self.itemID then
        return { itemID = self.itemID }
    end

    if self.spellID then
        return { spellID = self.spellID }
    end
end

HUI_CDMCustomPingAuraMixin = CreateFromMixins(HUI_CDMCustomPingMixin)

function HUI_CDMCustomPingAuraMixin:GetTargetInfo()
    if self.huiPingSpellID then
        return { spellID = self.huiPingSpellID }
    end
end

function HUI_CDMCustomPingAuraMixin:ApplyPingable(spellID, frameName)
    self.huiPingSpellID = spellID
    self.huiPingFrameName = frameName

    self:SetupPingable()
    self:SetMouseMotionEnabled(self:IsPingEnabled())
end
