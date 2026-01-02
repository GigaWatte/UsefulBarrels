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
	--self:noise("SRefuelGlobalObject:initNew" .. tostring(generator))
	self.barrelX = ub_barrel.isoObject:getX()
    self.barrelY = ub_barrel.isoObject:getY()
	self.barrelZ = ub_barrel.isoObject:getZ()

	self.ub_barrel = ub_barrel
    self.generator = generator
end

-- restore global object data from isoobject moddata
function SRefuelGlobalObject:stateFromIsoObject(isoObject)
	--self:noise("SRefuelGlobalObject:stateFromIsoObject: " .. tostring(isoObject))
    self.generator = isoObject
	self:fromModData(isoObject:getModData())
	self.ub_barrel = UBUtils.GetBarrelAtCoords(self.barrelX, self.barrelY, self.barrelZ)
end

function SRefuelGlobalObject:stateToIsoObject(isoObject)
	--self:noise("SRefuelGlobalObject:stateToIsoObject: " .. tostring(isoObject))
	self.generator = isoObject
	self:toModData(isoObject:getModData())
	self.ub_barrel = UBUtils.GetBarrelAtCoords(self.barrelX, self.barrelY, self.barrelZ)
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
    --self:noise("save object modData for generator: "..self.x..','..self.y..','..self.z .. " to " .. tostring(self.generator))
	local isoObject = self.generator
	if isoObject then
		self:toModData(isoObject:getModData())
	end
end

function SRefuelGlobalObject:aboutToRemoveFromSystem()
	--self:noise("about to remove luaObject: " ..self.x..','..self.y..','..self.z .. " to " .. tostring(self.generator))
	local isoObject = self.generator
	if isoObject then
		local modData = isoObject:getModData()
		modData.barrelX = nil
		modData.barrelY = nil
		modData.barrelZ = nil
		isoObject:setModData(modData)
	end
end

function SRefuelGlobalObject:checkRefuelGenerator()
	if not self.generator then self:noise("no generator");return end
	if not UBUtils.GetBarrelAtCoords(self.barrelX, self.barrelY, self.barrelZ) then self.noise("barrel is missing"); return end

	local startGeneratorFuel = self.generator:getFuel()

	if (startGeneratorFuel > 90) then self:noise("fuel is above 90");return end
	if not self.ub_barrel then self:noise("no barrel");return end
    if self.ub_barrel.Type ~= UBFluidBarrel.Type then self:noise("not a fluid barrel");return end
	if not self.ub_barrel:ContainsFluid(Fluid.Petrol) then self:noise("no petrol in barrel");return end

	local fuelAmount = self.ub_barrel:getAmount()

	if not (self.ub_barrel:getAmount() >= 1.0) then self:noise("amount in barrel lower than 1");return end
	
    local amount = fuelAmount - 1.0
    self.ub_barrel:adjustAmount(amount)

    self.generator:setFuel(startGeneratorFuel + 10)
    self.generator:sync()

    self:noise("generator refueled: " .. startGeneratorFuel .. " -> " .. self.generator:getFuel())
	self:noise("barrel updated: " .. fuelAmount .. " -> " .. self.ub_barrel:getAmount())
end