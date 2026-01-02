require "TimedActions/ISBaseTimedAction"

local UB_Const = require "UB_Const"
local UB_Barrel = require "UB_Barrel"
local UB_Utils = require "UB_Utils"

UB_BarrelUnscrewAction = ISBaseTimedAction:derive("UB_BarrelUnscrewAction");

function UB_BarrelUnscrewAction:isValid()
    if SandboxVars.UsefulBarrels.RequirePipeWrench then
        return self.character:isEquipped(self.wrench)
    else
        return true
    end
end

function UB_BarrelUnscrewAction:update()
    if self.wrench then
        self.wrench:setJobDelta(self:getJobDelta())
    end
    self.character:faceThisObject(self.barrelObj)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function UB_BarrelUnscrewAction:start()
    if self.wrench then
        self.wrench:setJobType(getText("ContextMenu_UB_UnscrewPlug", self.objectLabel))
        self.wrench:setJobDelta(0.0)
    end
    self.sound = self.character:playSound("RepairWithWrench")
end

function UB_BarrelUnscrewAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    if self.wrench then
        self.wrench:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self);
end

function UB_BarrelUnscrewAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    if self.wrench then
        self.wrench:setJobDelta(0.0)
    end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function UB_BarrelUnscrewAction:complete()
    if self.barrelObj then
        UB_Barrel.AddFluidContainer(self.barrel)
        UB_Utils.info(string.format("Added fluid container to: %s", tostring(self.barrel)))
    else
        UB_Utils.info(string.format("Target %s is not isoObject", tostring(self.barrelObj)))
    end

    return true
end

function UB_BarrelUnscrewAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return UB_Const.UNCAP_DURATION
end

function UB_BarrelUnscrewAction:new(character, barrelObj, wrench)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character;
    o.barrelObj = barrelObj;
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({barrelObj});
    o.wrench = wrench;
    o.objectLabel = o.barrel.altLabel;
    o.maxTime = o:getDuration();
    return o;
end
