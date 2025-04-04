require "TimedActions/ISBaseTimedAction"

ISUBSiphonFromVehicle = ISBaseTimedAction:derive("ISUBSiphonFromVehicle")

function ISUBSiphonFromVehicle:isValid()
	return self.vehicle:isInArea(self.part:getArea(), self.character)
end

function ISUBSiphonFromVehicle:waitToStart()
	self.character:faceThisObject(self.barrel.isoObject)
	return self.character:shouldBeTurning()
end

function ISUBSiphonFromVehicle:update()
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

	local barrelUnits = self.barrelStart + (self.barrelTarget - self.barrelStart) * self:getJobDelta()
	self.fuelFluidContainer:adjustAmount(math.ceil(barrelUnits));

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISUBSiphonFromVehicle:start()
	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)

	self.character:reportEvent("EventTakeWater");

	self.sound = self.character:playSound("VehicleAddFuelFromGasPump")
end

function ISUBSiphonFromVehicle:stop()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.stop(self)
end

function ISUBSiphonFromVehicle:serverStop()
    local barrelLitres = self.barrelStart + (self.barrelTarget - self.barrelStart) * self.netAction:getProgress()
    self.fuelFluidContainer:adjustAmount(math.ceil(barrelLitres));
    local litres = self.tankStart + (self.tankTarget - self.tankStart) * self.netAction:getProgress()
    self.part:setContainerContentAmount(math.floor(litres))
    self.vehicle:transmitPartModData(self.part)
end

function ISUBSiphonFromVehicle:perform()
	self.character:stopOrTriggerSound(self.sound)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISUBSiphonFromVehicle:complete()
    if self.vehicle then
        if not self.part then
            print('no such part ',self.part)
            return false
        end
        self.part:setContainerContentAmount(self.tankTarget)
		self.fuelFluidContainer.setAmount(self.barrelTarget)
        self.vehicle:transmitPartModData(self.part)
    else
        print('no such vehicle id=', self.vehicle)
    end
	return true
end

function ISUBSiphonFromVehicle:getDuration()
    self.tankStart = self.part:getContainerContentAmount()
	self.barrelStart = self.fuelFluidContainer:getAmount()

	local barrelFreeSpace = self.fuelFluidContainer:getCapacity() - self.barrelStart
	local amountToTransfer = math.min(self.tankStart, barrelFreeSpace)

	self.tankTarget = self.tankStart - amountToTransfer
	self.barrelTarget = self.barrelStart + amountToTransfer
	self.amountSent = self.barrelStart

	return amountToTransfer * 50
end

function ISUBSiphonFromVehicle:new(character, part, barrel)
	local o = ISBaseTimedAction.new(self, character)
	o.vehicle = part:getVehicle()
	o.part = part
	o.fuelFluidContainer = barrel.fluidContainer
	o.barrel = barrel
	--o.stopOnWalk = false
	--o.stopOnRun = false
	o.maxTime = o:getDuration()
	return o
end

