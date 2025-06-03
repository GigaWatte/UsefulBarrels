require "TimedActions/ISBaseTimedAction"

UB_SiphonFromVehicleAction = ISBaseTimedAction:derive("UB_SiphonFromVehicleAction")

function UB_SiphonFromVehicleAction:isValid()
    return self.vehicle:isInArea(self.part:getArea(), self.character)
end

function UB_SiphonFromVehicleAction:waitToStart()
    self.character:faceThisObject(self.barrel.isoObject)
    return self.character:shouldBeTurning()
end

function UB_SiphonFromVehicleAction:update()
    local litres = self.tankStart + (self.tankTarget - self.tankStart) * self:getJobDelta()
    litres = math.floor(litres)
    if litres ~= self.amountSent then
        if not self.vehicle then
            print('no such vehicle id=', self.vehicle)
            return
        end
        if not self.part then
            print('no such part ', self.part)
            return
        end

        self.part:setContainerContentAmount(litres)

        local barrelUnits = self.barrelStart + (self.barrelTarget - self.barrelStart) * self:getJobDelta()
        barrelUnits = math.ceil(barrelUnits)

        if self.barrel:isEmpty() and self.barrel:canAddFluid(Fluid.Petrol) then
            self.barrel:addFluid(Fluid.Petrol, barrelUnits)
        else
            self.barrel:adjustSpecificFluidAmount(Fluid.Petrol, barrelUnits)
        end
        
        self.vehicle:transmitPartModData(self.part)
        self.amountSent = litres
    end

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function UB_SiphonFromVehicleAction:start()
    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)

    self.character:reportEvent("EventTakeWater");

    self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_SiphonFromVehicleAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_SiphonFromVehicleAction:serverStop()
    local barrelLitres = self.barrelStart + (self.barrelTarget - self.barrelStart) * self.netAction:getProgress()
    self.barrel:adjustAmount(math.ceil(barrelLitres));
    local litres = self.tankStart + (self.tankTarget - self.tankStart) * self.netAction:getProgress()
    self.part:setContainerContentAmount(math.floor(litres))
    self.vehicle:transmitPartModData(self.part)
end

function UB_SiphonFromVehicleAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_SiphonFromVehicleAction:complete()
    if self.vehicle then
        if not self.part then
            print('no such part ',self.part)
            return false
        end
        local litres = self.tankStart + (self.tankTarget - self.tankStart) * self:getJobDelta()
        self.part:setContainerContentAmount(litres)

        local barrelUnits = self.barrelStart + (self.barrelTarget - self.barrelStart) * self:getJobDelta()
        barrelUnits = math.ceil(barrelUnits)

        if self.barrel:isEmpty() and self.barrel:canAddFluid(Fluid.Petrol) then
            self.barrel:addFluid(Fluid.Petrol, barrelUnits)
        else
            self.barrel:adjustSpecificFluidAmount(Fluid.Petrol, barrelUnits)
        end
        
        self.vehicle:transmitPartModData(self.part)
    else
        print('no such vehicle id=', self.vehicle)
    end
    return true
end

function UB_SiphonFromVehicleAction:getDuration()
    self.tankStart = self.part:getContainerContentAmount()
    self.barrelStart = self.barrel:getAmount()

    local barrelFreeSpace = self.barrel:getCapacity() - self.barrelStart
    local amountToTransfer = math.min(self.tankStart, barrelFreeSpace)

    self.tankTarget = self.tankStart - amountToTransfer
    self.barrelTarget = self.barrelStart + amountToTransfer
    self.amountSent = self.barrelStart

    return amountToTransfer * 50
end

function UB_SiphonFromVehicleAction:new(character, part, barrel)
    local o = ISBaseTimedAction.new(self, character)
    o.vehicle = part:getVehicle()
    o.part = part
    o.barrel = barrel
    --o.stopOnWalk = false
    --o.stopOnRun = false
    o.maxTime = o:getDuration()
    return o
end

