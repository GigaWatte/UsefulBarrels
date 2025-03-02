
require "TimedActions/ISBaseTimedAction"

ISUBDoBarrelUncap = ISBaseTimedAction:derive("ISUBDoBarrelUncap");

function ISUBDoBarrelUncap:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function ISUBDoBarrelUncap:new(character, barrelObj, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
    o.barrelObj = barrelObj;
	o.wrench = wrench;
	o.maxTime = o:getDuration();
	return o;
end

function ISUBDoBarrelUncap:isValid()
	if SandboxVars.UsefulBarrels.RequirePipeWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function ISUBDoBarrelUncap:update()
	self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function ISUBDoBarrelUncap:start()
	self.sound = self.character:playSound("RepairWithWrench")
end

function ISUBDoBarrelUncap:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function ISUBDoBarrelUncap:perform()
	self.character:stopOrTriggerSound(self.sound)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISUBDoBarrelUncap:complete()
	if self.barrelObj then
		if not self.barrelObj:hasComponent(ComponentType.FluidContainer) then
			local component = ComponentType.FluidContainer:CreateComponent()
			local barrelCapacity = SandboxVars.UsefulBarrels.BarrelCapacity
            component:setCapacity(barrelCapacity)
			component:addFluid(FluidType.Petrol, 0)
            component:setContainerName("UB_Fuel_" .. self.barrelObj:getSprite():getProperties():Val("CustomName"))

			GameEntityFactory.AddComponent(self.barrelObj, true, component)
		end

		local modData = self.barrelObj:getModData()
		if not modData["UB_Uncapped"] then
			modData["UB_Uncapped"] = true
			self.barrelObj:setModData(modData)
			print("set at uncap")
		end

		buildUtil.setHaveConstruction(self.barrelObj:getSquare(), true)
	else
		print(string.format("invalid target %s",tostring(self.barrelObj)))
	end

	return true;
end
