require "Map/CGlobalObject"

CRefuelGlobalObject = CGlobalObject:derive("CRefuelGlobalObject")

function CRefuelGlobalObject:new(luaSystem, globalObject)
	local o = CGlobalObject.new(self, luaSystem, globalObject)
	return o
end

function CRefuelGlobalObject:getObject()
	return self:getIsoObject()
end
