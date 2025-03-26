
require "TimedActions/ISBaseTimedAction"

ISUBDoBarrelUncap = ISBaseTimedAction:derive("ISUBDoBarrelUncap");

function ISUBDoBarrelUncap:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function ISUBDoBarrelUncap:new(character, barrel, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
    o.barrel = barrel
	o.barrelObj = barrel.isoObject
	o.wrench = wrench
	o.objectLabel = barrel.objectLabel
	o.maxTime = o:getDuration()
	return o
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
	self.barrel:Uncap()
	return true
end
