require "TimedActions/ISBaseTimedAction"

local UB_Const = require "UB_Const"
local UB_Utils = require "UB_Utils"

UB_RefuelVehicleAction = ISBaseTimedAction:derive("UB_RefuelVehicleAction")

function UB_RefuelVehicleAction:isValid()
    if not self.barrel then
        UB_Utils.info("Barrel is nil")
        return
    end
    return self.vehicle:isInArea(self.part:getArea(), self.character)
end

function UB_RefuelVehicleAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function UB_RefuelVehicleAction:update()
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
        litres = math.floor(litres)
        if litres ~= self.amountSent then
            if self.vehicle then
                if not self.part then
                    print('no such part ',self.part)
                    return
                end
                self.part:setContainerContentAmount(litres)
                self.vehicle:transmitPartModData(self.part)
            else
                print('no such vehicle id=', self.vehicle)
            end
            self.amountSent = litres
        end
        local litresTaken = litres - self.tankStart
        --local barrelUnits = self.barrelStart + (self.barrelTarget - self.barrelStart) * progress
        local old = self.barrel:getAmount()
        self.barrel:adjustAmount(self.barrelStart - litresTaken);
        self.barrelObj:sync()
        LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, old);

        --UB_Utils.info(string.format(table.concat({
        --    "UB_RefuelVehicleAction:update()",
        --    "amountSent=%s"
        --}, "\n"),
        --self.amountSent))
    end

    self.character:setMetabolicTarget(Metabolics.HeavyDomestic);
end

function UB_RefuelVehicleAction:animEvent(event, parameter)
    if isServer() then
        if event == "update" then
            self:update();
        end
    end
end

function UB_RefuelVehicleAction:serverStart()
    local period = 1000; -- basically 50 * 20
    emulateAnimEvent(self.netAction, period, "update", nil)
end

function UB_RefuelVehicleAction:start()
    self:setActionAnim("fill_container_tap")
    self:setOverrideHandModels(nil, nil)

    --self.character:reportEvent("EventTakeWater");

    self.sound = self.character:playSound("GetWaterFromLake")
end

function UB_RefuelVehicleAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function UB_RefuelVehicleAction:perform()
    self.character:stopOrTriggerSound(self.sound)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function UB_RefuelVehicleAction:complete()
    self.barrel:adjustAmount(self.barrelTarget)
    self.barrelObj:sync()
    LuaEventManager.triggerEvent("OnWaterAmountChange", self.barrelObj, -1)
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

    --UB_Utils.info(string.format(table.concat({
    --    "UB_RefuelVehicleAction:complete()",
    --    "amountSent=%s"
    --}, "\n"),
    --self.amountSent))

    return true
end

function UB_RefuelVehicleAction:serverStop()
    --local barrelLitres = self.barrelStart + (self.barrelTarget - self.barrelStart) * self.netAction:getProgress()
    --self.barrel:adjustAmount(math.ceil(barrelLitres));
    --local litres = self.tankStart + (self.tankTarget - self.tankStart) * self.netAction:getProgress()
    --self.part:setContainerContentAmount(math.floor(litres))
    self.vehicle:transmitPartModData(self.part)
end

function UB_RefuelVehicleAction:getDuration()
    self.tankStart = self.part:getContainerContentAmount()
    self.barrelStart = self.barrel:getAmount()

    local tankLitresRequired = self.part:getContainerCapacity() - self.tankStart
    local amountToTransfer = math.min(tankLitresRequired, self.barrelStart)

    self.tankTarget = self.tankStart + amountToTransfer
    self.barrelTarget = self.barrelStart - amountToTransfer
    self.amountSent = self.tankStart

    UB_Utils.info(string.format(table.concat({
        "UB_RefuelVehicleAction:getDuration()",
        "tank start=%s -> target=%s",
        "barrel Start=%s -> target=%s",
        "amountSent=%s",
        "time=%s"
    }, "\n"),
    self.tankStart, self.tankTarget,
    self.barrelStart, self.barrelTarget,
    self.amountSent, amountToTransfer * UB_Const.BASE_FUEL_TRANSFER_RATE))

    if self.character:isTimedActionInstant() then
        return 1
    end

    return amountToTransfer * UB_Const.BASE_FUEL_TRANSFER_RATE
end

function UB_RefuelVehicleAction:new(character, part, barrelObj)
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

