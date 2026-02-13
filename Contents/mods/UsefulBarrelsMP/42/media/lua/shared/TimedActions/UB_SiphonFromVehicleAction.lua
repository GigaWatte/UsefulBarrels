require "TimedActions/ISBaseTimedAction"

local UB_Const = require "UB_Const"
local UB_Utils = require "UB_Utils"

UB_SiphonFromVehicleAction = ISBaseTimedAction:derive("UB_SiphonFromVehicleAction")

function UB_SiphonFromVehicleAction:isValid()
    if not self.barrel then
        UB_Utils.info("Barrel is nil")
        return
    end
    return self.vehicle:isInArea(self.part:getArea(), self.character)
end

function UB_SiphonFromVehicleAction:waitToStart()
    self.character:faceThisObject(self.barrel.isoObject)
    return self.character:shouldBeTurning()
end

function UB_SiphonFromVehicleAction:update()
    local progress
	if isServer() then
		progress = self.netAction:getProgress()
	else
		progress = self:getJobDelta()
	end

    if not isServer() then
		self.character:faceThisObject(self.vehicle)
	end

    if not isClient() then
        local litres = self.tankStart + (self.tankTarget - self.tankStart) * progress
        litres = math.ceil(litres)
        if litres ~= self.amountSent then
            self.part:setContainerContentAmount(litres)
            self.vehicle:transmitPartModData(self.part)
            self.amountSent = litres
        end

        local litresTaken = self.tankStart - litres
        local old = self.barrel:getAmount()
        if self.barrel:isEmpty() and self.barrel:canAddFluid(Fluid.Petrol) then
            self.barrel:addFluid(Fluid.Petrol, litresTaken)
        else
            self.barrel:adjustSpecificFluidAmount(Fluid.Petrol, self.barrelStart + litresTaken)
        end
        self.barrelObj:sync()
        LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, old);

        UB_Utils.info(string.format(table.concat({
            "UB_SiphonFromVehicleAction:update()",
            "amountSent=%s"
        }, "\n"),
        self.amountSent))
    end

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function UB_SiphonFromVehicleAction:animEvent(event, parameter)
	if isServer() then
		if event == "update" then
			self:update();
		end
	end
end

function UB_SiphonFromVehicleAction:serverStart()
	local period = 1000; -- basically 50 * 20
	emulateAnimEvent(self.netAction, period, "update", nil)
end

function UB_SiphonFromVehicleAction:start()
    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)

    self.character:reportEvent("EventTakeWater");

    --self.sound = self.character:playSound("GetWaterFromLake")
    self.sound = self.character:playSound("CanisterAddFuelSiphon")
end

function UB_SiphonFromVehicleAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_SiphonFromVehicleAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_SiphonFromVehicleAction:complete()
    self.barrel:adjustAmount(self.barrelTarget)
    self.barrelObj:sync()
    LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, -1);
    if self.vehicle then
        if not self.part then
            UB_Utils.info(string.format('no such part=%s', tostring(self.part)))
            return false
        end

        self.part:setContainerContentAmount(self.tankTarget)
        self.vehicle:transmitPartModData(self.part)
    else
        UB_Utils.info(string.format('no such vehicle id=', tostring(self.vehicle)))
    end

    UB_Utils.info(string.format(table.concat({
        "UB_SiphonFromVehicleAction:complete()",
        "amountSent=%s"
    }, "\n"),
    self.amountSent))

    return true
end

function UB_SiphonFromVehicleAction:serverStop()
    --local barrelLitres = self.barrelStart + (self.barrelTarget - self.barrelStart) * self.netAction:getProgress()
    --self.barrel:adjustAmount(math.ceil(barrelLitres));
    --local litres = self.tankStart + (self.tankTarget - self.tankStart) * self.netAction:getProgress()
    --self.part:setContainerContentAmount(math.floor(litres))
    self.vehicle:transmitPartModData(self.part)
end

function UB_SiphonFromVehicleAction:getDuration()
    self.barrelStart = self.barrel:getAmount()
    self.tankStart = self.part:getContainerContentAmount()

    local barrelFreeSpace = self.barrel:getFreeCapacity()
    local amountToTransfer = math.min(barrelFreeSpace, self.tankStart)

    self.tankTarget = self.tankStart - amountToTransfer
    self.barrelTarget = self.barrelStart + amountToTransfer
    self.amountSent = math.ceil(self.barrelStart)

    UB_Utils.info(string.format(table.concat({
        "UB_SiphonFromVehicleAction:getDuration()",
        "tank start=%s -> target=%s",
        "barrel Start=%s -> target=%s",
        "amountSent=%s",
        "time=%s",
    }, "\n"),
    self.tankStart, self.tankTarget,
    self.barrelStart, self.barrelTarget,
    self.amountSent, amountToTransfer * UB_Const.BASE_FUEL_TRANSFER_RATE))

    if self.character:isTimedActionInstant() then
        return 1
    end

    return amountToTransfer * UB_Const.BASE_FUEL_TRANSFER_RATE
end

function UB_SiphonFromVehicleAction:new(character, part, barrelObj)
    local o = ISBaseTimedAction.new(self, character)
    o.vehicle = part:getVehicle()
    o.part = part
    o.barrelObj = barrelObj
    o.barrel = UB_Utils.GetValidBarrelFromWorldObjects({barrelObj})
    --UB_Utils.info(o.barrelObj)
    --UB_Utils.info(o.barrel)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = o:getDuration()
    return o
end

