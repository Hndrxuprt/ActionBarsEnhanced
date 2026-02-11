local AddonName, Addon = ...

local function EstimateCastDuration(castBar, pip, callback)
    if not castBar or not pip then
        callback(0)
        return
    end

    local barLeft = castBar:GetLeft()
    local barRight = castBar:GetRight()
    local pipStart = pip:GetCenter()

    local barWidth = barRight - barLeft

    local pipRel = pipStart - barLeft

    local delay = 0.05

    C_Timer.After(delay, function()

        local pipNow = pip:GetCenter()
        local pipNowRel = pipNow - barLeft
        local delta = math.abs(pipNowRel - pipRel)

        local speed = delta / delay
        local estimatedTotal = barWidth / speed

        if estimatedTotal < 0.1 then estimatedTotal = 0.1 end
        if estimatedTotal > 10 then estimatedTotal = 10 end

        callback(estimatedTotal)
    end)
end

local function Hook_UpdateShownState(self, state)
    if not state then return end
    local frameName = self:GetName()

    if self.ChannelShadow then
        self.ChannelShadow:Hide()
    end

    local barType = self.__barType or {}

    --[[ if self.barType == "empowered" then
        self.__latencyBar:Hide()
        self.__sqwBar:Hide()
        return
    end ]]
    --local timeDiff = GetTime() - sendTime

    local _, _, latencyHome, latencyWorld = GetNetStats()
    local latency = latencyHome > latencyWorld and latencyHome or latencyWorld
    if not latency then return end

    local point = self.channeling and "LEFT" or "RIGHT"
    local strata = self.channeling and "OVERLAY" or "OVERLAY"

    if Addon:GetValue("CastBarShowSQW", nil, frameName) then
        self.__sqwBar:ClearAllPoints()
        self.__sqwBar:SetPoint(point, self.Background, point)
        self.__sqwBar:SetDrawLayer(strata, 2)

        Addon:SetTexture(self.__sqwBar, Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCastBarSQWTexture", nil, frameName)))
        local r, g, b, a = Addon:GetRGBA("CastBarSQWColor", nil, frameName)
        self.__sqwBar:SetVertexColor(r, g, b, a)

        self.__sqwBar:SetWidth(math.min((self:GetWidth() * (self.__sqw / self.maxValue)), self:GetWidth()))
        self.__sqwBar:SetHeight(self:GetHeight())
        self.__sqwBar:Show()

        self.__sqwBar:SetAlphaFromBoolean(barType.empowered, 0, a)
    else
        self.__sqwBar:Hide()
    end

    if Addon:GetValue("CastBarShowLatency", nil, frameName) then
        self.__latencyBar:ClearAllPoints()
        self.__latencyBar:SetPoint(point, self.Background, point)
        self.__latencyBar:SetDrawLayer(strata, 3)

        Addon:SetTexture(self.__latencyBar, Addon:GetStatusBarTextureByName(Addon:GetValue("CurrentCastBarLatencyTexture", nil, frameName)))
        local r, g, b, a = Addon:GetRGBA("CastBarLatencyColor", nil, frameName)
        self.__latencyBar:SetVertexColor(r, g, b, a)

        self.__latencyBar:SetWidth(math.min((self:GetWidth() * (latency / 1000) / self.maxValue), self:GetWidth()))
        self.__latencyBar:SetHeight(self:GetHeight())
        self.__latencyBar:Show()

        self.__latencyBar:SetAlphaFromBoolean(barType.empowered, 0, a)
    else
        self.__latencyBar:Hide()
    end

    --[[ C_Timer.After(0, function()
        EstimateCastDuration(self, self.Spark, function(castDuration)
            
            
            self.__latencyBar:SetWidth(self:GetWidth() * (latency / 1000) / castDuration)
            self.__latencyBar:SetHeight(self:GetHeight())
            self.__latencyBar:Show()

            self.__sqwBar:SetWidth(self:GetWidth() * (self.__sqw / castDuration))
            self.__sqwBar:SetHeight(self:GetHeight())
            self.__sqwBar:Show()
        end)
    end) ]]
end

local function ProcessEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if PlayerCastingBarFrame and Addon:GetValue("CastBarEnable", nil, "PlayerCastingBarFrame") then
            if PlayerCastingBarFrame.UpdateShownState then
                hooksecurefunc(PlayerCastingBarFrame, "UpdateShownState", Hook_UpdateShownState)
            end
            ABE_CastingBarMixin.SetHooks(PlayerCastingBarFrame)
        end
    end
end

local eventHandlerFrame = CreateFrame('Frame')
eventHandlerFrame:SetScript('OnEvent', ProcessEvent)
eventHandlerFrame:RegisterEvent('PLAYER_LOGIN')