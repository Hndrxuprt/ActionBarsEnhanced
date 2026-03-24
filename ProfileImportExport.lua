local AddonName, Addon = ...

local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

local L = Addon.L
Addon.P = {}

ActionBarsEnhancedProfilesMixin = {}
ActionBarsEnhancedImportDialogMixin = {}
ActionBarsEnhancedExportDialogMixin = {}

local DefaultProfiles = {
    ["ElvUI Style"] = "fIv3pXX1vCwpEJlqDbwZcgd2G)G2sBDSJ)inon0nSGHjTH4nGDm8qLUZU7fMrSSZvZmRPBEPvwQs0h6l8MLCLI4H(E8B5Ti(l4O1(XKA6MQkv1Mi1Tp1xA65(1mZDbR6x8o35Ep3Z5353535mK5pXYTOFLgHlg4SnDvgTwTIob7EE25MVrqaTE08oHr4k8)7dWDSOF9OdkvZP5vxHUzJAobhO2Wd9Qg5EY(yJ8GqAQZCFp0QEFmLWU8XBWvO1CI8EeTKVx9ObyJREDyrNkBvnWNnVFn)GInVFtgAJZMyCZnqyJ0LDV3gBesJwllB00EJtWM0O7w3PCnQ7XfIC3LhI7jcXI(1QIE0X63k)nV5BFVk(1l5hEQy3H7LBg43OEvHFUyoNswx)1FZCLZKBZm5cY8k871Z099AGtd1sTQn1Bt3OPzNPlRWH8XydMaxYnsWnAyvvuKJ)OTxv69P)6OI(bvPiIo9Xapc8ZWvY2DgxF94DDmzlc7cMMD1iNOgHLDc4xDJa6kR6xZRANKJkiweJiutQYRHbzgLWM4v5YcA7knk7T1vxMw1RX2Sjn3AsEs5hW4SZ)QSMiW7NL)brE18IAoVpYt83P(h5r3HgS7fydn)clVcDB)hrxA(fwDhpK62cJZkBfQzL7XjkRwXPg1UqNH)4x(TF7)LnmpMxy55Ae4WdWajXUL26A(JDHV6p(77b)xmh6a8GIBHJjU4TlDB5nYJCykCrLz4MpLP8ETppTPqyw6bRqFenqz2KkfPjnY)9Ygs63cQVt1QE13KWgvUMoRhFPksrYBKR2j1k8GWAV445HSXnprjN6vPB7vrEY2M38e90I)0YoHBjqxlKARdiE(qgp7HRPPmdQbgoqXVWXnsvRNvKnxkWR67700VrexiYkvgw7oez(RBuM0ojnWT(Lfh1mhJzclrgWUW)8l(srQnWUWZYLBk8NTnJEcgqPZfQCGUSweFkgCVS8CvmQG4IydsHfI87EnysWc((2f(x)JFhEfNao)4W3Ha9MfUuwz2ujo4jsgy2rvQ(HpmTi2T5E5HLkr4o8Myeyx4G927t6PNmSH7spijmdSeB1sIwjIMs0MaJ2pCwcmbbUiwaE2Ju5PvhHt0swnR6cbN8k5GSe41gGDUUAaL6CUWPisToJBDTj6rsynvyue2rpQ8M4nUqFUWfoIEM(0)IgiOVrt7tbNEGJBpC7O3Jf0pmfmyMoPCnoYpRbqg7tgajCMXGBBH9HCKk4Vx9iAqqdw0C1922nDhZe0qkp)Qq31YiT2roY4Wy8tz2aXJPOBxeohmUic(WgEv2ArV6EHUUWWei3mDmzuRFhyern)8ia4VTGvg2hlFXgBSb)wn1tNc(zKhRE1TK1k2f(6zNvY7Sl83gzKPe1mwjD3WcMLseYheFgXHuu6deLuQUIZOT(n1wV9kROT(F9fV4qP17OReJBMEUKRt2gRyCBm8whnwJquUJ6gQoRWRNQpCk1hKd8JaP2YhrdI8qbSLc83jY1cUgbUEsPpUb9SyGnCZy05n0()F)Z(SdvvLyn6F5t)uUipCll9gVXrcuXg)6V8pZvF0762YDzjGHOOFRsyQTOiVNwsSO4sDPji6Kuod8wZaVTvB5MuW(ANgPQDevqlSSwr8IijpoSstN(PeOagZiQ31jiMwD970EPA(LDQTknIRZfUBrH42tEYVbBRcZq2xK4uYX4VT9J2I2u(8JVB1nf9zSl8FEYt4X1Zs9AtjR4z9CPv2IQhuyuCD(ErBunD20TZh4Jx2c0qKze4erDHB8aOmMKNR3NHV4E3BzvZpE77uTCipw)kDw6RE(Zpurhp86x)Dv5Hx(s(IzGFOOtE7YnK8uf(Vp3hWq5xsBQA62vFos7fD4Yf3dNSy7YorUhiobkHWHBHxjrcLxHJ7Gzc)GTDQPICfcYpM4iXtEWZnY(XVdQSQw0gRzQXRBuNESwPn)64o10BEkrTPt3wUjTtpzlJbhmghcHKNoXei6i6K(jdoOqvOC8pHPZ(yEiJExOl8U9AC)RH3VMhAeKdjNIo9qyKNjtxhLIWNelEYocCNSSChfXKNqLMew3yKfIOfS5udKoIFjwtn14)(M3KhQInhdTkoohaNR2oondx11Fhx8BmKbM(E0diGYntjCaZPXAP0k1dZnsCAvUlnY0rTEPa)kyf4oYp44999z8NuK7eAOPJRpSE7xlM9KKXXPuUTDHVzJn4AuWv7TLHTJrECSPN(0pxLS)cXpv4Ib3HGssX54sncDJlHNPLUuWgvRXo7ZEXwynyQsxEbRwPG0sZIMRgZ1riylCOK9JJvw0pmu9ThI2B7ojCcmEMeR)fZPGJIWh667Dk(Cx9dFx(0eNppoSaotbmq83jglNoyg4KNSpi30yd)0dPPOVei)qTnxAgy0SQHPWoZyVByOb4TJhrmCfCP(zJWf65KIU64om2Xn98HhVcthr)TKptGa(eoJc7uH9KGBLbf7H9D564VDwwEzHq3av7yrfjFbL85frjZpJnlbhsGcInfKptkao5pDXXIZkq(s9Zrye0))GW8Kq(b4jejgoMedNqGEigo0qcmSpx2O3nme5tE8aWaeVcheFhboQ(cpuZbMXf5X825icHatexKa7tcL3xopl)p5a2GaUcj5t24e4u9derFGLkReR(PdJFab(XgFBx8B(jU60ZByPspVPl8wtd7tGFUezJ)SJ0FmcEumjmDwy2ld)brt5H7QFIkvDJF1)l",
    ["CooldownManager Style"] = "1zvtSnXXx8y26MgCd4yNpO4ayknLpkq5JeoujKbNVCRWHeIdKOasZAVtSxLnEhn7AcohQqi9VkNHdiUH4yovfHQ6fuRYTEBuOQhqQQTMGQuP)lQMEV9nZo7xMqUK1Z8M37373738MxKVI03Oww4Q26QgdBAAOzUC1RQJxgt)jsxdps(RGxY8M4jvRQHxsVufs3ZyHDT7I1OQdBAysrnal)8sMvNuvttVA5iBY)rEvRfNUKQbw5UW2JwvTObg54GrYZpBb9LWuhhiIv41glHQscAUm)y3DNUT2AlrzLefZL5RJhN)lW(wbbyFUmp)yR99CJPrsuosIIri94LdJGTuTbJT1nRI2aqX0lRtWtRVcUcPlhqfifq31B75fGBCQU2LuRBwZUqDcwH0B2AlSa)aHzTVHTJkS3jclQc)ucG5fyCf27IAka0nXujaqK(8GOGaaVN1KQHPi27JijHnZzs1xXSQTQX4uZLTReLTROpsGyH)RqsmMzPAwJrvxcpnbByKvLU6(j7D4Aukuzhw1YgwH)Vjalgd8ej(yGltpvnvnaxQPluG0)BADbvAzSn3(nUif0hPNqLcaG0lp2bmdkzCEcro02hXRGnawhurM6vT3nKsV5ztrsixLtPxEHfSW2Z2FBq5lKhffitR2j77THwrmIUD5opu8CH1hjv4DdHVUADx3SqI(9V97(f1SS1xOEoLnKBCnDn7kBfJ0Blg6KBZfX5IqR5mAt5s5W6LRypqiYIFChYkU)zDmKlucHljA3tlLkbh5uSg4TrHHOJyTwTDbbQP)6ICf1k1mTni7TkQslGVfO)XK4zn0xzfvQwA(DhWcq63AWDAtubk8BhQt5spUDteQMC6AyEmKxBElu(SrBgGU5EBOgJBywu1yASTnCL3A1ZSjG5slAjpGYDfwYBHLlZF)Y)h04zhqeDsshlfCuhnLRnj1Se4YLpeRBudGEYzAViUUSd3EdDWqKChpActrF1aT9A081TjA7LlZlMzge)tO93VF)7)qE7V4bAd74)7mQwzrHrHk7l46P)86x)2sp5(zrVp5nc9Ys06bqSZXve9Dv8ViwbxArSMSKEayDUTqy1CHd)owLMIekyNVoVMa0HEyajA86qi8J5im7vgQSWYAutImwjB6zR8UYDU8LZhktF(R)hxoZ9ZIEF6FdjaqF0O3IqXwwlRwpuTFofs3Uf1Awv8s42xhaHltJ8Szct6sQgU24Pr4gkxStsYaLm)KTRqQcr)P8cwXPs4z4Mo)wQmpUF2iEergKyBWTNFDGl7rUYYlzAs4YYo8IMVZz5B4rRocjw0Cz(RVDQFfOmwCXT8GHgrI3AsmGxfZT46seBgsIkEGUXmxnDOhO7ZfsqBmdERm5H3xOmEUJ3wJW6KdUju9diWAeMWoalgA9aPvlQzzdOWVDVAF3rU(GEMNlZZE2Z(x4pUs6NVXnUDiL0i5ZoUeVStbmZi5b6I39vNiQABWTWTh9jA6mLHFtBwce78jfJxCvm1wVK7l8kUa50Us7xm0qxqkTF58Z7CjwX)zUrY70TnRx3w2PGzqCDZ5cL(WuiEkx4KayLNrPHd8KWF2KWGgHxAUB46YHcqrBn4GxqEz7))KNiuofpSRHNXnf26Xp(79hKtMqWmoSplPRTNnGtFvMmUD9AS(68ts6zgBDdD76TmOkFKlfKZuxqUXAhXEpHJ8NxKhu)zjzDeAyXIcTincBNi2Uu4iQZ5zXQqskhak8CvSEz9X(OTIX2lILA3SbrS91FBSHIYoDf2bIY2F7SpC3SdPWoyu2aryFmID4byhjf7Si2XIXobID8ySZKIDse7tHsu)PyFcIDueBpSpGDUHyPHPt6zsd16yXRxWRsqmfay10ob(Xj8dC)P8Mp4sWDGQLQ7Fr7v7CThkPVF4bp474k4Y(FsvGqLNnuNSZD(TBKg(WsEJ04mESCUcPY2jj9EQL3RUm1SwvnFe8B9uafIEL0Xrzh5G8k1zrK90YedtDn3zfs6nRaVjAwtBBZLADgvzo7k4)so7EY3WPbK3CkVz4ez2U4SpubBz95MQPpO8ZP)yT1(vjR(0N(0FrWQop9CV7XP7)l",
}

function NewProfile_OnTextChanged(self)
    if not self:HasFocus() and self:GetText() == "" then
        self.AcceptButton:Hide()
    else
        self.AcceptButton:Show()
    end
end
function NewProfile_OnEditFocusLost(self)
    if self:GetText() == "" then
        self.AcceptButton:Hide()
    end
end
function NewProfile_OnAcceptClick(self)
    local editBox = self:GetParent()
    local profileName = editBox:GetText()

    if Addon.P.profilesList == nil then
        Addon.P.profilesList = {}
    end
    if not Addon.P.profilesList[profileName] then
        ActionBarsEnhancedProfilesMixin:CreateProfile(profileName)
        ActionBarsEnhancedProfilesMixin:SetProfile(profileName, true)
        editBox:SetText("")
        editBox:ClearFocus()
    else
        Addon.Print("Profile name already exists")
    end
end
function ActionBarsEnhancedProfilesMixin:Init()
    if not ActionBarEnhancedProfilesFrame then
        local profilesFrame = CreateFrame("Frame", "ActionBarEnhancedProfilesFrame", UIParent, "ActionBarsEnhancedProfilesTemplate")
        profilesFrame:SetParent(UIParent)
        profilesFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        profilesFrame:SetMovable(true)
        profilesFrame:EnableMouse(true)
        profilesFrame:EnableMouseWheel(true)
        profilesFrame:RegisterForDrag("LeftButton")
        profilesFrame:SetScript("OnDragStart", function(self, button)
            self:StartMoving()
        end)
        profilesFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)
        profilesFrame:SetUserPlaced(true)

        profilesFrame.Content.Header.HeaderText:SetText(L.ProfilesHeaderText)
        profilesFrame.Content.CopyProfileFrame.CopyText:SetText(L.ProfilesCopyText)
        profilesFrame.Content.DeleteProfileFrame.DeleteText:SetText(L.ProfilesDeleteText)
        profilesFrame.Content.ImportExportFrame.ImportExportText:SetText(L.ProfilesImportText)

        profilesFrame.Content.Header.CurrentProfile:SetText(self:GetPlayerProfile())
        

        local function SelectProfileSetup()
            local frame = profilesFrame.Content.NewProfileFrame.ProfileSelect
            local IsSelected = function(id)
                return id == ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
            end

            local OnSelect = function(id)
                ActionBarsEnhancedProfilesMixin:SetProfile(id, true)
                profilesFrame.Content.Header.CurrentProfile:SetText(id)
            end

            local menuGenerator = function(_, rootDescription)
                rootDescription:CreateTitle("Select Profile")
                for index, profileName in ipairs(Addon.P.profilesOrder) do
                    local categoryID = profileName
                    local categoryName = profileName
                    rootDescription:CreateRadio(categoryName, IsSelected, OnSelect, categoryID)
                end
            end
            frame.Dropdown:SetupMenu(menuGenerator)
        end

        local function CopyProfileSetup()
            local frame = profilesFrame.Content.CopyProfileFrame

            local menuGenerator = function(_, rootDescription)
                rootDescription:CreateTitle("Copy Profile")
                local currProfile = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()

                for index, profileName in ipairs(Addon.P.profilesOrder) do
                    if profileName ~= currProfile then
                        rootDescription:CreateButton(profileName, function()
                            ActionBarsEnhancedProfilesMixin:CopyProfile(profileName, currProfile)
                            ActionBarsEnhancedProfilesMixin:SetProfile(currProfile, true)
                        end)
                    end
                end
            end
            frame.Dropdown:SetupMenu(menuGenerator)
        end
        local function DeleteProfileSetup()
            local frame = profilesFrame.Content.DeleteProfileFrame

            local menuGenerator = function(_, rootDescription)
                rootDescription:CreateTitle("Delete Profile")
                local currProfile = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()

                for index, profileName in ipairs(Addon.P.profilesOrder) do
                    if profileName ~= currProfile and profileName ~= "Default" and not DefaultProfiles[profileName]  then
                        rootDescription:CreateButton(profileName, function()
                            ActionBarsEnhancedProfilesMixin:DeleteProfile(profileName)
                        end)
                    end
                end
            end
            frame.Dropdown:SetupMenu(menuGenerator)
        end
        local function SetupSpecProfiles()
            local playerID = Addon:GetPlayerID()
            local frame = profilesFrame.Content.SpecProfilesFrame
            local checkBox = frame.EnableSpecProfiles

            local numSpec = GetNumSpecializations()

            if Addon.P.mapping[playerID].specEnabled then
                checkBox:SetChecked(true)
            else
                checkBox:SetChecked(false)
            end

            checkBox:SetScript("OnClick", function(self)
                for i=1, numSpec do
                    if self:GetChecked() then
                        frame["SpecDropdown"..i]:Enable()
                    else
                        frame["SpecDropdown"..i]:Disable()
                    end
                end
                Addon.P.mapping[playerID].specEnabled = self:GetChecked()
            end)

            checkBox.Text:SetText("Enable Spec Profiles")
            checkBox.Text:SetFontObject("GameFontNormal")

            for i=1, numSpec do
                local dropDown = frame["SpecDropdown"..i]
                dropDown:Show()
                local specID, specName, _, specIcon = GetSpecializationInfo(i)
                local currentSpec = GetSpecialization()

                if currentSpec == i then
                    dropDown.Label:SetText(specName .. " - |cff0bbe76Active|r")
                else
                    dropDown.Label:SetText(specName)
                end
                if not checkBox:GetChecked() then
                    dropDown:Disable()
                end
                
                local IsSelected = function(id)
                    return id == Addon.P.mapping[playerID].specProfiles[i]
                end

                local OnSelect = function(id)                    
                    if currentSpec == i then
                        ActionBarsEnhancedProfilesMixin:SetProfile(id, false)
                        profilesFrame.Content.Header.CurrentProfile:SetText(id)
                    else
                        local playerID = Addon:GetPlayerID()
                        Addon.P.mapping[playerID].specProfiles[i] = id
                    end
                end

                local menuGenerator = function(_, rootDescription)
                    rootDescription:CreateTitle("Select Spec Profile")
                    local currProfile = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()

                    for index, profileName in ipairs(Addon.P.profilesOrder) do
                        local categoryID = profileName
                        local categoryName = profileName
                        rootDescription:CreateRadio(categoryName, IsSelected, OnSelect, categoryID)
                    end

                end

                dropDown:SetupMenu(menuGenerator)
            end
        end

        SelectProfileSetup()
        CopyProfileSetup()
        DeleteProfileSetup()
        SetupSpecProfiles()
    else
        ActionBarEnhancedProfilesFrame:Show()
    end
    
end

function Addon:GetPlayerID()
    local name, server = UnitFullName("player")
    local playerID = name.."-"..server
    return playerID
end

function ActionBarsEnhancedProfilesMixin:SetProfile(profileName, reload, config)
    local playerID = Addon:GetPlayerID()

    local currentProfile = profileName
    local profileData = Addon.P.profilesList[currentProfile]
    if not profileData then
        return
    end
    
    if profileData.FontHotKeyScale and profileData.FontHotKeyScale < 1.0 then
        profileData.FontHotKeyScale = 1.0
    end
    if profileData.FontStacksScale and profileData.FontStacksScale < 1.0 then
        profileData.FontStacksScale = 1.0
    end

    Addon.C["GlobalSettings"] = {}
    for key, defaultValue in pairs(Addon.Defaults) do
        if profileData["GlobalSettings"] and profileData["GlobalSettings"][key] ~= nil then
            if key == "EdgeSize" then

                --todo remove this workaround after some time
                if profileData["GlobalSettings"][key] > 2 then
                    Addon.Print("EdgeSize in GlobalSettings set to 2" )
                    profileData["GlobalSettings"][key] = 2
                end
            end
            Addon.C["GlobalSettings"][key] = profileData["GlobalSettings"][key]
        else
            Addon.C["GlobalSettings"][key] = type(defaultValue) == "table" and CopyTable(defaultValue) or defaultValue
        end
    end

    for catName, catData in pairs(profileData) do
        if catName ~= "GlobalSettings" then
            Addon.C[catName] = Addon.C[catName] or {}
            
            local targetCat = Addon.C[catName]

            for key, value in pairs(catData) do
                if key == "EdgeSize" then
                    if value > 2 then
                        Addon.Print("EdgeSize in", catName, value, " set to 2" )
                        profileData[catName][key] = 2
                    end
                end
                if key == "UseCDMBackdrop" then
                    print(catName, key, value)
                end
                Addon.C[catName][key] = value
            end
        end
    end

    local activeSpec = GetSpecialization()

    Addon.P.mapping[playerID].globalProfile = currentProfile
    Addon.P.mapping[playerID].specProfiles[activeSpec] = currentProfile

    if reload then
        if not StaticPopup_Visible("ABE_RELOAD") then
            StaticPopup_Show("ABE_RELOAD")
        end
    end
end

function ActionBarsEnhancedProfilesMixin:InstallDefaultPresets()
    for profileName, profileString in pairs(DefaultProfiles) do
        if not Addon.P.profilesList[profileName] then
            ActionBarsEnhancedImportDialogMixin:AcceptImport(_, DefaultProfiles[profileName], profileName)
        end
    end
end

function ActionBarsEnhancedProfilesMixin:ResetProfile()
    local profileName = self:GetPlayerProfile()
    if DefaultProfiles[profileName] then
        self:DeleteProfile(profileName)
        ActionBarsEnhancedImportDialogMixin:AcceptImport(_, DefaultProfiles[profileName], profileName, true)
    else
        wipe(Addon.P.profilesList[profileName])
        self:SetProfile(profileName, true)
    end
end

function ActionBarsEnhancedProfilesMixin:CreateProfile(profileName)
    Addon.P.profilesList[profileName] = { ["GlobalSettings"] = {} }

    self:AddProfileOrder(profileName)
end

function ActionBarsEnhancedProfilesMixin:ResetCatOptions(catName)
    local profileName = self:GetPlayerProfile()
    if Addon.P.profilesList[profileName][catName] then
        Addon.P.profilesList[profileName][catName] = nil
        StaticPopup_Show("ABE_RELOAD")
    end
end

function ActionBarsEnhancedProfilesMixin:DeleteProfile(profileName)
    if Addon.P.profilesList[profileName] ~= nil then
        Addon.P.profilesList[profileName] = nil
        self:RemoveProfileOrder(profileName)
        return true
    end
    return false
end

function ActionBarsEnhancedProfilesMixin:CopyProfileCategory(fromCatName, toCatName, reload)
    local profileName = self:GetPlayerProfile()
    if Addon.P.profilesList[profileName][toCatName] == nil then
        Addon.P.profilesList[profileName][toCatName] = {}
    end
    wipe(Addon.P.profilesList[profileName][toCatName])
    Addon.P.profilesList[profileName][toCatName] = CopyTable(Addon.P.profilesList[profileName][fromCatName])
    if reload then
        if not StaticPopup_Visible("ABE_RELOAD") then
            StaticPopup_Show("ABE_RELOAD")
        end
    end
end
function ActionBarsEnhancedProfilesMixin:CopyProfile(fromProfileName, toProfileName)
    if Addon.P.profilesList[fromProfileName] ~= nil then
        wipe(Addon.P.profilesList[toProfileName])
        for key, value in pairs(Addon.P.profilesList[fromProfileName]) do
            Addon.P.profilesList[toProfileName][key] = type(value) == "table" and CopyTable(value) or value
        end
        StaticPopup_Show("ABE_RELOAD")
    end
end

function ActionBarsEnhancedProfilesMixin:NeedMigrateProfile()
    local playerID = Addon:GetPlayerID()

    local migrate = false
    local tmp = {}
    for key, defaulValue in pairs(Addon.Defaults) do
        if ABDB[key] ~= nil then
            migrate = true
            tmp[key] = type(ABDB[key]) == "table" and CopyTable(ABDB[key]) or ABDB[key]
            ABDB[key] = nil
        end
    end
    if migrate then
        return true, tmp
    end
    return false
end

function ActionBarsEnhancedProfilesMixin:CheckProfiles15()
    local anyMigrated = false
    for profileName, profileData in pairs(Addon.P.profilesList) do
        local needMigrate = self:NeedMigrateProfile15(profileName)
        if needMigrate then
            anyMigrated = true
            Addon.Print("Profile "..profileName.." need migrate to v2.0")
            self:MigrateProfile15(profileName)
        else
            --Addon.Print(profileName.." profile ready for v2.0")
        end
        self:CheckProfilesOrer(profileName)
    end
    if anyMigrated then
        table.sort(Addon.P.profilesOrder)
    end
end

function ActionBarsEnhancedProfilesMixin:CheckProfiles247()
    local playerID = Addon:GetPlayerID()
    local numSpec = GetNumSpecializations()
    local mapping = Addon.P.mapping
    if mapping and type(mapping[playerID]) == "string" then
        Addon.Print("Character "..playerID.." need migrate to v2.4.7")
        local currentProfile = mapping[playerID]
        mapping[playerID] = {
            globalProfile = currentProfile,
            specEnabled = false,
            specProfiles = {},
        }
        for i=1, numSpec do
            mapping[playerID].specProfiles[i] = currentProfile
        end
        Addon.Print("Character "..playerID.." migrated to v2.4.7")
    end
end

function ActionBarsEnhancedProfilesMixin:NeedMigrateProfile15(profileName)
    return not Addon.P.profilesList[profileName]["GlobalSettings"]
end

function ActionBarsEnhancedProfilesMixin:MigrateProfile15(profileName)
    Addon.Print("Start migrating profie "..profileName.." to v2.0")
    if not Addon.P.profilesList[profileName]["GlobalSettings"] then
        Addon.P.profilesList[profileName]["GlobalSettings"] = {}
    end

    for key, value in pairs(Addon.P.profilesList[profileName]) do
        if key ~= "GlobalSettings" then
            Addon.P.profilesList[profileName]["GlobalSettings"][key] = value
            Addon.P.profilesList[profileName][key] = nil
        end
    end
    Addon.Print(profileName.." migrated to v2.0")
end

function ActionBarsEnhancedProfilesMixin:CheckProfilesOrer(profileName)
    if Addon.P.profilesOrder == nil then
        Addon.P.profilesOrder = {}
    end

    if Addon.P.profilesList[profileName] then
        tInsertUnique(Addon.P.profilesOrder, profileName)
    else
        tDeleteItem(Addon.P.profilesOrder, profileName)
    end
end

function ActionBarsEnhancedProfilesMixin:AddProfileOrder(profileName)
    table.insert(Addon.P.profilesOrder, profileName)
end
function ActionBarsEnhancedProfilesMixin:RemoveProfileOrder(profileName)
    tDeleteItem(Addon.P.profilesOrder, profileName)
end
function ActionBarsEnhancedProfilesMixin:GetProfileOrder(profileName)
    return tIndexOf(Addon.P.profilesOrder, profileName)
end

function ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local playerID = Addon:GetPlayerID()
    if Addon.P.mapping == nil then
        Addon.P.mapping = {}
    end
    if Addon.P.profilesOrder == nil then
        Addon.P.profilesOrder = {}
    end
    if Addon.P.mapping[playerID] == nil then
        Addon.P.mapping[playerID] = {
            globalProfile = "Default",
            specEnabled = false,
            specProfiles = {},
        }
        local numSpec = GetNumSpecializations()
        for i=1, numSpec do
            Addon.P.mapping[playerID].specProfiles[i] = "Default"
        end
        --Addon.P.mapping[playerID] = "Default"
    end
    if Addon.P.profilesList == nil then
        Addon.P.profilesList = {}
    end
    if Addon.P.profilesList["Default"] == nil then
        Addon.P.profilesList["Default"] = { ["GlobalSettings"] = {} }
        self:AddProfileOrder("Default")
    end

    local specProfileEnabled = Addon.P.mapping[playerID].specEnabled
    local activeSpec = GetSpecialization()
    local mappedProfile = specProfileEnabled and Addon.P.mapping[playerID].specProfiles[activeSpec] or Addon.P.mapping[playerID].globalProfile
    if mappedProfile ~= "Default" then
        if Addon.P.profilesList[mappedProfile] == nil then
            Addon.P.mapping[playerID].globalProfile = "Default"
            Addon.P.mapping[playerID].specProfiles[activeSpec] = "Default"
        end
    end
    
    return specProfileEnabled and Addon.P.mapping[playerID].specProfiles[activeSpec] or Addon.P.mapping[playerID].globalProfile
end

function Addon.CompressData(data)
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return encoded
end

function Addon.DecompressData(data)
    local decoded = LibDeflate:DecodeForPrint(data)
    if not decoded then
        Addon.Print("Cant decode string")
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        Addon.Print("Cant decompress string")
    end
    local success, deserialized = LibSerialize:Deserialize(decompressed)

    if success then
        return deserialized
    end
    return Addon.Print("Cant deserialize string")
end

function ActionBarsEnhancedProfilesMixin:SelfTest()
    local profileName = self:GetPlayerProfile()
    local profile = Addon.P.profilesList[profileName]
    local exportTbl = CopyTable(profile)
    local encoded = Addon.CompressData(exportTbl)
    local decoded = Addon.DecompressData(encoded)
    
    if decoded then
        Addon.Print("SELF TEST GOOD")
    else
        Addon.Print("SELF TEST BAD")
    end
end

function ActionBarsEnhancedProfilesMixin:ExportProfile()
    local profileName = self:GetPlayerProfile()
    if Addon.P.profilesList[profileName] then
        local exportTbl = CopyTable(Addon.P.profilesList[profileName])

        local exportString = Addon.CompressData(exportTbl)

        if not ActionBarEnhancedExportProfile then
            local ExportProfile = CreateFrame("Frame", "ActionBarEnhancedExportProfile", ActionBarEnhancedProfilesFrame, "ActionBarsEnhancedExportDialog")
            ExportProfile:SetParent(ActionBarEnhancedProfilesFrame)
            ExportProfile:SetPoint("CENTER", ActionBarEnhancedProfilesFrame, "CENTER", 0, 0)
            ExportProfile.ExportControl.ExportContainer.EditBox:SetText(exportString)
            ExportProfile.ExportControl.ExportContainer.EditBox:HighlightText()
            ExportProfile.ExportControl.ExportContainer.EditBox:SetAutoFocus(true)
            ExportProfile:Show()
        else
            ActionBarEnhancedExportProfile.ExportControl.ExportContainer.EditBox:SetText(exportString)
            ActionBarEnhancedExportProfile.ExportControl.ExportContainer.EditBox:HighlightText()
            ActionBarEnhancedExportProfile.ExportControl.ExportContainer.EditBox:SetAutoFocus(true)
            ActionBarEnhancedExportProfile:Show()
        end
    end
end

function ActionBarsEnhancedImportDialogMixin:HasDefaultProfiles()
    if not Addon.P.profilesList then return false end
    
    local i = 0
    for profileName, data in pairs(DefaultProfiles) do
        i = i + 1
        if Addon.P.profilesList[profileName] then
            i = i - 1
        end
    end
    return i == 0
end

function ActionBarsEnhancedImportDialogMixin:AcceptImport(_, profileString, profileName, shouldSet, rewrite)
    if not profileString then
        profileString = ActionBarEnhancedImportProfile.ImportControl.InputContainer.EditBox:GetText()
    end
    if not profileName then
        profileName = ActionBarEnhancedImportProfile.NameControl.EditBox:GetText()
    end
    if profileString ~= "" and profileName ~= "" then
        if Addon.P.profilesList[profileName] ~= nil then
            if not rewrite then
                Addon.Print("Profile with this name already exists")
                return false
            else
                ActionBarsEnhancedProfilesMixin:DeleteProfile(profileName)
            end
        end
        if Addon.P.profilesList[profileName] == nil then            
            local profileTable = Addon.DecompressData(profileString)
            if profileTable then
                Addon.P.profilesList[profileName] = CopyTable(profileTable)
                if ActionBarEnhancedImportProfile and ActionBarEnhancedImportProfile:IsVisible() then
                    ActionBarEnhancedImportProfile:Hide()
                end

                ActionBarsEnhancedProfilesMixin:AddProfileOrder(profileName)

                if shouldSet then
                    ActionBarsEnhancedProfilesMixin:SetProfile(profileName, true)
                end
                return true
            end
        end
    end
end

function ActionBarsEnhancedProfilesMixin:ImportProfile()
    if not ActionBarEnhancedImportProfile then
        local ImportProfile = CreateFrame("Frame", "ActionBarEnhancedImportProfile", ActionBarEnhancedProfilesFrame, "ActionBarsEnhancedImportDialog")
        ImportProfile:SetParent(ActionBarEnhancedProfilesFrame)
        ImportProfile:SetPoint("CENTER", ActionBarEnhancedProfilesFrame, "CENTER", 0, 0)
    else
        ActionBarEnhancedImportProfile:Show()
    end
end

function ActionBarsEnhancedProfilesMixin:GetProfiles()
    local profileTbl = {}
    for index, profileName in ipairs(Addon.P.profilesOrder) do
        if Addon.P.profilesList[profileName] then
            table.insert(profileTbl, profileName)
        end
    end

    return profileTbl
end

function ABE_ImportProfile(profileName, profileString, shouldSet, rewrite)
    return ActionBarsEnhancedImportDialogMixin:AcceptImport(_, profileString, profileName, shouldSet, rewrite)
end

function ABE_GetProfiles()
    return ActionBarsEnhancedProfilesMixin:GetProfiles()
end

function Addon:GetCurrentProfileTable()
    local profileName = ActionBarsEnhancedProfilesMixin:GetPlayerProfile()
    local profileTable = Addon.P.profilesList[profileName]
    return profileTable
end

function ActionBarsEnhancedProfilesMixin:OnSpecChanged(profile)
    local playerID = Addon:GetPlayerID()
    local currentSpec = GetSpecialization()
    local isSpecEnabled = Addon.P.mapping[playerID].specEnabled
    
    if not isSpecEnabled then return end

    local specProfile = Addon.P.mapping[playerID].specProfiles[currentSpec]

    --print(profile, specProfile, specProfile ~= profile)

    if specProfile ~= profile then
        --print("Set specProfile: ", profile, specProfile)
        ActionBarsEnhancedProfilesMixin:SetProfile(specProfile, false)
        C_Timer.After(1.0, function()
            Addon:RefreshButtons()
            ABE_CastingBarMixin.SetLook(PlayerCastingBarFrame)
        end)
    end

end