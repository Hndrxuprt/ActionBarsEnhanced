local AddonName, Addon = ...

local C = Addon.Options
local L = Addon.L
local T = Addon.Templates

ActionBarEnhancedMixin = {}
ActionBarEnhancedDropdownMixin = {}
ActionBarEnhancedCheckboxMixin = {}
ActionBarColorMixin = {}
ActionBarEnhancedButtonPreviewMixin = {}
ActionBarEnhancedContainerMixin = {}
ActionBarEnhancedOptionsContentMixin = {}
ActionBarEnhancedCheckboxSliderMixin = {}

function ActionBarEnhancedMixin:OnLoad()

end

function ActionBarEnhanced_UpdateScrollFrame(self, delta)
    local newValue = self:GetVerticalScroll() - (delta * 20);

    if (newValue < 0) then
        newValue = 0;
    elseif (newValue > self:GetVerticalScrollRange()) then
        newValue = self:GetVerticalScrollRange();
    end
    self:SetVerticalScroll(newValue);
end

function Addon:GetRGB(settingName)
    local color = C[settingName]

    if color == "CLASS_COLOR" then
        local r,g,b,a = PlayerUtil.GetClassColor():GetRGB()
        return r, g, b
    elseif type(color) == "table" then
        return color.r, color.g, color.b
    else
        return 1.0, 1.0, 1.0
    end
end
function Addon:GetRGBA(settingName)
    local color = C[settingName]

    if color == "CLASS_COLOR" then
        local r,g,b,a = PlayerUtil.GetClassColor():GetRGB()
        return r, g, b, a or 1.0
    elseif type(color) == "table" then
        return color.r, color.g, color.b, color.a
    else
        return 1.0, 1.0, 1.0, 1.0
    end
end

function Addon:SaveSetting(key, value)
    C[key] = value
    ABDB[key] = value
end

function Addon:HideBars(barName)
    local bar = _G[barName]
    if bar then
        if C["Hide"..barName] then
            bar:Hide()
        else
            bar:Show()
        end
    end
end

function ActionBarEnhancedMixin:InitOptions()
    if ActionBarEnhancedOptionsFrame then
        ActionBarEnhancedOptionsFrame:Show(not ActionBarEnhancedOptionsFrame:IsVisible())
        return
    end
    local optionsFrame = CreateFrame("Frame", "ActionBarEnhancedOptionsFrame", UIParent, "ActionBarEnhancedOptionsFrameTemplate")
    optionsFrame:SetParent(UIParent)
    optionsFrame:SetPoint("LEFT", UIParent, "LEFT", 10, -150)
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:EnableMouseWheel(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", function(self, button)
        self:StartMoving()
    end)
    optionsFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    optionsFrame:SetUserPlaced(true)
    optionsFrame.TitleContainer.TitleText:SetText("Options")
    --optionsFrame.Inset.Bg:SetAtlas("auctionhouse-background-auctions", true)
    optionsFrame.Inset.Bg:SetAtlas("auctionhouse-background-index", true)
    optionsFrame.Inset.Bg:SetHorizTile(false)
    optionsFrame.Inset.Bg:SetVertTile(false)
    optionsFrame.Inset.Bg:SetAllPoints()
    ActionBarEnhancedOptionsFramePortrait:SetTexture("interface/AddOns/ActionBarsEnhanced/assets/icon2.tga")
    

    local defaultSizes = {}
    function ActionBarEnhancedDropdownMixin:RefreshPreview(button)
        if not button then return end

        local pushedAtlas = T.PushedTextures[C.CurrentPushedTexture] or nil
        if pushedAtlas and pushedAtlas.atlas then
            button:SetPushedAtlas(pushedAtlas.atlas)
            if pushedAtlas.point then
                button.PushedTexture:ClearAllPoints()
                button.PushedTexture:SetPoint("CENTER", button, "CENTER")
            end
            if pushedAtlas.size then
                defaultSizes.PushedTexture = {button.PushedTexture:GetSize()}
                button.PushedTexture:SetSize(pushedAtlas.size[1], pushedAtlas.size[2])
            elseif defaultSizes.PushedTexture then
                button.PushedTexture:SetSize(defaultSizes.PushedTexture[1], defaultSizes.PushedTexture[2])
            end
        end
        button.PushedTexture:SetDesaturated(C.DesaturatePushed)
        if C.UsePushedColor then
            button.PushedTexture:SetVertexColor(Addon:GetRGBA("PushedColor"))
        end
        local highlightAtlas = T.HighlightTextures[C.CurrentHighlightTexture] or nil
        if highlightAtlas and highlightAtlas.hide then
            button.HighlightTexture:SetAtlas("")
            button.HighlightTexture:Hide()
        else
            button.HighlightTexture:Show()
            if highlightAtlas and highlightAtlas.atlas then
                button.HighlightTexture:SetAtlas(highlightAtlas.atlas)
                if highlightAtlas.point then
                    button.HighlightTexture:ClearAllPoints()
                    button.HighlightTexture:SetPoint("CENTER", button, "CENTER")
                end
                if highlightAtlas.size then
                    defaultSizes.HighlightTexture = {button.HighlightTexture:GetSize()}
                    button.HighlightTexture:SetSize(highlightAtlas.size[1], highlightAtlas.size[2])
                elseif defaultSizes.HighlightTexture then
                    button.HighlightTexture:SetSize(defaultSizes.HighlightTexture[1], defaultSizes.HighlightTexture[2])
                end
            end

            button.HighlightTexture:SetDesaturated(C.DesaturateHighlight)
            if C.UseHighlightColor then
                button.HighlightTexture:SetVertexColor(Addon:GetRGBA("HighlightColor"))
            end
        end
        if button.CheckedTexture then
            local checkedAtlas = T.CheckedTextures[C.CurrentCheckedTexture] or nil
            if checkedAtlas and checkedAtlas.hide then
                button.CheckedTexture:SetAtlas("")
            else
                if checkedAtlas and checkedAtlas.atlas then
                    button.CheckedTexture:SetAtlas(checkedAtlas.atlas)
                    if checkedAtlas.point then
                        button.CheckedTexture:ClearAllPoints()
                        button.CheckedTexture:SetPoint("CENTER", button, "CENTER")
                    end
                    if checkedAtlas.size then
                        defaultSizes.CheckedTexture = {button.CheckedTexture:GetSize()}
                        button.CheckedTexture:SetSize(checkedAtlas.size[1], checkedAtlas.size[2])
                    elseif defaultSizes.CheckedTexture then
                        button.CheckedTexture:SetSize(defaultSizes.CheckedTexture[1], defaultSizes.CheckedTexture[2])
                    end
                end

                button.CheckedTexture:SetDesaturated(C.DesaturateChecked)
                if C.UseCheckedColor then
                    button.CheckedTexture:SetVertexColor(Addon:GetRGBA("CheckedColor"))
                end
            end
        end
    end

    function ActionBarEnhancedDropdownMixin:SetupDropdown(frame, setting, name, IsSelected, OnSelect)
        local menuGenerator = function(_, rootDescription)
            rootDescription:CreateTitle(name)
            
            for i = 1, #setting do
                local categoryID = i
                local categoryName = setting[i].name
                rootDescription:CreateRadio(categoryName, IsSelected, OnSelect, categoryID)
            end
        end
        frame.Text:SetText(name)
        frame.Control.Dropdown:SetupMenu(menuGenerator)
        frame.Control.Dropdown:SetWidth(300)
        frame.Control.IncrementButton:Hide()
        frame.Control.DecrementButton:Hide()
    end

    function ActionBarEnhancedDropdownMixin:SetupCheckbox(checkboxFrame, name, value, callback)
        checkboxFrame.Text:SetText(name)
        checkboxFrame.Checkbox:SetChecked(C[value])
        checkboxFrame.Checkbox:SetScript("OnClick",
            function()
                Addon:SaveSetting(value, not C[value])
                if callback and type(callback) == "function" then
                    callback()
                end
            end
        )
    end

    function ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(checkboxFrame, name, checkboxValue, sliderValue, min, max, step, sliderName, callback)
        checkboxFrame.Text:SetText(name)
        local options = Settings.CreateSliderOptions(min or 0, max or 1, step or 0.1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Top, function(value) return sliderName or "" end);
        checkboxFrame.SliderWithSteppers:Init(C[sliderValue], options.minValue, options.maxValue, options.steps, options.formatters)
        checkboxFrame.SliderWithSteppers:RegisterCallback("OnValueChanged",
            function(self, value)
                Addon:SaveSetting(sliderValue, value)
                if callback and type(callback) == "function" then
                    callback()
                end
            end,
            checkboxFrame.SliderWithSteppers
        )
        checkboxFrame.SliderWithSteppers:SetEnabled(C[checkboxValue])
        checkboxFrame.Checkbox:SetChecked(C[checkboxValue])
        checkboxFrame.Checkbox:SetScript("OnClick",
            function()
                Addon:SaveSetting(checkboxValue, not C[checkboxValue])
                checkboxFrame.SliderWithSteppers:SetEnabled(C[checkboxValue])
            end
        )
    end

    function ActionBarEnhancedDropdownMixin:SetupColorSwatch(frame, name, value, checkboxValues, alpha)
        frame.Text:SetText(name)
        if checkboxValues then
            for k, checkValue in pairs(checkboxValues) do
                local frameName = "Checkbox"..k
                if k == 2 then
                    frame[frameName].text:SetText(L.Desaturate)
                end
                frame[frameName]:Show()
                frame[frameName]:SetChecked(C[checkValue])
                frame[frameName]:SetScript("OnClick",
                    function()
                        Addon:SaveSetting(checkValue, not C[checkValue])
                    end
                )
            end
        end

        frame.ColorSwatch.Color:SetVertexColor(Addon:GetRGBA(value))
        
        frame.ColorSwatch:SetScript("OnClick", function(button, buttonName, down)
            self:OpenColorPicker(frame, value, alpha)
        end)
    end

    function ActionBarEnhancedDropdownMixin:OpenColorPicker(frame, value, alpha)

        local info = UIDropDownMenu_CreateInfo()

        info.r, info.g, info.b, info.opacity = Addon:GetRGBA(value)

        info.hasOpacity = alpha

        if ColorPickerFrame then
            if not ColorPickerFrame.classButton then
                local button = CreateFrame("Button", nil, ColorPickerFrame, "UIPanelButtonTemplate")
                button:SetPoint("RIGHT", -20, 0)
                button:SetSize(90, 25)
                button:SetText("Class")
                button:Show()
                button:SetScript("OnClick", function()
                    info.r, info.g, info.b = PlayerUtil.GetClassColor():GetRGB()
                    info.a = 1.0
                    ColorPickerFrame:SetupColorPickerAndShow(info)
                end)
                ColorPickerFrame.classButton = button
            end
        end

        info.swatchFunc = function ()
            local r,g,b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            frame.ColorSwatch.Color:SetVertexColor(r,g,b)
            Addon:SaveSetting(value, { r=r, g=g, b=b, a=a })
        end

        info.cancelFunc = function ()
            local r,g,b,a = ColorPickerFrame:GetPreviousValues()
            frame.ColorSwatch.Color:SetVertexColor(r,g,b)

            Addon:SaveSetting(value, { r=r, g=g, b=b, a=a })
        end

        ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    ---------------------------------------------
    -----------------GLOW OPTIONS----------------
    ---------------------------------------------
    optionsFrame.ScrollFrame.ScrollChild.GlowOptionsContainer.Title:SetText(L.GlowTypeTitle)
    optionsFrame.ScrollFrame.ScrollChild.GlowOptionsContainer.Desc:SetText(L.GlowTypeDesc)
    ActionBarEnhancedDropdownMixin:SetupDropdown(
        optionsFrame.ScrollFrame.ScrollChild.GlowOptionsContainer.GlowOptions,
        T.LoopGlow,
        L.GlowType,
        function(id) return id == C.CurrentLoopGlow end,
        function(id)
            Addon:SaveSetting("CurrentLoopGlow", id)
        end
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        optionsFrame.ScrollFrame.ScrollChild.GlowOptionsContainer.CustomColorGlow,
        L.UseCustomColor,
        "LoopGlowColor",
        {"UseLoopGlowColor", "DesaturateGlow"}
    )

    ---------------------------------------------
    -----------------PROC OPTIONS----------------
    ---------------------------------------------
    optionsFrame.ScrollFrame.ScrollChild.ProcOptionsContainer.Title:SetText(L.ProcStartTitle)
    optionsFrame.ScrollFrame.ScrollChild.ProcOptionsContainer.Desc:SetText(L.ProcStartDesc)
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        optionsFrame.ScrollFrame.ScrollChild.ProcOptionsContainer.HideProc,
        L.HideProcAnim,
        "HideProc"
    )
    ActionBarEnhancedDropdownMixin:SetupDropdown(
        optionsFrame.ScrollFrame.ScrollChild.ProcOptionsContainer.ProcOptions,
        T.ProcGlow,
        L.StartProcType,
        function(id) return id == C.CurrentProcGlow end,
        function(id) 
            Addon:SaveSetting("CurrentProcGlow", id)
        end
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        optionsFrame.ScrollFrame.ScrollChild.ProcOptionsContainer.CustomColorProc,
        L.UseCustomColor,
        "ProcColor",
        {"UseProcColor", "DesaturateProc"}
    )

    ---------------------------------------------
    -----------------FADE OPTIONS----------------
    ---------------------------------------------
    optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.Title:SetText(L.FadeTitle)
    optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.Desc:SetText(L.FadeDesc)

    ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(
        optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.FadeOutBars,
        L.FadeOutBars,
        "FadeBars",
        "FadeBarsAlpha",
        0, 1, 0.1, "Fade Alpha"
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.FadeInOnCombat,
        L.FadeInOnCombat,
        "FadeInOnCombat"
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.FadeInOnTarget,
        L.FadeInOnTarget,
        "FadeInOnTarget"
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.FadeInOnCasting,
        L.FadeInOnCasting,
        "FadeInOnCasting"
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        optionsFrame.ScrollFrame.ScrollChild.FadeOptionsContainer.FadeInOnHover,
        L.FadeInOnHover,
        "FadeInOnHover"
    )


    ---------------------------------------------

    local pushedContainer = optionsFrame.ScrollFrame.ScrollChild.PushedOptionsContainer
    local highlightContainer = optionsFrame.ScrollFrame.ScrollChild.HighlightOptionsContainer
    local checkedContainer = optionsFrame.ScrollFrame.ScrollChild.CheckedOptionsContainer
    local hideContainer = optionsFrame.ScrollFrame.ScrollChild.HideFramesOptionsContainer
    local fontContainer = optionsFrame.ScrollFrame.ScrollChild.FontOptionsContainer

    ---------------------------------------------
    ------------PUSHED TEXTURE OPTIONS-----------
    ---------------------------------------------
    pushedContainer.Title:SetText(L.PushedTitle)
    pushedContainer.Desc:SetText(L.PushedDesc)
    ActionBarEnhancedDropdownMixin:SetupDropdown(
        pushedContainer.PushedTextureOptions,
        T.PushedTextures,
        L.PushedTextureType,
        function(id) return id == C.CurrentPushedTexture end,
        function(id)
            Addon:SaveSetting("CurrentPushedTexture", id)
            ActionBarEnhancedDropdownMixin:RefreshPreview(pushedContainer.PreviewPushed)
            ActionBarEnhancedDropdownMixin:RefreshPreview(highlightContainer.PreviewHighlight)
            ActionBarEnhancedDropdownMixin:RefreshPreview(checkedContainer.PreviewChecked)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewInterrupt)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewCasting)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewReticle)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont05)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont075)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont1)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont15)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont2)
        end
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        pushedContainer.CustomColorPushed,
        L.UseCustomColor,
        "PushedColor",
        {"UsePushedColor", "DesaturatePushed"}
    )
    pushedContainer.PreviewPushed.icon:SetTexture("interface/icons/ability_warrior_revenge.blp")
    ---------------------------------------------
    ----------HIGHLIGHT TEXTURE OPTIONS----------
    ---------------------------------------------
    highlightContainer.Title:SetText(L.HighlightTitle)
    highlightContainer.Desc:SetText(L.HighlightDesc)
    ActionBarEnhancedDropdownMixin:SetupDropdown(
        highlightContainer.HighlightTextureOptions,
        T.HighlightTextures,
        L.HighliteTextureType,
        function(id) return id == C.CurrentHighlightTexture end,
        function(id)
            Addon:SaveSetting("CurrentHighlightTexture", id)
            ActionBarEnhancedDropdownMixin:RefreshPreview(pushedContainer.PreviewPushed)
            ActionBarEnhancedDropdownMixin:RefreshPreview(highlightContainer.PreviewHighlight)
            ActionBarEnhancedDropdownMixin:RefreshPreview(checkedContainer.PreviewChecked)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewInterrupt)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewCasting)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewReticle)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont05)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont075)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont1)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont15)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont2)
        end
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        highlightContainer.CustomColorHighlight,
        L.UseCustomColor,
        "HighlightColor",
        {"UseHighlightColor", "DesaturateHighlight"},
        true
    )
    highlightContainer.PreviewHighlight.icon:SetTexture("interface/icons/ability_creature_felsunder.blp")
    ---------------------------------------------
    -----------CHECKED TEXTURE OPTIONS-----------
    ---------------------------------------------
    checkedContainer.Title:SetText(L.CheckedTitle)
    checkedContainer.Desc:SetText(L.CheckedDesc)
    ActionBarEnhancedDropdownMixin:SetupDropdown(
        checkedContainer.CheckedTextureOptions,
        T.CheckedTextures,
        L.CheckedTextureType,
        function(id) return id == C.CurrentCheckedTexture end,
        function(id)
            Addon:SaveSetting("CurrentCheckedTexture", id)
            ActionBarEnhancedDropdownMixin:RefreshPreview(pushedContainer.PreviewPushed)
            ActionBarEnhancedDropdownMixin:RefreshPreview(highlightContainer.PreviewHighlight)
            ActionBarEnhancedDropdownMixin:RefreshPreview(checkedContainer.PreviewChecked)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewInterrupt)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewCasting)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewReticle)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont05)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont075)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont1)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont15)
            ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewFont2)
        end
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        checkedContainer.CustomColorChecked,
        L.UseCustomColor,
        "CheckedColor",
        {"UseCheckedColor","DesaturateChecked"},
        true
    )
    checkedContainer.PreviewChecked.icon:SetTexture("interface/icons/spell_shadow_shadowbolt.blp")
    ---------------------------------------------
    ------------COOLDOWN SWIPE OPTIONS-----------
    ---------------------------------------------
    optionsFrame.ScrollFrame.ScrollChild.ColorOverrideOptionsContainer.Title:SetText(L.ColorOverrideTitle)
    optionsFrame.ScrollFrame.ScrollChild.ColorOverrideOptionsContainer.Desc:SetText(L.ColorOverrideDesc)
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        optionsFrame.ScrollFrame.ScrollChild.ColorOverrideOptionsContainer.CustomColorCooldown,
        L.CustomColorCooldownSwipe,
        "CooldownColor",
        {"UseCooldownColor"},
        true
    )

    ---------------------------------------------
    -------------SPELL USABLE OPTIONS------------
    ---------------------------------------------
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        optionsFrame.ScrollFrame.ScrollChild.ColorOverrideOptionsContainer.CustomColorOOR,
        L.CustomColorOOR,
        "OORColor",
        {"UseOORColor", "OORDesaturate"}
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        optionsFrame.ScrollFrame.ScrollChild.ColorOverrideOptionsContainer.CustomColorOOM,
        L.CustomColorOOM,
        "OOMColor",
        {"UseOOMColor", "OOMDesaturate"}
    )
    ActionBarEnhancedDropdownMixin:SetupColorSwatch(
        optionsFrame.ScrollFrame.ScrollChild.ColorOverrideOptionsContainer.CustomColorNotUsable,
        L.CustomColorNoUse,
        "NoUseColor",
        {"UseNoUseColor", "NoUseDesaturate"}
    )

    ---------------------------------------------
    --------------HIDE FRAMES OPTIONS------------
    ---------------------------------------------
    hideContainer.Title:SetText(L.HideFrameTitle)
    hideContainer.Desc:SetText(L.HideFrameDesc)
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        hideContainer.HideBagBars,
        L.HideBagsBar,
        "HideBagsBar",
        function() Addon:HideBars("BagsBar") end
        
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        hideContainer.HideMicroMenu,
        L.HideMicroMenuBar,
        "HideMicroMenu",
        function() Addon:HideBars("MicroMenu") end
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        hideContainer.HideInterrupt,
        L.HideInterrupt,
        "HideInterrupt"
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        hideContainer.HideCasting,
        L.HideCasting,
        "HideCasting"
    )
    ActionBarEnhancedDropdownMixin:SetupCheckbox(
        hideContainer.HideReticle,
        L.HideReticle,
        "HideReticle"
    )

    hideContainer.PreviewInterrupt.icon:SetTexture("interface/icons/spell_frost_icestorm.blp")
    hideContainer.PreviewInterrupt.InterruptDisplay:Show()
    hideContainer.PreviewInterrupt.InterruptDisplay.Base.AnimIn:SetLooping("REPEAT")
    hideContainer.PreviewInterrupt.InterruptDisplay.Highlight.AnimIn:SetLooping("REPEAT")
    hideContainer.PreviewInterrupt.InterruptDisplay.Base.AnimIn:Play()
    hideContainer.PreviewInterrupt.InterruptDisplay.Highlight.AnimIn:Play()
    hideContainer.PreviewInterrupt.Title.TitleText:SetText("Interrupt")

    hideContainer.PreviewCasting.icon:SetTexture("interface/icons/ability_evoker_firebreath.blp")
    hideContainer.PreviewCasting.SpellCastAnimFrame:Show()
    hideContainer.PreviewCasting.SpellCastAnimFrame.Fill.CastingAnim:SetLooping("REPEAT")
    hideContainer.PreviewCasting.SpellCastAnimFrame.EndBurst.FinishCastAnim:SetLooping("REPEAT")
    hideContainer.PreviewCasting.SpellCastAnimFrame.Fill.CastingAnim:Play()
    hideContainer.PreviewCasting.SpellCastAnimFrame.EndBurst.FinishCastAnim:Play()
    hideContainer.PreviewCasting.Title.TitleText:SetText("Casting")

    hideContainer.PreviewReticle.icon:SetTexture("interface/icons/inv_misc_herb_talandrasrose.blp")
    hideContainer.PreviewReticle.TargetReticleAnimFrame:Show()
    hideContainer.PreviewReticle.TargetReticleAnimFrame.HighlightAnim:SetLooping("REPEAT")
    hideContainer.PreviewReticle.TargetReticleAnimFrame.HighlightAnim:Play()
    hideContainer.PreviewReticle.Title.TitleText:SetText("Reticle")

    ---------------------------------------------
    -----------------FONT OPTIONS----------------
    ---------------------------------------------
    fontContainer.Title:SetText(L.FontTitle)
    fontContainer.Desc:SetText(L.FontDesc)

    ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(
        fontContainer.HotkeyScale,
        L.FontHotKeyScale,
        "FontHotKey",
        "FontHotKeyScale",
        0, 2, 0.1, "Font Scale",
        function()
            local HotKey05 = fontContainer.PreviewFont05.TextOverlayContainer.HotKey
            HotKey05:SetScale(fontContainer.PreviewFont05:GetScale() + C.FontHotKeyScale)
            local HotKey075 = fontContainer.PreviewFont075.TextOverlayContainer.HotKey
            HotKey075:SetScale(fontContainer.PreviewFont075:GetScale() + C.FontHotKeyScale)
        end
    )
    ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(
        fontContainer.StacksScale,
        L.FontStacksScale,
        "FontStacks",
        "FontStacksScale",
        0, 2, 0.1, "Font Scale",
        function()
            local Count05 = fontContainer.PreviewFont05.TextOverlayContainer.Count
            Count05:SetScale(fontContainer.PreviewFont05:GetScale() + C.FontStacksScale)
            local Count075 = fontContainer.PreviewFont075.TextOverlayContainer.Count
            Count075:SetScale(fontContainer.PreviewFont075:GetScale() + C.FontStacksScale)
        end        
    )
    ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(
        fontContainer.NameScale,
        L.FontNameScale,
        "FontName",
        "FontNameScale",
        0, 2, 0.1, "Font Scale"
    )

    fontContainer.PreviewFont05.icon:SetTexture("interface/icons/ability_warrior_punishingblow.blp")
    fontContainer.PreviewFont075.icon:SetTexture("interface/icons/spell_holy_righteousfury.blp")
    fontContainer.PreviewFont1.icon:SetTexture("interface/icons/ability_monk_tigerpalm.blp")
    fontContainer.PreviewFont15.icon:SetTexture("interface/icons/ability_druid_ferociousbite.blp")
    fontContainer.PreviewFont2.icon:SetTexture("interface/icons/ability_deathknight_remorselesswinters2.blp")

    fontContainer.PreviewFont05.TextOverlayContainer.HotKey:SetText("1")
    fontContainer.PreviewFont075.TextOverlayContainer.HotKey:SetText("2")
    fontContainer.PreviewFont1.TextOverlayContainer.HotKey:SetText("3")
    fontContainer.PreviewFont15.TextOverlayContainer.HotKey:SetText("4")
    fontContainer.PreviewFont2.TextOverlayContainer.HotKey:SetText("4")

    fontContainer.PreviewFont05.TextOverlayContainer.Count:SetText("99")
    fontContainer.PreviewFont075.TextOverlayContainer.Count:SetText("99")
    fontContainer.PreviewFont1.TextOverlayContainer.Count:SetText("99")
    fontContainer.PreviewFont15.TextOverlayContainer.Count:SetText("99")
    fontContainer.PreviewFont2.TextOverlayContainer.Count:SetText("99")



    ActionBarEnhancedDropdownMixin:RefreshPreview(pushedContainer.PreviewPushed)
    ActionBarEnhancedDropdownMixin:RefreshPreview(highlightContainer.PreviewHighlight)
    ActionBarEnhancedDropdownMixin:RefreshPreview(checkedContainer.PreviewChecked)
    ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewInterrupt)
    ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewCasting)
    ActionBarEnhancedDropdownMixin:RefreshPreview(hideContainer.PreviewReticle)
    ActionBarEnhancedDropdownMixin:RefreshPreview(fontContainer.PreviewFont05)
    ActionBarEnhancedDropdownMixin:RefreshPreview(fontContainer.PreviewFont075)
    ActionBarEnhancedDropdownMixin:RefreshPreview(fontContainer.PreviewFont1)
    ActionBarEnhancedDropdownMixin:RefreshPreview(fontContainer.PreviewFont15)
    ActionBarEnhancedDropdownMixin:RefreshPreview(fontContainer.PreviewFont2)

    optionsFrame:Show()
    optionsFrame.ScrollFrame.ScrollChild:SetWidth(optionsFrame.ScrollFrame:GetWidth())
end

RegisterNewSlashCommand(ActionBarEnhancedMixin.InitOptions, "ActionBarsEnhanced", "abe")