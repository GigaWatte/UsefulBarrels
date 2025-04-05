require "TimedActions/ISBaseTimedAction"

UB_TransferFluidAction = ISBaseTimedAction:derive("UB_TransferFluidAction");

function UB_TransferFluidAction:isValidStart()
	return FluidContainer.CanTransfer(self.sourceFluidContainer, self.destFluidContainer)
end

function UB_TransferFluidAction:isValid()
	return self.character:isEquipped(self.itemToOperate)
end

function UB_TransferFluidAction:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function UB_TransferFluidAction:update()
	self.itemToOperate:setJobDelta(self:getJobDelta())
	self.character:faceLocation(self.square:getX(), self.square:getY())
	if not isClient() then
		local sourceAmount = self.sourceFluidContainer:getAmount()
		if sourceAmount > 0 then
			local actionCurrent = math.floor(self.amount * self:getJobDelta() + 0.001);
			local destinationAmount = self.destFluidContainer:getAmount();
			local desiredAmount = (self.destinationStart + actionCurrent)
			if desiredAmount > destinationAmount then
				local amountToTransfer = desiredAmount - destinationAmount
				FluidContainer.Transfer(self.sourceFluidContainer, self.destFluidContainer, amountToTransfer)
			end
		else
			self.action:forceComplete()
		end
	end
    self.character:setMetabolicTarget(Metabolics.LightWork);
end

function UB_TransferFluidAction:start()
	local o = self
	o.destinationStart = o.destFluidContainer:getAmount()
	o.destinationTarget = o.destinationStart + o.amount

	if not isClient() then
		self:init()
	end
	self.itemToOperate:setJobType(getText("ContextMenu_UB_TransferFluidAction"))
	self.itemToOperate:setJobDelta(0.0)
	
	self:setOverrideHandModels(nil, self.itemToOperate:getStaticModel())
	self:setActionAnim("TakeGasFromPump")

	self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_TransferFluidAction:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.itemToOperate:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function UB_TransferFluidAction:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.itemToOperate:setJobDelta(0.0)
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function UB_TransferFluidAction:complete()
	local itemCurrent = self.destFluidContainer:getAmount();
	if self.destinationTarget > itemCurrent then
		FluidContainer.Transfer(self.sourceFluidContainer, self.destFluidContainer, self.destinationTarget - itemCurrent)
	end

	return true;
end

function UB_TransferFluidAction:serverStart()

end

function UB_TransferFluidAction:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end

	local basePerLiter = 50
	local speedModifier = 1
	if self.speedModifierApply then
		speedModifier = SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier
	end
	return (basePerLiter * self.amount) / speedModifier
end

function UB_TransferFluidAction:init()

end

function UB_TransferFluidAction:new(character, sourceFluidContainer, destFluidContainer, lookAt, itemToOperate, speedModifierApply)
	local o = ISBaseTimedAction.new(self, character)
	o.sourceFluidContainer = sourceFluidContainer
	o.destFluidContainer = destFluidContainer
	o.square = lookAt
	o.itemToOperate = itemToOperate
	o.speedModifierApply = speedModifierApply ~= nil
	local freeCapacity = o.destFluidContainer:getFreeCapacity()
	local sourceCurrent = tonumber(o.sourceFluidContainer:getAmount())
	o.amount = math.min(sourceCurrent, freeCapacity)
	o.maxTime = o:getDuration()
	return o;
end