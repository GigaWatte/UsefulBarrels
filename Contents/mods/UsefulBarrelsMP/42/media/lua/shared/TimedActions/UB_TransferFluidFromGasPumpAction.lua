require "TimedActions/ISBaseTimedAction"

local UB_Const = require "UB_Const"
local UB_Utils = require "UB_Utils"

UB_TransferFluidFromGasPumpAction = ISBaseTimedAction:derive("UB_TransferFluidFromGasPumpAction")

function UB_TransferFluidFromGasPumpAction:isValid()
    return self.fuelStation:getPipedFuelAmount() > 0
end

function UB_TransferFluidFromGasPumpAction:waitToStart()
    self.character:faceThisObject(self.fuelStation)
    return self.character:shouldBeTurning()
end

function UB_TransferFluidFromGasPumpAction:update()
    local progress
	if isServer() then
		progress = self.netAction:getProgress()
	else
		progress = self:getJobDelta()
	end

    if not isClient() then
        local sourceAmount = self.fuelStation:getPipedFuelAmount()
        if sourceAmount > 0 then
            local actionCurrent = math.floor(self.amountToTransfer * progress + 0.001)
            local destinationAmount = self.barrel:getAmount()
            local desiredAmount = (self.destinationStart + actionCurrent)
            if desiredAmount > destinationAmount then
                local amountToTransfer = desiredAmount - destinationAmount
                self.fuelStation:setPipedFuelAmount(sourceAmount - (amountToTransfer))
                self.barrelObj:sync()
                self.barrel:addFluid(Fluid.Petrol, amountToTransfer)
            end
        end

        self.character:setMetabolicTarget(Metabolics.LightWork)
    end
end

function UB_TransferFluidFromGasPumpAction:start()
    self:setActionAnim("TakeGasFromPump")
    self:setOverrideHandModels(nil, nil)

    self.character:reportEvent("EventTakeWater");

    self.sound = self.character:playSound("CanisterAddFuelFromGasPump")
end

function UB_TransferFluidFromGasPumpAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_TransferFluidFromGasPumpAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_TransferFluidFromGasPumpAction:complete()
    if self.fuelStation then
        local sourceAmount = self.fuelStation:getPipedFuelAmount()
        local destCurrentAmount = self.barrel:getAmount()
        if self.destinationTarget > destCurrentAmount then
            self.fuelStation:setPipedFuelAmount(sourceAmount - (self.destinationTarget - destCurrentAmount))
            self.barrelObj:sync()
            self.barrel:addFluid(Fluid.Petrol, self.destinationTarget - destCurrentAmount)
        end
    end
    return true
end

function UB_TransferFluidFromGasPumpAction:serverStart()
	local period = 1000; -- basically 50 * 20
	emulateAnimEvent(self.netAction, period, "update", nil)
end

function UB_TransferFluidFromGasPumpAction:animEvent(event, parameter)
	if isServer() then
		if event == "update" then
			self:update();
		end
	end
end

function UB_TransferFluidFromGasPumpAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    self.destinationStart = self.barrel:getAmount()
    self.destinationTarget = self.destinationStart + self.amountToTransfer

    local basePerLiter = 50

    return self.amountToTransfer * basePerLiter
end

function UB_TransferFluidFromGasPumpAction:new(character, fuelStation, barrelObj)
    local o = ISBaseTimedAction.new(self, character)
    o.fuelStation = fuelStation
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({barrelObj})
	o.stopOnWalk = true
	o.stopOnRun = true
    local destFreeCapacity = o.barrel:getFreeCapacity()
    local sourceCurrent = tonumber(o.fuelStation:getPipedFuelAmount())
    o.amountToTransfer = math.min(sourceCurrent, destFreeCapacity)
    o.maxTime = o:getDuration()
    return o
end
