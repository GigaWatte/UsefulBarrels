require "TimedActions/ISBaseTimedAction"

ISUBAddFuelFromBarrel = ISBaseTimedAction:derive("ISUBAddFuelFromBarrel");

function ISUBAddFuelFromBarrel:isValid()
	if self.generator:getFuel() >= 100 then ISBaseTimedAction.stop(self) end
	return self.generator:getObjectIndex() ~= -1
end

function ISUBAddFuelFromBarrel:waitToStart()
	self.character:faceThisObject(self.generator)
	return self.character:shouldBeTurning()
end

function ISUBAddFuelFromBarrel:update()
	self.character:faceThisObject(self.generator)

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function ISUBAddFuelFromBarrel:start()
	self:setActionAnim("refuelgascan")
	-- Don't call setOverrideHandModels() with self.petrol, the right-hand mask
	-- will bork the animation.
	--self:setOverrideHandModels(self.petrol:getStaticModel(), nil)
	self.sound = self.character:playSound("GeneratorAddFuel")
end

function ISUBAddFuelFromBarrel:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function ISUBAddFuelFromBarrel:perform()
	self.character:stopOrTriggerSound(self.sound)
    
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISUBAddFuelFromBarrel:complete()
	local endFuel = 0;
    print(self.fluidCont:getAmount())
	while self.fluidCont and self.fluidCont:getAmount() >= 1.0 and self.generator:getFuel() + endFuel < 100 do
		local amount = self.fluidCont:getAmount() - 1.0;
		self.fluidCont:adjustAmount(amount);
		endFuel = endFuel + 10;
	end
	self.generator:setFuel(self.generator:getFuel() + endFuel)
	self.generator:sync()

	return true;
end

function ISUBAddFuelFromBarrel:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 70 + (self.fluidCont:getAmount() * 50)
end

function ISUBAddFuelFromBarrel:new(character, generator, barrel, maxTime)
	local o = ISBaseTimedAction.new(self, character);
    o.barrel = barrel;
	o.fluidCont = o.barrel:getFluidContainer();
	o.generator = generator;
	o.maxTime = o:getDuration();
	return o;
end