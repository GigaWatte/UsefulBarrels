require "TimedActions/ISBaseTimedAction"

ISUBTransferFluid = ISBaseTimedAction:derive("ISUBTransferFluid");

function ISUBTransferFluid:isValid()
	local sourceAmount = self.sourceFluidContainer:getAmount()
	local canTransfer = FluidContainer.CanTransfer(self.sourceFluidContainer, self.destFluidContainer)
	return (sourceAmount > 0 and canTransfer)
end

function ISUBTransferFluid:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function ISUBTransferFluid:update()
	self.itemToOperate:setJobDelta(self:getJobDelta())
	self.character:faceLocation(self.square:getX(), self.square:getY())
	if not isClient() then
		local actionCurrent = math.floor(self.amount * self:getJobDelta() + 0.001);
		--print("update - action current " .. actionCurrent)
		local destinationAmount = self.destFluidContainer:getAmount();
		--print("update - destination amount " .. destinationAmount)
		local desiredAmount = (self.destinationStart + actionCurrent)
		--print("desired amount in target " .. desiredAmount)
		--print("desired is bigger than destination " .. tostring(desiredAmount > destinationAmount))
		if desiredAmount > destinationAmount then
			local amountToTransfer = desiredAmount - destinationAmount
			--print("amount to transfer " .. amountToTransfer)
			FluidContainer.Transfer(self.sourceFluidContainer, self.destFluidContainer, amountToTransfer)
			--self.sourceFluidContainer:removeFluid(amountToTransfer)
			--print("update - remove from source " .. amountToTransfer)
			--self.destFluidContainer:addFluid(Fluid.Petrol, amountToTransfer);
			--print("update - add to destination " ..  amountToTransfer)
		end
	end
    self.character:setMetabolicTarget(Metabolics.LightWork);
end

function ISUBTransferFluid:start()
	local o = self
	o.destinationStart = o.destFluidContainer:getAmount()
	--print("destination start amount " .. o.destinationStart)
	o.destinationTarget = o.destinationStart + o.amount
	--print("destination target amount " .. o.destinationTarget)

	if not isClient() then
		self:init()
	end
	self.itemToOperate:setJobType(getText("ContextMenu_TakeGasFromPump"))
	self.itemToOperate:setJobDelta(0.0)
	
	self:setOverrideHandModels(nil, self.itemToOperate:getStaticModel())
	self:setActionAnim("TakeGasFromPump")

	self.sound = self.character:playSound("GetWaterFromLake")
end

function ISUBTransferFluid:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.itemToOperate:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function ISUBTransferFluid:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.itemToOperate:setJobDelta(0.0)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISUBTransferFluid:complete()
	local itemCurrent = self.destFluidContainer:getAmount();
	--print("complete - destination amount " .. itemCurrent)
	--print ("destination target " .. self.destinationTarget)
	if self.destinationTarget > itemCurrent then
		FluidContainer.Transfer(self.sourceFluidContainer, self.destFluidContainer, self.destinationTarget - itemCurrent)
		--self.destFluidContainer:addFluid(Fluid.Petrol, self.destinationTarget - itemCurrent);
		--print("complete - add to destination " .. (self.destinationTarget - itemCurrent))
		--syncItemFields(self.character, self.itemToOperate);
		--self.sourceFluidContainer:removeFluid((self.destinationTarget - itemCurrent), true);
		--print("complete - remove from source " .. (self.destinationTarget - itemCurrent))
	end

	return true;
end

function ISUBTransferFluid:serverStart()

end

function ISUBTransferFluid:getDuration()
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

function ISUBTransferFluid:init()

end

function ISUBTransferFluid:new(character, sourceFluidContainer, destFluidContainer, lookAt, itemToOperate, speedModifierApply)
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