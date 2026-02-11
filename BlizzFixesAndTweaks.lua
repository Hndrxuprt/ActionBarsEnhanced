local AddonName, Addon = ...

local L = Addon.L

local lib = LibStub("LibEditModeOverride-1.0")

local framesToReanchor = {}

local function ReanchorFrame(self)
    if not self:CanChangeProtectedState() then return end

    local layoutFramesGoingRight
    if self.__layoutFramesGoingRight ~= nil then
        layoutFramesGoingRight = self.__layoutFramesGoingRight == 1
    else
        layoutFramesGoingRight = self.layoutFramesGoingRight
    end
    local layoutFramesGoingUp
    if self.__layoutFramesGoingUp ~= nil then
        layoutFramesGoingUp = self.__layoutFramesGoingUp == 1
    else
        layoutFramesGoingUp = self.layoutFramesGoingUp
    end

    local isCentered = false
    if self.gridLayoutType then
        isCentered = self.gridLayoutType == 1
    end

    local isHorizontal = self.isHorizontal

    local screenCenterX, screenCenterY = UIParent:GetCenter()
    local pointX, pointY

    local point = "CENTER"

    if not isHorizontal then
        if isCentered then
            if layoutFramesGoingRight then
                point = "LEFT"
            else
                point = "RIGHT"
            end
        else
            if layoutFramesGoingUp then
                point = "BOTTOM"
            else
                point = "TOP"
            end
        end
    else
        if isCentered then
            if layoutFramesGoingUp then
                point = "BOTTOM"
            else
                point = "TOP"
            end
        else
            if layoutFramesGoingRight then
                point = "LEFT"
                
            else
                point = "RIGHT"
            end
        end
    end
    if point == "BOTTOM" then
        pointX = self:GetCenter()
        pointY = self:GetBottom()
    elseif point == "TOP" then
        pointX = self:GetCenter()
        pointY = self:GetTop()
    elseif point == "LEFT" then
        pointX = self:GetLeft()
        pointY = (self:GetTop() + self:GetBottom()) / 2
    elseif point == "RIGHT" then
        pointX = self:GetRight()
        pointY = (self:GetTop() + self:GetBottom()) / 2
    end

    local offsetX = pointX - screenCenterX
    local offsetY = pointY - screenCenterY

    local frameName = self:GetName()

    framesToReanchor[frameName] = {
        point = point,
        offsetX = offsetX,
        offsetY = offsetY,
    }

    local framePoint = self:GetPoint(1)
    self.__anchorIcon:SetPoint("CENTER", self, point, 0, 0)
    if framePoint == point then
        self.__ANCHOR_MESSAGE = L.AnchorPosOK
        self.__anchorIcon:SetVertexColor(0.2,0.98,0.2,1)
    else
        self.__ANCHOR_MESSAGE = L.AnchorPosUNSAVED
        self.__anchorIcon:SetVertexColor(0.98,0.2,0.2,1)
    end

end

local function Hook_OnSystemPositionChange(self)
    local _, parent = self:GetPoint(1)
    local parentName = parent:GetName()
    if framesToReanchor[self:GetName()] then
        framesToReanchor[self:GetName()] = nil
    end
    
    if parentName ~= "UIParent" then
        self.__ANCHOR_MESSAGE = L.AnchorPosAttached..parentName
        self.__anchorIcon:SetVertexColor(0.98,0.98,0.2,1)
        return
    end
    ReanchorFrame(self)
end

local function ShowAnchorIcon(self)
    self.__ANCHOR_MESSAGE = L.AnchorPosOK

    if not self.__anchorIcon then
        self.__anchorIcon = self.Selection:CreateTexture(nil, "OVERLAY", nil, 7)
        self.__anchorIcon:SetAtlas("VignetteEvent-SuperTracked", false)
        self.__anchorIcon:SetSize(25,25)
        self.__anchorIcon:SetDesaturated(true)
        self.__anchorIcon:SetMouseClickEnabled(false)

        self.__anchorIcon:SetScript("OnEnter", function(icon)
            GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
            GameTooltip_AddColoredLine(GameTooltip, self.__ANCHOR_MESSAGE, LIGHTYELLOW_FONT_COLOR)
            GameTooltip:SetScale(0.82)
            GameTooltip:Show()
        end)
        self.__anchorIcon:SetScript("OnLeave",function(icon)
            GameTooltip:Hide()
        end)
    end
    local framePoint = self:GetPoint(1)
    self.__anchorIcon:SetPoint("CENTER", self, framePoint, 0, 0)
    self.__anchorIcon:SetVertexColor(1,1,1,0.5)
    self.__anchorIcon:Show()
end

local function OnEditModeEnter()
    if EditModeManagerFrame.registeredSystemFrames then
        for index, systemFrame in ipairs(EditModeManagerFrame.registeredSystemFrames) do
            local frameName = systemFrame:GetName()
            if tContains(Addon.CDMFrames, frameName) then
                ShowAnchorIcon(systemFrame)
                if systemFrame.OnSystemPositionChange and not systemFrame.__OnSystemPositionChangeHooked then
                    hooksecurefunc(systemFrame, "OnSystemPositionChange", Hook_OnSystemPositionChange)
                    systemFrame.__OnSystemPositionChangeHooked = true
                end
            end
        end
    end
end

local function OnEditModeExit()
    if InCombatLockdown() then return end
    local shouldApply = false
    lib:LoadLayouts()
    for frameName, data in pairs(framesToReanchor) do
        local frame = _G[frameName]
        if frame then
            lib:ReanchorFrame(frame, data.point, UIParent, "CENTER", data.offsetX, data.offsetY)
            framesToReanchor[frameName] = nil
            shouldApply = true
        end
    end
    if shouldApply then
        lib:ApplyChanges()
    end
end

local function ProcessEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:AddDynamicEventMethod(EventRegistry, "EditMode.Enter", OnEditModeEnter)
        self:AddDynamicEventMethod(EventRegistry, "EditMode.Exit", OnEditModeExit)
    end
end

local eventHandlerFrame = CreateFrame('Frame', nil, nil, "CallbackRegistrantTemplate")
eventHandlerFrame:SetScript('OnEvent', ProcessEvent)
eventHandlerFrame:RegisterEvent('PLAYER_LOGIN')