if isClient() then return end

require "Map/SGlobalObject"

SRefuelGlobalObject = SGlobalObject:derive("SRefuelGlobalObject")

function SRefuelGlobalObject:new(luaSystem, globalObject)
	local o = SGlobalObject.new(self, luaSystem, globalObject)
	return o
end

function SRefuelGlobalObject:initNew(generator, barrel)
    print("s init new global object")
	self.barrelX = barrel.isoObject:getX()
    self.barrelY = barrel.isoObject:getY()
    self.generator = generator
end

-- load data from object?
--function SRefuelGlobalObject:stateFromIsoObject(isoObject)
--    self.generator = isoObject
--	self:fromModData(isoObject:getModData())
	--self:processContainerItems()
	--self:changeFireLvl()
--end
-- and save data to object?
--function SRefuelGlobalObject:stateToIsoObject(isoObject)
	--self.generator = isoObject
	--self:toModData(isoObject:getModData())
	--self:processContainerItems()
	--self:changeFireLvl()
--end

--function SRefuelGlobalObject:fromModData(modData)
	--self.barrelX = modData.barrelX
	--self.barrelY = modData.barrelY
--end
function SRefuelGlobalObject:toModData(modData)
	modData.barrelX = self.barrelX
	modData.barrelY = self.barrelY
end
function SRefuelGlobalObject:saveData()
    self:noise('save object modData for generator '..self.x..','..self.y..','..self.z .. " to " .. tostring(self.getIsoObject()))
	local isoObject = self:getIsoObject()
	if isoObject then
		self:toModData(isoObject:getModData())
	end
end

function SRefuelGlobalObject:getObject()
	return self:getIsoObject()
end

function SRefuelGlobalObject:removeObject()
	print("s remove global object")
end

function SRefuelGlobalObject:refuelGenerator()
    print("refuel generator: " .. tostring(self.generator))
end