
require "TimedActions/ISBaseTimedAction"

UB_BarrelLidCutAction = ISBaseTimedAction:derive("UB_BarrelLidCutAction");

function UB_BarrelLidCutAction:isValid()
    if SandboxVars.UsefulBarrels.RequireBlowTorch then
        return self.character:isEquipped(self.blowTorch)
    else
        return true
    end
end

function UB_BarrelLidCutAction:update()
    self.blowTorch:setJobDelta(self:getJobDelta())
    self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
    if self.sound ~= 0 and not self.character:getEmitter():isPlaying(self.sound) then
        self.sound = self.character:playSound("BlowTorch")
    end
end

function UB_BarrelLidCutAction:start()
    self.blowTorch:setJobType(getText("ContextMenu_UB_BarrelLidCut", self.objectLabel))
    self.blowTorch:setJobDelta(0.0)
    self:setActionAnim("BlowTorch")
    self:setOverrideHandModels(self.blowTorch, nil)
    self.sound = self.character:playSound("BlowTorch")
end

function UB_BarrelLidCutAction:stop()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
    self.blowTorch:setJobDelta(0.0)
    ISBaseTimedAction.stop(self);
end

function UB_BarrelLidCutAction:perform()
    if self.sound ~= 0 then
        self.character:getEmitter():stopSound(self.sound)
    end
    self.blowTorch:setJobDelta(0.0)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function UB_BarrelLidCutAction:complete()
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

function UB_BarrelLidCutAction:getDuration()
    if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
        return 10
    end
    return 150 - (self.character:getPerkLevel(Perks.MetalWelding) * 10)
end

function UB_BarrelLidCutAction:new(character, barrel, blowTorch, uses)
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
