local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

Addon.Fonts = {}

Addon.config = {}

Addon.config.containers = {
    ---------------------------------
    -------------PRESETS-------------
    ---------------------------------
    PresetsOptionsContainer = {
        title = L.QuickPresets,
        desc = L.QuickPresetsDesc,
        new = true,
        childs = {}
    },
    
}