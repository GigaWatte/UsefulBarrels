
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
        
        ISTimedActionQueue.add(UB_RefuelVehicleAction:new(playerObj, part, barrel))
    end
end

local function DoDebugOption(context, playerObj, vehicle)
    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    debugOption.toolTip = ISWorldObjectContextMenu.addToolTip()

    local description = string.format(
        [[
        distance: %s
        isEngineStarted: %s
        ]],
        tostring(playerObj:DistToProper(vehicle)),
        tostring(vehicle:isEngineStarted())
    )

    local part_found = false
    for i=1,vehicle:getPartCount() do
        local part = vehicle:getPartByIndex(i-1)
        local partCategory = part:getCategory()
        if part 
            and partCategory 
            and part:isContainer() 
            and string.find(partCategory, "gastank")~=nil 
            and string.find(part:getContainerContentType(), "Gasoline")
            and part:getContainerContentAmount() < part:getContainerCapacity() then
                local barrels = UBUtils.GetBarrelsNearbyVehiclePart(vehicle, part, UBConst.VEHICLE_SCAN_DISTANCE)
                part_found = true
                description = description .. string.format(
                    [[
                    tank capacity: %s
                    tank content amount: %s
                    barrels: %s
                    ]],
                    tostring(part:getContainerCapacity()),
                    tostring(part:getContainerContentAmount()),
                    tostring(#barrels)
                )
                if #barrels > 0 then
                    local barrel = barrels[1]
                    local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
                    local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerObj:getInventory(), "Base.RubberHose")
                    
                    description = description .. string.format(
                        [[
                        SVCarRefuelRequiresHose %s
                        hasHoseNearby: %s
                        ]],
                        tostring(SandboxVars.UsefulBarrels.CarRefuelRequiresHose),
                        tostring(hasHoseNearby)
                    )
                end
        end
    end

    if not part_found then
        description = description .. string.format(
            [[
            gas tank not found
            ]]
        )
    end
    debugOption.toolTip.description = description
end

local ISVehicleMenu_FillPartMenu = ISVehicleMenu.FillPartMenu
function ISVehicleMenu.FillPartMenu(playerIndex, context, slice, vehicle)
    ISVehicleMenu_FillPartMenu(playerIndex, context, slice, vehicle)

    if not SandboxVars.UsefulBarrels.EnableCarRefuel then return end

    local playerObj = getSpecificPlayer(playerIndex)

    if SandboxVars.UsefulBarrels.DebugMode and context then
        DoDebugOption(context, playerObj, vehicle)
    end

    if playerObj:DistToProper(vehicle) >= 4 then return end
    if vehicle:isEngineStarted() then return end
    --local typeToItem = VehicleUtils.getItems(playerIndex)

    for i=1,vehicle:getPartCount() do
        local part = vehicle:getPartByIndex(i-1)
        local partCategory = part:getCategory()
        if part 
            and partCategory 
            and part:isContainer() 
            and string.find(partCategory, "gastank")~=nil 
            and string.find(part:getContainerContentType(), "Gasoline")
            and part:getContainerContentAmount() < part:getContainerCapacity() then
                local barrels = UBUtils.GetBarrelsNearbyVehiclePart(vehicle, part, UBConst.VEHICLE_SCAN_DISTANCE)

                if #barrels > 0 then
                    local barrel = barrels[1]
                    local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
                    local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerObj:getInventory(), "Base.RubberHose")
                    if slice then
                        if SandboxVars.UsefulBarrels.CarRefuelRequiresHose and not hasHoseNearby then 
                            slice:addSlice(
                                getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")), 
                                barrel.icon, 
                                nil, nil
                            )
                        elseif (SandboxVars.UsefulBarrels.CarRefuelRequiresHose and hasHoseNearby) or (not SandboxVars.UsefulBarrels.CarRefuelRequiresHose) then
                            slice:addSlice(
                                getText("ContextMenu_UB_RefuelFromBarrel"), 
                                barrel.icon, 
                                onPumpFromBarrel, playerObj, part, barrel
                            )
                        end
                    else
                        local option = context:addOption(
                            getText("ContextMenu_UB_RefuelFromBarrel"), 
                            playerObj, 
                            onPumpFromBarrel, part, barrel
                        )
                        if option and barrel.icon then
                            option.iconTexture = barrel.icon
                        end
                        if SandboxVars.UsefulBarrels.CarRefuelRequiresHose and not hasHoseNearby then 
                            UBUtils.DisableOptionAddTooltip(option, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose"))) 
                        end
                    end
                end
        end
    end
end