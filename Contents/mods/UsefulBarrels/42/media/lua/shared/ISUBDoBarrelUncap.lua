
require "TimedActions/ISBaseTimedAction"

ISUBDoBarrelUncap = ISBaseTimedAction:derive("ISUBDoBarrelUncap");

function ISUBDoBarrelUncap:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function ISUBDoBarrelUncap:new(character, barrelObj, wrench, objectLabel)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
    o.barrelObj = barrelObj;
	o.wrench = wrench;
	o.objectLabel = objectLabel
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
	self.wrench:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function ISUBDoBarrelUncap:start()
	self.wrench:setJobType(getText("ContextMenu_UB_UncapBarrel", self.objectLabel))
	self.wrench:setJobDelta(0.0)
	self.sound = self.character:playSound("RepairWithWrench")
end

function ISUBDoBarrelUncap:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.wrench:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function ISUBDoBarrelUncap:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.wrench:setJobDelta(0.0)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISUBDoBarrelUncap:complete()
	if self.barrelObj then
		if not self.barrelObj:hasComponent(ComponentType.FluidContainer) then
			local component = ComponentType.FluidContainer:CreateComponent()
			local barrelCapacity = SandboxVars.UsefulBarrels.BarrelCapacity
            component:setCapacity(barrelCapacity)
            component:setContainerName("UB_" .. self.barrelObj:getSprite():getProperties():Val("CustomName"))

			GameEntityFactory.AddComponent(self.barrelObj, true, component)

			local modData = self.barrelObj:getModData()
			if not modData["UB_Uncapped"] then
				modData["UB_Uncapped"] = true
				self.barrelObj:setModData(modData)
			end
		end

		buildUtil.setHaveConstruction(self.barrelObj:getSquare(), true)
	else
		print(string.format("invalid target %s",tostring(self.barrelObj)))
	end

	return true;
end
