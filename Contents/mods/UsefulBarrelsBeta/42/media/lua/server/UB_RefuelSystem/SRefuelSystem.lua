if isClient() then return end

require "Map/SGlobalObjectSystem"

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
	self.system:setObjectModDataKeys({'barrelX', 'barrelY'})
end

function SRefuelSystem:newLuaObject(globalObject)
	return SRefuelGlobalObject:new(self, globalObject)
end

function SRefuelSystem:isValidModData(modData)
	return modData ~= nil --and modData.fuelAmt ~= nil
end

-- when looking for iso object at square - but there may be multiple generators!
-- TODO rely on id to work with generator
function SRefuelSystem:isValidIsoObject(isoObject)
	return isoObject and instanceof(isoObject, "IsoGenerator")
end

function SRefuelSystem:bindGeneratorToBarrel(generator, barrel, playerObj, hose)
    local luaObject = SRefuelSystem.instance:newLuaObjectOnSquare(generator:getSquare())
    luaObject:initNew(generator, barrel)
    -- TODO remove hose from player or world
    --luaObject:addContainer()
    --luaObject:saveData()
end

function SRefuelSystem:unbindGeneratorFromBarrel(generator, barrel, playerObj)
    local luaObject = SRefuelSystem.instance:getLuaObjectOnSquare(generator:getSquare())
    if luaObject then
-- 		noise('removing luaObject at same location as newly-loaded isoObject')
		SRefuelSystem.instance:removeLuaObject(luaObject)
        -- TODO clean moddata?
	end
end

function SRefuelSystem:OnClientCommand(command, playerObj, args)
	SRefuelSystemCommand(command, playerObj, args)
end

SGlobalObjectSystem.RegisterSystemClass(SRefuelSystem)

function SRefuelSystem:refuelGenerators()
    print("s every one min - refuel generators")
    for i=1,self:getLuaObjectCount() do
		local luaObject = self:getLuaObjectByIndex(i)
        --luaObject:refuelGenerator()
	end
end

local function EveryOneMinute()
	SRefuelSystem.instance:refuelGenerators()
end

Events.EveryOneMinute.Add(EveryOneMinute)
