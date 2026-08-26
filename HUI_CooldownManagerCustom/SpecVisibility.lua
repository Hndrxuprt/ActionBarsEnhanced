local Addon = _G.HUI

function Addon:CDMSpecMatches(frameTbl, classFile, specID)
	if not frameTbl then return true end
	local specs = frameTbl.visibleSpecs
	if not specs or next(specs) == nil then
		return true
	end
	return specs[specID] == true
end

function Addon:CDMGetClassSpecOptions()
	local options = {}
	for i = 1, GetNumClasses() do
		local className, classFile, classID = GetClassInfo(i)
		if classFile and classID then
			local specs = {}
			local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
			for specIndex = 1, numSpecs do
				local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
				if specID and specName then
					tinsert(specs, { specID = specID, specName = specName })
				end
			end
			tinsert(options, {
				classFile = classFile,
				classID = classID,
				className = className,
				specs = specs,
			})
		end
	end
	return options
end

function Addon:CDMGetPlayerClassSpec()
	local _, classFile = UnitClass("player")
	local specIndex = GetSpecialization()
	local specID
	if specIndex then
		specID = GetSpecializationInfo(specIndex)
	end
	return classFile, specID
end