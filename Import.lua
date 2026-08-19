local AddonName, Addon = ...

local function RemapMedia(value)
    if type(value) == "string" then
        if value:find("^ABE_") then
            return "HUI_" .. value:sub(5)
        end
        return value
    elseif type(value) == "table" then
        for k, v in pairs(value) do
            value[k] = RemapMedia(v)
        end
    end
    return value
end

Addon.RemapMedia = RemapMedia

function Addon:ImportABDB(source)
    local db = self.db
    if not db or not source then return end

    if source.Profiles then
        db.Profiles = RemapMedia(self:DeepCopy(source.Profiles))
        db.Profiles.mapping = db.Profiles.mapping or {}
        db.Profiles.profilesList = db.Profiles.profilesList or {}
        db.Profiles.profilesOrder = db.Profiles.profilesOrder or {}
        self.P = db.Profiles
    end

    for key in pairs(self.Defaults) do
        if source[key] ~= nil then
            db[key] = RemapMedia(self:DeepCopy(source[key]))
        end
    end
end

function Addon:TryImport()
    local db = self.db
    if not db then return end

    if not db.__imported then
        db.__imported = true

        local P = db.Profiles
        if not (P and P.profilesList and next(P.profilesList)) then
            if _G.ABDB and type(_G.ABDB) == "table" then
                self:ImportABDB(_G.ABDB)
            end

            if _G.ABE_FAKE_AURAS and type(_G.ABE_FAKE_AURAS) == "table" then
                if not _G.HUI_FAKE_AURAS or not next(_G.HUI_FAKE_AURAS) then
                    _G.HUI_FAKE_AURAS = self:DeepCopy(_G.ABE_FAKE_AURAS)
                end
            end
        end
    end

    if db.Profiles then
        Addon.RemapMedia(db.Profiles)
    end
end
