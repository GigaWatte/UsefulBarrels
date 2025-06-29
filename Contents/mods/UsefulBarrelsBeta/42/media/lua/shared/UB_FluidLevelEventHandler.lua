local UBUtils = require "UBUtils"
local UBFluidBarrel = require "UBFluidBarrel"

local function OnWaterAmountChange(object, prevAmount)
    if not object then return end
    local ub_barrel = UBUtils.GetValidBarrel({object})
    if not ub_barrel then return end
    if ub_barrel.Type ~= UBFluidBarrel.Type then return end
    ub_barrel:UpdateWaterLevel()
end


Events.OnWaterAmountChange.Add(OnWaterAmountChange)