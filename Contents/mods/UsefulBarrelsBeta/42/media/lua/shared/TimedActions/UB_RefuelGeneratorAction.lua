require "TimedActions/ISBaseTimedAction"

UB_RefuelGeneratorAction = ISBaseTimedAction:derive("UB_RefuelGeneratorAction");

function UB_RefuelGeneratorAction:isValid()
	if self.generator:getFuel() >= 100 then ISBaseTimedAction.stop(self) end
	return self.generator:getObjectIndex() ~= -1
end

function UB_RefuelGeneratorAction:waitToStart()
	self.character:faceThisObject(self.generator)
	return self.character:shouldBeTurning()
end

function UB_RefuelGeneratorAction:update()
	self.character:faceThisObject(self.generator)

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function UB_RefuelGeneratorAction:start()
	self:setActionAnim("refuelgascan")
	self.sound = self.character:playSound("GeneratorAddFuel")
end

function UB_RefuelGeneratorAction:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function UB_RefuelGeneratorAction:perform()
	self.character:stopOrTriggerSound(self.sound)
    
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function UB_RefuelGeneratorAction:complete()
	local endFuel = 0;
	while self.barrel:getAmount() >= 1.0 and self.generator:getFuel() + endFuel < 100 do
		local amount = self.barrel:getAmount() - 1.0
		self.barrel:adjustAmount(amount)
		endFuel = endFuel + 10
	end
	self.generator:setFuel(self.generator:getFuel() + endFuel)
	self.generator:sync()

	return true;
end

function UB_RefuelGeneratorAction:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 70 + (self.amount * 50)
end

function UB_RefuelGeneratorAction:new(character, generator, barrel, maxTime)
	local o = ISBaseTimedAction.new(self, character)
	o.barrel = barrel
	o.generator = generator
	o.amount = 10 - o.generator:getFuel() / 10
	o.maxTime = o:getDuration()
	return o;
end