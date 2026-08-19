local AddonName, Addon = ...

local frame = CreateFrame("Frame")
Addon.EventFrame = frame

local handlers = {}

frame:SetScript("OnEvent", function(_, event, ...)
    local set = handlers[event]
    if set then
        for owner, funcs in pairs(set) do
            for i = 1, #funcs do
                funcs[i](...)
            end
        end
    end
end)

function Addon:RegisterEvent(event, func, owner)
    owner = owner or "Core"
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterEvent(event)
    end
    local set = handlers[event]
    if not set[owner] then
        set[owner] = {}
    end
    tinsert(set[owner], func)
end

function Addon:RegisterUnitEvent(event, unit, func, owner)
    owner = owner or "Core"
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterUnitEvent(event, unit)
    end
    local set = handlers[event]
    if not set[owner] then
        set[owner] = {}
    end
    tinsert(set[owner], func)
end

function Addon:UnregisterEvent(event, owner)
    owner = owner or "Core"
    local set = handlers[event]
    if not set then return end
    set[owner] = nil
    if not next(set) then
        handlers[event] = nil
        frame:UnregisterEvent(event)
    end
end

function Addon:UnregisterAllEvents(owner)
    owner = owner or "Core"
    for event, set in pairs(handlers) do
        if set[owner] then
            set[owner] = nil
            if not next(set) then
                handlers[event] = nil
                frame:UnregisterEvent(event)
            end
        end
    end
end
