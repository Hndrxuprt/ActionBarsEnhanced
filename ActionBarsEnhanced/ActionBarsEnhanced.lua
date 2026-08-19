local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= "ActionBarsEnhanced" then return end
    frame:UnregisterAllEvents()
end)