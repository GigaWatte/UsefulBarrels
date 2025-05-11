
require "TimedActions/ISBaseTimedAction"

UB_CutBarrelLidAction = ISBaseTimedAction:derive("UB_CutBarrelLidAction");

function UB_CutBarrelLidAction:isValid()
	if SandboxVars.UsefulBarrels.RequireWeldingMask then
		--return self.character:isEquipped(self.blowTorch)
		return true
	else
		return true
	end
end

function UB_CutBarrelLidAction:update()
	self.blowTorch:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function UB_CutBarrelLidAction:start()
	self.blowTorch:setJobType(getText("ContextMenu_UB_UncapBarrel", self.objectLabel))
	self.blowTorch:setJobDelta(0.0)
	self.sound = self.character:playSound("RepairWithWrench")
end

function UB_CutBarrelLidAction:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.blowTorch:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function UB_CutBarrelLidAction:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.blowTorch:setJobDelta(0.0)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function UB_CutBarrelLidAction:complete()
    local totalXP = 5
	if self.barrelObj then

        local cutSuccess = self.ub_barrel:CutLid()

		if cutSuccess then
			for i=1,self.uses do
				self.blowTorch:Use(false, false, true)
			end
			addXp(self.character, Perks.MetalWelding, totalXP)
		end
	else
		print(string.format("invalid target %s", tostring(self.barrelObj)))
	end

	return true
end

function UB_CutBarrelLidAction:getDuration()
	if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
		return 10
	end
    return 150 - (self.character:getPerkLevel(Perks.MetalWelding) * 10)
end

function UB_CutBarrelLidAction:new(character, barrel, blowTorch, uses)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
	o.ub_barrel = barrel
    o.barrelObj = barrel.isoObject
	o.blowTorch = blowTorch
	o.objectLabel = barrel.altLabel
    o.uses = uses
	o.maxTime = o:getDuration()
	return o
end
