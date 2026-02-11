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
                local frame = _G[ABE_BarsListMixin:GetFrameLebel()]
                if frame then
                    local frameName = frame:GetDisplayName()
                    return frameName
                end
            end,
            OnEnterPressed  = function(self)
                local frameName = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.DeleteFrame", frameLabel)
            end
        },
        ["CDMCustomFrameAddSpellByID"] = {
            type            = "editbox",
            name            = L.CDMCustomFrameAddSpellByID,
            defaultText     = "",
            numeric         = true,
            OnEnterPressed  = function(self)
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 13, frameLabel, checked)
            end
        },
        ["CDMCustomTrackTrink2"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot14,
            value           = "CDMCustomTrackTrink2",
            callback        = function(checked)
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 14, frameLabel, checked)
            end
        },
        ["CDMCustomTrackWeapon1"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot16,
            value           = "CDMCustomTrackWeapon1",
            callback        = function(checked)
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 16, frameLabel, checked)
            end
        },
        ["CDMCustomTrackWeapon2"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameTrackSlot17,
            value           = "CDMCustomTrackWeapon2",
            callback        = function(checked)
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                EventRegistry:TriggerEvent("CDMCustomItemList.AddItemBySlot", 17, frameLabel, checked)
            end
        },
        ["CDMCustomHideWhenEmpty"] = {
            type            = "checkbox",
            name            = L.CDMCustomFrameHideWhen0,
            value           = "CDMCustomHideEmpty",
            callback        = function(checked)
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
    }
}

Addon.config.containers["CDMCustomFrameBarGridContainer"] = {
    
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
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
                local frameLabel = ABE_BarsListMixin:GetFrameLebel()
                local frame = _G[frameLabel]
                frame:RefreshLayout()
            end,
        },
    }

}