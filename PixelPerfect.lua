local AddonName, Addon = ...

do
    local PP = {}
    Addon.PP = PP

    local ppEnabled = false

    function PP.SetEnabled(enabled)
        ppEnabled = enabled and true or false
    end

    function PP.IsEnabled()
        return ppEnabled
    end

    local function Nearest(x)
        return math.floor(x + 0.5)
    end

    local function Clean(x)
        return math.floor(x * 1000000 + 0.5) / 1000000
    end

    function PP.RefreshPhysical()
        local pw, ph = GetPhysicalScreenSize()
        if pw and pw > 0 and ph and ph > 0 then
            PP.physicalWidth, PP.physicalHeight = pw, ph
        elseif not PP.physicalHeight then
            PP.physicalWidth, PP.physicalHeight = 1920, 1080
        end
        PP.perfect = 768 / PP.physicalHeight
    end

    function PP.UpdateMult()
        PP.RefreshPhysical()
        local uiScale = UIParent and UIParent:GetScale() or 1
        PP.mult = PP.perfect / uiScale
    end
    PP.UpdateMult()

    function PP.Scale(x)
        if type(x) ~= "number" then return x end
        if not ppEnabled then return x end
        if x == 0 then return 0 end
        local m = PP.mult
        if m == 1 then return x end
        local px = x / m
        local whole = Nearest(px)
        if math.abs(px - whole) < 0.000001 then
            return Clean(whole * m)
        end
        return Clean((px > 0 and math.floor(px) or math.ceil(px)) * m)
    end

    function PP.Snap(x)
        if type(x) ~= "number" then return x end
        if not ppEnabled then return x end
        if x == 0 then return 0 end
        local m = PP.mult
        if m == 1 then return Clean(x) end
        return Clean(Nearest(x / m) * m)
    end

    function PP.ToPixels(coord)
        if coord == 0 then return 0 end
        if not ppEnabled then return coord end
        return Nearest(coord / PP.mult)
    end

    function PP.FromPixels(px)
        if px == 0 then return 0 end
        if not ppEnabled then return px end
        return Clean(px * PP.mult)
    end

    function PP.SnapForES(x, es)
        if x == 0 then return 0 end
        if not ppEnabled then return x end
        local onePixel = PP.perfect / es
        return Clean(Nearest(x / onePixel) * onePixel)
    end

    function PP.SnapCenterForDim(value, dim, es)
        if value == nil then return value end
        if not ppEnabled then return value end
        es = es or (UIParent and UIParent:GetEffectiveScale() or 1)
        local onePixel = PP.perfect / es
        local dimPx = 0
        if dim and dim > 0 then
            dimPx = Nearest(dim / onePixel)
        end
        local px
        if dimPx % 2 == 1 then
            px = Nearest(value / onePixel - 0.5) + 0.5
        else
            px = Nearest(value / onePixel)
        end
        return Clean(px * onePixel)
    end

    local function IsGuarded(frame)
        if not InCombatLockdown() then return false end
        if frame.CanChangeProtectedState then
            return not frame:CanChangeProtectedState()
        end
        if frame.IsProtected then
            return frame:IsProtected()
        end
        return false
    end

    local function ScaleDim(x)
        local s = PP.Scale(x)
        if type(x) == "number" and x > 0 and s == 0 then
            return PP.mult
        end
        return s
    end

    function PP.Size(frame, w, h)
        if IsGuarded(frame) then return end
        if not ppEnabled then
            frame:SetSize(w, h or w)
            return
        end
        frame:SetSize(ScaleDim(w), h and ScaleDim(h) or ScaleDim(w))
    end

    function PP.Width(frame, w)
        if IsGuarded(frame) then return end
        if not ppEnabled then
            frame:SetWidth(w)
            return
        end
        frame:SetWidth(ScaleDim(w))
    end

    function PP.Height(frame, h)
        if IsGuarded(frame) then return end
        if not ppEnabled then
            frame:SetHeight(h)
            return
        end
        frame:SetHeight(ScaleDim(h))
    end

    function PP.Point(obj, anchor, p1, p2, p3, p4)
        if IsGuarded(obj) then return end
        if not p1 then p1 = obj:GetParent() end
        if not ppEnabled then
            obj:SetPoint(anchor, p1, p2, p3, p4)
            return
        end
        if type(p1) == "number" then p1 = PP.Scale(p1) end
        if type(p2) == "number" then p2 = PP.Scale(p2) end
        if type(p3) == "number" then p3 = PP.Scale(p3) end
        if type(p4) == "number" then p4 = PP.Scale(p4) end
        obj:SetPoint(anchor, p1, p2, p3, p4)
    end

    local _pixelSnapDisabled = setmetatable({}, { __mode = "k" })

    function PP.DisablePixelSnap(obj)
        if not ppEnabled then return end
        if not obj then return end
        if issecretvalue and issecretvalue(obj) then return end
        if issecrettable and issecrettable(obj) then return end
        if _pixelSnapDisabled[obj] then return end
        if obj.IsForbidden and obj:IsForbidden() then return end

        local target = obj
        if not obj.SetSnapToPixelGrid and obj.GetStatusBarTexture then
            target = obj:GetStatusBarTexture()
            if type(target) ~= "table" or not target.SetSnapToPixelGrid then
                _pixelSnapDisabled[obj] = true
                return
            end
        end

        if target.SetSnapToPixelGrid then
            target:SetSnapToPixelGrid(false)
            target:SetTexelSnappingBias(0)
        end
        _pixelSnapDisabled[obj] = true
    end

    function PP.RegisterEvents()
        if PP.eventsRegistered then return end
        PP.eventsRegistered = true

        Addon:RegisterEvent("UI_SCALE_CHANGED", function()
            PP.UpdateMult()
        end, "PixelPerfect")

        Addon:RegisterEvent("DISPLAY_SIZE_CHANGED", function()
            PP.UpdateMult()
        end, "PixelPerfect")
    end
end

function Addon:InitPP()
    self.PP.RegisterEvents()
    self.PP.UpdateMult()
    self.PP.SetEnabled(self:GetValue("UsePixelPerfect"))
end
