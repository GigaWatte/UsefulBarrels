require "TimedActions/ISBaseTimedAction"

local UB_Const = require "UB_Const"
local UB_Utils = require "UB_Utils"

UB_TransferFluidFromObjectAction = ISBaseTimedAction:derive("UB_TransferFluidFromObjectAction")

function UB_TransferFluidFromObjectAction:isValid()
    return self.sink:getFluidAmount() > 0
end

function UB_TransferFluidFromObjectAction:waitToStart()
    self.character:faceThisObject(self.sink)
    return self.character:shouldBeTurning()
end

function UB_TransferFluidFromObjectAction:update()
    local progress
	if isServer() then
		progress = self.netAction:getProgress()
	else
		progress = self:getJobDelta()
	end

    if not isClient() then
        local sourceAmount = self.sink:getFluidAmount()
        if sourceAmount > 0 then
            local actionCurrent = math.floor(self.amountToTransfer * progress + 0.001)
            local destinationAmount = self.barrel:getAmount()
            local desiredAmount = (self.destinationStart + actionCurrent)
            if desiredAmount > destinationAmount then
                local amountToTransfer = desiredAmount - destinationAmount
                self.sink:transferFluidTo(self.barrel.fluidContainer, amountToTransfer)
                self.barrelObj:sync()
                LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, destinationAmount)
            end
        else
            self.action:forceComplete()
        end

        self.character:setMetabolicTarget(Metabolics.LightWork)
    end
end

function UB_TransferFluidFromObjectAction:start()
    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)

    self.character:reportEvent("EventTakeWater");

    self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_TransferFluidFromObjectAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_TransferFluidFromObjectAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_TransferFluidFromObjectAction:complete()
    if self.sink then
        local destCurrentAmount = self.barrel:getAmount()
        if self.destinationTarget > destCurrentAmount then
            self.sink:transferFluidTo(self.barrel.fluidContainer, self.destinationTarget - destCurrentAmount)
            self.barrelObj:sync()
            LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrel.isoObject, destCurrentAmount)
        end
    end
    return true
end

function UB_TransferFluidFromObjectAction:serverStart()
	local period = 1000; -- basically 50 * 20
	emulateAnimEvent(self.netAction, period, "update", nil)
end

function UB_TransferFluidFromObjectAction:animEvent(event, parameter)
	if isServer() then
		if event == "update" then
			self:update();
		end
	end
end

function UB_TransferFluidFromObjectAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    self.destinationStart = self.barrel:getAmount()
    self.destinationTarget = self.destinationStart + self.amountToTransfer

    local basePerLiter = 50

    return self.amountToTransfer * basePerLiter
end

function UB_TransferFluidFromObjectAction:new(character, sink, barrelObj)
    local o = ISBaseTimedAction.new(self, character)
    o.sink = sink
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({barrelObj})
	o.stopOnWalk = true
	o.stopOnRun = true
    local destFreeCapacity = o.barrel:getFreeCapacity()
    local sourceCurrent = tonumber(o.sink:getFluidAmount())
    o.amountToTransfer = math.min(sourceCurrent, destFreeCapacity)
    o.maxTime = o:getDuration()
    return o
end
