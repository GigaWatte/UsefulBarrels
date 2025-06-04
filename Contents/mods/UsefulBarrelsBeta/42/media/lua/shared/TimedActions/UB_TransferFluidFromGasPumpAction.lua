require "TimedActions/ISBaseTimedAction"

UB_TransferFluidFromGasPumpAction = ISBaseTimedAction:derive("UB_TransferFluidFromGasPumpAction")

function UB_TransferFluidFromGasPumpAction:isValid()
    return self.sourceObject:getPipedFuelAmount() > 0
end

function UB_TransferFluidFromGasPumpAction:waitToStart()
    self.character:faceThisObject(self.sourceObject)
    return self.character:shouldBeTurning()
end

function UB_TransferFluidFromGasPumpAction:update()
    local sourceAmount = self.sourceObject:getPipedFuelAmount()
    if sourceAmount > 0 then
        local actionCurrent = math.floor(self.amountToTransfer * self:getJobDelta() + 0.001)
        local destinationAmount = self.barrel:getAmount()
        local desiredAmount = (self.destinationStart + actionCurrent)
        if desiredAmount > destinationAmount then
            local amountToTransfer = desiredAmount - destinationAmount
            self.sourceObject:setPipedFuelAmount(sourceAmount - (amountToTransfer))
            self.barrel:addFluid(Fluid.Petrol, amountToTransfer)
        end
    else
        self.action:forceComplete()
    end

    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function UB_TransferFluidFromGasPumpAction:start()
    self.destinationStart = self.barrel:getAmount()
    self.destinationTarget = self.destinationStart + self.amountToTransfer

    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)

    self.character:reportEvent("EventTakeWater");

    self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_TransferFluidFromGasPumpAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_TransferFluidFromGasPumpAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_TransferFluidFromGasPumpAction:complete()
    if self.sourceObject then
        local sourceAmount = self.sourceObject:getPipedFuelAmount()
        local destCurrentAmount = self.barrel:getAmount()
        if self.destinationTarget > destCurrentAmount then
            self.sourceObject:setPipedFuelAmount(sourceAmount - (self.destinationTarget - destCurrentAmount))
            self.barrel:addFluid(Fluid.Petrol, self.destinationTarget - destCurrentAmount)
        end
    end
    return true
end

function UB_TransferFluidFromGasPumpAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    local basePerLiter = 50

    return self.amountToTransfer * basePerLiter
end

function UB_TransferFluidFromGasPumpAction:new(character, gas_pump, barrel)
    local o = ISBaseTimedAction.new(self, character)
    o.sourceObject = gas_pump
    o.barrel = barrel

    local destFreeCapacity = o.barrel:getFreeCapacity()
    local sourceCurrent = tonumber(o.sourceObject:getPipedFuelAmount())
    o.amountToTransfer = math.min(sourceCurrent, destFreeCapacity)
    o.maxTime = o:getDuration()
    return o
end
