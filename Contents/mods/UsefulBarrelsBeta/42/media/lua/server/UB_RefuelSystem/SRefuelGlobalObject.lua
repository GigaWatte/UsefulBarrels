if isClient() then return end

require "Map/SGlobalObject"

local UBUtils = require("UBUtils")
local UBFluidBarrel = require("UBFluidBarrel")

SRefuelGlobalObject = SGlobalObject:derive("SRefuelGlobalObject")

function SRefuelGlobalObject:new(luaSystem, globalObject)
	local o = SGlobalObject.new(self, luaSystem, globalObject)
	return o
end

function SRefuelGlobalObject:initNew(generator, ub_barrel)
	self.barrelX = barrel.isoObject:getX()
    self.barrelY = barrel.isoObject:getY()
	self.barrelZ = barrel.isoObject:getZ()

	self.ub_barrel = ub_barrel
    self.generator = generator
end

-- restore global object data from isoobject moddata
function SRefuelGlobalObject:stateFromIsoObject(isoObject)
    self.generator = isoObject
	self:fromModData(isoObject:getModData())

	local barrelSquare = getCell():getGridSquare(self.barrelX, self.barrelY, self.barrelZ)
	local barrels = UBUtils.GetBarrelsNearby(barrelSquare, 1)
	self.ub_barrel = barrels[1] or nil
end

	--self:processContainerItems()
	--self:changeFireLvl()
end
-- save state to mod data
function SRefuelGlobalObject:stateToIsoObject(isoObject)
	self.generator = isoObject
	self:toModData(isoObject:getModData())
	--self:processContainerItems()
	--self:changeFireLvl()
end

function SRefuelGlobalObject:fromModData(modData)
	self.barrelX = modData.barrelX
	self.barrelY = modData.barrelY
	self.barrelZ = modData.barrelZ
end
function SRefuelGlobalObject:toModData(modData)
	modData.barrelX = self.barrelX
	modData.barrelY = self.barrelY
	modData.barrelZ = self.barrelZ
end
function SRefuelGlobalObject:saveData()
    --self:noise('save object modData for generator '..self.x..','..self.y..','..self.z .. " to " .. tostring(self.getIsoObject()))
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

function SRefuelGlobalObject:checkRefuelGenerator()
	local startGeneratorFuel = self.generator:getFuel()

	if startGeneratorFuel > 90 then return end
	print("generator fuel is low than 90")
	if not self.ub_barrel then return end
	print("no barrel found")
    if self.ub_barrel.Type ~= UBFluidBarrel.Type then return end
	print("barrel is fluid type")
	if not self.ub_barrel:ContainsFluid(Fluid.Petrol) then return end
	print("barrel contains petrol")
	if not self.barrel:getAmount() >= 1.0 then return end
	
    local amount = self.barrel:getAmount() - 1.0
    self.barrel:adjustAmount(amount)

    self.generator:setFuel(startGeneratorFuel + 10)
    self.generator:sync()
	
    print("generator refueled: " .. startGeneratorFuel .. " -> " .. self.generator:getFuel())
end