
require "TimedActions/ISBaseTimedAction"

UB_BarrelUncapAction = ISBaseTimedAction:derive("UB_BarrelUncapAction");

function UB_BarrelUncapAction:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 40
end

function UB_BarrelUncapAction:new(character, barrelObj, wrench, objectLabel)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
    o.barrelObj = barrelObj;
	o.wrench = wrench;
	o.objectLabel = objectLabel
	o.maxTime = o:getDuration();
	return o;
end

function UB_BarrelUncapAction:isValid()
	if SandboxVars.UsefulBarrels.RequirePipeWrench then
		return self.character:isEquipped(self.wrench)
	else
		return true
	end
end

function UB_BarrelUncapAction:update()
	self.wrench:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function UB_BarrelUncapAction:start()
	self.wrench:setJobType(getText("ContextMenu_UB_UncapBarrel", self.objectLabel))
	self.wrench:setJobDelta(0.0)
	self.sound = self.character:playSound("RepairWithWrench")
end

function UB_BarrelUncapAction:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.wrench:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function UB_BarrelUncapAction:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.wrench:setJobDelta(0.0)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function UB_BarrelUncapAction:complete()
	if self.barrelObj then
		if not self.barrelObj:hasComponent(ComponentType.FluidContainer) then
			local component = ComponentType.FluidContainer:CreateComponent()
			local barrelCapacity = SandboxVars.UsefulBarrels.BarrelCapacity
            component:setCapacity(barrelCapacity)
            component:setContainerName("UB_" .. self.barrelObj:getSprite():getProperties():Val("CustomName"))
			
			local modData = self.barrelObj:getModData()

			local shouldSpawn = self:shouldSpawn()
			if SandboxVars.UsefulBarrels.InitialFluid and shouldSpawn then
				local fluid = self:getInitialFluid()
				if fluid then
					local amount = self:getInitialFluidAmount()
					component:addFluid(fluid, amount)
					modData["UB_Initial_fluid"] = tostring(fluid)
					modData["UB_Initial_amount"] = tostring(amount)
				end
			end

			GameEntityFactory.AddComponent(self.barrelObj, true, component)

			if not modData["UB_Uncapped"] then
				modData["UB_Uncapped"] = true
			end
			
			self.barrelObj:setModData(modData)
		end

		buildUtil.setHaveConstruction(self.barrelObj:getSquare(), true)
	else
		print(string.format("invalid target %s",tostring(self.barrelObj)))
	end

	return true;
end

function UB_BarrelUncapAction:getInitialFluid()
	local fluidTable = {}
	local fluids = luautils.split(SandboxVars.UsefulBarrels.InitialFluidPool)
	for _,fluidStr in ipairs(fluids, " ") do
		if Fluid.Get(fluidStr) then table.insert(fluidTable, Fluid.Get(fluidStr)) end
	end

	if #fluidTable == 1 then return nil end
	local index = ZombRand(#fluidTable) + 1

	return fluidTable[index]
end

function UB_BarrelUncapAction:getInitialFluidAmount()
	if SandboxVars.UsefulBarrels.InitialFluidMaxAmount > 0 then
		return PZMath.clamp(ZombRand(SandboxVars.UsefulBarrels.InitialFluidMaxAmount), 0, SandboxVars.UsefulBarrels.BarrelCapacity)
	end
	return 0
end

function UB_BarrelUncapAction:shouldSpawn()
	if SandboxVars.UsefulBarrels.InitialFluidSpawnChance == 100 then return true end
	if SandboxVars.UsefulBarrels.InitialFluidSpawnChance > 0 then
		return ZombRand(0,100) <= SandboxVars.UsefulBarrels.InitialFluidSpawnChance
	end
	return false
end
