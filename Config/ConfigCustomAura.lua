local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

local function RefreshAuraFrameSettings()
    local frameName = HUI_BarsListMixin:GetFrameLebel()
    local frame = frameName and _G[frameName]
    if frame and frame.RefreshSettings then
        frame:RefreshSettings()
    end
    if frame and frame.itemPool then
        HUI_CDMCustomFrameCustomized:RefreshCooldownFrame(frame, frameName, true)
    end
end

local function RefreshAuraFrameSkin()
    local frameName = HUI_BarsListMixin:GetFrameLebel()
    local frame = frameName and _G[frameName]
    if frame then
        HUI_CDMCustomFrameCustomized:RefreshSkin(frame, frameName)
    end
end

Addon.config.containers["CDMAuraFrameContainer"] = {
    title = L.CDMCustomFrameTitle,
    desc = L.CDMCustomFrameDesc,
    childs = {
        ["CDMCustomPing"] = {
            type            = "checkbox",
            name            = L.CDMCustomPingTitle,
            value           = "CDMCustomPingEnabled",
        },
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
    }
}

Addon.config.containers["CDMAuraFrameGridContainer"] = {
    title = L.CDMCustomFrameGridLayoutTitle,
    desc = L.CDMCustomFrameGridLayoutDesc,
    childs = {
        ["CDMCustomFrameItemSize"] = {
            type            = "checkboxSlider",
            name            = L.CDMCustomFrameElementSize,
            checkboxValue   = "UseCDMCustomItemSize",
            sliderValue     = "CDMCustomItemSize",
            min             = 20,
            max             = 80,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameIconPadding"] = {
            type            = "checkboxSlider",
            name            = L.IconPadding,
            checkboxValue   = "UseCDMCustomIconPadding",
            sliderValue     = "CDMCustomIconPadding",
            min             = -10,
            max             = 50,
            step            = 1,
            sliderName      = {top = L.Padding},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameStride"] = {
            type            = "checkboxSlider",
            name            = L.Stride,
            checkboxValue   = "UseCDMCustomStride",
            sliderValue     = "CDMCustomStride",
            min             = 1,
            max             = 20,
            step            = 1,
            sliderName      = {top = L.Columns},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameGridLayoutType"] = {
            type        = "dropdown",
            setting     = Addon.GridLayoutType,
            name        = L.GridLayoutType,
            IsSelected  = function(id) return id == Addon:GetValue("CDMGridLayoutType", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMGridLayoutType", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameHideWhenInactive"] = {
            type        = "dropdown",
            setting     = {L.AlwaysShow, L.ShowOnAura},
            name        = L.HideWhenInactive,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentHideWhenInactive", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentHideWhenInactive", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameVerticalGrowth"] = {
            type        = "dropdown",
            setting     = Addon.BarsVerticalGrow,
            name        = L.VerticalGrowth,
            IsSelected  = function(id) return id == Addon:GetValue("CDMVerticalGrowth", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMVerticalGrowth", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameHorizontalGrowth"] = {
            type        = "dropdown",
            setting     = Addon.BarsHorizontalGrow,
            name        = L.HorizontalGrowth,
            IsSelected  = function(id) return id == Addon:GetValue("CDMHorizontalGrowth", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMHorizontalGrowth", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameGridDirection"] = {
            type        = "dropdown",
            setting     = Addon.GridDirection,
            name        = L.GridDirection,
            IsSelected  = function(id) return id == Addon:GetValue("CDMCustomGridDirection", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMCustomGridDirection", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameStrata"] = {
            type        = "dropdown",
            setting     = Addon.FrameStratas,
            name        = L.FrameStrata,
            IsSelected  = function(id) return id == Addon:GetValue("CDMCustomFrameStrata", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMCustomFrameStrata", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSkin,
        },
        ["CDMCustomFrameLevel"] = {
            type            = "checkboxSlider",
            name            = L.FrameLevel,
            checkboxValue   = "UseCDMCustomFrameLevel",
            sliderValue     = "CDMCustomFrameLevel",
            min             = 0,
            max             = 100,
            step            = 1,
            sliderName      = {top = L.Level},
            callback        = RefreshAuraFrameSkin,
        },
    }
}

Addon.config.containers["CDMAuraFrameAttachContainer"] = {
    title = L.AttachTitle,
    desc = L.AttachDesc,
    childs = {
        ["CDMEnableAttach"] = {
            type            = "checkbox",
            name            = L.EnableAttach,
            value           = "CDMEnableAttach",
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshAnchors(frame, frameName)
            end,
        },
        ["CDMCustomFrameAttachTo"] = {
            type            = "editboxPicker",
            name            = L.CDMCustomFrameAttachFrameName,
            numLetters      = 100,
            pickerButtonName = L.FramePickerSelect,
            pickerOnClick   = function(self)
                Addon.FramePicker:Start(function(frameName)
                    local editBox = self:GetParent().EditBox
                    editBox:SetText(frameName)
                    editBox.currentName = frameName
                    Addon:SaveSetting("CurrentAttachFrame", frameName, true)
                    local customFrameName = HUI_BarsListMixin:GetFrameLebel()
                    local customFrame = _G[customFrameName]
                    HUI_CDMCustomFrameCustomized:RefreshAnchors(customFrame, customFrameName)
                end)
            end,
            defaultText     = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local name = Addon:GetValue("CurrentAttachFrame", nil, frameName)
                return name or ""
            end,
            OnEnterPressed  = function(self)
                local frameName = self:GetText()
                local frame = _G[frameName]
                if frame then
                    self.currentName = frameName

                    Addon:SaveSetting("CurrentAttachFrame", frameName, true)
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshAnchors(frame, frameName)
                else
                    Addon.Print("Cant find frame with name: |cffff0000", frameName)
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
        ["CDMCustomFrameAttachPoint"] = {
            type        = "dropdown",
            setting     = {Addon.AttachPoints, Addon.AttachPoints},
            name        = L.CDMCutomFrameAttachPoint,
            IsSelected  = {
                function(id) return id == Addon:GetValue("CurrentAttachPoint", nil, true) end,
                function(id) return id == Addon:GetValue("CurrentAttachRelativePoint", nil, true) end,
            },
            OnSelect    = {
                function(id) Addon:SaveSetting("CurrentAttachPoint", id, true) end,
                function(id) Addon:SaveSetting("CurrentAttachRelativePoint", id, true) end,
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
                    HUI_CDMCustomFrameCustomized:RefreshAnchors(frame, frameName)
                end,
                function()
                    local frameName = HUI_BarsListMixin:GetFrameLebel()
                    local frame = _G[frameName]
                    HUI_CDMCustomFrameCustomized:RefreshAnchors(frame, frameName)
                end,
            },
        },
        ["CDMCustomFrameAttachOffset"] = {
            type            = "checkboxSlider",
            name            = L.CDMCutomFrameAttachOffset,
            checkboxValue   = "UseAttachOffset",
            sliderValue     = {"AttachOffsetX", "AttachOffsetY"},
            min             = -100,
            max             = 100,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = function()
                local frameName = HUI_BarsListMixin:GetFrameLebel()
                local frame = _G[frameName]
                HUI_CDMCustomFrameCustomized:RefreshAnchors(frame, frameName)
            end,
        },
    }
}

Addon.config.containers["CDMAuraFrameIconContainer"] = {
    title = L.IconTitle,
    desc = L.IconDesc,
    childs = {
        ["CDMCustomFrameIconMaskTexture"] = {
            type        = "dropdown",
            setting     = T.IconMaskTextures,
            name        = L.IconMaskTextureType,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentIconMaskTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentIconMaskTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = function()
                HUIDropdownMixin:RefreshAllPreview()
                RefreshAuraFrameSettings()
            end,
        },
        ["CDMCustomFrameMaskScale"] = {
            type            = "checkboxSlider",
            name            = L.IconMaskScale,
            checkboxValue   = "UseIconMaskScale",
            sliderValue     = "IconMaskScale",
            min             = 0.5,
            max             = 1.5,
            step            = 0.01,
            sliderName      = {top = L.Scale},
            callback        = function()
                HUIDropdownMixin:RefreshAllPreview()
                RefreshAuraFrameSettings()
            end,
        },
        ["CDMCustomFrameIconScale"] = {
            type            = "checkboxSlider",
            name            = L.IconScale,
            checkboxValue   = "UseIconScale",
            sliderValue     = "IconScale",
            min             = 0.5,
            max             = 1.5,
            step            = 0.01,
            sliderName      = {top = L.Scale},
            callback        = function()
                HUIDropdownMixin:RefreshAllPreview()
                RefreshAuraFrameSettings()
            end,
        },
        ["PreviewIcon"] = {
            type = "preview",
        },
    }
}

Addon.config.containers["CDMAuraFrameCDContainer"] = {
    title = L.CDMCooldownTitle,
    desc = L.CDMCooldownDesc,
    childs = {
        ["CDMAuraFrameShowSwipe"] = {
            type            = "checkbox",
            name            = L.CDMAuraShowSwipe,
            value           = "CDMAuraShowSwipe",
            showNew         = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameSwipeTexture"] = {
            type        = "dropdown",
            setting     = T.SwipeTextures,
            name        = L.SwipeTextureType,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentSwipeTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentSwipeTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameSwipeSize"] = {
            type            = "checkboxSlider",
            name            = L.SwipeSize,
            checkboxValue   = "UseSwipeSize",
            sliderValue     = "SwipeSize",
            min             = 20,
            max             = 60,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameAuraSwipeColor"] = {
            type            = "colorSwatch",
            name            = L.CDMAuraSwipeColor,
            value           = "CooldownAuraColor",
            checkboxValues  = {"UseCooldownAuraColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameAuraTimerColor"] = {
            type            = "colorSwatch",
            name            = L.CDMAuraTimerColor,
            value           = "CDMAuraTimerColor",
            checkboxValues  = {"UseCDMAuraTimerColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameReverseSwipe"] = {
            type            = "checkbox",
            name            = L.CDMReverseSwipe,
            value           = "CDMReverseSwipe",
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameShowEdge"] = {
            type            = "checkbox",
            name            = L.CDMAuraShowEdge,
            value           = "CDMAuraShowEdge",
            showNew         = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameEdgeTexture"] = {
            type        = "dropdown",
            setting     = T.EdgeTextures,
            name        = L.EdgeTextureType,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentEdgeTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentEdgeTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameEdgeSize"] = {
            type            = "checkboxSlider",
            name            = L.EdgeSize,
            checkboxValue   = "UseEdgeSize",
            sliderValue     = "EdgeSize",
            min             = 0.5,
            max             = 2,
            step            = 0.1,
            sliderName      = {top = L.Scale},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameEdgeColor"] = {
            type            = "colorSwatch",
            name            = L.UseCustomColor,
            value           = "EdgeColor",
            checkboxValues  = {"UseEdgeColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameEdgeAlwaysShow"] = {
            type            = "checkbox",
            name            = L.EdgeAlwaysShow,
            value           = "EdgeAlwaysShow",
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameRemovePandemic"] = {
            type            = "checkbox",
            name            = L.CDMRemovePandemic,
            value           = "CDMRemovePandemic",
            callback        = RefreshAuraFrameSettings,
        },
    }
}

Addon.config.containers["CDMAuraFrameFontContainer"] = {
    title = L.FontTitle,
    desc = L.FontDesc,
    childs = {
        ["CDMAuraFrameShowTimer"] = {
            type            = "checkbox",
            name            = L.CDMAuraShowTimer,
            value           = "CDMAuraShowTimer",
            showNew         = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameCooldownFont"] = {
            type        = "dropdown",
            fontOption  = true,
            setting     = function() return Addon.Fonts end,
            name        = L.CooldownFont,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCooldownFont", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCooldownFont", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameCooldownFontSize"] = {
            type            = "checkboxSlider",
            name            = L.CooldownFontSize,
            checkboxValue   = "UseCooldownFontSize",
            sliderValue     = "CooldownFontSize",
            min             = 5,
            max             = 40,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameCooldownFontOffset"] = {
            type            = "checkboxSlider",
            name            = L.Offset,
            checkboxValue   = "UseCooldownFontOffset",
            sliderValue     = {"CooldownFontOffsetX", "CooldownFontOffsetY"},
            min             = -40,
            max             = 40,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameCooldownFontColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CooldownFontColor",
            checkboxValues  = {"UseCooldownFontColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameColorizedAuraFont"] = {
            type            = "checkbox",
            name            = L.ColorizedAuraFont,
            value           = "ColorizedAuraFont",
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameCooldownTimerFormat"] = {
            type        = "dropdown",
            setting     = Addon.CooldownTimerFormat,
            name        = L.CooldownTimerFormat,
            IsSelected  = function(id) return id == Addon:GetValue("CooldownTimerFormat", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CooldownTimerFormat", id, true) end,
            showNew     = true,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameCooldownMilliseconds"] = {
            type            = "checkboxSlider",
            name            = L.CooldownMilliseconds,
            showNew         = true,
            checkboxValue   = "UseCooldownMilliseconds",
            sliderValue     = "CooldownMillisecondsThreshold",
            min             = 1,
            max             = 60,
            step            = 1,
            sliderName      = {top = L.CooldownMillisecondsBelow},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameShowStacks"] = {
            type            = "checkbox",
            name            = L.CDMAuraShowStacks,
            value           = "CDMAuraShowStacks",
            showNew         = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameAlwaysShowStacks"] = {
            type            = "checkbox",
            name            = L.AlwaysShowStacks,
            value           = "AlwaysShowStacks",
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameStacksFont"] = {
            type        = "dropdown",
            fontOption  = true,
            setting     = function() return Addon.Fonts end,
            name        = L.StacksFont,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentStacksFont", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentStacksFont", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameStacksPoint"] = {
            type        = "dropdown",
            setting     = {Addon.AttachPoints, Addon.AttachPoints},
            name        = L.StacksAttachPoint,
            IsSelected  = {
                function(id) return id == Addon:GetValue("CurrentStacksPoint", nil, true) end,
                function(id) return id == Addon:GetValue("CurrentStacksRelativePoint", nil, true) end,
            },
            OnSelect    = {
                function(id) Addon:SaveSetting("CurrentStacksPoint", id, true) end,
                function(id) Addon:SaveSetting("CurrentStacksRelativePoint", id, true) end,
            },
            showNew     = false,
            OnEnter     = {
                false,
                false,
            },
            OnClose     = {
                RefreshAuraFrameSettings,
                RefreshAuraFrameSettings,
            },
        },
        ["CDMAuraFrameStacksOffset"] = {
            type            = "checkboxSlider",
            name            = L.StacksOffset,
            checkboxValue   = "UseStacksOffset",
            sliderValue     = {"StacksOffsetX", "StacksOffsetY"},
            min             = -40,
            max             = 40,
            step            = 1,
            sliderName      = {{top = L.OffsetX}, {top = L.OffsetY}},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameStacksFontSize"] = {
            type            = "checkboxSlider",
            name            = L.FontStacksSize,
            checkboxValue   = "UseStacksFontSize",
            sliderValue     = "StacksFontSize",
            min             = 5,
            max             = 40,
            step            = 1,
            sliderName      = {top = L.Size},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraFrameStacksFontColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "StacksColor",
            checkboxValues  = {"UseStacksColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
        },
    },
}

Addon.config.containers["CDMAuraBarGridContainer"] = {
    title = L.CDMCustomFrameGridLayoutTitle,
    desc = L.CDMCustomFrameGridLayoutDesc,
    childs = {
        ["CDMCustomFrameIconPadding"] = {
            type            = "checkboxSlider",
            name            = L.IconPadding,
            checkboxValue   = "UseCDMCustomIconPadding",
            sliderValue     = "CDMCustomIconPadding",
            min             = -10,
            max             = 50,
            step            = 1,
            sliderName      = {top = L.Padding},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameStride"] = {
            type            = "checkboxSlider",
            name            = L.Stride,
            checkboxValue   = "UseCDMCustomStride",
            sliderValue     = "CDMCustomStride",
            min             = 1,
            max             = 20,
            step            = 1,
            sliderName      = {top = L.Columns},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameGridLayoutType"] = {
            type        = "dropdown",
            setting     = Addon.GridLayoutType,
            name        = L.GridLayoutType,
            IsSelected  = function(id) return id == Addon:GetValue("CDMGridLayoutType", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMGridLayoutType", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameHideWhenInactive"] = {
            type        = "dropdown",
            setting     = {L.AlwaysShow, L.ShowOnAura},
            name        = L.HideWhenInactive,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentHideWhenInactive", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentHideWhenInactive", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameVerticalGrowth"] = {
            type        = "dropdown",
            setting     = Addon.BarsVerticalGrow,
            name        = L.VerticalGrowth,
            IsSelected  = function(id) return id == Addon:GetValue("CDMVerticalGrowth", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMVerticalGrowth", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameHorizontalGrowth"] = {
            type        = "dropdown",
            setting     = Addon.BarsHorizontalGrow,
            name        = L.HorizontalGrowth,
            IsSelected  = function(id) return id == Addon:GetValue("CDMHorizontalGrowth", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMHorizontalGrowth", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameGridDirection"] = {
            type        = "dropdown",
            setting     = Addon.GridDirection,
            name        = L.GridDirection,
            IsSelected  = function(id) return id == Addon:GetValue("CDMCustomGridDirection", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMCustomGridDirection", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameStrata"] = {
            type        = "dropdown",
            setting     = Addon.FrameStratas,
            name        = L.FrameStrata,
            IsSelected  = function(id) return id == Addon:GetValue("CDMCustomFrameStrata", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CDMCustomFrameStrata", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSkin,
        },
        ["CDMCustomFrameLevel"] = {
            type            = "checkboxSlider",
            name            = L.FrameLevel,
            checkboxValue   = "UseCDMCustomFrameLevel",
            sliderValue     = "CDMCustomFrameLevel",
            min             = 0,
            max             = 100,
            step            = 1,
            sliderName      = {top = L.Level},
            callback        = RefreshAuraFrameSkin,
        },
        ["CDMCustomFrameBarWidth"] = {
            type            = "checkboxSlider",
            name            = L.Width,
            checkboxValue   = "UseCDMCustomFrameBarWidth",
            sliderValue     = "CDMCustomFrameBarWidth",
            min             = 10,
            max             = 800,
            step            = 1,
            sliderName      = {top = L.Width},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarHeight"] = {
            type            = "checkboxSlider",
            name            = L.Height,
            checkboxValue   = "UseCDMCustomFrameBarHeight",
            sliderValue     = "CDMCustomFrameBarHeight",
            min             = 10,
            max             = 100,
            step            = 1,
            sliderName      = {top = L.Height},
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameStatusbarTexture"] = {
            type        = "dropdown",
            statusBar   = true,
            setting     = function() return T.StatusBarTextures end,
            name        = L.StatusBarTextures,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCDMCustomFrameStatusbarTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCDMCustomFrameStatusbarTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBackgroundTexture"] = {
            type        = "dropdown",
            statusBar   = true,
            setting     = function() return T.StatusBarTextures end,
            name        = L.StatusBarBGTextures,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCDMCustomFrameBackgroundTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCDMCustomFrameBackgroundTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBackgroundColor"] = {
            type            = "colorSwatch",
            name            = L.UseCustomBGColor,
            value           = "CDMCustomFrameBackgroundColor",
            checkboxValues  = {"UseCDMCustomFrameBackgroundColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFramePipTexture"] = {
            type        = "dropdown",
            setting     = function() return T.PipTextures end,
            name        = L.BarPipTexture,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCDMCustomFramePipTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCDMCustomFramePipTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFramePipSize"] = {
            type            = "checkboxSlider",
            name            = L.BarPipSize,
            checkboxValue   = "UseCDMCustomFramePipSize",
            sliderValue     = {"CDMCustomFramePipSizeX", "CDMCustomFramePipSizeY"},
            min             = 1,
            max             = 60,
            step            = 1,
            sliderName      = {{top = L.SizeX}, {top = L.SizeY}},
            callback        = RefreshAuraFrameSettings,
        },
    }
}

Addon.config.containers["CDMAuraBarIconOptionsContainer"] = {
    title = L.BarIconOptionsTitle,
    desc = L.BarIconOptionsDesc,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrametBarIconPosition"] = {
            type        = "dropdown",
            setting     = Addon.CastingBarIconPosition,
            name        = L.CastBarIconPos,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCDMCustomFrametBarIconPosition", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCDMCustomFrametBarIconPosition", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["IconMaskTextureOptions"] = {
            type        = "dropdown",
            setting     = T.IconMaskTextures,
            name        = L.IconMaskTextureType,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentIconMaskTexture", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentIconMaskTexture", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
    }
}

Addon.config.containers["CDMAuraBarFontContainer"] = {
    title = L.FontTitle,
    desc = L.FontDesc,
    childs = {
        ["CDMCustomFrameBarNameEnable"] = {
            type            = "checkbox",
            name            = L.EnableName,
            value           = "CustomFrameBarNameEnable",
            callback        = RefreshAuraFrameSettings,
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
            OnClose     = RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarNameColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CustomFrameBarNameColor",
            checkboxValues  = {"UsCustomFrameBarNameColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
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
                RefreshAuraFrameSettings,
                RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarNameJustifyH"] = {
            type        = "dropdown",
            setting     = Addon.BarTextJustifyH,
            name        = L.JustifyH,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarNameJustifyH", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarNameJustifyH", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },

        ["CDMCustomFrameBarStacksEnable"] = {
            type            = "checkbox",
            name            = L.EnableStacks,
            value           = "CustomFrameBarStacksEnable",
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMAuraBarAlwaysShowStacks"] = {
            type            = "checkbox",
            name            = L.AlwaysShowStacks,
            value           = "AlwaysShowStacks",
            callback        = RefreshAuraFrameSettings,
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
            OnClose     = RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarStacksColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CustomFrameBarStacksColor",
            checkboxValues  = {"UsCustomFrameBarStacksColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
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
                RefreshAuraFrameSettings,
                RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarStacksJustifyH"] = {
            type        = "dropdown",
            setting     = Addon.BarTextJustifyH,
            name        = L.JustifyH,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarStacksJustifyH", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarStacksJustifyH", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },

        ["CDMCustomFrameBarTimeEnable"] = {
            type            = "checkbox",
            name            = L.EnableTimer,
            value           = "CustomFrameBarTimeEnable",
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarTimeFormat"] = {
            type        = "dropdown",
            setting     = Addon.AuraTimeFormat,
            name        = L.CastTimeFormat,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimeFormat", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarTimeFormat", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarTimerFormat"] = {
            type        = "dropdown",
            setting     = Addon.CooldownTimerFormat,
            name        = L.CooldownTimerFormat,
            IsSelected  = function(id) return id == Addon:GetValue("CooldownTimerFormat", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CooldownTimerFormat", id, true) end,
            showNew     = true,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarTimeMilliseconds"] = {
            type            = "checkboxSlider",
            name            = L.CooldownMilliseconds,
            showNew         = true,
            checkboxValue   = "UseCooldownMilliseconds",
            sliderValue     = "CooldownMillisecondsThreshold",
            min             = 1,
            max             = 60,
            step            = 1,
            sliderName      = {top = L.CooldownMillisecondsBelow},
            callback        = RefreshAuraFrameSettings,
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
            OnClose     = RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarTimeColor"] = {
            type            = "colorSwatch",
            name            = L.FontColor,
            value           = "CustomFrameBarTimeColor",
            checkboxValues  = {"UseCustomFrameBarTimeColor"},
            alpha           = true,
            callback        = RefreshAuraFrameSettings,
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
                RefreshAuraFrameSettings,
                RefreshAuraFrameSettings,
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
            callback        = RefreshAuraFrameSettings,
        },
        ["CDMCustomFrameBarTimeJustifyH"] = {
            type        = "dropdown",
            setting     = Addon.BarTextJustifyH,
            name        = L.JustifyH,
            IsSelected  = function(id) return id == Addon:GetValue("CurrentCustomFrameBarTimeJustifyH", nil, true) end,
            OnSelect    = function(id) Addon:SaveSetting("CurrentCustomFrameBarTimeJustifyH", id, true) end,
            showNew     = false,
            OnEnter     = false,
            OnClose     = RefreshAuraFrameSettings,
        },
    }
}
