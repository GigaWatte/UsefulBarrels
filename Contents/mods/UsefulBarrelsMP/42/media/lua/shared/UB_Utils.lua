local UB_Barrel = require "UB_Barrel"
local UB_FluidBarrel = require "UB_FluidBarrel"
local UB_Utils = {}

function UB_Utils.info(message)
    -- add sandbox var check here
        if isClient() then
            if getDebug() then
                print(string.format("[UsefulBarrelsMP:Client] %s", tostring(message)))
            end
        else
            print(string.format("[UsefulBarrelsMP:Server] %s", tostring(message)))
        end
end

function UB_Utils.PredicateNotBroken(item) return not item:isBroken() end

function UB_Utils.PlayerGetItem(playerInv, itemTag)
    --local cond1 = playerInv:getFirstTypeEvalRecurse(itemName, UB_Utils.PredicateNotBroken)
    local cond2 = playerInv:getFirstTagEvalRecurse(itemTag, UB_Utils.PredicateNotBroken)
    return cond2 --cond1 or cond2
end

function UB_Utils.DisableOptionAddTooltip(option, description, object)
    if option then
        option.notAvailable = true
        option.toolTip = ISToolTip:new()
        if object then option.toolTip.object = object end
        if description then option.toolTip.description = description else option.toolTip.description = "" end
        if option.subOption then option.subOption = nil end
    end
end

function UB_Utils.GetValidBarrelFromWorldObjects(worldObjects)
    for i,isoObject in ipairs(worldObjects) do
        local isValid = UB_Barrel.validate(isoObject)
        if isValid then
            local ubFluidBarrel = UB_FluidBarrel:new(isoObject)
            if ubFluidBarrel then return ubFluidBarrel end
            local ubBarrel = UB_Barrel:new(isoObject)
            if ubBarrel then return ubBarrel end
        end
    end
end

function UB_Utils.CanCreateBarrelFluidMenu(playerObj, barrelSquare, barrelOption)
    -- thats from vanilla method. it seems to verify target square room and current player room
    if barrelSquare:getBuilding() ~= playerObj:getBuilding() then
        if barrelOption then
            UB_Utils.DisableOptionAddTooltip(barrelOption, getText("ContextMenu_UB_BuildingMismatch"))
        end
        return false
    end
    --if the player can reach the tile, populate the submenu, otherwise don't bother
    if not barrelSquare or not AdjacentFreeTileFinder.Find(barrelSquare, playerObj) then
        if barrelOption then
            UB_Utils.DisableOptionAddTooltip(barrelOption, getText("ContextMenu_UB_BarrelIsObstructed"))
        end
        return false
    end

    if IsoUtils.DistanceTo(playerObj:getX(), playerObj:getY(), barrelSquare:getX() + 0.5, barrelSquare:getY() + 0.5) > 4 then
        if barrelOption then
            UB_Utils.DisableOptionAddTooltip(barrelOption, getText("ContextMenu_UB_BarrelTooFar"))
            -- TODO remove all suboptions as well
            barrelOption.subOption = nil
        end
        return false
    end

    return true
end

function UB_Utils.GetWorldItemsNearby(square, distance, isDiamondShape)
    if not square then return nil end

    local squares = UB_Utils.GetSquaresInRange(square, distance, true, isDiamondShape)

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

function UB_Utils.GetSquaresInRange(square, distance, includeInitialSquare, isDiamondShape)
    if not distance then distance = 1 end
    if isDiamondShape == nil then isDiamondShape = true end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local cell = square:getCell()
    local squares = {}
    for xx = -distance,distance do
        for yy = -distance,distance do
            if (xx == 0) and (yy == 0) then
                local nextSquare = cell:getGridSquare(x+xx, y+yy, z)
                if nextSquare and includeInitialSquare == true then table.insert(squares, nextSquare) end
            elseif isDiamondShape and math.abs(xx) + math.abs(yy) <= distance then
                local nextSquare = cell:getGridSquare(x+xx, y+yy, z)
                if nextSquare then table.insert(squares, nextSquare) end
            elseif not isDiamondShape then
                local nextSquare = cell:getGridSquare(x+xx, y+yy, z)
                if nextSquare then table.insert(squares, nextSquare) end
            end
        end 
    end

    return squares
end

function UB_Utils.HasItemNearbyOrInInv(worldObjects, playerInv, itemTag)
    return UB_Utils.TableContainsItem(worldObjects, itemTag) or UB_Utils.PlayerHasItem(playerInv, itemTag)
end

function UB_Utils.PlayerHasItem(playerInv, itemTag)
    --local cond1 = playerInv:containsTypeEvalRecurse(itemName, UB_Utils.PredicateNotBroken)
    local cond2 = playerInv:containsTagEvalRecurse(itemTag, UB_Utils.PredicateNotBroken)
    return cond2 --cond1 or
end

function UB_Utils.TableContainsItem(table, itemTag)
    for _,v in pairs(table) do
        local item = v:getItem()
        if item:hasTag(itemTag) then return true end
    end
    return false
end

function UB_Utils.GetPlayerFluidContainers(playerInv)
    local itemsArray = playerInv:getAllEvalRecurse(
        function (item) return UB_Utils.PredicateAnyFluid(item) and not UB_Barrel.validate(item) end
    )
    return UB_Utils.ConvertToTable(itemsArray)
end

function UB_Utils.GetPlayerFluidContainersWithFluid(playerInv, fluid)
    local itemsArray = playerInv:getAllEvalRecurse(
        function (item) return (UB_Utils.PredicateFluid(item, fluid) or UB_Utils.PredicateHasFluidContainer(item)) and not UB_Barrel.validate(item) end
    )
    
    return UB_Utils.ConvertToTable(itemsArray)
end

function UB_Utils.PredicateAnyFluid(item)
    return item:getFluidContainer() and (item:getFluidContainer():getAmount() > 0) -- >= 0.5 previously
end

function UB_Utils.PredicateFluid(item, fluid)
    return item:getFluidContainer() and item:getFluidContainer():contains(fluid) and (item:getFluidContainer():getAmount() >= 0.5)
end

function UB_Utils.PredicateHasFluidContainer(item) return item:hasComponent(ComponentType.FluidContainer) end


function UB_Utils.ConvertToTable(list)
    local tbl = {}
    for i=0, list:size() - 1 do
        local item = list:get(i)
        table.insert(tbl, item)
    end
    return tbl
end

function UB_Utils.GetWorldFluidContainersNearby(barrel_square, distance, containerPredicate)
    local worldObjects = UB_Utils.GetWorldItemsNearby(barrel_square, distance)
    local fluidContainerItems = {}
    for _,worldInventoryObject in ipairs(worldObjects) do
        -- this is needed to update world item name to display an actual name of item
        if worldInventoryObject:getItem() then
            worldInventoryObject:setName(worldInventoryObject:getItem():getName())
        end

        if containerPredicate(worldInventoryObject) then
            table.insert(fluidContainerItems, worldInventoryObject)
        end
    end
    return fluidContainerItems
end

function UB_Utils.SortContainers(allContainers)
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

function UB_Utils.GetBarrelsNearby(square, distance, fluid, sortByDistance)
    -- this function not include an initial square in searching process
    if not square then return {} end

    local squares = UB_Utils.GetSquaresInRange(square, distance, false)

    local barrels = {}
    for _,curr in ipairs(squares) do
        local squareObjects = curr:getObjects()
        local sqTable = UB_Utils.ConvertToTable(squareObjects)
        local barrel = UB_Utils.GetValidBarrelFromWorldObjects(sqTable)
        if barrel and barrel.Type == UB_FluidBarrel.Type then
            if barrel:hasFluidContainer() then
                if fluid and barrel:ContainsFluid(fluid) then
                    table.insert(barrels, barrel)
                elseif fluid == nil then
                    table.insert(barrels, barrel)
                end
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

function UB_Utils.GetVehiclePartSquare(vehicle, part)
    local areaCenter = vehicle:getAreaCenter(part:getArea())
    if not areaCenter then return nil end
    return getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
end

function UB_Utils.GetVehiclesNeaby(square, distance)
    if not square then return {} end

    local squares = UB_Utils.GetSquaresInRange(square, distance, false, true)

    local vehicles = {}
    for _,curr in ipairs(squares) do
        local vehicle = curr:getVehicleContainer()
        if not luautils.tableContains(vehicles, vehicle) then table.insert(vehicles, vehicle) end
    end

    return vehicles
end

return UB_Utils
