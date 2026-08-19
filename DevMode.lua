local AddonName, Addon = ...

function Addon:IsDevMode()
    local db = self.db
    return db and db.devMode == true
end

function Addon:SetDevMode(enabled)
    local db = self.db
    if not db then return end

    db.devMode = enabled and true or false
    print("|cff1df2a8HUI|r: dev mode " .. (db.devMode and "ON" or "OFF") .. ", /reload to apply")
end

function Addon:ToggleDevMode()
    self:SetDevMode(not self:IsDevMode())
end

local function ShouldProfile(name)
    return name:match("^HUI")
        or name:match("^OptionsCDM")
        or name == "CDMCustomDraggedItemMixin"
        or name == "ActionBarColorMixin"
end

function Addon:ApplyProfiler()
    if not self:IsDevMode() then return end

    local FP = _G.NumyFunctionProfiler
    if not FP or not FP.WrapModules then return end

    local count = 0
    for name, obj in pairs(_G) do
        if type(obj) == "table" and type(name) == "string" and ShouldProfile(name) then
            if not obj.GetObjectType then
                FP:WrapModules("HUI", name, obj, 1)
                count = count + 1
            end
        end
    end

    print("|cff1df2a8HUI|r: profiler wrapped " .. count .. " targets")
end

local function HandleHuiCommand(msg)
    local arg = strtrim(msg or ""):lower()
    if arg == "dev" then
        Addon:ToggleDevMode()
        return
    end
    HUIMixin.InitOptions()
end

local function HandleDevCommand(msg)
    local arg = strtrim(msg or ""):lower()
    if arg == "on" or arg == "1" or arg == "enable" then
        Addon:SetDevMode(true)
    elseif arg == "off" or arg == "0" or arg == "disable" then
        Addon:SetDevMode(false)
    else
        Addon:ToggleDevMode()
    end
end

RegisterNewSlashCommand(HandleHuiCommand, "HUI", "hui")
RegisterNewSlashCommand(HandleDevCommand, "huidev", "huidev")
