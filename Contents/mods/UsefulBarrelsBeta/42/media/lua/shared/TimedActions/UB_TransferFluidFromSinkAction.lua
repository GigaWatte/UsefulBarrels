require "TimedActions/ISBaseTimedAction"

UB_TransferFluidFromSinkAction = ISBaseTimedAction:derive("UB_TransferFluidFromSinkAction")

function UB_TransferFluidFromSinkAction:isValid()
    return self.sourceObject:getFluidAmount() > 0
end

function UB_TransferFluidFromSinkAction:waitToStart()
    self.character:faceThisObject(self.sourceObject)
    return self.character:shouldBeTurning()
end

function UB_TransferFluidFromSinkAction:update()
    local sourceAmount = self.sourceObject:getFluidAmount()
    if sourceAmount > 0 then
        local actionCurrent = math.floor(self.amountToTransfer * self:getJobDelta() + 0.001)
        local destinationAmount = self.barrel:getAmount()
        local desiredAmount = (self.destinationStart + actionCurrent)
        if desiredAmount > destinationAmount then
            local amountToTransfer = desiredAmount - destinationAmount
            self.sourceObject:transferFluidTo(self.barrel.fluidContainer, amountToTransfer)
            -- trigger event for barrel
            LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrel.isoObject, destinationAmount)
        end
    else
        self.action:forceComplete()
    end

    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function UB_TransferFluidFromSinkAction:start()
    self.destinationStart = self.barrel:getAmount()
	self.destinationTarget = self.destinationStart + self.amountToTransfer

    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)

    self.character:reportEvent("EventTakeWater");

    self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_TransferFluidFromSinkAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_TransferFluidFromSinkAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_TransferFluidFromSinkAction:complete()
    if self.sourceObject then
        local destCurrentAmount = self.barrel:getAmount()
        if self.destinationTarget > destCurrentAmount then
            self.sourceObject:transferFluidTo(self.barrel.fluidContainer, self.destinationTarget - destCurrentAmount)
            -- trigger event for destination object also
            LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrel.isoObject, destCurrentAmount)
        end
    end
    return true
end

function UB_TransferFluidFromSinkAction:getDuration()
    if self.character:isTimedActionInstant() then
		return 1
	end

    local basePerLiter = 50

    return self.amountToTransfer * basePerLiter
end

function UB_TransferFluidFromSinkAction:new(character, sink, barrel)
    local o = ISBaseTimedAction.new(self, character)
    o.sourceObject = sink
    o.barrel = barrel

    local destFreeCapacity = o.barrel:getFreeCapacity()
    local sourceCurrent = tonumber(o.sourceObject:getFluidAmount())
    o.amountToTransfer = math.min(sourceCurrent, destFreeCapacity)
    o.maxTime = o:getDuration()
    return o
end
