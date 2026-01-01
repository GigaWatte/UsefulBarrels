
local UB_Utils = require "UB_Utils"
local UB_FluidBarrel = require "UB_FluidBarrel"

local ISAddFluidFromItemAction_getDuration = ISAddFluidFromItemAction.getDuration
function ISAddFluidFromItemAction:getDuration()
    local original_duration = ISAddFluidFromItemAction_getDuration(self)

    if SandboxVars.UsefulBarrels.RequireFunnelForFill == false then return original_duration end

    if SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier > 1 then
        local ub_barrel = UB_Utils.GetValidBarrelFromWorldObjects({self.objectTo})
        if ub_barrel and ub_barrel.Type == UB_FluidBarrel.Type then
            local speedModifier = SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier

            UB_Utils.info(string.format(
                "original_duration=%.2f, speedModifier=%.2f, after_apply=%.2f",
                original_duration, speedModifier, original_duration / speedModifier
            ))

            return original_duration / speedModifier
        end
    end

    return original_duration
end