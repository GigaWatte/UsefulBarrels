local UB_Utils = require "UB_Utils"
local UB_FluidBarrel = require "UB_FluidBarrel"

local function OnWaterAmountChange(object, prevAmount)
    if not object then return end
    local ub_barrel = UB_Utils.GetValidBarrelFromWorldObjects({object});
    if not ub_barrel then return end
    if ub_barrel.Type ~= UB_FluidBarrel.Type then return end
    ub_barrel:UpdateWaterLevel()
end


Events.OnWaterAmountChange.Add(OnWaterAmountChange)