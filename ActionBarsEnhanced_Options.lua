local AddonName, Addon = ...

local L = Addon.L
local T = Addon.Templates

Addon.IsBeta = IsBetaBuild() or IsPublicTestClient()

Addon.ActionBarNames = {
    "GlobalSettings",
    "MainActionBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
    "PetActionBar",
    "StanceBar",
    "BagsBar",
    "MicroMenu",
}

Addon.CDMFrames = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
    "BuffBarCooldownViewer",
}

local printCount = 0
local lastCallTime = nil

function Addon:DebugPrint(...)
    local currentTime = GetTime()
    local timeStr = ""

    if lastCallTime then
        local timeDiff = currentTime - lastCallTime
        if timeDiff <= 10 then
            timeStr = string.format(" [%.2fs]", timeDiff)
        else
            printCount = 0
            lastCallTime = nil
        end
    end

    printCount = printCount + 1
    
    local prefix = string.format("[%d]%s ", printCount, timeStr)
    print(prefix, ...)
    
    lastCallTime = currentTime
end

function Addon:GetFontsList()
    local fontList = {"Default"}
    local LSMFonts = LibStub("LibSharedMedia-3.0"):List("font")
    for _, fontName in ipairs(LSMFonts) do
        table.insert(fontList, fontName)
    end
    return fontList
end

function Addon:GetStatusBarTextures()
    local tbl = {
        {
            name = "Blizzard BuffBar",
            texture = "UI-HUD-CoolDownManager-Bar"
        },
        {
            name = "Blizzard BuffBar BG",
            texture = "UI-HUD-CoolDownManager-Bar-BG"
        },
        {
            name = "Blizzard Midnight Barfill",
            texture = "midnight-scenario-barfill"
        },
        {
            name = "Blizzard Widget White",
            texture = "widgetstatusbar-fill-white"
        },
        {
            name = "Blizzard Machinebar",
            texture = "machinebar-fill-white"
        },
        {
            name = "Blizzard EdgeBottom",
            texture = "_ItemUpgradeTooltip-NineSlice-EdgeBottom"
        },
        {
            name = "Blizzard Widget Glow",
            texture = "widgetstatusbar-glowcenter"
        },
        {
            name = "Blizzard Widget BG",
            texture = "widgetstatusbar-bgcenter"
        },
        {
            name = "Blizzard Activities Fill",
            texture = "activities-bar-fill"
        },
        {
            name = "Blizzard Activities Bonus",
            texture = "activities-bar-fill-bonus"
        },
        {
            name = "Blizzard Activities Glow",
            texture = "activities-bar-fill-glow"
        },
        {
            name = "Blizzard Activities BG",
            texture = "activities-bar-background"
        },
        {
            name = "Blizzard Stripped",
            texture = "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss-2x"
        },
        {
            name = "Blizzard Select Left",
            texture = "glues-characterSelect-GS-TopHUD-left"
        },
        {
            name = "Blizzard Select Right",
            texture = "glues-characterSelect-GS-TopHUD-right"
        },
        {
            name = "Blizzard Select Left2",
            texture = "glues-characterSelect-GS-TopHUD-left-hover"
        },
        {
            name = "Blizzard Select Right2",
            texture = "glues-characterSelect-GS-TopHUD-right-hover"
        },
        {
            name = "Blizzard Dashboard Fill",
            texture = "housing-dashboard-fillbar-fill-threshold"
        },
        {
            name = "Blizzard Jailerstower Right",
            texture = "jailerstower-highlight-row-left"
        },

    }
    local LSM = LibStub("LibSharedMedia-3.0")
    local LSMStatusBarTextures = LSM:List("statusbar")
    for i, name in ipairs(LSMStatusBarTextures) do
        table.insert(tbl, { name = name, texture = LSM:Fetch("statusbar", name) })
    end
    return tbl
end

function Addon:GetStatusBarTextureByName(name)
    if type(name) == "number" then
        name = "Blizzard BuffBar"
    end
    local statusBars = T.StatusBarTextures
    if statusBars then
        for _, statusBar in ipairs(statusBars) do
            if statusBar.name == name then
                return statusBar.texture
            end
        end
    end
    return "UI-HUD-CoolDownManager-Bar"
end

function Addon:GetFontObject(fontName, outline, color, size, isStanceBar, frameName)
    if fontName == "Default" then
        fontName = "Fonts\\ARIALN.TTF"
    end
    outline = outline or ""
    if color then
        color.r = RoundToSignificantDigits(color.r, 2)
        color.g = RoundToSignificantDigits(color.g, 2)
        color.b = RoundToSignificantDigits(color.b, 2)
    end

    color = color or {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
    size = (size or 17) * (isStanceBar and 0.69 or 1.0)
    local fontNameKey = (frameName or (isStanceBar and "ABECD_Small_" or "ABECD_")).. fontName
    if not Addon.CooldownFont[fontNameKey] then
        Addon.CooldownFont[fontNameKey] = CreateFont(fontNameKey)
    end
    local fontObject = Addon.CooldownFont[fontNameKey]

    local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", fontName)
    fontObject:SetFont(fontPath, size, outline)
    fontObject:SetTextColor(color.r, color.g, color.b, color.a)
    return fontObject, fontNameKey
end

function Addon:IsSpellOnGCD(spellID, spellCooldownInfo)
    if not spellID then return false, false end

    local gcdInfo = C_Spell.GetSpellCooldown(61304)

    if not spellCooldownInfo then
        spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
    end

    local timeNow = GetTime()

    local startTime = spellCooldownInfo.startTime
    local duration = spellCooldownInfo.duration
    local endTime = spellCooldownInfo.startTime + spellCooldownInfo.duration
    local cooldownActive = endTime > timeNow

    local isOnGCD = false
    if gcdInfo and duration ~= 0 then
        if startTime == gcdInfo.startTime and duration == gcdInfo.duration then
            isOnGCD = true
        end
    end

    local isOnActualCooldown = cooldownActive and not isOnGCD

    return isOnGCD, isOnActualCooldown
end

--Shamelessly stolen from Platynator
function Addon:GetInterruptSpell()
    local interruptSpells = Addon.InterruptMap[UnitClassBase("player")] or {}

    for _, spellID in ipairs(interruptSpells) do
        if C_SpellBook.IsSpellKnownOrInSpellBook(spellID) or C_SpellBook.IsSpellKnownOrInSpellBook(spellID, Enum.SpellBookSpellBank.Pet) then
            return spellID
        end
    end
end

local EditModeIconDataProvider = nil

function Addon:GetRandomClassSpellIcon()
	if not EditModeIconDataProvider then
		local spellIconsOnly = true
		EditModeIconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook, spellIconsOnly);
	end

    local numIcons = EditModeIconDataProvider:GetNumIcons()

	return EditModeIconDataProvider:GetIconByIndex(math.random(2, numIcons));
end

function Addon:SetTexture(frame, texture, useAtlasSize)
    if not frame then return end
    if not texture then texture = "" end
    useAtlasSize = useAtlasSize or false

    if not C_Texture.GetAtlasInfo(texture) then
        frame:SetTexture(texture)
        return
    else
        frame:SetAtlas(texture, useAtlasSize)
    end
end

function Addon:UpdateButtons()

end

local function LightenHexColor(hex, factor)
    factor = factor or 1.3

    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255

    r = math.min(255, math.floor(r * factor + 0.5))
    g = math.min(255, math.floor(g * factor + 0.5))
    b = math.min(255, math.floor(b * factor + 0.5))

    return string.format("%02X%02X%02X", r, g, b)
end
local function GetGradientTextUTF8(text, startHex, endHex)
    if not text or text == "" then return "" end

    if not startHex then
        local classColorHex
        if PlayerUtil and PlayerUtil.GetClassColor then
            classColorHex = PlayerUtil.GetClassColor():GenerateHexColorNoAlpha()
        end
        classColorHex = classColorHex or "d1d1d1"

        startHex = startHex or classColorHex
    end
    endHex = endHex or LightenHexColor(startHex)

    local len = strlenutf8(text)
    if not len or len == 0 then return "" end

    local r1 = tonumber(startHex:sub(1, 2), 16) or 255
    local g1 = tonumber(startHex:sub(3, 4), 16) or 255
    local b1 = tonumber(startHex:sub(5, 6), 16) or 255

    local r2 = tonumber(endHex:sub(1, 2), 16) or 255
    local g2 = tonumber(endHex:sub(3, 4), 16) or 255
    local b2 = tonumber(endHex:sub(5, 6), 16) or 255

    local parts = {}
    local denom = len > 1 and (len - 1) or 1

    for i = 1, len do
        local t = (i - 1) / denom
        local r = r1 + (r2 - r1) * t
        local g = g1 + (g2 - g1) * t
        local b = b1 + (b2 - b1) * t

        r = math.min(255, math.max(0, math.floor(r + 0.5)))
        g = math.min(255, math.max(0, math.floor(g + 0.5)))
        b = math.min(255, math.max(0, math.floor(b + 0.5)))

        local hex = string.format("%02X%02X%02X", r, g, b)
        local char = string.utf8sub(text, i, i)
        parts[i] = "|cff" .. hex .. char .. "|r"
    end

    return table.concat(parts)
end

Addon.FontObjects = {}
Addon.CooldownFont = {}

StaticPopupDialogs["ABE_RELOAD"] = {
    text = "You have made changes to your profile settings that require a UI Reload.",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function()
        ReloadUI();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
StaticPopupDialogs["ABE_RESET_CAT"] = {
    text = "Are you sure you want to reset the settings for this action bar?",
    button1 = "Yes",
    button2 = "Cancel",
    OnAccept = function(dialog, barName)
        ABE_BarsListMixin:ResetBarSettings(barName);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

ActionBarEnhancedMixin = {}
ActionBarEnhancedDropdownMixin = {}
ActionBarEnhancedCheckboxMixin = {}
ActionBarColorMixin = {}
ActionBarEnhancedButtonPreviewMixin = {}
ActionBarEnhancedContainerMixin = {}
ActionBarEnhancedOptionsContentMixin = {}
ActionBarEnhancedCheckboxSliderMixin = {}

ABE_BarsFrameMixin = {}

function ABE_BarsFrameMixin:OnClick()
    ABE_BarsFrameMixin:Toggle()
end
function ABE_BarsFrameMixin:OnLoad()
    ABE_BarsFrameMixin:Collapse()
end

function ABE_BarsFrameMixin:Toggle()
	if ABE_BarsFrameMixin.collapsed then
		ABE_BarsFrameMixin:Expand()
	else
		ABE_BarsFrameMixin:Collapse()
	end
end
function ABE_BarsFrameMixin:Expand()
    ABE_BarsFrameMixin.collapsed = false
    ActionBarEnhancedOptionsAdvancedFrame:SetPoint("LEFT", ActionBarEnhancedOptionsFrame, "RIGHT", -5, 0)
end
function ABE_BarsFrameMixin:Collapse()
    ABE_BarsFrameMixin.collapsed = true
    ActionBarEnhancedOptionsAdvancedFrame:SetPoint("LEFT", ActionBarEnhancedOptionsFrame, "RIGHT", -205, 0)
end

ActionBarEnhancedApplyPresetButtonMixin = {}

function ActionBarEnhancedApplyPresetButtonMixin:OnClick()
    ActionBarsEnhancedProfilesMixin:SetProfile(self.preset, true)
end

function Addon:Welcome()
    print(L.welcomeMessage1)
    print(L.welcomeMessage2..Addon.shortCommand)
end

function Addon.Print(...)
    print("|cffedc99eActionBarsEnhanced:|r",...)
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

local function GetColorRGBA(settingName, profileName, context)
    local color = Addon:GetValue(settingName, profileName, context)

    if color == "CLASS_COLOR" then
        local classColor = PlayerUtil.GetClassColor()
        local r, g, b = classColor:GetRGB()
        local a = classColor.a or 1.0
        return r, g, b, a
    elseif type(color) == "table" then
        return color.r or 1.0, color.g or 1.0, color.b or 1.0, color.a or 1.0
    else
        return 1.0, 1.0, 1.0, 1.0
    end
end

function Addon:GetRGB(settingName, profileName, context)
    local r, g, b = GetColorRGBA(settingName, profileName, context)
    return r, g, b
end

function Addon:GetRGBA(settingName, profileName, context)
    return GetColorRGBA(settingName, profileName, context)
end

local toReload = {
    ["FadeBars"] = true,
    ["CurrentNormalTexture"] = true,
    ["DesaturateNormal"] = true,
    ["UseNormalTextureColor"] = true,
    ["NormalTextureColor"] = true,
    ["CurrentBackdropTexture"] = true,
    ["DesaturateBackdrop"] = true,
    ["UseBackdropColor"] = true,
    ["BackdropColor"] = true,
    ["UseIconMaskScale"] = true,
    ["IconMaskScale"] = true,
    ["CurrentIconMaskTexture"] = true,
    ["UseIconScale"] = true,
    ["IconScale"] = true,
    ["CurrentPushedTexture"] = true,
    ["DesaturatePushed"] = true,
    ["UsePushedColor"] = true,
    ["PushedColor"] = true,
    ["CurrentHighlightTexture"] = true,
    ["DesaturateHighlight"] = true,
    ["UseHighlightColor"] = true,
    ["HighlightColor"] = true,
    ["CurrentCheckedTexture"] = true,
    ["DesaturateChecked"] = true,
    ["UseCheckedColor"] = true,
    ["CheckedColor"] = true,
    ["UseCooldownColor"] = true,
    ["UseOORColor"] = true,
    ["UseOOMColor"] = true,
    ["UseNoUseColor"] = true,
    ["HideInterrupt"] = true,
    ["HideCasting"] = true,
    ["HideReticle"] = true,
    ["FontHotKey"] = true,
    ["FontStacks"] = true,
    ["FontHideName"] = true,
    ["FontName"] = true,
    ["FontNameScale"] = true,
    ["ModifyWAGlow"] = true,
    ["CurrentWAProcGlow"] = true,
    ["WAProcColor"] = true,
    ["UseWAProcColor"] = true,
    ["DesaturateWAProc"] = true,
    ["CurrentWALoopGlow"] = true,
    ["WALoopColor"] = true,
    ["UseWALoopColor"] = true,
    ["DesaturateWALoop"] = true,
    ["AddWAMask"] = true,

    ["FontHotKeyScale"] = true,
    ["CurrentHotkeyFont"] = true,
    ["CurrentHotkeyOutline"] = true,
    ["UseHotkeyFontSize"] = true,
    ["HotkeyFontSize"] = true,
    ["UseHotkeyOffset"] = true,
    ["HotkeyOffsetX"] = true,
    ["HotkeyOffsetY"] = true,
    ["UseHotkeyColor"] = true,
    ["HotkeyColor"] = true,
    ["CurrentHotkeyPoint"] = true,
    ["CurrentHotkeyRelativePoint"] = true,
    ["UseHotkeyShadow"] = true,
    ["HotkeyShadow"] = true,
    ["UseHotkeyShadowOffset"] = true,
    ["HotkeyShadowOffsetX"] = true,
    ["HotkeyShadowOffsetY"] = true,

    ["FontStacksScale"] = true,
    ["CurrentStacksFont"] = true,
    ["CurrentStacksOutline"] = true,
    ["UseStacksFontSize"] = true,
    ["StacksFontSize"] = true,
    ["UseStacksOffset"] = true,
    ["StacksOffsetX"] = true,
    ["StacksOffsetY"] = true,
    ["UseStacksColor"] = true,
    ["StacksColor"] = true,
    ["CurrentStacksPoint"] = true,
    ["CurrentStacksRelativePoint"] = true,
    ["UseStacksShadow"] = true,
    ["StacksShadow"] = true,
    ["UseStacksShadowOffset"] = true,
    ["StacksShadowOffsetX"] = true,
    ["StacksShadowOffsetY"] = true,

    ["UseSwipeSize"] = true,
    ["SwipeSize"] = true,
    ["UseEdgeSize"] = true,
    ["EdgeSize"] = true,
    ["CurrentCooldownFont"] = true,
    ["UseCooldownFontSize"] = true,
    ["CooldownFontSize"] = true,

    ["CurrentBarPadding"] = true,

    ["CDMEnable"] = true,
    ["CDMBackdropSize"] = true,
    ["UseCDMBackdrop"] = true,

    ["ColorizedCooldownFont"] = true,
    ["CastBarEnable"] = true,
}
function Addon:GetCurrentProfile()
    return ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
end

function Addon:SaveSetting(key, value, config)
    local barName
    if config then
        if config == true then
            barName = ABE_BarsListMixin:GetFrameLebel()
            if barName then
                config = barName
            else
                config = "GlobalSettings"
            end
        end
    end
    config = config or "GlobalSettings"

    local currentProfile = Addon:GetCurrentProfile()

    --[[ if config then
        Addon.C[config][key] = value
        if not ABDB.Profiles.profilesList[currentProfile][config] then
            ABDB.Profiles.profilesList[currentProfile][config] = {}
        end
        ABDB.Profiles.profilesList[currentProfile][config][key] = value
    else
        Addon.C[key] = value
        ABDB.Profiles.profilesList[currentProfile][key] = value
    end ]]

    if not Addon.C[config] then
        Addon.C[config] = {}
    end
    Addon.C[config][key] = value
    if not ABDB.Profiles.profilesList[currentProfile][config] then
        ABDB.Profiles.profilesList[currentProfile][config] = {}
    end
    ABDB.Profiles.profilesList[currentProfile][config][key] = value

    if toReload[key] then
        if not StaticPopup_Visible("ABE_RELOAD") then
            StaticPopup_Show("ABE_RELOAD")
        end
    end
end
function Addon:SetValue(valueName, newValue, profileName, config)
    if not valueName or not config then return end

    profileName = profileName or ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profile = profileName and ABDB.Profiles.profilesList[profileName]

    if profile and profile[configName] then
        profile[configName][valueName] = newValue
        return true
    end
    return false
end
function Addon:GetValue(valueName, profileName, config)
    local configName

    if config == true then
        local barName = ABE_BarsListMixin and ABE_BarsListMixin:GetFrameLebel()
        configName = barName or "GlobalSettings"
    elseif type(config) == "string" then
        configName = config
    else
        configName = "GlobalSettings"
    end

    local profile = profileName and ABDB.Profiles.profilesList[profileName] or Addon.C

    local value
    if profile and profile[configName] then
        value = profile[configName][valueName]
    end

    if value == nil and configName ~= "GlobalSettings" and profile and profile["GlobalSettings"] then
        value = profile["GlobalSettings"][valueName]
    end

    if value == nil then
        value = Addon.Defaults[valueName]
    end
    
    return value
end

function ActionBarEnhancedMixin:Reset()
    if ABDB then
        wipe(ABDB)
    end
end

function ActionBarEnhancedMixin:OpenProfileFrame()
    ActionBarsEnhancedProfilesMixin:Init()
end

function ActionBarEnhancedMixin:InitOptions()

    if ActionBarEnhancedOptionsFrame then
        ActionBarEnhancedOptionsFrame:Show(not ActionBarEnhancedOptionsFrame:IsVisible())
        return
    end

    Addon:BuildPresetsPreview()

    local optionsFrame = CreateFrame("Frame", "ActionBarEnhancedOptionsFrame", UIParent, "ActionBarEnhancedOptionsFrameTemplate")
    optionsFrame:SetParent(UIParent)
    optionsFrame:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
    --optionsFrame:SetScale(0.95)

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
    optionsFrame.TitleContainer.TitleText:SetText("ActionBarsEnhanced")
    --optionsFrame.Inset.Bg:SetAtlas("auctionhouse-background-auctions", true)
    optionsFrame.Inset.Bg:SetAtlas("auctionhouse-background-index", true)
    optionsFrame.Inset.Bg:SetHorizTile(false)
    optionsFrame.Inset.Bg:SetVertTile(false)
    optionsFrame.Inset.Bg:SetAllPoints()
    ActionBarEnhancedOptionsFramePortrait:SetTexture("interface/AddOns/ActionBarsEnhanced/assets/icon2.tga")

    optionsFrame.CloseButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)

    ABE_BarsFrameMixin:Init()

    function ActionBarEnhancedDropdownMixin:RefreshProcLoop(button, value, profileName, barName)
        
        if not barName then barName = ABE_BarsListMixin:GetFrameLebel() end
        
        local loopAnim = value and T.LoopGlow[value] or (T.LoopGlow[Addon:GetValue("CurrentLoopGlow", profileName, barName)] or nil)

        local region = button.ProcGlow
        if loopAnim.atlas then
            region.ProcLoopFlipbook:SetAtlas(loopAnim.atlas)    
        elseif loopAnim.texture then
            region.ProcLoopFlipbook:SetTexture(loopAnim.texture)
        end
        if loopAnim then
            region.ProcLoopFlipbook:ClearAllPoints()
            region.ProcLoopFlipbook:SetSize(region:GetSize())
            region.ProcLoopFlipbook:SetPoint("CENTER", region, "CENTER", -1.5, 1)
            region.ProcLoop.FlipAnim:SetFlipBookRows(loopAnim.rows or 6)
            region.ProcLoop.FlipAnim:SetFlipBookColumns(loopAnim.columns or 5)
            region.ProcLoop.FlipAnim:SetFlipBookFrames(loopAnim.frames or 30)
            region.ProcLoop.FlipAnim:SetDuration(loopAnim.duration or 1.0)
            region.ProcLoop.FlipAnim:SetFlipBookFrameWidth(loopAnim.frameW or 0.0)
            region.ProcLoop.FlipAnim:SetFlipBookFrameHeight(loopAnim.frameH or 0.0)
            region.ProcLoopFlipbook:SetScale(loopAnim.scale or 1)
        end
        --region.ProcLoopFlipbook:SetTexCoords(333, 400, 0.412598, 0.575195, 0.393555, 0.78418, false, false)
        region.ProcLoopFlipbook:SetDesaturated(Addon:GetValue("DesaturateGlow", profileName, barName)) --Addon.C.DesaturateGlow
        if Addon:GetValue("UseLoopGlowColor", profileName, barName) then
            region.ProcLoopFlipbook:SetVertexColor(Addon:GetRGB("LoopGlowColor", profileName, barName))
        else
            region.ProcLoopFlipbook:SetVertexColor(1.0, 1.0, 1.0)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshProcStart(button, value, profileName, barName)
        local function GetFlipBook(...)
            local Animations = {...}

            for _, Animation in ipairs(Animations) do
                if Animation:GetObjectType() == "FlipBook" then
                    Animation:SetParentKey("FlipAnim")
                    return Animation
                end
            end
        end
        local procAnim = value and T.ProcGlow[value] or (T.ProcGlow[Addon:GetValue("CurrentProcGlow", profileName, barName)] or nil)
        local region = button.ProcGlow
        local startProc = region.ProcStartAnim.FlipAnim or GetFlipBook(region.ProcStartAnim:GetAnimations())
            
        if startProc and region.ProcStartFlipbook:IsVisible() then
            
            if Addon:GetValue("HideProc", profileName, barName) then
                startProc:SetDuration(0)
                region.ProcStartFlipbook:Hide()
            else
                region.ProcStartFlipbook:Show()
                if procAnim.atlas then
                    region.ProcStartFlipbook:SetAtlas(procAnim.atlas)
                elseif procAnim.texture then
                    region.ProcStartFlipbook:SetTexture(procAnim.texture)
                end
                if procAnim then
                    startProc:SetFlipBookRows(procAnim.rows or 6)
                    startProc:SetFlipBookColumns(procAnim.columns or 5)
                    startProc:SetFlipBookFrames(procAnim.frames or 30)
                    startProc:SetDuration(procAnim.duration or 0.702)
                    startProc:SetFlipBookFrameWidth(procAnim.frameW or 0.0)
                    startProc:SetFlipBookFrameHeight(procAnim.frameH or 0.0)
                    region.ProcStartFlipbook:SetScale(procAnim.scale or 1)
                end
                region.ProcStartFlipbook:SetDesaturated(Addon:GetValue("DesaturateProc", profileName, barName)) --Addon.C.DesaturateProc

                if Addon:GetValue("UseProcColor", profileName, barName) then
                    region.ProcStartFlipbook:SetVertexColor(Addon:GetRGB("ProcColor", profileName, barName))
                else
                    region.ProcStartFlipbook:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshAltGlow(button, value, profileName, barName)
        local altGlowAtlas = value and T.PushedTextures[value] or (T.PushedTextures[Addon:GetValue("CurrentAssistAltType", profileName, barName)] or nil)
        local region = button.ProcGlow
        if altGlowAtlas then
            region.ProcAltGlow:SetAtlas(altGlowAtlas.atlas)
        end
        region.ProcAltGlow:SetDesaturated(Addon:GetValue("DesaturateAssistAlt", profileName, barName))
        if Addon:GetValue("UseAssistAltColor", profileName, barName) then
            region.ProcAltGlow:SetVertexColor(Addon:GetRGB("AssistAltColor"))
        else
            region.ProcAltGlow:SetVertexColor(1.0, 1.0, 1.0)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshNormalTexture(button, value, profileName, barName)
        local normalAtlas = value and T.NormalTextures[value] or (T.NormalTextures[Addon:GetValue("CurrentNormalTexture", profileName, barName)] or nil)
        if normalAtlas then
            if normalAtlas.hide then
                button.NormalTexture:Hide()
            else
                Addon:SetTexture(button.NormalTexture, normalAtlas.texture)

                if normalAtlas.point then
                    button.NormalTexture:ClearAllPoints()
                    button.NormalTexture:SetPoint(normalAtlas.point, button, normalAtlas.point)
                else
                    button.NormalTexture:SetPoint("TOPLEFT")
                end
                if normalAtlas.padding then
                    button.NormalTexture:SetPointsOffset(normalAtlas.padding[1], normalAtlas.padding[2])
                else
                    button.NormalTexture:SetPointsOffset(0,0)
                end
                if normalAtlas.size then
                    button.NormalTexture:SetSize(normalAtlas.size[1], normalAtlas.size[2])
                end
                if normalAtlas.coords then
                    button.NormalTexture:SetTexCoord(normalAtlas.coords[1], normalAtlas.coords[2], normalAtlas.coords[3], normalAtlas.coords[4])
                end
                button.NormalTexture:SetDrawLayer("OVERLAY")
            end
        end
        button.NormalTexture:SetDesaturated(Addon:GetValue("DesaturateNormal", profileName, barName)) --Addon.C.DesaturateNormal)
        if Addon:GetValue("UseNormalTextureColor", profileName, barName) then
            button.NormalTexture:SetVertexColor(Addon:GetRGBA("NormalTextureColor", profileName, barName))
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshBackdropTexture(button, value, profileName, barName)
        button.icon:Hide()
        local backdropAtlas = value and T.BackdropTextures[value] or (T.BackdropTextures[Addon:GetValue("CurrentBackdropTexture", profileName, barName)] or nil)
        if button.SlotBackground then
            if backdropAtlas then
                if backdropAtlas.hide then
                    button.SlotBackground:Hide()
                else
                    if backdropAtlas.atlas then
                        button.SlotBackground:SetAtlas(backdropAtlas.atlas)
                    end
                    if backdropAtlas.texture then
                        button.SlotBackground:SetTexture(backdropAtlas.texture)
                    end
                    if backdropAtlas.point then
                        button.SlotBackground:ClearAllPoints()
                        button.SlotBackground:SetPoint(backdropAtlas.point, button, backdropAtlas.point)
                    else
                        button.SlotBackground:SetPoint("TOPLEFT")
                    end
                    if backdropAtlas.padding then
                        button.SlotBackground:SetPointsOffset(backdropAtlas.padding[1], backdropAtlas.padding[2])
                    else
                        button.SlotBackground:SetPointsOffset(0,0)
                    end
                    if backdropAtlas.size then
                        button.SlotBackground:SetSize(backdropAtlas.size[1], backdropAtlas.size[2])
                    end
                    if backdropAtlas.coords then
                        button.SlotBackground:SetTexCoord(backdropAtlas.coords[1], backdropAtlas.coords[2], backdropAtlas.coords[3], backdropAtlas.coords[4])
                    end
                end
            end
            button.SlotBackground:SetDesaturated(Addon:GetValue("DesaturateBackdrop", profileName, barName))
            if Addon:GetValue("UseBackdropColor", profileName, barName) then
                button.SlotBackground:SetVertexColor(Addon:GetRGBA("BackdropColor", profileName, barName))
            end
        end
    end
    local defaultSizes = {}
    function ActionBarEnhancedDropdownMixin:RefreshPushedTexture(button, value, profileName, barName)
        local pushedAtlas = value and T.PushedTextures[value] or (T.PushedTextures[Addon:GetValue("CurrentPushedTexture", profileName, barName)] or nil)
        if pushedAtlas then
            if pushedAtlas.atlas then
                button:SetPushedAtlas(pushedAtlas.atlas)
            elseif pushedAtlas.texture then
                button.PushedTexture:SetTexture(pushedAtlas.texture)
            end
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
        button.PushedTexture:SetDesaturated(Addon:GetValue("DesaturatePushed", profileName, barName))
        if Addon:GetValue("UsePushedColor", profileName, barName) then
            button.PushedTexture:SetVertexColor(Addon:GetRGBA("PushedColor", profileName, barName))
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshHighlightTexture(button, value, profileName, barName)
        local highlightAtlas = value and T.HighlightTextures[value] or (T.HighlightTextures[Addon:GetValue("CurrentHighlightTexture", profileName, barName)] or nil)
        if highlightAtlas and highlightAtlas.hide then
            button.HighlightTexture:SetAtlas("")
            button.HighlightTexture:Hide()
        else
            button.HighlightTexture:Show()
            if highlightAtlas then
                if highlightAtlas.atlas then
                    button.HighlightTexture:SetAtlas(highlightAtlas.atlas)
                elseif highlightAtlas.texture then
                    button.HighlightTexture:SetTexture(highlightAtlas.texture)
                end
                if highlightAtlas.point then
                    button.HighlightTexture:ClearAllPoints()
                    button.HighlightTexture:SetPoint("CENTER", button, "CENTER", -0.5, 0.5)
                end
                if highlightAtlas.size then
                    defaultSizes.HighlightTexture = {button.HighlightTexture:GetSize()}
                    button.HighlightTexture:SetSize(highlightAtlas.size[1], highlightAtlas.size[2])
                elseif defaultSizes.HighlightTexture then
                    button.HighlightTexture:SetSize(defaultSizes.HighlightTexture[1], defaultSizes.HighlightTexture[2])
                end
            end

            button.HighlightTexture:SetDesaturated(Addon:GetValue("DesaturateHighlight", profileName, barName))
            if Addon:GetValue("UseHighlightColor", profileName, barName) then
                button.HighlightTexture:SetVertexColor(Addon:GetRGBA("HighlightColor", profileName, barName))
            end
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshCheckedTexture(button, value, profileName, barName)
        local checkedAtlas = value and T.HighlightTextures[value] or (T.HighlightTextures[Addon:GetValue("CurrentCheckedTexture", profileName, barName)] or nil)
        if checkedAtlas and checkedAtlas.hide then
            button.CheckedTexture:SetAtlas("")
        else
            if checkedAtlas then
                if checkedAtlas.atlas then
                    button.CheckedTexture:SetAtlas(checkedAtlas.atlas)
                elseif checkedAtlas.texture then
                    button.CheckedTexture:SetTexture(checkedAtlas.texture)
                end
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

            button.CheckedTexture:SetDesaturated(Addon:GetValue("DesaturateChecked", profileName, barName))
            if Addon:GetValue("UseCheckedColor", profileName, barName) then
                button.CheckedTexture:SetVertexColor(Addon:GetRGBA("CheckedColor", profileName, barName))
            end
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshIconTexture(button, value, profileName, barName)
        button.icon:ClearAllPoints()
        button.icon:SetPoint("CENTER", button, "CENTER", -0.5, 0.5)
        if isStanceBar then
            button.icon:SetSize(31,31)
            button.icon:SetScale(Addon:GetValue("UseIconScale", profileName, barName) and Addon:GetValue("IconScale", profileName, barName) * 0.69 or 1.0)
        else
            button.icon:SetSize(46,45)
            button.icon:SetScale(Addon:GetValue("UseIconScale", profileName, barName) and Addon:GetValue("IconScale", profileName, barName) or 1.0)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshIconMaskTexture(button, value, profileName, barName)
        local iconMaskAtlas = value and T.IconMaskTextures[value] or (T.IconMaskTextures[Addon:GetValue("CurrentIconMaskTexture", profileName, barName)] or nil)
        if iconMaskAtlas then
            if Addon:GetValue("CurrentIconMaskTexture", profileName, barName) > 1 then
                button.IconMask:SetHorizTile(false)
	            button.IconMask:SetVertTile(false)
                Addon:SetTexture(button.IconMask,iconMaskAtlas.texture)
                if iconMaskAtlas.point then
                    button.IconMask:ClearAllPoints()
                    button.IconMask:SetPoint(iconMaskAtlas.point, button.icon, iconMaskAtlas.point)
                end
                if iconMaskAtlas.size then
                    button.IconMask:SetSize(iconMaskAtlas.size[1], iconMaskAtlas.size[2])
                end
                if iconMaskAtlas.coords then
                    button.IconMask:SetTexCoord(iconMaskAtlas.coords[1], iconMaskAtlas.coords[2], iconMaskAtlas.coords[3], iconMaskAtlas.coords[4])
                end
            end
            if isStanceBar then
                button.IconMask:SetScale(Addon:GetValue("UseIconMaskScale", profileName, barName) and Addon:GetValue("IconMaskScale", profileName, barName) * 0.69 or 1.0)
            else
                button.IconMask:SetScale(Addon:GetValue("UseIconMaskScale", profileName, barName) and Addon:GetValue("IconMaskScale", profileName, barName) or 1.0)
            end
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshHotkeyFont(button, value, profileName, barName)
        local font = value or Addon:GetValue("CurrentHotkeyFont", profileName, barName)
        button.TextOverlayContainer.HotKey:SetFont(
            font ~= "Default" and LibStub("LibSharedMedia-3.0"):Fetch("font", font) or "Fonts\\ARIALN.TTF",
            (Addon:GetValue("UseHotkeyFontSize", profileName, barName) and Addon:GetValue("HotkeyFontSize", profileName, barName) or 11),
            Addon:GetValue("CurrentHotkeyOutline", profileName, barName) > 1 and Addon.FontOutlines[Addon:GetValue("CurrentHotkeyOutline", profileName, barName)] or ""
        )

        button.TextOverlayContainer.HotKey:ClearAllPoints()
        local fontSize = Addon:GetValue("UseHotkeyFontSize", profileName, barName) and Addon:GetValue("HotkeyFontSize", profileName, barName) or 11
        button.TextOverlayContainer.HotKey:SetFontHeight(fontSize)
        button.TextOverlayContainer.HotKey:SetWidth(0)
        button.TextOverlayContainer.HotKey:SetPoint(
            Addon.AttachPoints[Addon:GetValue("CurrentHotkeyPoint", profileName, barName)],
            button.TextOverlayContainer,
            Addon.AttachPoints[Addon:GetValue("CurrentHotkeyRelativePoint", profileName, barName)],
            Addon:GetValue("UseHotkeyOffset", profileName, barName) and Addon:GetValue("HotkeyOffsetX", profileName, barName) or -5,
            Addon:GetValue("UseHotkeyOffset", profileName, barName) and Addon:GetValue("HotkeyOffsetY", profileName, barName) or -5
        )
        if Addon:GetValue("UseHotkeyColor", profileName, barName) then
            button.TextOverlayContainer.HotKey:SetVertexColor(Addon:GetRGBA("HotkeyColor", profileName, barName))
        end
        if Addon:GetValue("UseHotkeyShadow", profileName, barName) then
            button.TextOverlayContainer.HotKey:SetShadowColor(Addon:GetRGBA("HotkeyShadow", profileName, barName))
        else
            button.TextOverlayContainer.HotKey:SetShadowColor(0,0,0,0)
        end
        if Addon:GetValue("UseHotkeyShadowOffset", profileName, barName) then
            button.TextOverlayContainer.HotKey:SetShadowOffset(Addon:GetValue("HotkeyShadowOffsetX", profileName, barName), Addon:GetValue("HotkeyShadowOffsetY", profileName, barName))
        else
            button.TextOverlayContainer.HotKey:SetShadowOffset(0,0)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshStacksFont(button, value, profileName, barName)
        local font = value or Addon:GetValue("CurrentStacksFont", profileName, barName)
        button.TextOverlayContainer.Count:SetFont(
            font ~= "Default" and LibStub("LibSharedMedia-3.0"):Fetch("font", font) or "Fonts\\ARIALN.TTF",
            (Addon:GetValue("UseStacksFontSize", profileName, barName) and Addon:GetValue("StacksFontSize", profileName, barName) or 16),
            Addon:GetValue("CurrentStacksOutline", profileName, barName) > 1 and Addon.FontOutlines[Addon:GetValue("CurrentStacksOutline", profileName, barName)] or ""
        )
        button.TextOverlayContainer.Count:ClearAllPoints()
        local fontSize = Addon:GetValue("UseStacksFontSize", profileName, barName) and Addon:GetValue("StacksFontSize", profileName, barName) or 16
        button.TextOverlayContainer.Count:SetFontHeight(fontSize)
        button.TextOverlayContainer.Count:SetPoint(
            Addon.AttachPoints[Addon:GetValue("CurrentStacksPoint", profileName, barName)],
            button.TextOverlayContainer,
            Addon.AttachPoints[Addon:GetValue("CurrentStacksRelativePoint", profileName, barName)],
            Addon:GetValue("UseStacksOffset", profileName, barName) and Addon:GetValue("StacksOffsetX", profileName, barName) or -5,
            Addon:GetValue("UseStacksOffset", profileName, barName) and Addon:GetValue("StacksOffsetY", profileName, barName) or 5
        )
        if Addon:GetValue("UseStacksColor", profileName, barName) then
            button.TextOverlayContainer.Count:SetVertexColor(Addon:GetRGBA("StacksColor", profileName, barName))
        end
        if Addon:GetValue("UseStacksShadow", profileName, barName) then
            button.TextOverlayContainer.Count:SetShadowColor(Addon:GetRGBA("StacksShadow", profileName, barName))
        else
            button.TextOverlayContainer.Count:SetShadowColor(0,0,0,0)
        end
        if Addon:GetValue("UseStacksShadowOffset", profileName, barName) then
            button.TextOverlayContainer.Count:SetShadowOffset(Addon:GetValue("StacksShadowOffsetX", profileName, barName), Addon:GetValue("StacksShadowOffsetY", profileName, barName))
        else
            button.TextOverlayContainer.Count:SetShadowOffset(0,0)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshSwipeTexture(button, value, profileName, barName)
        value = value or Addon:GetValue("CurrentSwipeTexture", profileName, barName)
        local textureSet = T.SwipeTextures[value]
        if value > 1 then
            button.cooldown:SetSwipeTexture(textureSet.texture)
        end
        if Addon:GetValue("UseSwipeSize", profileName, barName) then
            button.cooldown:ClearAllPoints()
            button.cooldown:SetPoint("CENTER", button.icon, "CENTER", 0, 0)
            button.cooldown:SetSize(Addon:GetValue("SwipeSize", profileName, barName), Addon:GetValue("SwipeSize", profileName, barName))
        end

        if not button.aura and Addon:GetValue("UseCooldownColor", profileName, barName) then
            local r, g, b, a = Addon:GetRGBA("CooldownColor", profileName, barName)
            button.cooldown:SetSwipeColor(r, g, b, a)
        elseif button.aura and Addon:GetValue("UseCooldownAuraColor", profileName, barName) then
            local r, g, b, a = Addon:GetRGBA("CooldownAuraColor", profileName, barName)
            button.cooldown:SetSwipeColor(r, g, b, a)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshEdgeTexture(button, value, profileName, barName)
        value = value or Addon:GetValue("CurrentEdgeTexture", profileName, barName)
        local textureSet = T.EdgeTextures[value]
        button.cooldownEdge:SetEdgeTexture(textureSet.texture)
        if Addon:GetValue("UseEdgeSize", profileName, barName) then
            local size = Addon:GetValue("EdgeSize", profileName, barName)
            if size > 2 then
                Addon:SetValue("EdgeSize", 1, profileName, barName)
                size = 1
            end
            button.cooldownEdge:SetEdgeScale(size)
        end

        if Addon:GetValue("UseEdgeColor", profileName, barName) then
            button.cooldownEdge:SetEdgeColor(Addon:GetRGBA("EdgeColor", profileName, barName))
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshCooldownFont(button, value, profileName, barName)
        local font = value or Addon:GetValue("CurrentCooldownFont", profileName, barName)
        local color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
        if not button.aura and Addon:GetValue("UseCooldownFontColor", profileName, barName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CooldownFontColor", profileName, barName)
        elseif button.aura and Addon:GetValue("UseCDMAuraTimerColor", profileName, barName) then
            color.r,color.g,color.b,color.a = Addon:GetRGBA("CDMAuraTimerColor", profileName, barName)
        end
        local _, fontName = Addon:GetFontObject(
            font,
            "OUTLINE, SLUG",
            color,
            Addon:GetValue("UseCooldownFontSize", profileName, barName) and Addon:GetValue("CooldownFontSize", profileName, barName) or 17,
            false,
            barName
        )
        local timerString = button.cooldown:GetCountdownFontString()
        button.cooldown:SetCountdownFont(fontName)
        timerString:SetVertexColor(color.r,color.g,color.b,color.a)

        if Addon:GetValue("UseCooldownFontOffset", profileName, barName) then
            local offsetX = Addon:GetValue("CooldownFontOffsetX", profileName, barName)
            local offsetY = Addon:GetValue("CooldownFontOffsetY", profileName, barName)

            timerString:SetPointsOffset(offsetX, offsetY)
        else
            timerString:SetPointsOffset(0, 0)
        end
    end

    function ActionBarEnhancedDropdownMixin:RefreshPreview(button, profileName, barName)

        if not barName then barName = ABE_BarsListMixin:GetFrameLebel() end

        if button.Name then
            if Addon:GetValue("FontHideName", profileName, barName) then
                button.Name:Hide()
            else
                button.Name:Show()
            end
        end
        
        if barName and (tContains(Addon.CDMFrames, barName) or
        string.find(barName, "CDMCustomFrame")) then
            button.NormalTexture:Hide()
            button.CheckedTexture:Hide()
            --button.BackdropTexture:Hide()
            button.HighlightTexture:Hide()
            if button.Name then
                button.Name:Hide()
            end
            if button.TextOverlayContainer then
                button.TextOverlayContainer.HotKey:Hide() --HotKey
            end
            button:EnableMouse(false)
        end

        if not button then return end

        local region = button.ProcGlow
        if region then                
            ActionBarEnhancedDropdownMixin:RefreshProcStart(button, nil, profileName, barName)

            ActionBarEnhancedDropdownMixin:RefreshProcLoop(button, nil, profileName, barName)

            ActionBarEnhancedDropdownMixin:RefreshAltGlow(button, nil, profileName, barName)
        end

        if button.NormalTexture then
            ActionBarEnhancedDropdownMixin:RefreshNormalTexture(button, nil, profileName, barName)
        end

        if button.backdropPreview then
            ActionBarEnhancedDropdownMixin:RefreshBackdropTexture(button, nil, profileName, barName)
        end

        ActionBarEnhancedDropdownMixin:RefreshPushedTexture(button, nil, profileName, barName)

        ActionBarEnhancedDropdownMixin:RefreshHighlightTexture(button, nil, profileName, barName)
        if button.CheckedTexture then
            ActionBarEnhancedDropdownMixin:RefreshCheckedTexture(button, nil, profileName, barName)
        end
        if button.IconMask then
            ActionBarEnhancedDropdownMixin:RefreshIconMaskTexture(button, nil, profileName, barName)
        end

        if button.icon then
            ActionBarEnhancedDropdownMixin:RefreshIconTexture(button, nil, profileName, barName)
        end

        local textScaleMult = button:GetScale()
        if textScaleMult < 1 then
            button.Name:SetScale(Addon:GetValue("FontName", profileName, barName) and (textScaleMult + Addon:GetValue("FontNameScale", profileName, barName)) or 1.0)
            button.TextOverlayContainer.HotKey:SetScale(Addon:GetValue("FontHotKey", profileName, barName) and Addon:GetValue("FontHotKeyScale", profileName, barName) or 1.0)
            button.TextOverlayContainer.Count:SetScale(Addon:GetValue("FontStacks", profileName, barName) and Addon:GetValue("FontStacksScale", profileName, barName) or 1.0)
        end

        
        if button.TextOverlayContainer then
            ActionBarEnhancedDropdownMixin:RefreshHotkeyFont(button, nil, profileName, barName)

            ActionBarEnhancedDropdownMixin:RefreshStacksFont(button, nil, profileName, barName)
        end

        if button.cooldown then
            ActionBarEnhancedDropdownMixin:RefreshSwipeTexture(button, nil, profileName, barName)
            ActionBarEnhancedDropdownMixin:RefreshCooldownFont(button, nil, profileName, barName)
            if not button.cooldownEdge then
                button.cooldown:SetDrawEdge(Addon:GetValue("EdgeAlwaysShow", profileName, barName))
            end
        end
        if button.cooldownEdge then
            ActionBarEnhancedDropdownMixin:RefreshEdgeTexture(button, nil, profileName, barName)
        end
    end

    function ActionBarEnhancedDropdownMixin:SetupDropdown(control, setting, name, IsSelected, OnSelect, showNew, OnEnter, OnClose,frames)
        local function SetupSingleDropdown(control, setting, name, IsSelected, OnSelect, showNew, OnEnter, OnClose, frames)
            local frame = control:GetParent()
            local menuGenerator = function(_, rootDescription)
                rootDescription:CreateTitle(name)
                local extent = 20
                local maxEntrys = 25
                local maxScrollExtent = extent * maxEntrys
                rootDescription:SetScrollMode(maxScrollExtent)
                
                if type(setting) == "function" then
                    setting = setting()
                end
                for i = 1, #setting do
                    local categoryName = setting[i].name or setting[i]
                    local categoryID = (frame.isFontOption or frame.isStatusBar) and categoryName or i
                    local radio = rootDescription:CreateRadio(categoryName, IsSelected, OnSelect, categoryID)
                    if frame.isFontOption then
                        if i > 1 then
                            if not Addon.FontObjects["ABE_"..categoryName] then
                                local fontObject = CreateFont("ABE_"..categoryName)
                                local fontPath = LibStub("LibSharedMedia-3.0"):Fetch("font", categoryName)
                                fontObject:SetFont(fontPath, 11, "")
                                Addon.FontObjects["ABE_"..categoryName] = fontObject
                            end
                            radio:AddInitializer(function(button, description, menu)
                                button.fontString:SetFontObject(Addon.FontObjects["ABE_"..categoryName])
                            end)
                        end
                    end
                    if frame.isStatusBar then
                        radio:AddInitializer(function(button, description, menu)
                            local texture = button:AttachTexture()
                            texture:SetHeight(18)
                            texture:SetPoint("LEFT", button, "LEFT", 15, 0)
                            texture:SetPoint("RIGHT", button, "RIGHT")
                            texture:SetDrawLayer("BACKGROUND")
                            Addon:SetTexture(texture, setting[i].texture)
                        end)
                    end
                    if OnEnter then
                        radio:SetOnEnter(function(button)
                            OnEnter(categoryID, frames)
                        end)
                    end
                end
            end
            if showNew then
                frame.NewFeature:Show()
            else
                frame.NewFeature:Hide()
            end
            if OnClose then
                control.Dropdown:RegisterCallback(DropdownButtonMixin.Event.OnMenuClose, function() OnClose(_, frames) end)
            end

            frame.Text:SetText(name)
            control.Dropdown:SetupMenu(menuGenerator)
            control.IncrementButton:Hide()
            control.DecrementButton:Hide()
        end

        local isDouble = control.Control1 and control.Control2
        
        if isDouble then
            SetupSingleDropdown(control.Control1, setting[1] or setting, name[1] or name, IsSelected[1], OnSelect[1], nil, OnEnter[1], OnClose[1],frames)
            SetupSingleDropdown(control.Control2, setting[2] or setting, name[2] or name, IsSelected[2], OnSelect[2], nil, OnEnter[2], OnClose[2],frames)
            control.Control1.Dropdown:SetWidth(140)
            control.Control2.Dropdown:SetWidth(140)
        else
            SetupSingleDropdown(control.Control, setting, name, IsSelected, OnSelect, showNew, OnEnter, OnClose,frames)
            control.Control.Dropdown:SetWidth(300)
        end
    end

    function ActionBarEnhancedDropdownMixin:SetupCheckbox(checkboxFrame, name, value, callback, showNew)
        if checkboxFrame.new then
            checkboxFrame.NewFeature:Show()
        else
            checkboxFrame.NewFeature:Hide()
        end
        checkboxFrame.Text:SetText(name)
        checkboxFrame.Checkbox:SetChecked(Addon:GetValue(value, nil, true))
        checkboxFrame.Checkbox:SetScript("OnClick",
            function(button, buttonName, down)
                Addon:SaveSetting(value, not Addon:GetValue(value, nil, true), true)
                if callback and type(callback) == "function" then
                    callback(button:GetChecked())
                end
            end
        )
    end

    function ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(checkboxFrame, name, checkboxValue, sliderValue, min, max, step, sliderName, callback, frames)
        checkboxFrame.Text:SetText(name)

        local function SetupSingleSlider(slider, name, checkboxValue, sliderValue, min, max, step, sliderName, callback, frames)
            local checkboxFrame = slider:GetParent()
            local options = Settings.CreateSliderOptions(min or 0, max or 1, step or 0.1)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Top, function(value) return sliderName.top and sliderName.top..": |cffcccccc"..RoundToSignificantDigits(value, 2) or "" end)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value) return sliderName.right and RoundToSignificantDigits(value, 2) or "" end)
            slider:Init(Addon:GetValue(sliderValue, nil, true), options.minValue, options.maxValue, options.steps, options.formatters)
            slider:RegisterCallback("OnValueChanged",
                function(self, value)
                    Addon:SaveSetting(sliderValue, value, true)

                    if not self._debounce then
                        self._debounce = true
                        C_Timer.After(0.1, function()
                            if callback and type(callback) == "function" then
                                callback(_, frames)
                            end
                            self._debounce = false
                        end)
                    end
                end,
                slider
            )
            slider:SetEnabled(Addon:GetValue(checkboxValue, nil, true))
            checkboxFrame.Checkbox:SetChecked(Addon:GetValue(checkboxValue, nil, true))
            checkboxFrame.Checkbox:SetScript("OnClick",
                function()
                    Addon:SaveSetting(checkboxValue, not Addon:GetValue(checkboxValue, nil, true), true)
                    if checkboxFrame.SliderWithSteppers then
                        checkboxFrame.SliderWithSteppers:SetEnabled(Addon:GetValue(checkboxValue, nil, true))
                    end
                    if checkboxFrame.SliderWithSteppers1 then
                        checkboxFrame.SliderWithSteppers1:SetEnabled(Addon:GetValue(checkboxValue, nil, true))
                    end
                    if checkboxFrame.SliderWithSteppers2 then
                        checkboxFrame.SliderWithSteppers2:SetEnabled(Addon:GetValue(checkboxValue, nil, true))
                    end

                end
            )
        end

        local isDouble = checkboxFrame.SliderWithSteppers1 and checkboxFrame.SliderWithSteppers2

        if isDouble then
            SetupSingleSlider(checkboxFrame.SliderWithSteppers1, name, checkboxValue, sliderValue[1], min, max, step, sliderName[1], callback, frames)
            SetupSingleSlider(checkboxFrame.SliderWithSteppers2, name, checkboxValue, sliderValue[2], min, max, step, sliderName[2], callback, frames)
        else
            SetupSingleSlider(checkboxFrame.SliderWithSteppers, name, checkboxValue, sliderValue, min, max, step, sliderName, callback, frames)
        end

    end

    function ActionBarEnhancedDropdownMixin:SetupColorSwatch(frame, name, value, checkboxValues, alpha, callback)
        frame.Text:SetText(name)
        if checkboxValues then
            for k, checkValue in pairs(checkboxValues) do
                local frameName = "Checkbox"..k
                if k == 2 then
                    frame[frameName].text:SetText(L.Desaturate)
                end
                frame[frameName]:Show()
                frame[frameName]:SetChecked(Addon:GetValue(checkValue, nil, true))
                frame[frameName]:SetScript("OnClick",
                    function()
                        Addon:SaveSetting(checkValue, not Addon:GetValue(checkValue, nil, true), true)
                    end
                )
            end
        end

        frame.ColorSwatch.Color:SetVertexColor(Addon:GetRGBA(value, nil, true))
        
        frame.ColorSwatch:SetScript("OnClick", function(button, buttonName, down)
            self:OpenColorPicker(frame, value, alpha, callback)
        end)
    end

    function ActionBarEnhancedDropdownMixin:OpenColorPicker(frame, value, alpha, callback)
        
        local info = UIDropDownMenu_CreateInfo()
        
        info.r, info.g, info.b, info.opacity = Addon:GetRGBA(value, nil, true)

        info.hasOpacity = alpha

        if ColorPickerFrame then
            if not ColorPickerFrame.classButton then
                local button = CreateFrame("Button", nil, ColorPickerFrame, "UIPanelButtonTemplate")
                button:SetPoint("RIGHT", -20, 0)
                button:SetSize(90, 25)
                button:SetText("Class")
                button:Show()
                ColorPickerFrame.classButton = button
            end
            ColorPickerFrame.classButton:SetScript("OnClick", function()
                info.r, info.g, info.b = PlayerUtil.GetClassColor():GetRGB()
                info.a = 1.0
                ColorPickerFrame:SetupColorPickerAndShow(info)
            end)
        end
        local okayButton = ColorPickerFrame.Footer.OkayButton
        if not okayButton._okayScript then
            okayButton._okayScript = okayButton:GetScript("OnClick")
        end
        if okayButton then
            okayButton:SetScript("OnClick", function(self)
                okayButton._okayScript(self)

                if callback and type(callback) == "function" then
                    callback()
                end
            end)
        end

        info.swatchFunc = function ()
            local r,g,b = ColorPickerFrame:GetColorRGB()
            local a = alpha and ColorPickerFrame:GetColorAlpha() or 1.0
            frame.ColorSwatch.Color:SetVertexColor(r,g,b)
            Addon:SaveSetting(value, { r=r, g=g, b=b, a=a }, true)
        end

        info.cancelFunc = function ()
            local r,g,b,a = ColorPickerFrame:GetPreviousValues()
            frame.ColorSwatch.Color:SetVertexColor(r,g,b)

            Addon:SaveSetting(value, { r=r, g=g, b=b, a=a }, true)
            if type(callback) == "function" then
                callback()
            end
        end

        ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    ActionBarEnhancedEditBoxMixin = {}

    function ActionBarEnhancedEditBoxMixin:SetupEditBox(name, defaultText, OnEnterPressed, OnEditFocusLost, OnEditFocusGained, numeric, numLetters)
        self.Label:SetText(name)
        local text = ""
        if type(defaultText) == "function" then
            text = defaultText() or ""
        else
            text = defaultText or ""
        end
        self.EditBox:SetText(text)

        if numeric then
            self.EditBox:SetNumeric(numeric)
        end
        if numLetters then
            self.EditBox:SetMaxLetters(numLetters)
        end
        
        if OnEnterPressed and type(OnEnterPressed) == "function" then
            local OnEnterPressedOrig = self.EditBox:GetScript("OnEnterPressed")
            self.EditBox:SetScript("OnEnterPressed", function(self)
                OnEnterPressedOrig(self)
                OnEnterPressed(self)
            end)
        end
        if OnEditFocusLost and type(OnEditFocusLost) == "function" then
            local OnEditFocusLostOrig = self.EditBox:GetScript("OnEditFocusLost")
            self.EditBox:SetScript("OnEditFocusLost", function(self)
                OnEditFocusLostOrig(self)
                OnEditFocusLost(self)
            end)
        end
        if OnEditFocusGained and type(OnEditFocusGained) == "function" then
            local OnEditFocusGainedOrig = self.EditBox:GetScript("OnEditFocusGained")
            self.EditBox:SetScript("OnEditFocusGained", function(self)
                OnEditFocusGainedOrig(self)
                OnEditFocusGained(self)
            end)
        end
    end

    ActionBarEnhancedEditBoxEditMixin = {}

    function ActionBarEnhancedEditBoxEditMixin:OnEnterPressed()
        
    end
    function ActionBarEnhancedEditBoxEditMixin:OnEditFocusLost()
        
    end
    function ActionBarEnhancedEditBoxEditMixin:OnEditFocusGained()
        
    end

    ---------------------------------------------
    ActionBarEnhancedButtonMixin = {}

    function ActionBarEnhancedButtonMixin:SetupButton(name, OnClick, buttonName)
        self.Label:SetText(name)
        self.Button:SetText(buttonName)
        if OnClick and type(OnClick) == "function" then
            self.Button:SetScript("OnClick", function(self)
                OnClick(self)
            end)
        end

    end
    ---------------------------------------------

    ActionBarEnhancedDropdownMixin.AllPreview = {}
    ActionBarEnhancedDropdownMixin.CooldownPreview = {}
    ActionBarEnhancedDropdownMixin.FontPreview = {}

    function ActionBarEnhancedDropdownMixin:SetupPreview(button, config)

        button.icon:SetTexture(Addon:GetRandomClassSpellIcon())

        if config.sub == "LoopGlow" then
            button.ProcGlow.ProcStartFlipbook:Hide()
            button.ProcGlow.ProcAltGlow:Hide()
            button.ProcGlow.ProcLoop:Play()
        elseif config.sub == "ProcGlow" then
            button.ProcGlow.ProcLoopFlipbook:Hide()
            button.ProcGlow.ProcAltGlow:Hide()
            button.ProcGlow.ProcStartAnim:Play()
        elseif config.sub == "Backdrop" then
            button.backdropPreview = true
        elseif config.sub == "CooldownSwipe" then
            table.insert(self.CooldownPreview, button)
            button.aura = config.aura
            button.cooldown:SetHideCountdownNumbers(not button.aura)
            CooldownFrame_Set(button.cooldown, GetTime(), math.random(10,120), true, false, 1)
            button.cooldown:SetScript("OnCooldownDone", function()
                CooldownFrame_Set(button.cooldown, GetTime(), math.random(10, 120), true, false, 1)
            end)
        elseif config.sub == "CooldownEdge" then
            table.insert(self.CooldownPreview, button)
            button.cooldownEdge = button.cooldown
            button.cooldownEdge:SetHideCountdownNumbers(true)
            button.cooldownEdge:SetDrawSwipe(false)
            CooldownFrame_Set(button.cooldownEdge, GetTime(), math.random(2, 15), true, true, 1)
            button.cooldownEdge:SetScript("OnCooldownDone", function()
                CooldownFrame_Set(button.cooldownEdge, GetTime(), math.random(2, 15), true, true, 1)
            end)
        elseif config.sub == "CooldownFont" then
            table.insert(self.CooldownPreview, button)
            CooldownFrame_Set(button.cooldown, GetTime(), math.random(10,120), true, false, 1)
            button.cooldown:SetScript("OnCooldownDone", function()
                CooldownFrame_Set(button.cooldown, GetTime(), math.random(10,120), true, false, 1)
            end)
        elseif config.sub == "AnimInterrupt" then
            button.InterruptDisplay:Show()
            button.InterruptDisplay.Base.AnimIn:SetLooping("REPEAT")
            button.InterruptDisplay.Highlight.AnimIn:SetLooping("REPEAT")
            button.InterruptDisplay.Base.AnimIn:Play()
            button.InterruptDisplay.Highlight.AnimIn:Play()
            button.Title.TitleText:SetText("Interrupt")
        elseif config.sub == "AnimCasting" then
            button.SpellCastAnimFrame:Show()
            button.SpellCastAnimFrame.Fill.CastingAnim:SetLooping("REPEAT")
            button.SpellCastAnimFrame.EndBurst.FinishCastAnim:SetLooping("REPEAT")
            button.SpellCastAnimFrame.Fill.CastingAnim:Play()
            button.SpellCastAnimFrame.EndBurst.FinishCastAnim:Play()
            button.Title.TitleText:SetText("Casting")
        elseif config.sub == "AnimReticle" then
            button.TargetReticleAnimFrame:Show()
            button.TargetReticleAnimFrame.HighlightAnim:SetLooping("REPEAT")
            button.TargetReticleAnimFrame.HighlightAnim:Play()
            button.Title.TitleText:SetText("Reticle")
        elseif config.sub == "Font" then
            table.insert(self.FontPreview, button)
            button.TextOverlayContainer.HotKey:SetText(config.hotkey or (math.random(1,10)-1))
            button.TextOverlayContainer.Count:SetText(config.stacks or (math.random(1,100)-1))
            button.Name:SetText(config.name or "Name")
        end
        if config.func then
            config.func(button)
        end
        table.insert(self.AllPreview, button)

        ActionBarEnhancedDropdownMixin:RefreshPreview(button)
    end

    function ActionBarEnhancedDropdownMixin:SetupPreviewPreset(frame, config)
        local currentProfile = Addon:GetCurrentProfile()
        local buttons = { frame.Button1, frame.Button2, frame.Button3, frame.Button4 }

        for i, button in pairs(buttons) do
            if i == 1 then
                button.ProcGlow.ProcStartFlipbook:Hide()
                button.ProcGlow.ProcAltGlow:Hide()
                button.ProcGlow.ProcLoop:Play()
            end
            button.icon:SetTexture(Addon:GetRandomClassSpellIcon())
            self:RefreshPreview(button, config.preset)
            button.TextOverlayContainer.HotKey:SetText(config.hotkey or (math.random(2,10)-1))
            button.TextOverlayContainer.Count:SetText(config.stacks or (math.random(1,5)-1))
        end

        frame.Title:SetText(config.text)
        frame.Desc:SetText(config.desc or "")

        frame.ApplyButton.preset = config.preset

        if config.preset == currentProfile then
            frame.ApplyButton:SetText(L.PresetActive)
            frame.ApplyButton:Disable()
        else
            frame.ApplyButton:SetText(L.PresetSelect)
            frame.ApplyButton:Enable()
        end

    end

    function ActionBarEnhancedDropdownMixin:RefreshFontPreview()
        for _, button in pairs(self.FontPreview) do
            self:RefreshPreview(button)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshCooldownPreview()
        for _, button in pairs(self.CooldownPreview) do
            self:RefreshPreview(button)
        end
    end
    function ActionBarEnhancedDropdownMixin:RefreshAllPreview()
        for _, button in pairs(self.AllPreview) do
            self:RefreshPreview(button)
        end
    end

    --ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, dataProvider, "OptionsContainerTemplate", ElementInitializer)
    ActionBarEnhancedMixin:InitData(Addon.layoutPresets)

    optionsFrame:Show()
end

function ActionBarEnhancedMixin:InitData(layout)
    if not self.dataProvider then
        self.dataProvider = CreateDataProvider()
    else
        self.dataProvider:Flush()
        self.view:Flush()
        self.scrollBox:Flush()
    end
    
    if not self.processedCache then self.processedCache = {} end

    local function ElementInitializer(frame, elementData)
        local containerDef = elementData
        local containerName = containerDef.name

        if frame.builtChildren then
            for _, child in ipairs(frame.builtChildren) do
                child:Hide()
                child:SetParent(nil) 
            end
            wipe(frame.builtChildren)
        else
            frame.builtChildren = {}
        end

        frame:Show()
        --frame:SetSize(720, containerDef.size or 180)
        --frame:SetID(containerDef.id or 0)

        local containerConfig = Addon.config.containers[containerName]
        if containerConfig then
            local title = containerConfig.title
            if containerConfig.new then
                title = GetGradientTextUTF8(title, "51e8d1", "edfcfa")
                frame.NewFeature:Show()
            else
                title = GetGradientTextUTF8(title, "ffb536", "ffd68f")
                frame.NewFeature:Hide()
            end
            frame.Title:SetText(title)
            frame.Desc:SetText(containerConfig.desc)
        else
            frame.Title:SetText(containerName)
            frame.Desc:SetText("")
            frame.NewFeature:Hide()
        end

        Addon:BuildContainerChildren(frame, containerDef, containerConfig, frame.builtChildren)
    end

    self.scrollBox = ActionBarEnhancedOptionsFrame.ScrollBox
    self.scrollBar = ActionBarEnhancedOptionsFrame.ScrollBar

    local template
    if layout then
        for i, layoutData in ipairs(layout) do
            if layoutData then
                template = layoutData.template or "OptionsContainerTemplate"
                self.dataProvider:Insert({
                    name = layoutData.name,
                    childs = layoutData.childs,
                })
            end
        end
    end

    if layout == Addon.layoutPresets then
        self.mod = 90
    else
        self.mod = 36
    end

    if not self.view then
        self.view = CreateScrollBoxListLinearView()
        self.view:SetPadding(2, 2, 20, 50, 20) --top, bottom, left, right, spacing
        --view:SetElementExtent(200)
        self.view:SetElementExtentCalculator(function(dataIndex, elementData)
            local height = 0
            local childHeight = 0
            for i, child in ipairs(elementData.childs) do
                if not(child.template:find("Button")) then
                    childHeight = child.height or self.mod
                    height = height + childHeight
                end
            end
            return 90 + height
        end)

        self.view:SetElementResetter(function(frame, elementData)
            --[[ local existing = { frame:GetChildren() }
            for _, child in ipairs(existing) do
                if child ~= frame.Title and child ~= frame.Desc then
                    child:Hide()
                end
            end ]]
        end)

        self.view:SetElementInitializer(template, function(frame, elementData)
            ElementInitializer(frame, elementData)
        end)
        ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)
        self.scrollBox:SetInterpolateScroll(true)
        self.scrollBox:SetPanExtent(40)
    end
    self.scrollBox:Init(self.view)
    self.scrollBox:SetDataProvider(self.dataProvider)
end

function Addon:InitChildElement(child, config, frames)
    if config.type == "dropdown" then
        if config.fontOption then
            child.isFontOption = true
        end
        if config.statusBar then
            child.isStatusBar = true
        end
        ActionBarEnhancedDropdownMixin:SetupDropdown(
            child,
            config.setting,
            config.name,
            config.IsSelected,
            config.OnSelect,
            config.showNew,
            config.OnEnter,
            config.OnClose,
            frames
        )
    elseif config.type == "checkbox" then
        if config.showNew then
            child.new = true
        end
        ActionBarEnhancedDropdownMixin:SetupCheckbox(child, config.name, config.value, config.callback, frames)
    elseif config.type == "colorSwatch" then
        ActionBarEnhancedDropdownMixin:SetupColorSwatch(
            child,
            config.name,
            config.value,
            config.checkboxValues,
            config.alpha,
            config.callback)
    elseif config.type == "checkboxSlider" then
        ActionBarEnhancedCheckboxSliderMixin:SetupCheckboxSlider(
            child,
            config.name,
            config.checkboxValue,
            config.sliderValue,
            config.min,
            config.max,
            config.step,
            config.sliderName,
            config.callback,
            frames
        )
    elseif config.type == "preview" then
        ActionBarEnhancedDropdownMixin:SetupPreview(child, config)
    elseif config.type == "previewPreset" then
        ActionBarEnhancedDropdownMixin:SetupPreviewPreset(child, config)
    elseif config.type == "itemList" then
        OptionsCDMCustomItemListMixin:SetupItemList()
    elseif config.type == "editbox" then
        ActionBarEnhancedEditBoxMixin.SetupEditBox(
            child,
            config.name,
            config.defaultText,
            config.OnEnterPressed,
            config.OnEditFocusLost,
            config.OnEditFocusGained,
            config.numeric,
            config.numLetters
        )
    elseif config.type == "button" then
        ActionBarEnhancedButtonMixin.SetupButton(
            child,
            config.name,
            config.OnClick,
            config.buttonName
        )
    end
end


RegisterNewSlashCommand(ActionBarEnhancedMixin.InitOptions, Addon.command, Addon.shortCommand)

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LDBIcon = LibStub:GetLibrary("LibDBIcon-1.0")

local ldb = LDB:NewDataObject("ActionBarEnhanced", {
    type = "launcher",
    icon = "Interface\\AddOns\\ActionBarsEnhanced\\assets\\minimap_icon.png",
    OnClick = function(_, button)
        if button == "LeftButton" then
            ActionBarEnhancedMixin.InitOptions()
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cFFAA13D4ActionBarEnhanced|r")
        tooltip:AddLine("|cFFFFFFFFLeft-click to open options")
    end
})

Addon.minimap = Addon.minimap or {hide=false}
LDBIcon:Register("ActionBarEnhanced", ldb, Addon.minimap)
