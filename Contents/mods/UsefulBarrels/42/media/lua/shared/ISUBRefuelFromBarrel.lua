--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISUBRefuelFromBarrel = ISBaseTimedAction:derive("ISUBRefuelFromBarrel")

function ISUBRefuelFromBarrel:isValid()
	return self.vehicle:isInArea(self.part:getArea(), self.character)
end

function ISUBRefuelFromBarrel:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISUBRefuelFromBarrel:update()
	local litres = self.tankStart + (self.tankTarget - self.tankStart) * self:getJobDelta()
	litres = math.floor(litres)
	if litres ~= self.amountSent then
        if self.vehicle then
            if not self.part then
                print('no such part ',self.part)
                return
            end
            self.part:setContainerContentAmount(litres)
            self.vehicle:transmitPartModData(self.part)
        else
            print('no such vehicle id=', self.vehicle)
        end
		self.amountSent = litres
	end
--[[
	if isClient() then
		if math.floor(litres) ~= self.amountSent then
			local args = { vehicle = self.vehicle:getId(), part = self.part:getId(), amount = litres }
			sendClientCommand(self.character, 'vehicle', 'setContainerContentAmount', args)
			self.amountSent = math.floor(litres)
		end
	else
		self.part:setContainerContentAmount(litres)
	end
--]]
	local pumpUnits = self.pumpStart + (self.pumpTarget - self.pumpStart) * self:getJobDelta()
	pumpUnits = math.ceil(pumpUnits)
	self.fuelStation:setPipedFuelAmount(pumpUnits);

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISUBRefuelFromBarrel:start()
	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)

	self.character:reportEvent("EventTakeWater");

	self.sound = self.character:playSound("VehicleAddFuelFromGasPump")
end

function ISUBRefuelFromBarrel:stop()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.stop(self)
end

function ISUBRefuelFromBarrel:serverStop()
    local pumpUnits = self.pumpStart + (self.pumpTarget - self.pumpStart) * self.netAction:getProgress()
    self.fuelStation:setPipedFuelAmount(math.ceil(pumpUnits));
    local litres = self.tankStart + (self.tankTarget - self.tankStart) * self.netAction:getProgress()
    self.part:setContainerContentAmount(math.floor(litres))
    self.vehicle:transmitPartModData(self.part)
end

function ISUBRefuelFromBarrel:perform()
	self.character:stopOrTriggerSound(self.sound)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISUBRefuelFromBarrel:complete()
    if self.vehicle then
        if not self.part then
            print('no such part ',self.part)
            return false
        end
        self.part:setContainerContentAmount(self.tankTarget)
        self.vehicle:transmitPartModData(self.part)
    else
        print('no such vehicle id=', self.vehicle)
    end
	return true
end

function ISUBRefuelFromBarrel:getDuration()
    self.tankStart = self.part:getContainerContentAmount()
	self.pumpStart = self.fuelFluidContainer:getAmount()

	--local pumpLitresAvail = self.pumpStart * (Vehicles.JerryCanLitres / 8)
	local tankLitresFree = self.part:getContainerCapacity() - self.tankStart
	local takeLitres = math.min(tankLitresFree, self.pumpStart)
	self.tankTarget = self.tankStart + takeLitres
	self.pumpTarget = self.pumpStart - takeLitres
	self.amountSent = self.tankStart

	return takeLitres * 50
end

function ISUBRefuelFromBarrel:new(character, part, barrel)
	local o = ISBaseTimedAction.new(self, character)
	o.vehicle = part:getVehicle()
	o.part = part
	o.fuelFluidContainer = barrel:getFluidContainer()
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = o:getDuration()
	return o
end

