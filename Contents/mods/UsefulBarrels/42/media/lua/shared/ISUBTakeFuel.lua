require "TimedActions/ISBaseTimedAction"

ISUBTakeFuel = ISBaseTimedAction:derive("ISUBTakeFuel");

function ISUBTakeFuel:isValid()
	local sourceAmount = self.fuelSource:getFluidContainer():getAmount()
	local containsPetrol = self.fuelSource:getFluidContainer():contains(Fluid.Petrol)
	return (sourceAmount > 0 and containsPetrol)
end

function ISUBTakeFuel:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function ISUBTakeFuel:update()
	self.itemToOperate:setJobDelta(self:getJobDelta())
	self.character:faceLocation(self.square:getX(), self.square:getY())
	if not isClient() then
		local actionCurrent = math.floor(self.amount * self:getJobDelta() + 0.001);
		--print("update - action current " .. actionCurrent)
		local destinationAmount = self.fuelDestination:getFluidContainer():getAmount();
		--print("update - destination amount " .. destinationAmount)
		local desiredAmount = (self.destinationStart + actionCurrent)
		--print("desired amount in target " .. desiredAmount)
		--print("desired is bigger than destination " .. tostring(desiredAmount > destinationAmount))
		if desiredAmount > destinationAmount then
			local amountToTransfer = desiredAmount - destinationAmount
			--print("amount to transfer " .. amountToTransfer)
			self.fuelSource:getFluidContainer():removeFluid(amountToTransfer)
			--print("update - remove from source " .. amountToTransfer)
			self.fuelDestination:getFluidContainer():addFluid(Fluid.Petrol, amountToTransfer);
			--print("update - add to destination " ..  amountToTransfer)
		end
	end
    self.character:setMetabolicTarget(Metabolics.LightWork);
end

function ISUBTakeFuel:start()
	local o = self
	o.destinationStart = o.fuelDestination:getFluidContainer():getAmount()
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

function ISUBTakeFuel:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.itemToOperate:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function ISUBTakeFuel:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.itemToOperate:setJobDelta(0.0)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISUBTakeFuel:complete()
	local itemCurrent = self.fuelDestination:getFluidContainer():getAmount();
	--print("complete - destination amount " .. itemCurrent)
	--print ("destination target " .. self.destinationTarget)
	if self.destinationTarget > itemCurrent then
		self.fuelDestination:getFluidContainer():addFluid(Fluid.Petrol, self.destinationTarget - itemCurrent);
		--print("complete - add to destination " .. (self.destinationTarget - itemCurrent))
		--syncItemFields(self.character, self.itemToOperate);
		self.fuelSource:getFluidContainer():removeFluid((self.destinationTarget - itemCurrent), true);
		--print("complete - remove from source " .. (self.destinationTarget - itemCurrent))
	end

	return true;
end

function ISUBTakeFuel:serverStart()

end

function ISUBTakeFuel:getDuration()
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

function ISUBTakeFuel:init()

end

function ISUBTakeFuel:new(character, fuelSource, fuelDestination, lookAt, itemToOperate, barrelObj, speedModifierApply)
	local o = ISBaseTimedAction.new(self, character)
	o.fuelSource = fuelSource
	o.square = lookAt
	o.fuelDestination = fuelDestination
	o.itemToOperate = itemToOperate
	o.barrelObj = barrelObj
	local freeCapacity = o.fuelDestination:getFluidContainer():getFreeCapacity()
	--print("destination free capacity " .. freeCapacity)
	local sourceCurrent = tonumber(o.fuelSource:getFluidContainer():getAmount())
	--print("source amount fuel " .. sourceCurrent)
	o.amount = math.min(sourceCurrent, freeCapacity)
	--print("amount to transfer " .. o.amount)
	if speedModifierApply ~= nil then o.speedModifierApply = true else o.speedModifierApply = false end
	o.maxTime = o:getDuration()
	return o;
end