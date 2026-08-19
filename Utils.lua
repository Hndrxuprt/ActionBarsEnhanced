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
