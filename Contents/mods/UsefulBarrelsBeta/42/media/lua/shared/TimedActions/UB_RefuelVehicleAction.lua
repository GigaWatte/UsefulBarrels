require "TimedActions/ISBaseTimedAction"

UB_RefuelVehicleAction = ISBaseTimedAction:derive("UB_RefuelVehicleAction")

function UB_RefuelVehicleAction:isValid()
	return self.vehicle:isInArea(self.part:getArea(), self.character)
end

function UB_RefuelVehicleAction:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function UB_RefuelVehicleAction:update()
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

function UB_RefuelVehicleAction:start()
	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)

	self.character:reportEvent("EventTakeWater");

	self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_RefuelVehicleAction:stop()
	self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.stop(self)
end

function UB_RefuelVehicleAction:serverStop()
    local barrelLitres = self.barrelStart + (self.barrelTarget - self.barrelStart) * self.netAction:getProgress()
    self.fuelFluidContainer:adjustAmount(math.ceil(barrelLitres));
    local litres = self.tankStart + (self.tankTarget - self.tankStart) * self.netAction:getProgress()
    self.part:setContainerContentAmount(math.floor(litres))
    self.vehicle:transmitPartModData(self.part)
end

function UB_RefuelVehicleAction:perform()
	self.character:stopOrTriggerSound(self.sound)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function UB_RefuelVehicleAction:complete()
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

function UB_RefuelVehicleAction:getDuration()
    self.tankStart = self.part:getContainerContentAmount()
	self.barrelStart = self.fuelFluidContainer:getAmount()

	local tankLitresRequired = self.part:getContainerCapacity() - self.tankStart
	local amountToTransfer = math.min(tankLitresRequired, self.barrelStart)

	self.tankTarget = self.tankStart + amountToTransfer
	self.barrelTarget = self.barrelStart - amountToTransfer
	self.amountSent = self.tankStart

	return amountToTransfer * 50
end

function UB_RefuelVehicleAction:new(character, part, barrel)
	local o = ISBaseTimedAction.new(self, character)
	o.vehicle = part:getVehicle()
	o.part = part
	o.fuelFluidContainer = barrel.fluidContainer
	--o.stopOnWalk = false
	--o.stopOnRun = false
	o.maxTime = o:getDuration()
	return o
end

