local UB_Utils = require "UB_Utils"
local UB_FluidBarrel = require "UB_FluidBarrel"

local function OnWaterAmountChange(object, prevAmount)
    --print(string.format("Update water amount %s for: ", prevAmount), object)
    if not object then return end
    local ub_barrel = UB_Utils.GetValidBarrelFromWorldObjects({object});
    --print(string.format("barrel validated"), object)
    if not ub_barrel then return end
    --print(string.format("barrel type"), ub_barrel.Type)
    if ub_barrel.Type ~= UB_FluidBarrel.Type then return end
    --print(string.format("call update water level"), ub_barrel.Type)
    ub_barrel:UpdateWaterLevel()
end


Events.OnWaterAmountChange.Add(OnWaterAmountChange)