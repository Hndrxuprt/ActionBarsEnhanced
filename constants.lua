local AddonName, Addon = ...

Addon.BarsToHide = {
    "BagsBar",
    "MicroMenu",
}

Addon.Options = {}

Addon.Defaults = {
    CurrentLoopGlow = 2,
    DesaturateGlow = true,
    UseLoopGlowColor = true,
    LoopGlowColor = { r=0.2, g=0.7, b=1.0, a=1.0 },

    HideProc = true,
    CurrentProcGlow = 1,
    DesaturateProc = false,
    UseProcColor = false,
    ProcColor = { r=1.0, g=1.0, b=1.0, a=1.0 },

    CurrentAssistType = 2,
    DesaturateAssist = false,
    UseAssistGlowColor = false,
    AssistGlowColor = { r=1.0, g=1.0, b=1.0, a=1.0 },
    CurrentAssistAltType = 2,
    DesaturateAssistAlt = false,
    UseAssistAltColor = false,
    AssistAltColor = { r=1.0, g=1.0, b=1.0, a=1.0 },

    FadeBars = true,
    FadeBarsAlpha = 0.45,
    FadeInOnCombat = true,
    FadeInOnTarget = true,
    FadeInOnCasting = true,
    FadeInOnHover = true,

    CurrentPushedTexture = 2,
    DesaturatePushed = true,
    UsePushedColor = true,
    PushedColor = "CLASS_COLOR",

    CurrentHighlightTexture = 2,
    DesaturateHighlight = true,
    UseHighlightColor = true,
    HighlightColor = "CLASS_COLOR",

    CurrentCheckedTexture = 2,
    DesaturateChecked = true,
    UseCheckedColor = true,
    CheckedColor = "CLASS_COLOR",

    UseCooldownColor = true,
    CooldownColor = { r=0.0, g=0.0, b=0.0, a=0.65 },

    UseOORColor = true,
    OORDesaturate = true,
    OORColor = { r=0.64, g=0.15, b=0.15, a=1.0 },

    UseOOMColor = true,
    OOMDesaturate = true,
    OOMColor = { r=0.5, g=0.5, b=0.5, a=1.0 },

    UseNoUseColor = true,
    NoUseDesaturate = true,
    NoUseColor = { r=0.6, g=0.6, b=0.6, a=1.0 },

    HideBagsBar = true,
    HideMicroMenu = true,
    HideInterrupt = true,
    HideCasting = true,
    HideReticle = true,

    FontHotKey = true,
    FontHotKeyScale = 1.0,
    FontStacks = true,
    FontStacksScale = 1.0,
    FontName = true,
    FontNameScale = 1.0,

}

Addon.Templates = {
    LoopGlow = {
        {
            name = "Modern Blizzard Glow",
            atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook",
        },
        {
            name = "Modern Blizzard Assist Glow",
            texture = "Interface/addons/ActionBarsEnhanced/assets/flipbook2.tga",
        },
        {
            name = "Modern Blizzard Assist Rainbow Glow",
            texture = "Interface/addons/ActionBarsEnhanced/assets/flipbook_rainbow2.tga",
            rows = 6,
            columns = 10,
            frames = 60,
            duration = 0.9,
            frameW = 80,
            frameH = 80,
            scale = 1.05,
        },
        {
            name = "Classic Blizzard Glow",
            texture = "Interface\\SpellActivationOverlay\\IconAlertAnts",
            rows = 5,
            columns = 5,
            frames = 25,
            duration = 0.3,
            frameW = 48,
            frameH = 48,
            scale = 0.85,
        },
        {
            name = "GCD",
            atlas = "UI-CooldownManager-Alert-Flipbook",
            rows = 11,
            columns = 2,
            frames = 22,
            duration = 1.0,
            scale = 0.7,
        }, 
        {
            name = "GCD 2",
            texture = "Interface/addons/ActionBarsEnhanced/assets/GCD_2.tga",
            rows = 6,
            columns = 2,
            frames = 12,
            duration = 0.5,
            frameW = 47,
            frameH = 47,
            scale = 0.7,
        },
        {
            name = "Rogue CP Blue",
            atlas = "UF-RogueCP-Slash-Blue",
            rows = 3,
            columns = 6,
            frames = 18,
            duration = 0.7,
            scale = 1.3,
        },
        {
            name = "Rogue CP Red",
            atlas = "UF-RogueCP-Slash-Red",
            rows = 3,
            columns = 6,
            frames = 18,
            duration = 0.7,
            scale = 1.3,
        },
        {
            name = "Druid CP Red",
            atlas = "UF-DruidCP-Slash",
            rows = 3,
            columns = 8,
            frames = 24,
            duration = 0.7,
            scale = 1.3,
        },
        {
            name = "Chi Wind",
            atlas = "UF-Chi-WindFX",
            rows = 3,
            columns = 6,
            frames = 18,
            duration = 0.7,
            scale = 1.3,
        },
        {
            name = "Essence",
            atlas = "UF-Essence-Flipbook-FX-Circ",
            rows = 3,
            columns = 10,
            frames = 30,
            duration = 1.0,
            scale = 1.2,
        },
        {
            name = "Vigor",
            atlas = "dragonriding_sgvigor_burst_flipbook",
            rows = 4,
            columns = 4,
            frames = 16,
            duration = 1.0,
            scale = 1.2,
        },
        {
            name = "Vigor 2",
            atlas = "dragonriding_sgvigor_decor_flipbook_left",
            rows = 2,
            columns = 4,
            frames = 8,
            duration = 0.7,
            scale = 0.8,
        },
        {
            name = "FX",
            atlas = "groupfinder-eye-flipbook-foundfx",
            rows = 5,
            columns = 15,
            frames = 75,
            duration = 1.0,
            scale = 1.0,
        },
        {
            name = "Arrow",
            atlas = "Ping_Marker_FlipBook_OnMyWay",
            rows = 4,
            columns = 6,
            frames = 24,
            duration = 1.0,
            scale = 0.7,
        },
        {
            name = "Soul",
            atlas = "UF-SoulShards-Flipbook-Soul",
            rows = 3,
            columns = 7,
            frames = 21,
            duration = 1.2,
            scale = 0.9,
        },
        {
            name = "Frost",
            atlas = "perks-frost-FX",
            rows = 3,
            columns = 5,
            frames = 15,
            duration = 0.7,
            scale = 0.9,
        },

    },
    ProcGlow = {
        {
            name = "Modern Blizzard Proc",
            atlas = "UI-HUD-ActionBar-Proc-Start-Flipbook",
        },
        {
            name = "Modern Blizzard Blue Proc",
            atlas = "RotationHelper-ProcStartBlue-Flipbook-2x",
        },
        {
            name = "Classic Blizzard Proc",
            texture = "Interface/addons/ActionBarsEnhanced/assets/ClassicLike_Flipbook.tga",
            rows = 4,
            columns = 3,
            frames = 12,
            duration = 0.25,
            frameW = 80,
            frameH = 80,
            scale = 0.9,
        },
    },
    PushedTextures = {
        {
            name = "Default Blizzard",
            index = 1,
            atlas = "UI-HUD-ActionBar-IconFrame-Down",
        }, --1
        {
            name = "WowLabs 1",
            atlas = "wowlabs-spell-icon-frame-highlight",
            point = "CENTER",
            size = {52,52},
        }, --2
        {
            name = "WowLabs 2",
            atlas = "plunderstorm-actionbar-slot-border-swappable",
            point = "CENTER",
            size = {60,60},
        }, --3
        {
            name = "WowLabs 3",
            atlas = "wowlabs-ability-icon-frame",
            size = {47,47},
            coords = {0.94, 0, 0.94, 0},
            point = "TOPLEFT",
        }, --4
        {
            name = "Proc Alert",
            atlas = "UI-HUD-RotationHelper-ProcAltGlow",
            size = {48,48},
            point = "CENTER",
        }, --5
        {
            name = "Talents Border",
            atlas = "talents-node-choiceflyout-square-yellow",
            point = "CENTER",
            size = {43,43},
        }, --6
        {
            name = "Talents Border 2",
            atlas = "talents-node-choiceflyout-square-ghost",
            point = "CENTER",
            size = {48,48},
        }, --7
        {
            name = "Talents Border 3",
            atlas = "talents-node-square-ghost",
            point = "TOPLEFT",
            coords = {0.91, 0, 0.91, 0},
            size = {49,49},
        }, --8
        {
            name = "Transmog",
            atlas = "transmog-frame-pink",
            point = "CENTER",
            size = {48,48},
        }, --9
        {
            name = "Click cast",
            atlas = "ClickCast-Highlight-Binding",
            point = "CENTER",
            size = {45,45},
        }, --10
        {
            name = "Kyrian",
            atlas = "CovenantSanctum-Upgrade-Icon-Border-Kyrian",
            point = "TOPLEFT",
            coords = {0.96, 0, 0.96, 0},
            size = {46,46},
        }, --11
        {
            name = "Professions grey",
            atlas = "Professions-ChoiceReagent-Frame",
            point = "TOPLEFT",
            coords = {0.94, 0, 0.94, 0},
            size = {48,48},
        }, --12
        {
            name = "Professions gold",
            atlas = "Professions-Recrafting-Frame-Item",
            point = "TOPLEFT",
            coords = {0.94, 0, 0.94, 0},
            size = {48,48},
        }, --13
        {
            name = "Professions slot white",
            atlas = "professions-slot-frame-white",
            point = "CENTER",
            size = {45,45},
        }, --14
        {
            name = "Professions Gear Enchant",
            atlas = "GearEnchant_IconBorder",
            point = "CENTER",
            size = {48,48},
        }, --15
        {
            name = "Runecarving",
            atlas = "runecarving-icon-center-selected",
            point = "TOPLEFT",
            coords = {0.88, 0.10, 0.88, 0.10},
            size = {45,45},
        }, --16
        {
            name = "Runecarving 2",
            atlas = "runecarving-icon-reagent-border",
            point = "CENTER",
            size = {57,57},
        }, --17
        {
            name = "Spellbook",
            atlas = "spellbook-item-unassigned-glow",
            point = "TOPLEFT",
            coords = {0.92, 0.08, 0.92, 0.08},
            size = {45,45},
        }, --18
    },
    HighlightTextures = {
        {
            name = "Hide",
            hide = true,
        },
        {
            name = "Default Blizzard Highlight",
            atlas = "UI-HUD-ActionBar-IconFrame-Mouseover",
        },
        {
            name = "Bags Glow",
            atlas = "bags-glow-white",
            point = "CENTER",
            size = {41,41},
        },
        {
            name = "Item Upgrade",
            atlas = "ItemUpgrade_FX_SlotInnerGlow",
            point = "CENTER",
            size = {39,39},
        },
        {
            name = "Professions",
            atlas = "UI_bg_npcreward",
            size = {45,45},
        },
        {
            name = "Spellbook",
            atlas = "spellbook-item-petautocast-corners",
            size = {44,44},
        },
        {
            name = "Conduit",
            atlas = "Soulbinds_Tree_Conduit_Arrows",
            point = "TOPLEFT",
            size = {45,44},
        },
        {
            name = "Transmog",
            atlas = "transmog-frame-pink",
            point = "CENTER",
            size = {46,46},
        },
        {
            name = "Azerite",
            atlas = "AzeriteIconFrame",
            size = {44,44},
        },
        {
            name = "Mount Equipment",
            atlas = "mountequipment-slot-corners-open",
            point = "CENTER",
            size = {45,45},
        },
    },
    CheckedTextures = {
        {
            name = "Hide",
            hide = true,
        },
        {
            name = "Default Blizzard Highlight",
            atlas = "UI-HUD-ActionBar-IconFrame-Mouseover",
        },
        {
            name = "Bags Glow",
            atlas = "bags-glow-white",
            point = "CENTER",
            size = {41,41},
        },
        {
            name = "Item Upgrade",
            atlas = "ItemUpgrade_FX_SlotInnerGlow",
            point = "CENTER",
            size = {39,39},
        },
        {
            name = "Professions",
            atlas = "UI_bg_npcreward",
            size = {45,45},
        },
        {
            name = "Spellbook",
            atlas = "spellbook-item-petautocast-corners",
            size = {44,44},
        },
        {
            name = "Conduit",
            atlas = "Soulbinds_Tree_Conduit_Arrows",
            point = "TOPLEFT",
            size = {45,44},
        },
        {
            name = "Transmog",
            atlas = "transmog-frame-pink",
            point = "CENTER",
            size = {46,46},
        },
        {
            name = "Azerite",
            atlas = "AzeriteIconFrame",
            size = {44,44},
        },
        {
            name = "Mount Equipment",
            atlas = "mountequipment-slot-corners-open",
            point = "CENTER",
            size = {45,45},
        },
    },
}