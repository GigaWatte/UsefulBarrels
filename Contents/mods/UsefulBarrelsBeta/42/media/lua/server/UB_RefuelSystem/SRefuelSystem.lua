if isClient() then return end

require "Map/SGlobalObjectSystem"

local UBUtils = require("UBUtils")

SRefuelSystem = SGlobalObjectSystem:derive("SRefuelSystem")

function SRefuelSystem:new()
	local o = SGlobalObjectSystem.new(self, "UB_Refuel")
	return o
end

function SRefuelSystem:initSystem()
	SGlobalObjectSystem.initSystem(self)

	-- Specify GlobalObjectSystem fields that should be saved.
	self.system:setModDataKeys(nil)
	
	-- Specify GlobalObject fields that should be saved.
	self.system:setObjectModDataKeys({'barrelX', 'barrelY', 'barrelZ'})

	self:noise("SRefuelSystem initialized")
end

function SRefuelSystem:newLuaObject(globalObject)
	return SRefuelGlobalObject:new(self, globalObject)
end

function SRefuelSystem:isValidModData(modData)
	return modData ~= nil and modData.barrelX ~= nil and modData.barrelY ~= nil and modData.barrelZ ~= nil
end

function SRefuelSystem:isValidIsoObject(isoObject)
	return isoObject and instanceof(isoObject, "IsoGenerator")
end

function SRefuelSystem.bindGeneratorToBarrel(generator, barrel, playerObj, hose)
    local luaObject = SRefuelSystem.instance:newLuaObjectOnSquare(generator:getSquare())
    luaObject:initNew(generator, barrel)
	luaObject:saveData()

	UBUtils.RemoveItem(hose, playerObj)
end

function SRefuelSystem.unbindGeneratorFromBarrel(generator, playerObj)
    local luaObject = SRefuelSystem.instance:getLuaObjectOnSquare(generator:getSquare())
    if luaObject then
		SRefuelSystem.instance:removeLuaObject(luaObject)

		local inv = playerObj:getInventory()
		inv:SpawnItem("Base.RubberHose")
	end
end

function SRefuelSystem:OnClientCommand(command, playerObj, args)
	SRefuelSystemCommand(command, playerObj, args)
end

function SRefuelSystem:OnObjectAboutToBeRemoved(isoObject)
	SGlobalObjectSystem.OnObjectAboutToBeRemoved(self, isoObject)
	UBUtils.AddItemToSquare(isoObject:getSquare(), "Base.RubberHose")
end

SGlobalObjectSystem.RegisterSystemClass(SRefuelSystem)

function SRefuelSystem:refuelGenerators()
	--self:noise("every minute: check generators for refuel")
    for i=1,self:getLuaObjectCount() do
		--self:noise("checking object #"..i)
		local luaObject = self:getLuaObjectByIndex(i)
		luaObject:checkRefuelGenerator()
	end
end

local function EveryOneMinute()
	if SRefuelSystem.instance then
		SRefuelSystem.instance:refuelGenerators()
	end
end

Events.EveryOneMinute.Add(EveryOneMinute)
