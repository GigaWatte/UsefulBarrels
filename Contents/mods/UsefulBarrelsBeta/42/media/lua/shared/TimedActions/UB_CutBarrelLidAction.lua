
require "TimedActions/ISBaseTimedAction"

UB_CutBarrelLidAction = ISBaseTimedAction:derive("UB_CutBarrelLidAction");

function UB_CutBarrelLidAction:isValid()
	if SandboxVars.UsefulBarrels.RequirePipeWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function UB_CutBarrelLidAction:update()
	self.wrench:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function UB_CutBarrelLidAction:start()
	self.wrench:setJobType(getText("ContextMenu_UB_UncapBarrel", self.objectLabel))
	self.wrench:setJobDelta(0.0)
	self.sound = self.character:playSound("RepairWithWrench")
end

function UB_CutBarrelLidAction:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.wrench:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function UB_CutBarrelLidAction:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.wrench:setJobDelta(0.0)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function UB_CutBarrelLidAction:complete()
    local totalXP = 5
	if self.barrelObj then

        local modData = self.barrelObj:getModData()

        if not modData["UB_CutLid"] then
            modData["UB_CutLid"] = true
        end
		-- enable rain factor
		local newSprite = self.barrel:getSprite(UBBarrel.LIDLESS)
		if newSprite then
			modData["UB_OriginalSprite"] = self.barrelObj:getSprite():getName()
			modData["UB_CurrentSprite"] = newSprite
			self.barrelObj:setSprite(newSprite)
		else
			error("missing sprite...")
		end

		self.barrelObj:setModData(modData)

        for i=1,self.uses do
            self.item:Use(false, false, true);
        end

        addXp(self.character, Perks.MetalWelding, totalXP)

		buildUtil.setHaveConstruction(self.barrelObj:getSquare(), true)
	else
		print(string.format("invalid target %s",tostring(self.barrelObj)))
	end

	return true;
end

function UB_CutBarrelLidAction:getDuration()
	if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
		return 10
	end
    return 150 - (self.character:getPerkLevel(Perks.MetalWelding) * 10)
end

function UB_CutBarrelLidAction:new(character, barrel, blowTorch, objectLabel, uses)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character
	-- TODO do I have barrel actually here?
	o.barrel = barrel
    o.barrelObj = barrel.isoObject
	o.blowTorch = blowTorch
	o.objectLabel = objectLabel
    o.uses = uses
	o.maxTime = o:getDuration()
	return o
end
