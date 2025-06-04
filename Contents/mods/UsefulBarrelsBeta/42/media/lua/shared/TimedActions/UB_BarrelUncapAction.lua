
require "TimedActions/ISBaseTimedAction"
local UBUtils = require "UBUtils"

UB_BarrelUncapAction = ISBaseTimedAction:derive("UB_BarrelUncapAction");

function UB_BarrelUncapAction:isValid()
    if SandboxVars.UsefulBarrels.RequirePipeWrench then
        return self.character:isEquipped(self.wrench)
    else
        return true
    end
end

function UB_BarrelUncapAction:update()
    if self.wrench then
        self.wrench:setJobDelta(self:getJobDelta())
    end
    self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function UB_BarrelUncapAction:start()
    if self.wrench then
        self.wrench:setJobType(getText("ContextMenu_UB_UncapBarrel", self.objectLabel))
        self.wrench:setJobDelta(0.0)
    end
    self.sound = self.character:playSound("RepairWithWrench")
end

function UB_BarrelUncapAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    if self.wrench then
        self.wrench:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self);
end

function UB_BarrelUncapAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    if self.wrench then
        self.wrench:setJobDelta(0.0)
    end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function UB_BarrelUncapAction:complete()
    if self.barrelObj then
        self.ub_barrel:AddFluidContainerToBarrel()
    else
        print(string.format("invalid target %s", tostring(self.barrelObj)))
    end

    return true
end

function UB_BarrelUncapAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 40
end

function UB_BarrelUncapAction:new(character, ub_barrel, wrench)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character;
    o.ub_barrel = ub_barrel;
    o.barrelObj = ub_barrel.isoObject;
    o.wrench = wrench;
    o.objectLabel = ub_barrel.altLabel;
    o.maxTime = o:getDuration();
    return o;
end
