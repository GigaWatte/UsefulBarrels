-- << functions from vanilla pz
local function predicatePetrol(item)
	return item:getFluidContainer() and item:getFluidContainer():contains(Fluid.Petrol) and (item:getFluidContainer():getAmount() >= 0.5)
end

local function predicateStoreFuel(item)
	local fluidContainer = item:getFluidContainer()
	if not fluidContainer then return false end
	-- our item can store fluids and is empty
	if fluidContainer:isEmpty() then --and not item:isBroken()
		return true
	end
	-- or our item is already storing fuel but is not full
	if fluidContainer:contains(Fluid.Petrol) and (fluidContainer:getAmount() < fluidContainer:getCapacity()) and not item:isBroken() then
		return true
	end
	return false
end

local function getMoveableDisplayName(obj)
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

local function predicateNotBroken(item)
	return not item:isBroken()
end

-- >> end functions from vanilla pz

local function hasPipeWrench(playerInv) return playerInv:containsTypeEvalRecurse("PipeWrench", predicateNotBroken) or playerInv:containsTagEvalRecurse("PipeWrench", predicateNotBroken) end

local function getPipeWrench(playerInv) return playerInv:getFirstTypeEvalRecurse("PipeWrench", predicateNotBroken) or playerInv:getFirstTagEvalRecurse("PipeWrench", predicateNotBroken) end

local function UBGetValidBarrel(worldobjects)
    local valid_sprite_names = {
        "industry_01_22", 
        "industry_01_23", 
        "location_military_generic_01_14", 
        "location_military_generic_01_15", 
        "location_military_generic_01_6", 
        "location_military_generic_01_7",
    }

    for i,isoobject in ipairs(worldobjects) do
		if not isoobject or not isoobject:getSquare() then return end
        if not isoobject:getSprite() then return end
        if not isoobject:getSpriteName() then return end
        for i = 1, #valid_sprite_names do
            if isoobject:getSpriteName() == valid_sprite_names[i] then return isoobject end
        end
    end
end

local function IBDoBarrelUncap(player, drumObject)
    local playerObj = getSpecificPlayer(player)
    local wrench = getPipeWrench(playerObj:getInventory())

    if luautils.walkAdj(playerObj, drumObject:getSquare(), true) then
        if SandboxVars.UsefulBarrels.RequirePipeWrench then
            if wrench then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), wrench, true)
                ISTimedActionQueue.add(ISUBDoBarrelUncap:new(playerObj, drumObject, wrench))
            else
                -- pipewrench is missing
            end
        else
            ISTimedActionQueue.add(ISUBDoBarrelUncap:new(playerObj, drumObject, wrench))
        end
    end
end

local function UBFormatFluidAmount(setX, amount, max, fluidName)
	if max >= 9999 then
		return string.format("%s: <SETX:%d> %s", getText(fluidName), setX, getText("Tooltip_WaterUnlimited"))
	end
	return string.format("%s: <SETX:%d> %s / %s", getText(fluidName), setX, luautils.round(amount, 2) .. "L", max .. "L")
end

-- << recreated vanilla functions to work with Petrol filled FluidContainers

local function UBOnTransferFuel(squareToApproach, fuelContainer, fuelContainerList, player, reverse)
    if not reverse then reverse = false end
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local didWalk = false
    for i,item in ipairs(fuelContainerList) do
        if not didWalk and (not squareToApproach or not luautils.walkAdj(playerObj, squareToApproach, true)) then
			return
		end
		didWalk = true

        local returnToContainer = item:getContainer():isInCharacterInventory(playerObj) and item:getContainer()
		ISWorldObjectContextMenu.transferIfNeeded(playerObj, item)
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, playerObj:getPlayerNum())

        if not reverse then
            ISTimedActionQueue.add(ISUBTakeFuel:new(playerObj, fuelContainer, item, squareToApproach, item, fuelContainer))
        else
            ISTimedActionQueue.add(ISUBTakeFuel:new(playerObj, item, fuelContainer, squareToApproach, item, fuelContainer))
        end

        if returnToContainer and (returnToContainer ~= playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, playerInv, returnToContainer))
        end
    end
end


local function UBDoFuelMenu(fuelStorage, playerNum, context)
    local playerObj = getSpecificPlayer(playerNum)
    local playerInv = playerObj:getInventory()
    local squareToApproach = fuelStorage:getSquare()
	
    if squareToApproach:getBuilding() ~= playerObj:getBuilding() then
        context:addOption(getText("ContextMenu_TooFarISuppose"))
        return 
    end

    local allContainers = {}
    local allContainerTypes = {}
    local allContainersOfType = {}

    local allContainersWithFuel = playerInv:getAllEvalRecurse(predicatePetrol)

    local pourInto = playerInv:getAllEvalRecurse(predicateStoreFuel)

    local hasContainerWithFuel = false

    -- player does not have any containers in inventory to work with
    if pourInto:isEmpty() and allContainersWithFuel:isEmpty() then
        local missionOption = context:addOption(getText("ContextMenu_UB_NoContainers"))
        missionOption.notAvailable = true
        return
    end

    if not squareToApproach or not AdjacentFreeTileFinder.Find(squareToApproach, playerObj) then
        --if the player can reach the tile, populate the submenu, otherwise don't bother
        return;
    end

    --make a table of all containers
    for i=0, pourInto:size() - 1 do
        local container = pourInto:get(i)
        table.insert(allContainers, container)
    end

    --the table can have small groups of identical containers		eg: 1, 1, 2, 3, 1, 3, 2
    --so it needs sorting to group them all together correctly		eg: 1, 1, 1, 2, 2, 3, 3
    table.sort(allContainers, function(a,b) return not string.sort(a:getName(), b:getName()) end)

    --once sorted, we can use it to make smaller tables for each item type
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

    --local hasHose = false
    --local hasFunnelNearby = false
    --local funnel = nil
    --SandboxVars.UsefulBarrels.RequireHoseForTake
    --SandboxVars.UsefulBarrels.RequireFunnelForFill
    --SandboxVars.UsefulBarrels.FunnelSpeedUpFillPercentage

    if fuelStorage:getFluidContainer():getAmount() > 0 and not pourInto:isEmpty() then
        local takeOption = context:addOption(getText("ContextMenu_UB_TakeGas"), worldobjects, nil)
        local takeMenu = ISContextMenu:getNew(context)
        context:addSubMenu(takeOption, takeMenu)

        if pourInto:size() > 1 then
            local containerOption = takeMenu:addGetUpOption(getText("ContextMenu_UB_PourToAll"), squareToApproach, UBOnTransferFuel, fuelStorage, allContainers, playerNum);
        end

        for _, destContainer in pairs(allContainers) do
            local fuelContainerList = {}
            table.insert(fuelContainerList, destContainer)
            local containerOption = takeMenu:addGetUpOption(destContainer:getName(), squareToApproach, UBOnTransferFuel, fuelStorage, fuelContainerList, playerNum);
            containerOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            containerOption.toolTip.maxLineWidth = 512
            containerOption.toolTip.description = getText("ContextMenu_UB_GasAmount") .. string.format("%d / %d", destContainer:getFluidContainer():getAmount(), destContainer:getFluidContainer():getCapacity())
        end
    else
        local takeOption = context:addOption(getText("ContextMenu_UB_TakeGas"), worldobjects, nil)
        takeOption.notAvailable = true
        takeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
        takeOption.toolTip.description = getText("Tooltip_UB_NoFuelInBarrel")
    end

    -- if player have canisters with fuel
    if not allContainersWithFuel:isEmpty() then
        local addOption = context:addOption(getText("ContextMenu_UB_AddGas"), worldobjects, nil)
        local addMenu = ISContextMenu:getNew(context)
        context:addSubMenu(addOption, addMenu)

        if allContainersWithFuel:size() > 1 then
            local fuelContainerTable = {}
            for i=0, allContainersWithFuel:size() - 1 do
                local container = allContainersWithFuel:get(i)
                table.insert(fuelContainerTable, container)
            end
            local containerOption = addMenu:addGetUpOption(getText("ContextMenu_UB_AddFromAll"), squareToApproach, UBOnTransferFuel, fuelStorage, fuelContainerTable, playerNum, true);
        end
        for i=0, allContainersWithFuel:size()-1 do
            local fuelContainerTable = {}
            destContainer = allContainersWithFuel:get(i)
            table.insert(fuelContainerTable, destContainer)
            local containerOption = addMenu:addGetUpOption(destContainer:getName(), squareToApproach, UBOnTransferFuel, fuelStorage, fuelContainerTable, playerNum, true);
            containerOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            containerOption.toolTip.maxLineWidth = 512
            containerOption.toolTip.description = getText("ContextMenu_UB_GasAmount") .. string.format("%d / %d", destContainer:getFluidContainer():getAmount(), destContainer:getFluidContainer():getCapacity())
        end
    else
        local addOption = context:addOption(getText("ContextMenu_UB_AddGas"), worldobjects, nil)
        addOption.notAvailable = true
        addOption.toolTip = ISWorldObjectContextMenu.addToolTip()
        addOption.toolTip.description = getText("Tooltip_UB_NoFuelInInventory")
    end
end

-- >> end recreated functions from vanilla pz

local function UBContextMenu(player, context, worldobjects, test)
    local fetch = ISWorldObjectContextMenu.fetchVars or {}
	local playerInv = getSpecificPlayer(player):getInventory()
	local playerHasPipeWrench = hasPipeWrench(playerInv)
    local barrelObj = UBGetValidBarrel(worldobjects)

    if not barrelObj then return end

    local hasFluidContainer = barrelObj:hasComponent(ComponentType.FluidContainer)
    local objectName = barrelObj:getSprite():getProperties():Val("CustomName")
    local objectLabel = getMoveableDisplayName(barrelObj)

    if not hasFluidContainer then
        local openBarrelOption = context:addOptionOnTop(getText("ContextMenu_UB_UncapBarrel", objectLabel), player, IBDoBarrelUncap, barrelObj);
        --local openBarrelOption = context:addOptionOnTop(string.format("%s %s", getText("ContextMenu_UB_UncapBarrel"), objectLabel), player, doBarrelUncap, drumStorageObj);
        if not playerHasPipeWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
            openBarrelOption.notAvailable = true;
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            openBarrelOption.toolTip = tooltip
            openBarrelOption.toolTip.description = getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench"));
        end
    end

    if hasFluidContainer then
        -- get vanilla FluidContainer object option
        local barrelOption = context:getOptionFromName(objectLabel)
        if not barrelOption then
            barrelOption = context:getOptionFromName(objectName)
        end

        if barrelOption then
            local barrelMenu = context:getSubMenu(barrelOption.subOption)

            -- remove all vanilla options
            if context:getOptionFromName(getText("ContextMenu_AddWaterFromItem")) then context:removeOptionByName(getText("ContextMenu_AddWaterFromItem")) end
            if barrelMenu:getOptionFromName(getText("Fluid_Show_Info")) then barrelMenu:removeOptionByName(getText("Fluid_Show_Info")) end
            if barrelMenu:getOptionFromName(getText("Fluid_Transfer_Fluids")) then barrelMenu:removeOptionByName(getText("Fluid_Transfer_Fluids")) end
            if barrelMenu:getOptionFromName(getText("ContextMenu_Drink")) then barrelMenu:removeOptionByName(getText("ContextMenu_Drink")) end
            if barrelMenu:getOptionFromName(getText("ContextMenu_Fill")) then barrelMenu:removeOptionByName(getText("ContextMenu_Fill")) end
            if barrelMenu:getOptionFromName(getText("ContextMenu_Wash")) then barrelMenu:removeOptionByName(getText("ContextMenu_Wash")) end

            local infoOption = barrelMenu:addOption(getText("Fluid_UB_Show_Info"))
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            local tx = getTextManager():MeasureStringX(tooltip.font, getText("Fluid_Name_Petrol") .. ":") + 20
            local fluidAmount = barrelObj:getFluidContainer():getAmount();
            local fluidMax = barrelObj:getFluidContainer():getCapacity();
            tooltip.description = tooltip.description .. UBFormatFluidAmount(tx, fluidAmount, fluidMax, "Fluid_Name_Petrol");
            infoOption.toolTip = tooltip
            -- add our own menu
            UBDoFuelMenu(barrelObj, player, barrelMenu)
        end
    end

end

Events.OnFillWorldObjectContextMenu.Add(UBContextMenu)

local ISMoveableSpriteProps_canPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
function ISMoveableSpriteProps:canPickUpMoveable( _character, _square, _object )
    -- modify weight params to include fluid container weight also
    local modData = _object:getModData()
    if _object:getFluidContainer() and not _object:getFluidContainer():isEmpty() and modData["UB_Uncapped"] ~= nil then
        local sprite = _object:getSprite()
        local props = sprite:getProperties()
        local itemWeight = _object:getFluidContainer():getAmount()

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

        self.weight = itemWeight
        self.rawWeight = self.weight * 10
    end

    return ISMoveableSpriteProps_canPickUpMoveable(self, _character, _square, _object)
end