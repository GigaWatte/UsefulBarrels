if getActivatedMods():contains("\\RicksMLC_PayAtThePump") then
    local lib = require("RicksMLC_PayAtThePump")
    local overrideISRefuelFromGasPumpNew = UB_TransferFluidFromGasPumpAction.new
    function UB_TransferFluidFromGasPumpAction:new(character, part, fuelStation, time)
        local this = overrideISRefuelFromGasPumpNew(self, character, part, fuelStation, time)
        print(lib)
        --initPurchaseFuel(this)
        return this
    end

    local overrideISRefuelFromGasPumpUpdate = UB_TransferFluidFromGasPumpAction.update
    function UB_TransferFluidFromGasPumpAction.update(self)
        overrideISRefuelFromGasPumpUpdate(self)
        --updateFuelPurchase(self, self.tankStart, self.tankTarget)
    end

    local overrideStop = UB_TransferFluidFromGasPumpAction.stop
    function UB_TransferFluidFromGasPumpAction.stop(self)
        --handleEmergencyStop(self)
        overrideStop(self)
    end
end