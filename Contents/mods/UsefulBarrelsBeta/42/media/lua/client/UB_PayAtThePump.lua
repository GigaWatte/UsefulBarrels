
if getActivatedMods():contains("\\RicksMLC_PayAtThePump") then
    local originalUB_TransferFluidFromGasPumpActionNew = UB_TransferFluidFromGasPumpAction.new
    function UB_TransferFluidFromGasPumpAction:new(character, fuelStation, barrel)
        local this = originalUB_TransferFluidFromGasPumpActionNew(self, character, fuelStation, barrel)
        RicksMLC_PayAtPumpAPI.initPurchaseFuel(this)
        return this
    end

    local originalUB_TransferFluidFromGasPumpActionUpdate = UB_TransferFluidFromGasPumpAction.update
    function UB_TransferFluidFromGasPumpAction:update()
        originalUB_TransferFluidFromGasPumpActionUpdate(self)
        RicksMLC_PayAtPumpAPI.updateFuelPurchase(self, self.destinationStart, self.destinationTarget)
    end

    local originalUB_TransferFluidFromGasPumpActionStop = UB_TransferFluidFromGasPumpAction.stop
    function UB_TransferFluidFromGasPumpAction:stop()
        RicksMLC_PayAtPumpAPI.handleEmergencyStop(self)
        originalUB_TransferFluidFromGasPumpActionStop(self)
    end
end