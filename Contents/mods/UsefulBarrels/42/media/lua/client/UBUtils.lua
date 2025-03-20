
local UBUtils = {}


-- add my barrels to predicates
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

function UBUtils.getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

function UBUtils.predicateNotBroken(item)
	return not item:isBroken()
end

function UBUtils.FormatFluidAmount(setX, amount, max, fluidName)
	if max >= 9999 then
		return string.format("%s: <SETX:%d> %s", getText(fluidName), setX, getText("Tooltip_WaterUnlimited"))
	end
	return string.format("%s: <SETX:%d> %s / %s", getText(fluidName), setX, luautils.round(amount, 2) .. "L", max .. "L")
end

function UBUtils.GetValidBarrelObject(worldobjects)
    local valid_barrel_moveable_names = {
        "Base.MetalDrum",
		"Base.Mov_LightGreenBarrel",
		"Base.Mov_OrangeBarrel",
		"Base.Mov_DarkGreenBarrel",
    }
    for i,isoobject in ipairs(worldobjects) do
		if not isoobject or not isoobject:getSquare() then return end
        if not isoobject:getSprite() then return end
        if not isoobject:getSpriteName() then return end
        for i = 1, #valid_barrel_moveable_names do
            if isoobject:getSprite():getProperties():Val("CustomItem") == valid_barrel_moveable_names[i] then return isoobject end
        end
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

function UBUtils.ValidateFluidCategoty(fluidContainer)
	local allowList = {
		[FluidCategory.Industrial] = SandboxVars.UsefulBarrels.AllowIndustrial,
		[FluidCategory.Fuel]       = SandboxVars.UsefulBarrels.AllowFuel,
		[FluidCategory.Hazardous]  = SandboxVars.UsefulBarrels.AllowHazardous,
		[FluidCategory.Alcoholic]  = SandboxVars.UsefulBarrels.AllowAlcoholic,
		[FluidCategory.Beverage]   = SandboxVars.UsefulBarrels.AllowBeverage,
		[FluidCategory.Medical]    = SandboxVars.UsefulBarrels.AllowMedical,
		[FluidCategory.Colors]     = SandboxVars.UsefulBarrels.AllowColors,
		[FluidCategory.Dyes]       = SandboxVars.UsefulBarrels.AllowDyes,
		[FluidCategory.HairDyes]   = SandboxVars.UsefulBarrels.AllowHairDyes,
		[FluidCategory.Poisons]    = SandboxVars.UsefulBarrels.AllowPoisons,
		[FluidCategory.Water]      = SandboxVars.UsefulBarrels.AllowWater,
	}
	local fluid = fluidContainer:getPrimaryFluid()
	if not fluid then return true end
	for category, allowed in pairs(allowList) do
		if fluid:isCategory(category) and allowed then return true end
	end
	return false
end

function UBUtils.CanTransferFluid(sourceContainers, targetFluidContainer, transferToSource)
	local toSource = transferToSource ~= nil
	local allContainers = {}
	for _,container in pairs(sourceContainers) do
		local fluidContainer = container:getComponent(ComponentType.FluidContainer)
		if not toSource and FluidContainer.CanTransfer(fluidContainer, targetFluidContainer) then
			if UBUtils.ValidateFluidCategoty(fluidContainer) then
				table.insert(allContainers, container)
			end
		elseif toSource and FluidContainer.CanTransfer(targetFluidContainer, fluidContainer) then
			table.insert(allContainers, container)
		end
	end
	return allContainers
end

function UBUtils.SortContainers(allContainers)
	local allContainerTypes = {}
	if #allContainers == 0 then return allContainerTypes end
	local allContainersOfType = {}
	-- TODO improve sort
	-- first equipped and capable to get fluid
	-- then then most filled
	-- then other ones
	----the table can have small groups of identical containers		eg: 1, 1, 2, 3, 1, 3, 2
	----so it needs sorting to group them all together correctly		eg: 1, 1, 1, 2, 2, 3, 3
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

function UBUtils.GetTranslatedFluidNameOrEmpty(fluidObject)
	if fluidObject then
		return fluidObject:getTranslatedName()
	else
		return getText("ContextMenu_Empty")
	end
end

function UBUtils.FilterMyBarrels(allContainers)
	local containers = {}
	local namesToSearch = {
		Translator.getItemNameFromFullType("Base.MetalDrum"),
		Translator.getItemNameFromFullType("Base.Mov_LightGreenBarrel"),
		Translator.getItemNameFromFullType("Base.Mov_OrangeBarrel"),
		Translator.getItemNameFromFullType("Base.Mov_DarkGreenBarrel"),
	}
	-- remove barrel options from sub menu
	for _,container in pairs(allContainers) do
		local foundMatch = false
		for i = 1, #namesToSearch do
			if container:getName() == namesToSearch[i] then foundMatch = true end
		end
		if not foundMatch then table.insert(containers, container) end
	end
	return containers
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

function UBUtils.CalculateTooltipWeight(_object)
	local weight = 0
	if _object then
		local itemWeight
		if _object:hasComponent(ComponentType.FluidContainer) then
			itemWeight = _object:getFluidContainer():getAmount()
		end
		local sprite = _object:getSprite()
		local props = sprite:getProperties()
		if props and props:Is("CustomItem")  then
			local customItem = props:Val("CustomItem")
			local itemInstance = nil;
			if not ISMoveableSpriteProps.itemInstances[customItem] then
				itemInstance = instanceItem(customItem);
				if itemInstance then
					ISMoveableSpriteProps.itemInstances[customItem] = itemInstance;
				end
			else
				itemInstance = ISMoveableSpriteProps.itemInstances[customItem];
			end
			if itemInstance then
				itemWeight = itemWeight + itemInstance:getActualWeight()
			end
		end
		weight = itemWeight
    end
	return weight
end

function UBUtils.GenerateGridCoordinates(distance, isDiamondShape)
	if not distance then distance = 1 end
	if not isDiamondShape then isDiamondShape = true end
	local grid = {}
	for x = -distance,distance + 1 do
		for y = -distance,distance + 1 do
			if isDiamondShape and math.abs(x) + math.abs(y) <= distance then 
				table.insert(grid, {["x"]=x, ["y"]=y}) 
			elseif not isDiamondShape then
				table.insert(grid, {["x"]=x, ["y"]=y})
			end

		end 
	end
	return grid
end

function UBUtils.GetSquaresFromCenterAtDistance(square, distance, includeInitialSquare)
	local x,y,z = square:getX(), square:getY(), square:getZ()
	local cell = square:getCell()
	local grid = UBUtils.GenerateGridCoordinates(distance, true)
	local squares = {}
	for _,coord in ipairs(grid) do
		local nextSquare = cell:getGridSquare(x+coord.x, y+coord.y, z)
		if nextSquare then table.insert(squares, nextSquare) end
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
	if not distance then distance = 1 end

	local squares = UBUtils.GetSquaresFromCenterAtDistance(square, distance, true)

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
	if not distance then distance = 1 end

	local squares = UBUtils.GetSquaresFromCenterAtDistance(square, distance, false)

	local barrels = {}
	for _,curr in ipairs(squares) do
		local squareObjects = curr:getObjects()
		local sqTable = UBUtils.ConvertToTable(squareObjects)
		local barrel = UBUtils.GetValidBarrelObject(sqTable)
		if barrel and UBUtils.IsUBBarrel(barrel) then
			if fluid and barrel:getFluidContainer():contains(fluid) then
				table.insert(barrels, barrel)
			elseif fluid == nil then
				table.insert(barrels, barrel)
			end
		end
	end
	
	return barrels
end

function UBUtils.IsUBBarrel(object)
	if object then
        local modData = object:getModData()
        if modData and modData["UB_Uncapped"] ~= nil then
            return true
        end
		-- in case of InventoryItem picked from world
		if modData and modData["modData"] and modData["modData"]["UB_Uncapped"] ~= nil then
			return true
		end
    end
	return false
end

function UBUtils.GetBarrelNearbyVehicle(vehicle)
    local part = vehicle:getPartById("GasTank")
	if not part then return nil end
	local areaCenter = vehicle:getAreaCenter(part:getArea())
	if not areaCenter then return nil end
	local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
	if not square then return nil end

    local barrels = UBUtils.GetBarrelsNearby(square, 4, Fluid.Petrol)

    if #barrels == 1 then return nil end

    return barrels[1]
end

return UBUtils