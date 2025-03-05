
local UBUtils = require "UBUtils"

local UBContextMenu = {}

-- << recreated vanilla functions to work with Petrol filled FluidContainers
function UBContextMenu:OnTransferFuel(squareToApproach, fuelContainer, fuelContainerList, playerObj, reverse, hasFunnelNearby)
    if not reverse then reverse = false end
    if not hasFunnelNearby then hasFunnelNearby = false end
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
            local speedModifierApply = SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier > 0 and hasFunnelNearby
            ISTimedActionQueue.add(ISUBTakeFuel:new(playerObj, item, fuelContainer, squareToApproach, item, fuelContainer, speedModifierApply))
        end

        if returnToContainer and (returnToContainer ~= playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, playerInv, returnToContainer))
        end
    end
end

function UBContextMenu:DoFluidMenu(context)
    local squareToApproach = self.barrelObj:getSquare()
    -- thats from vanilla method. it seems to verify target square room and current player room
    if squareToApproach:getBuilding() ~= self.playerObj:getBuilding() then
        return 
    end
    --if the player can reach the tile, populate the submenu, otherwise don't bother
    if not squareToApproach or not AdjacentFreeTileFinder.Find(squareToApproach, self.playerObj) then
        return;
    end
    
    function DoTakeFluidMenu()
        -- need to check exactly after all movements!
        local hasHoseNearby = UBUtils.playerHasItem(self.loot.inventory, "RubberHose") or UBUtils.playerHasItem(self.playerInv, "RubberHose")
        --local takeOption = context:addOption(getText("ContextMenu_UB_TakeGas"))
        local takeOption = context:getOptionFromName(getText("ContextMenu_Fill"))
        --if takeOption and self.barrelObj:getFluidContainer():isEmpty() then-- or pourInto:isEmpty() then
        --    takeOption.notAvailable = true
        --    takeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
        --    takeOption.toolTip.description = getText("Tooltip_UB_NoFuelInBarrel")
        --end
        if takeOption and SandboxVars.UsefulBarrels.RequireHoseForTake and not hasHoseNearby then 
            takeOption.notAvailable = true
            takeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            takeOption.toolTip.description = getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose"))
            takeOption.subOption = nil
        else
            --local takeMenu = ISContextMenu:getNew(context)
            --context:addSubMenu(takeOption, takeMenu)
            --if pourInto:size() > 1 then
            --    local containerOption = takeMenu:addGetUpOption(getText("ContextMenu_UB_PourToAll"), squareToApproach, OnTransferFuel, self.barrelObj, allContainers, playerNum);
            --end
            --for _, destContainer in pairs(allContainers) do
            --    local fuelContainerList = {}
            --    table.insert(fuelContainerList, destContainer)
            --    local containerOption = takeMenu:addGetUpOption(destContainer:getName(), squareToApproach, OnTransferFuel, self.barrelObj, fuelContainerList, playerNum);
            --    containerOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            --    containerOption.toolTip.maxLineWidth = 512
            --    containerOption.toolTip.description = getText("ContextMenu_UB_GasAmount") .. string.format("%d / %d", destContainer:getFluidContainer():getAmount(), destContainer:getFluidContainer():getCapacity())
            --end
        end
    end
    -- from inventory containers add to barrel
    function DoAddFluidMenu()
        function FilterContainers(pourOut)
            local allContainers = {}
            --make a table of all containers
            for i=0, pourOut:size() - 1 do
                local container = pourOut:get(i)
                if (FluidContainer.CanTransfer(container:getFluidContainer(), self.barrelObj:getFluidContainer())) then
                    table.insert(allContainers, container)
                end
            end
            return allContainers
        end
        function SortContainers(allContainers)
            local allContainerTypes = {}
            if #allContainers == 0 then return allContainerTypes end
            local allContainersOfType = {}
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
        local hasFunnelNearby = UBUtils.playerHasItem(self.loot.inventory, "Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")
        local allContainers = FilterContainers(self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateAnyFluid(item) end))
        local allContainerTypes = SortContainers(allContainers)

        if SandboxVars.UsefulBarrels.RequireFunnelForFill and not hasFunnelNearby then
            local addOption = context:insertOptionAfter(getText("Fluid_UB_Show_Info"), getText("ContextMenu_UB_AddGas"))
            addOption.notAvailable = true
            addOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            addOption.toolTip.description = getText("Tooltip_UB_FunnelMissing", getItemName("Base.Funnel"))
        else
            local addOption = context:insertOptionAfter(getText("Fluid_UB_Show_Info"), getText("ContextMenu_UB_AddGas"))
            local addMenu = ISContextMenu:getNew(context)
            
            if #allContainers == 0 then
                addOption.notAvailable = true
                addOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                addOption.toolTip.description = getText("Tooltip_UB_NoFuelInInventory")
            else
                context:addSubMenu(addOption, addMenu)
            end

            if #allContainers > 1 then
                local containerOption = addMenu:addGetUpOption(
                    getText("ContextMenu_UB_AddFromAll"), 
                    squareToApproach, 
                    UBContextMenu.OnTransferFluid, self.barrelObj:getFluidContainer(), allContainers, self.playerObj, true, hasFunnelNearby
                )
                -- here is tooltip also
            end
            for _,containerType in pairs(allContainerTypes) do
                local destItem = containerType[1]
                if #containerType > 1 then
                    local containerOption = addMenu:addOption(destItem:getName() .. " (" .. #containerType ..")")
                    local containerTypeMenu = ISContextMenu:getNew(addMenu)
                    addMenu:addSubMenu(containerOption, containerTypeMenu)

                    -- add one
                    -- add all
                else
                    local fuelContainerTable = {}
                    table.insert(fuelContainerTable, destItem)
                    local containerOption = addMenu:addGetUpOption(
                        destItem:getName(),
                        squareToApproach,
                        UBContextMenu.OnTransferFluid, self.barrelObj:getFluidContainer(), fuelContainerTable, self.playerObj, true, hasFunnelNearby
                    )
                    -- here is also tooltip
                end
            end
        --    if allContainersWithFuel:size() > 1 then
        --        local fuelContainerTable = {}
        --        for i=0, allContainersWithFuel:size() - 1 do
        --            local container = allContainersWithFuel:get(i)
        --            table.insert(fuelContainerTable, container)
        --        end
        --        local containerOption = addMenu:addGetUpOption(getText("ContextMenu_UB_AddFromAll"), squareToApproach, OnTransferFuel, self.barrelObj, fuelContainerTable, playerNum, true, hasFunnelNearby);
        --    end
        --    for i=0, allContainersWithFuel:size()-1 do
        --        local fuelContainerTable = {}
        --        destContainer = allContainersWithFuel:get(i)
        --        table.insert(fuelContainerTable, destContainer)
        --        local containerOption = addMenu:addGetUpOption(destContainer:getName(), squareToApproach, OnTransferFuel, self.barrelObj, fuelContainerTable, playerNum, true, hasFunnelNearby);
        --        containerOption.toolTip = ISWorldObjectContextMenu.addToolTip()
        --        containerOption.toolTip.maxLineWidth = 512
        --        containerOption.toolTip.description = getText("ContextMenu_UB_GasAmount") .. string.format("%d / %d", destContainer:getFluidContainer():getAmount(), destContainer:getFluidContainer():getCapacity())
        --    end
        end
    end


    --local pourInto = self.playerInv:getAllEvalRecurse(function (item) return  UBUtils.predicateStoreFluid(item, Fluid.Petrol) end)

    --local hasContainerWithFuel = false

    -- player does not have any containers in inventory to work with
    --if pourInto:isEmpty() and allContainersWithFuel:isEmpty() then
    --    local missionOption = context:addOption(getText("ContextMenu_UB_NoContainers"))
    --    missionOption.notAvailable = true
    --    return
    --end
    DoTakeFluidMenu()
    DoAddFluidMenu()
end
-- >> end recreated functions from vanilla pz

function UBContextMenu:DoBarrelUncap()
    if luautils.walkAdj(self.playerObj, self.barrelObj:getSquare(), true) then

        if SandboxVars.UsefulBarrels.RequirePipeWrench and self.isValidWrench then
            ISWorldObjectContextMenu.equip(self.playerObj, self.playerObj:getPrimaryHandItem(), self.wrench, true)
        end

        ISTimedActionQueue.add(ISUBDoBarrelUncap:new(self.playerObj, self.barrelObj, self.wrench))
    end
end

function UBContextMenu:AddInfoOption(context)
    local fluidAmount = self.barrelObj:getFluidContainer():getAmount()
    local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info"))
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local fluidMax = self.barrelObj:getFluidContainer():getCapacity()
    local fluidName
    if fluidAmount > 0 then
        fluidName = self.barrelObj:getFluidContainer():getPrimaryFluid():getTranslatedName()
    else
        fluidName = getText("ContextMenu_Empty")
    end
    local tx = getTextManager():MeasureStringX(tooltip.font, fluidName .. ":") + 20
    tooltip.description = tooltip.description .. UBUtils.FormatFluidAmount(tx, fluidAmount, fluidMax, fluidName);
    infoOption.toolTip = tooltip
end

function UBContextMenu:RemoveVanillaOptions(context, subcontext)
    -- remove default add water menu coz I want to handle all fluids not just water
    if context:getOptionFromName(getText("ContextMenu_AddWaterFromItem")) then context:removeOptionByName(getText("ContextMenu_AddWaterFromItem")) end

    -- a whole UI pannel just to know what fluid and amount inside? ... i will replace it on option with tooltip
    if subcontext:getOptionFromName(getText("Fluid_Show_Info")) then subcontext:removeOptionByName(getText("Fluid_Show_Info")) end

    -- remove transfer because I want to implement tools requirements
    if subcontext:getOptionFromName(getText("Fluid_Transfer_Fluids")) then subcontext:removeOptionByName(getText("Fluid_Transfer_Fluids")) end
    -- drink? from barrel? no
    if subcontext:getOptionFromName(getText("ContextMenu_Drink")) then subcontext:removeOptionByName(getText("ContextMenu_Drink")) end

    --if subcontext:getOptionFromName(getText("ContextMenu_Fill")) then subcontext:removeOptionByName(getText("ContextMenu_Fill")) end
    -- the same as above
    if subcontext:getOptionFromName(getText("ContextMenu_Wash")) then subcontext:removeOptionByName(getText("ContextMenu_Wash")) end
end

function UBContextMenu:MainMenu(player, context, worldobjects, test)
    local fetch = ISWorldObjectContextMenu.fetchVars or {}

    if not self.barrelHasFluidContainer then
        local openBarrelOption = context:addOptionOnTop(getText("ContextMenu_UB_UncapBarrel", self.objectLabel), nil, function() return UBContextMenu:DoBarrelUncap() end);
        if not self.isValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
            openBarrelOption.notAvailable = true;
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            openBarrelOption.toolTip = tooltip
            openBarrelOption.toolTip.description = getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench"));
        end
    end

    if self.barrelHasFluidContainer then
        -- get vanilla FluidContainer object option
        local barrelOption = context:getOptionFromName(self.objectLabel)
        if not barrelOption then
            barrelOption = context:getOptionFromName(self.objectName)
        end

        if barrelOption then
            local barrelMenu = context:getSubMenu(barrelOption.subOption)
            self:RemoveVanillaOptions(context, barrelMenu)
            self:AddInfoOption(barrelMenu) -- info option instead of a whole UI window
            UBContextMenu:DoFluidMenu(barrelMenu) -- add our own menu
        end
    end
end

function UBContextMenu:Bootstrap(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    -- does it cache previous player position loot
    o.loot = getPlayerLoot(player)
    o.playerInv = o.playerObj:getInventory()
    o.barrelObj = UBUtils.GetValidBarrelObject(worldobjects)
    
    if not o.barrelObj then return end

    o.wrench = UBUtils.playerGetItem(o.playerInv, "PipeWrench")
    o.isValidWrench = o.wrench ~= nil and UBUtils.predicateNotBroken(o.wrench)

    o.barrelHasFluidContainer = o.barrelObj:hasComponent(ComponentType.FluidContainer)
    o.objectName = o.barrelObj:getSprite():getProperties():Val("CustomName")
    o.objectLabel = UBUtils.getMoveableDisplayName(o.barrelObj)

    -- do I actually need all that shit? try the vanilla one
    return self:MainMenu(player, context, worldobjects, test)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBContextMenu:Bootstrap(player, context, worldobjects, test) end)

-- remove add water menu option
-- add 'add fluid' menu option
-- add and fill stil require instruments
-- drink also require tool

local ISMoveableSpriteProps_canPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
function ISMoveableSpriteProps:canPickUpMoveable( _character, _square, _object )
    -- modify weight params to include fluid container weight also
    if _object and _object:getFluidContainer() and not _object:getFluidContainer():isEmpty() then
        local modData = _object:getModData()
        if modData["UB_Uncapped"] ~= nil then
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
    end

    return ISMoveableSpriteProps_canPickUpMoveable(self, _character, _square, _object)
end