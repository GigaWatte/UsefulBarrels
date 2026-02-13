require "TimedActions/ISBaseTimedAction"

local UB_Const = require "UB_Const"
local UB_Utils = require "UB_Utils"

UB_RefuelGeneratorAction = ISBaseTimedAction:derive("UB_RefuelGeneratorAction");

function UB_RefuelGeneratorAction:isValid()
    if self.generator:getFuelPercentage() >= 100 then ISBaseTimedAction.stop(self) end
    return self.generator:getObjectIndex() ~= -1
end

function UB_RefuelGeneratorAction:waitToStart()
    self.character:faceThisObject(self.generator)
    return self.character:shouldBeTurning()
end

function UB_RefuelGeneratorAction:update()
    self.character:faceThisObject(self.generator)

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function UB_RefuelGeneratorAction:start()
    self:setActionAnim("refuelgascan")
    self.sound = self.character:playSound("GeneratorAddFuel")
end

function UB_RefuelGeneratorAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function UB_RefuelGeneratorAction:perform()
    self.character:stopOrTriggerSound(self.sound)

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function UB_RefuelGeneratorAction:complete()
    local barrelAmount = self.barrel:getAmount()
    local endFuel = math.min(barrelAmount, self.generator:getMaxFuel() - self.generator:getFuel())
    self.barrel:adjustAmount(barrelAmount - endFuel)
    self.barrelObj:sync()
    self.generator:setFuel(self.generator:getFuel() + endFuel)
    self.generator:sync()
    LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, barrelAmount)
    return true
end

function UB_RefuelGeneratorAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    local endFuel = math.min(self.barrel:getAmount(), self.generator:getMaxFuel() - self.generator:getFuel())
    local time = 70 + (endFuel * 50)
    UB_Utils.info(string.format(table.concat({
        "UB_RefuelGeneratorAction:getDuration()",
        "fuel to transfer=%s",
        "time=%s"
    }, "\n"), endFuel, time
    ))
    return time
end

function UB_RefuelGeneratorAction:new(character, generator, barrelObj, maxTime)
    local o = ISBaseTimedAction.new(self, character)
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({barrelObj})
    o.generator = generator
    o.maxTime = o:getDuration()
    return o;
end