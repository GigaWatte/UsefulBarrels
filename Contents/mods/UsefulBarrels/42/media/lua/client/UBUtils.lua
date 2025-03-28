
local UBUtils = {}
local UBBarrel = require("UBBarrel")

function UBUtils.predicateFluid(item, fluid)
    return item:getFluidContainer() and item:getFluidContainer():contains(fluid) and (item:getFluidContainer():getAmount() >= 0.5)
end

function UBUtils.predicateHasEmptyFluidContainer(item)
    return item:hasComponent(ComponentType.FluidContainer) and item:getComponent(ComponentType.FluidContainer):isEmpty()
end

function UBUtils.predicateHasFluidContainer(item) return item:hasComponent(ComponentType.FluidContainer) end

function UBUtils.predicateAnyFluid(item)
    return item:getFluidContainer() and (item:getFluidContainer():getAmount() >= 0.5)
end

function UBUtils.predicateStoreFluid(item, fluid)
    local fluidContainer = item:getFluidContainer()
    if not fluidContainer then return false end
    -- our item can store fluids and is empty
    if fluidContainer:isEmpty() then --and not item:isBroken()
        return true
    end
    -- or our item is already storing fuel but is not full
    if fluidContainer:contains(fluid) and (fluidContainer:getAmount() < fluidContainer:getCapacity()) and not item:isBroken() then
        return true
    end
    return false
end

function UBUtils.predicateNotBroken(item)
    return not item:isBroken()
end

function UBUtils.hasItemNearbyOrInInv(worldObjects, playerInv, item)
	return UBUtils.TableContainsItem(worldObjects, item) or UBUtils.playerHasItem(self.playerInv, item)
end

function UBUtils.getPlayerFluidContainers(playerInv)
	return playerInv:getAllEvalRecurse(
		function (item) return UBUtils.predicateAnyFluid(item) and not UBBarrel.validate(item) end
	)
end

function UBUtils.getPlayerFluidContainersWithFluid(playerInv, fluid)
	return playerInv:getAllEvalRecurse(
        function (item) return (
			UBUtils.predicateFluid(item, fluid) or UBUtils.predicateHasFluidContainer(item)
		) and not UBBarrel.validate(item) end
    )
end

function UBUtils.FormatFluidAmount(setX, amount, max, fluidName)
    if max >= 9999 then
        return string.format("%s: <SETX:%d> %s", getText(fluidName), setX, getText("Tooltip_WaterUnlimited"))
    end
    return string.format("%s: <SETX:%d> %s / %s", getText(fluidName), setX, luautils.round(amount, 2) .. "L", max .. "L")
end

function UBUtils.GetUBBarrel(worldObjects)
    for i,isoObject in ipairs(worldObjects) do
		local obj = UBBarrel:new(isoObject)
        if obj then return obj end
    end
end

function UBUtils.playerHasItem(playerInv, itemName) return playerInv:containsTypeEvalRecurse(itemName, UBUtils.predicateNotBroken) or playerInv:containsTagEvalRecurse(itemName, UBUtils.predicateNotBroken) end

function UBUtils.playerGetItem(playerInv, itemName) return playerInv:getFirstTypeEvalRecurse(itemName, UBUtils.predicateNotBroken) or playerInv:getFirstTagEvalRecurse(itemName, UBUtils.predicateNotBroken) end

function UBUtils.ConvertToTable(list)
    local tbl = {}
    for i=0, list:size() - 1 do
        local item = list:get(i)
        table.insert(tbl, item)
    end
    return tbl
end

function UBUtils.SortContainers(allContainers)
    local allContainerTypes = {}
    if #allContainers == 0 then return allContainerTypes end
    local allContainersOfType = {}
    ----the table can have small groups of identical containers        eg: 1, 1, 2, 3, 1, 3, 2
    ----so it needs sorting to group them all together correctly        eg: 1, 1, 1, 2, 2, 3, 3
    table.sort(allContainers, function(a,b) return not string.sort(a:getName(), b:getName()) end)
    ----once sorted, we can use it to make smaller tables for each item type
    local previousContainer = nil;
    for _,container in pairs(allContainers) do
        if previousContainer ~= nil and container:getName() ~= previousContainer:getName() then
            table.insert(allContainerTypes, allContainersOfType)
            allContainersOfType = {}
        end
        table.insert(allContainersOfType, container)
        previousContainer = container
    end
    table.insert(allContainerTypes, allContainersOfType)
    return allContainerTypes
end

function UBUtils.DisableOptionAddTooltip(option, description)
    if option then
        option.notAvailable = true
        option.toolTip = ISWorldObjectContextMenu.addToolTip()
        if description then option.toolTip.description = description else option.toolTip.description = "" end
    end
end

function UBUtils.CleanMenuFromBarrels(context, optionName)
    local option = context:getOptionFromName(optionName)
    if option then
        local subMenu = context:getSubMenu(option.subOption)
        if subMenu then
            local namesToSearch = {
                Translator.getItemNameFromFullType("Base.MetalDrum"),
                Translator.getItemNameFromFullType("Base.Mov_LightGreenBarrel"),
                Translator.getItemNameFromFullType("Base.Mov_OrangeBarrel"),
                Translator.getItemNameFromFullType("Base.Mov_DarkGreenBarrel"),
            }
            -- remove barrel options from sub menu
            for i = 1, #namesToSearch do
                if subMenu:getOptionFromName(namesToSearch[i]) then subMenu:removeOptionByName(namesToSearch[i]) end
            end
            -- remove fill all button if there is only one container left
            if subMenu.numOptions <= 3 and subMenu:getOptionFromName(getText("ContextMenu_FillAll")) then 
                subMenu:removeOptionByName(getText("ContextMenu_FillAll")) 
            end
            -- remove entire option if there is no options at all
            if subMenu.numOptions == 1 then
                context:removeOptionByName(optionName)
            end 
        end
    end
end

function UBUtils.CleanItemContainersFromBarrels(containerList, container)
    local filteredContainerList = {}
    if not containerList or (containerList and #containerList == 0) and container then
        if container:hasModData() then
            local modData = container:getModData()
            if modData["modData"] ~= nil and modData["modData"]["UB_Uncapped"] ~= nil then
                -- skip my barrel
            else
                table.insert(filteredContainerList, container)
            end
        else
            table.insert(filteredContainerList, container)
        end
    elseif containerList then
        for _,container in pairs(containerList) do
            if container:hasModData() then
                local modData = container:getModData()
                if modData["modData"] ~= nil and modData["modData"]["UB_Uncapped"] ~= nil then
                    -- skip my barrels
                else
                    table.insert(filteredContainerList, container)
                end
            else
                table.insert(filteredContainerList, container)
            end
        end
    end
    return filteredContainerList
end

function UBUtils.GetSquaresInRange(square, distance, includeInitialSquare, isDiamondShape)
	if not distance then distance = 1 end
    if not isDiamondShape then isDiamondShape = true end

    local x,y,z = square:getX(), square:getY(), square:getZ()
    local cell = square:getCell()
	local squares = {}
    for xx = -distance,distance + 1 do
        for yy = -distance,distance + 1 do
            if isDiamondShape and math.abs(x) + math.abs(y) <= distance then
				local nextSquare = cell:getGridSquare(x+xx, y+yy, z)
                if nextSquare then table.insert(squares, nextSquare) end
            elseif not isDiamondShape then
				local nextSquare = cell:getGridSquare(x+xx, y+yy, z)
                if nextSquare then table.insert(squares, nextSquare) end
            end
        end 
    end

    if includeInitialSquare ~= nil and includeInitialSquare then
        table.insert(squares, square)
    end
    return squares
end

function UBUtils.TableContainsItem(table, item_name)
    for _,v in pairs(table) do 
        local item = v:getItem()
        if item_name == item:getFullType() then return true end
    end
    return false
end

function UBUtils.GetWorldItemsNearby(square, distance)
    if not square then return nil end

    local squares = UBUtils.GetSquaresInRange(square, distance, true)

    local worldItems = {}
    for _,curr in ipairs(squares) do
        local squareWorldItems = curr:getWorldObjects()
        local sqTable = UBUtils.ConvertToTable(squareWorldItems)
        for _,worldItem in ipairs(sqTable) do
            table.insert(worldItems, worldItem)
        end
    end

    return worldItems
end

function UBUtils.GetBarrelsNearby(square, distance, fluid)
    -- this function not include an initial square in searching process
    if not square then return nil end

    local squares = UBUtils.GetSquaresInRange(square, distance, false)

    local barrels = {}
    for _,curr in ipairs(squares) do
        local squareObjects = curr:getObjects()
        local sqTable = UBUtils.ConvertToTable(squareObjects)
        local barrel = UBUtils.GetUBBarrel(sqTable)
        if barrel and barrel:hasFluidContainer() then
            if fluid and barrel:ContainsFluid(fluid) then
                table.insert(barrels, barrel)
            elseif fluid == nil then
                table.insert(barrels, barrel)
            end
        end
    end
    
    return barrels
end

function UBUtils.GetBarrelsNearbyVehicle(vehicle, distance)
    local part = vehicle:getPartById("GasTank")
    if not part then return nil end
    local areaCenter = vehicle:getAreaCenter(part:getArea())
    if not areaCenter then return nil end
    local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
    if not square then return nil end

    local barrels = UBUtils.GetBarrelsNearby(square, distance, Fluid.Petrol)

    if #barrels == 1 then return nil end

    return barrels
end

return UBUtils