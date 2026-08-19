local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

Addon.config.containers["CDMCustomFrameBarContainer"] = {
    title = L.CDMCustomFrameTitle,
    desc = L.CDMCustomFrameDesc,
    childs = {
        ["CDMCustomItemListFrame"] = {
            type        = "itemList",
            name        = "Item List",
        },
        ["CDMCustomFrameEditBox"] = {
            type            = "editbox",
            name            = L.CDMCustomFrameName,
            defaultText     = function()
                local frame = _G[HUI_BarsListMixin:GetFrameLebel()]
                if frame then
                    local frameName = frame:GetDisplayName()
                    return frameName
                end
            end,
            OnEnterPressed  = function(self)
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                local name = self:GetText()
                self.currentName = name
                if frame then
                    frame:SetDisplayName(name)
                    frame:SaveDisplayName(name)
                    EventRegistry:TriggerEvent("CDMCustomItemList.RenameFrame", frameName, name)
                end
                self:ClearFocus()
            end,
            OnEditFocusLost = function(self)
                self:SetText(self.currentName)
            end,
            OnEditFocusGained = function(self)
                self.currentName = self:GetText()
            end,
        },
        ["CDMCustomFrameDeleteButton"] = {
            type            = "button",
            name            = L.CDMCustomFrameDelete,
            buttonName      = L.Delete,
            OnClick         = function(self)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.DeleteFrame", frameLabel)
            end
        },
        ["CDMCustomFrameAddSpellByID"] = {
            type            = "editbox",
            name            = L.CDMCustomFrameAddSpellByID,
            defaultText     = "",
            numeric         = true,
            OnEnterPressed  = function(self)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local id = self:GetText()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddSpellByID", id, frameLabel)
                self:ClearFocus()
                self:SetText("")
            end,
        },
        ["CDMCustomFrameAddItemByID"] = {
            type            = "editbox",
            name            = L.CDMCustomFrameAddItemByID,
            defaultText     = "",
            numeric         = true,
            OnEnterPressed  = function(self)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local id = self:GetText()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemByID", id, frameLabel)
                self:ClearFocus()
                self:SetText("")
            end,
        },
        ["CDMCustomTrackTrink1"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot13,
            value           = "CDMCustomTrackTrink1",
            callback        = function(checked)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 13, frameLabel, checked)
            end
        },
        ["CDMCustomTrackTrink2"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot14,
            value           = "CDMCustomTrackTrink2",
            callback        = function(checked)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 14, frameLabel, checked)
            end
        },
        ["CDMCustomTrackWeapon1"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot16,
            value           = "CDMCustomTrackWeapon1",
            callback        = function(checked)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 16, frameLabel, checked)
            end
        },
        ["CDMCustomTrackWeapon2"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot17,
            value           = "CDMCustomTrackWeapon2",
            callback        = function(checked)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 17, frameLabel, checked)
            end
        },
        ["CDMCustomHideWhenEmpty"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameHideWhen0,
            value           = "CDMCustomHideEmpty",
            callback        = function(checked)
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end
        },
        ["CDMCustomAlphaWhenNotCD"] = {
            type            = "checkboxSlider",
            name            = L.CDMCustomFrameAlphaOnCD,
            checkboxValue   = "UseCDMCustomAlphaNoCD",
            sliderValue     = "CDMCustomAlphaNoCD",
            min             = 0,
            max             = 1,
            step            = 0.1,
            sliderName      = {top = L.Alpha},
            callback        = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
    }
}

Addon.config.containers["CDMCustomFrameBarGridContainer"] = {
    
}

Addon.config.containers["CDMCustomFrameBarFontContainer"] = {
    title = L.FontTitle,
    desc = L.FontDesc,
    childs = {
        ["CDMCustomFrameBarNameEnable"] = {
            type            = "checkbox",
            name            = L.EnableName,
            value           = "CustomFrameBarNameEnable",
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarNameFont"] = {
            type        = "dropdown",
            fontOption  = true,
            setting     = function() return Addon.Fonts end,
            name        = L.NameFont,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarNameFont", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarNameFont", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarNameSize"] = {
            type            = "checkboxSlider",
            name            = L.FontNameSize,
            checkboxValue   = "UseCustomFrameBarNameSize",
            sliderValue     = "CustomFrameBarNameSize",
            min             = 5,
            max             = 40,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarNameColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CustomFrameBarNameColor",
            checkboxValues  = {"UsCustomFrameBarNameColor"},
            alpha           = true,
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarNamePoint"] = {
            type        = "dropdown",
            setting     = {Addon.AttachPoints, Addon.AttachPoints},
            name        = L.AttachPoint,
            IsSelected  = {
                function(id) return id == Addon:GetValue("CustomFrameBarNamePoint", nil, true) end,
                function(id) return id == Addon:GetValue("CustomFrameBarNameRelativePoint", nil, true) end,
            },
            OnSelect    = {
                function(id) Addon:SaveSetting("CustomFrameBarNamePoint", id, true) end,
                function(id) Addon:SaveSetting("CustomFrameBarNameRelativePoint", id, true) end,
            },
            showNew     = false,
            OnEnter     = {
                false,
                false,
            },
            OnClose     = {
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
                end,
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
                end,
            },
        },
        ["CDMCustomFrameBarNameOffset"] = {
            type            = "checkboxSlider",
            name            = L.Offset,
            checkboxValue   = "UseCustomFrameBarNameOffset",
            sliderValue     = {"CustomFrameBarNameOffsetX", "CustomFrameBarNameOffsetY"},
            min             = -40,
            max             = 40,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarNameJustifyH"] = {
            type        = "dropdown",
            setting     = Addon.BarTextJustifyH,
            name        = L.JustifyH,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarNameJustifyH", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarNameJustifyH", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshName(frame, frameName)
            end,
        },

        ["CDMCustomFrameBarStacksEnable"] = {
            type            = "checkbox",
            name            = L.EnableStacks,
            value           = "CustomFrameBarStacksEnable",
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarStacksFont"] = {
            type        = "dropdown",
            fontOption  = true,
            setting     = function() return Addon.Fonts end,
            name        = L.StacksFont,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarStacksFont", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarStacksFont", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarStacksSize"] = {
            type            = "checkboxSlider",
            name            = L.FontStacksSize,
            checkboxValue   = "UseCustomFrameBarStacksSize",
            sliderValue     = "CustomFrameBarStacksSize",
            min             = 5,
            max             = 40,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarStacksColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CustomFrameBarStacksColor",
            checkboxValues  = {"UsCustomFrameBarStacksColor"},
            alpha           = true,
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarStacksPoint"] = {
            type        = "dropdown",
            setting     = {Addon.AttachPoints, Addon.AttachPoints},
            name        = L.AttachPoint,
            IsSelected  = {
                function(id) return id == Addon:GetValue("CustomFrameBarStacksPoint", nil, true) end,
                function(id) return id == Addon:GetValue("CustomFrameBarStacksRelativePoint", nil, true) end,
            },
            OnSelect    = {
                function(id) Addon:SaveSetting("CustomFrameBarStacksPoint", id, true) end,
                function(id) Addon:SaveSetting("CustomFrameBarStacksRelativePoint", id, true) end,
            },
            showNew     = false,
            OnEnter     = {
                false,
                false,
            },
            OnClose     = {
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
                end,
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
                end,
            },
        },
        ["CDMCustomFrameBarStacksOffset"] = {
            type            = "checkboxSlider",
            name            = L.Offset,
            checkboxValue   = "UseCustomFrameBarStacksOffset",
            sliderValue     = {"CustomFrameBarStacksOffsetX", "CustomFrameBarStacksOffsetY"},
            min             = -40,
            max             = 40,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarStacksJustifyH"] = {
            type        = "dropdown",
            setting     = Addon.BarTextJustifyH,
            name        = L.JustifyH,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarStacksJustifyH", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarStacksJustifyH", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshStacks(frame, frameName)
            end,
        },


        ["CDMCustomFrameBarTimeEnable"] = {
            type            = "checkbox",
            name            = L.EnableTimer,
            value           = "CustomFrameBarTimeEnable",
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarTimeFormat"] = {
            type        = "dropdown",
            setting     = Addon.AuraTimeFormat,
            name        = L.CastTimeFormat,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimeFormat", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarTimeFormat", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarTimeFont"] = {
            type        = "dropdown",
            fontOption  = true,
            setting     = function() return Addon.Fonts end,
            name        = L.TimerFont,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimeFont", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarTimeFont", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarTimeSize"] = {
            type            = "checkboxSlider",
            name            = L.FontTimerSize,
            checkboxValue   = "UseCustomFrameBarTimeSize",
            sliderValue     = "CustomFrameBarTimeSize",
            min             = 5,
            max             = 40,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarTimeColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CustomFrameBarTimeColor",
            checkboxValues  = {"UseCustomFrameBarTimeColor"},
            alpha           = true,
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarTimePoint"] = {
            type        = "dropdown",
            setting     = {Addon.AttachPoints, Addon.AttachPoints},
            name        = L.AttachPoint,
            IsSelected  = {
                function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimePoint", nil, true) end,
                function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimeRelativePoint", nil, true) end,
            },
            OnSelect    = {
                function(id) Addon:SaveSetting("CurrentCustomFrameBarTimePoint", id, true) end,
                function(id) Addon:SaveSetting("CurrentCustomFrameBarTimeRelativePoint", id, true) end,
            },
            showNew     = false,
            OnEnter     = {
                false,
                false,
            },
            OnClose     = {
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
                end,
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
                end,
            },
        },
        ["CDMCustomFrameBarTimeOffset"] = {
            type            = "checkboxSlider",
            name            = L.Offset,
            checkboxValue   = "UseCustomFrameBarTimeOffset",
            sliderValue     = {"CustomFrameBarTimeOffsetX", "CustomFrameBarTimeOffsetY"},
            min             = -40,
            max             = 40,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
        ["CDMCustomFrameBarTimeJustifyH"] = {
            type        = "dropdown",
            setting     = Addon.BarTextJustifyH,
            name        = L.JustifyH,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimeJustifyH", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarTimeJustifyH", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshDuration(frame, frameName)
            end,
        },
    }
}

Addon.config.containers["CDMCustomFrameBarIconOptionsContainer"] = {
    title = L.CastBarsIconOptionsTitle,
    desc = L.CastBarsIconOptionsDesc,
    childs = {
        ["CDMCustomFrameBarIconSize"] = {
            type            = "checkboxSlider",
            name            = L.IconSize,
            checkboxValue   = "UseCDMCustomFrameBarIconSize",
            sliderValue     = "CDMCustomFrameBarIconSize",
            min             = 10,
            max             = 80,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
        ["CDMCustomFrametBarIconPosition"] = {
            type        = "dropdown",
            setting     = Addon.CastingBarIconPosition,
            name        = L.CastBarIconPos,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCDMCustomFrametBarIconPosition", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
        ["CDMCustomFrameBarIconOffset"] = {
            type            = "checkboxSlider",
            name            = L.Offset,
            checkboxValue   = "UseCDMCustomFrameBarIconOffset",
            sliderValue     = {"CDMCustomFrameBarIconOffsetX", "CDMCustomFrameBarIconOffsetY"},
            min             = -40,
            max             = 40,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
        ["IconMaskTextureOptions"] = {
            type        = "dropdown",
            setting     = T.IconMaskTextures,
            name        = L.IconMaskTextureType,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentIconMaskTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentIconMaskTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
        ["MaskScale"] = {
            type            = "checkboxSlider",
            name            = L.IconMaskScale,
            checkboxValue   = "UseIconMaskScale",
            sliderValue     = "IconMaskScale",
            min             = 0.5,
            max             = 1.5,
            step            = 0.01,
            sliderName      = {top = L.Scale},
            callback        = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
        ["IconScale"] = {
            type            = "checkboxSlider",
            name            = L.IconScale,
            checkboxValue   = "UseIconScale",
            sliderValue     = "IconScale",
            min             = 0.5,
            max             = 1.5,
            step            = 0.01,
            sliderName      = {top = L.Scale},
            callback        = function()
                local frameLabel = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
    }

}