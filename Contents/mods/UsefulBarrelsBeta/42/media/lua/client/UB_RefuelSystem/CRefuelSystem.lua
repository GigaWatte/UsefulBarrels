require "Map/CGlobalObjectSystem"

CRefuelSystem = CGlobalObjectSystem:derive("CRefuelSystem")

function CRefuelSystem:new()
	local o = CGlobalObjectSystem.new(self, "UB_Refuel")
	return o
end

function CRefuelSystem:isValidIsoObject(isoObject)
	return instanceof(isoObject, "IsoObject") --validate ubbarrel
end

function CRefuelSystem:newLuaObject(globalObject)
	return CRefuelGlobalObject:new(self, globalObject)
end

CGlobalObjectSystem.RegisterSystemClass(CRefuelSystem)
