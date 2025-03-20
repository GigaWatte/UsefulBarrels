
local UBUtils = require "UBUtils"

local onPumpFromBarrel = function(playerObj, part, barrel)
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	if barrel then
		local square = fuelStation:getSquare();
		if square then
			local action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
			action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
			ISTimedActionQueue.add(action)
			ISTimedActionQueue.add(ISRefuelFromGasPump:new(playerObj, part, barrel))
		end
	end
end

local ISVehicleMenu_FillPartMenu = ISVehicleMenu.FillPartMenu
function ISVehicleMenu.FillPartMenu(playerIndex, context, slice, vehicle)
    ISVehicleMenu_FillPartMenu(playerIndex, context, slice, vehicle)

    local playerObj = getSpecificPlayer(playerIndex);
	if playerObj:DistToProper(vehicle) >= 4 then
		return
	end
    local typeToItem = VehicleUtils.getItems(playerIndex)
	for i=1,vehicle:getPartCount() do
		local part = vehicle:getPartByIndex(i-1)
		if not vehicle:isEngineStarted() and part:isContainer() and part:getContainerContentType() == "Gasoline" then
            local barrel = UBUtils.GetBarrelNearbyVehicle(vehicle)
            if barrel then
                local square = barrel:getSquare()
                if square and part:getContainerContentAmount() < part:getContainerCapacity() then
                    if slice then
                        slice:addSlice(getText("ContextMenu_UB_RefuelFromBarrel"), getTexture("media/textures/Item_Drum_Orange.png"), ISVehiclePartMenu.onPumpGasoline, playerObj, part, barrel)
                    else
                        context:addOption(getText("ContextMenu_UB_RefuelFromBarrel"), playerObj, ISVehiclePartMenu.onPumpGasoline, part, barrel)
                    end
                end
            end
        end
    end
end