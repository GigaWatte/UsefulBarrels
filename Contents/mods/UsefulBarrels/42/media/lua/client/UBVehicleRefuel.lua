
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"

local onPumpFromBarrel = function(playerObj, part, barrel)
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	if barrel then
		local action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
		action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
		ISTimedActionQueue.add(action)
		
		ISTimedActionQueue.add(ISUBRefuelFromBarrel:new(playerObj, part, barrel))
	end
end

local ISVehicleMenu_FillPartMenu = ISVehicleMenu.FillPartMenu
function ISVehicleMenu.FillPartMenu(playerIndex, context, slice, vehicle)
    ISVehicleMenu_FillPartMenu(playerIndex, context, slice, vehicle)

	if not SandboxVars.UsefulBarrels.EnableCarRefuel then return end

    local playerObj = getSpecificPlayer(playerIndex)
	if playerObj:DistToProper(vehicle) >= 4 then return end
	if vehicle:isEngineStarted() then return end
    --local typeToItem = VehicleUtils.getItems(playerIndex)
	local part = vehicle:getPartById("GasTank")
	local barrels = UBUtils.GetBarrelsNearbyVehicle(vehicle, 3)

	if not barrels then return end

	if part and part:isContainer() and part:getContainerContentType() == "Gasoline" and #barrels > 0 then
		local barrel = barrels[1]
		local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
        local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerObj:getInventory(), "Base.RubberHose")
		if part:getContainerContentAmount() < part:getContainerCapacity() then
			if slice then
				if SandboxVars.UsefulBarrels.CarRefuelRequiresHose and not hasHoseNearby then 
					slice:addSlice(
						getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")), 
						getTexture("media/textures/Item_Drum_Orange.png"), 
						nil, nil
					)
				elseif (SandboxVars.UsefulBarrels.CarRefuelRequiresHose and hasHoseNearby) or (not SandboxVars.UsefulBarrels.CarRefuelRequiresHose) then
					slice:addSlice(
						getText("ContextMenu_UB_RefuelFromBarrel"), 
						getTexture("media/textures/Item_Drum_Orange.png"), 
						onPumpFromBarrel, playerObj, part, barrel
					)
				end
			else
				local option = context:addOption(
					getText("ContextMenu_UB_RefuelFromBarrel"), 
					playerObj, 
					onPumpFromBarrel, part, barrel
				)
				if SandboxVars.UsefulBarrels.CarRefuelRequiresHose and not hasHoseNearby then 
					UBUtils.DisableOptionAddTooltip(option, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose"))) 
				end
			end
		end
	end
end