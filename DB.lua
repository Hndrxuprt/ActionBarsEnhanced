local AddonName, Addon = ...

HUIDB = HUIDB or {}

Addon.db = HUIDB
Addon.P = HUIDB.Profiles or {}
Addon.C = {}

function Addon:InitDB()
    HUIDB = HUIDB or {}
    HUIDB.PP = nil
    self.db = HUIDB
    self.P = HUIDB.Profiles or {}
    HUIDB.Profiles = self.P
    self.P.mapping = self.P.mapping or {}
    self.P.profilesList = self.P.profilesList or {}
    self.P.profilesOrder = self.P.profilesOrder or {}
end
