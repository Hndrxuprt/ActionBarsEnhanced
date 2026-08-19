local AddonName, Addon = ...

local FramePicker = {}
Addon.FramePicker = FramePicker

local pickerFrame
local highlight
local callback
local hoveredFrame
local active = false
local armed = false

local function IsPickableFrame(frame)
    if not frame then return false end
    if not frame.IsShown then return false end
    if not frame:GetName() then return false end
    if not frame:IsShown() then return false end
    if frame == WorldFrame or frame == UIParent or frame == pickerFrame then return false end
    return true
end

local function ResolvePickableFrame(frame)
    while frame do
        if IsPickableFrame(frame) then
            return frame
        end
        frame = frame:GetParent()
    end
end

local function GetFocusFrame()
    if GetMouseFocus then
        return ResolvePickableFrame(GetMouseFocus())
    elseif GetMouseFoci then
        local foci = GetMouseFoci()
        if foci then
            for _, region in ipairs(foci) do
                local frame = ResolvePickableFrame(region)
                if frame then
                    return frame
                end
            end
        end
    end
end

function FramePicker:HighlightFrame(frame)
    if frame == hoveredFrame then return end
    hoveredFrame = frame
    if not frame then
        highlight:Hide()
        highlight.PulseAnim:Stop()
        return
    end
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 6)
    highlight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -6)
    highlight:Show()
    if not highlight.PulseAnim:IsPlaying() then
        highlight.PulseAnim:Play()
    end
end

function FramePicker:OnUpdate()
    if IsKeyDown("ESCAPE") then
        self:Stop()
        return
    end
    if IsMouseButtonDown("RightButton") then
        self:Stop()
        return
    end
    local down = IsMouseButtonDown("LeftButton")
    if not down then
        armed = true
    elseif armed and hoveredFrame then
        armed = false
        local name = hoveredFrame:GetName()
        local cb = callback
        self:Stop()
        if cb then cb(name) end
        return
    end
    self:HighlightFrame(GetFocusFrame())
end

function FramePicker:OnCombatStart()
    if active then
        self:Stop()
    end
end

function FramePicker:Start(cb)
    if active or InCombatLockdown() then return end
    active = true
    callback = cb
    armed = false
    if not pickerFrame then
        pickerFrame = CreateFrame("Frame", nil, UIParent)
        pickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        pickerFrame:SetScript("OnUpdate", function() FramePicker:OnUpdate() end)
        highlight = CreateFrame("Frame", nil, pickerFrame, "HUI_FramePickerHighlightTemplate")
    end
    if HUIOptionsFrame then HUIOptionsFrame:Hide() end
    if HUIOptionsAdvancedFrame then HUIOptionsAdvancedFrame:Hide() end
    Addon:RegisterEvent("PLAYER_REGEN_DISABLED", function() FramePicker:OnCombatStart() end, "FramePicker")
    EventRegistry:TriggerEvent("HUI.FramePicker.Enter")
    pickerFrame:Show()
end

function FramePicker:Stop()
    if not active then return end
    active = false
    callback = nil
    hoveredFrame = nil
    armed = false
    if highlight then
        highlight:Hide()
        highlight.PulseAnim:Stop()
    end
    if pickerFrame then pickerFrame:Hide() end
    Addon:UnregisterEvent("PLAYER_REGEN_DISABLED", "FramePicker")
    EventRegistry:TriggerEvent("HUI.FramePicker.Exit")
    if HUIOptionsFrame then HUIOptionsFrame:Show() end
    if HUIOptionsAdvancedFrame then HUIOptionsAdvancedFrame:Show() end
end
