
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
	return UBUtils.TableContainsItem(worldObjects, item) or UBUtils.playerHasItem(playerInv, item)
end

function UBUtils.getPlayerFluidContainers(playerInv)
    local itemsArray = playerInv:getAllEvalRecurse(
        function (item) return UBUtils.predicateAnyFluid(item) and not UBBarrel.validate(item) end
    )
	return UBUtils.ConvertToTable(itemsArray)
end

function UBUtils.getPlayerFluidContainersWithFluid(playerInv, fluid)
	local itemsArray = playerInv:getAllEvalRecurse(
        function (item) return (UBUtils.predicateFluid(item, fluid) or UBUtils.predicateHasFluidContainer(item)) and not UBBarrel.validate(item) end
    )
    
    return UBUtils.ConvertToTable(itemsArray)
end

function UBUtils.GetValidBarrel(worldObjects)
    for i,isoObject in ipairs(worldObjects) do
        --print(isoObject)
        if UBBarrel.validate(isoObject) then return isoObject end
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
    if isDiamondShape == nil then isDiamondShape = true end

    local x,y,z = square:getX(), square:getY(), square:getZ()
    local cell = square:getCell()
	local squares = {}
    for xx = -distance,distance do
        for yy = -distance,distance do
            if isDiamondShape and math.abs(xx) + math.abs(yy) <= distance then
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

function UBUtils.GetWorldItemsNearby(square, distance, isDiamondShape)
    if not square then return nil end

    local squares = UBUtils.GetSquaresInRange(square, distance, true, isDiamondShape)

    local worldItems = {}
    for _,curr in ipairs(squares) do
        local squareWorldItems = curr:getWorldObjects()
        for i=0, squareWorldItems:size() - 1 do
            local item = squareWorldItems:get(i)
            if not luautils.tableContains(worldItems, item) then table.insert(worldItems, item) end
        end
    end

    return worldItems
end

function UBUtils.GetBarrelsNearby(square, distance, fluid, sortByDistance)
    -- this function not include an initial square in searching process
    if not square then return {} end

    local squares = UBUtils.GetSquaresInRange(square, distance, false)

    local barrels = {}
    for _,curr in ipairs(squares) do
        local squareObjects = curr:getObjects()
        local sqTable = UBUtils.ConvertToTable(squareObjects)
        local plainBarrel = UBUtils.GetValidBarrel(sqTable)
        local barrel = UBBarrel:new(plainBarrel)
        if barrel and barrel:hasFluidContainer() then
            if fluid and barrel:ContainsFluid(fluid) then
                table.insert(barrels, barrel)
            elseif fluid == nil then
                table.insert(barrels, barrel)
            end
        end
    end

    if #barrels > 1 and sortByDistance ~= nil and sortByDistance then
        table.sort(barrels, function(a,b) return IsoUtils.DistanceTo(
            a.isoObject:getX(), a.isoObject:getY(), square:getX(), square:getY()
        ) < IsoUtils.DistanceTo(
            b.isoObject:getX(), b.isoObject:getY(), square:getX(), square:getY()
        ) end)
    end
    
    return barrels
end

function UBUtils.GetVehiclePartSquare(vehicle, part)
    local areaCenter = vehicle:getAreaCenter(part:getArea())
    if not areaCenter then return nil end
    return getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
end

function UBUtils.GetVehiclesNeaby(square, distance)
    if not square then return {} end

    local squares = UBUtils.GetSquaresInRange(square, distance, false, true)

    local vehicles = {}
    for _,curr in ipairs(squares) do
        local vehicle = curr:getVehicleContainer()
        if not luautils.tableContains(vehicles, vehicle) then table.insert(vehicles, vehicle) end
    end

    return vehicles
end

function UBUtils.GetWorldFluidContainersNearby(barrel_square, distance, containerPredicate)
    local worldObjects = UBUtils.GetWorldItemsNearby(barrel_square, distance)
    local fluidContainerItems = {}
    for _,worldInventoryObject in ipairs(worldObjects) do
        -- this is needed to update world item name to display an actual name of item
        if worldInventoryObject:getItem() then 
            worldInventoryObject:setName(worldInventoryObject:getItem():getName()) 
        end

        if containerPredicate then
            table.insert(fluidContainerItems, worldInventoryObject)
        end
    end
    return fluidContainerItems
end

function UBUtils.CanCreateBarrelFluidMenu(playerObj, barrelSquare, barrelOption)
    -- thats from vanilla method. it seems to verify target square room and current player room
    if barrelSquare:getBuilding() ~= playerObj:getBuilding() then
        if barrelOption then
            UBUtils.DisableOptionAddTooltip(barrelOption, getText("ContextMenu_UB_BuildingMismatch"))
        end
        return false
    end
    --if the player can reach the tile, populate the submenu, otherwise don't bother
    if not barrelSquare or not AdjacentFreeTileFinder.Find(barrelSquare, playerObj) then
        if barrelOption then
            UBUtils.DisableOptionAddTooltip(barrelOption, getText("ContextMenu_UB_BarrelIsObstructed"))
        end
        return false
    end

    if IsoUtils.DistanceTo(playerObj:getX(), playerObj:getY(), barrelSquare:getX() + 0.5, barrelSquare:getY() + 0.5) > 4 then
        if barrelOption then
            UBUtils.DisableOptionAddTooltip(barrelOption, getText("ContextMenu_UB_BarrelTooFar"))
        end
        return false
    end

    return true
end

return UBUtils