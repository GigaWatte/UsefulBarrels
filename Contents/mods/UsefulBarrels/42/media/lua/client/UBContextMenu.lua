
local UBUtils = require "UBUtils"

local UBContextMenu = {}

local function playerHasItem(playerInv, itemName) return playerInv:containsTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:containsTagEvalRecurse(itemName, predicateNotBroken) end

local function playerGetItem(playerInv, itemName) return playerInv:getFirstTypeEvalRecurse(itemName, predicateNotBroken) or playerInv:getFirstTagEvalRecurse(itemName, predicateNotBroken) end

-- << recreated vanilla functions to work with Petrol filled FluidContainers
function UBContextMenu:OnTransferFuel(squareToApproach, fuelContainer, fuelContainerList, player, reverse, hasFunnelNearby)
    if not reverse then reverse = false end
    if not hasFunnelNearby then hasFunnelNearby = false end
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
    local barrelFluidContainer = self.barrelObj:getFluidContainer()
    local barrelFluidInside = barrelFluidContainer:getPrimaryFluid()
    local barrelContainsMixture = barrelFluidContainer:isMixture()
    --barrelFluidContainer:canAddFluid(fluid)

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
        local hasHoseNearby = playerHasItem(self.loot.inventory, "RubberHose") or playerHasItem(self.playerInv, "RubberHose")
        local takeOption = context:addOption(getText("ContextMenu_UB_TakeGas"))

        if not (self.barrelObj:getFluidContainer():getAmount() > 0) or pourInto:isEmpty() then
            takeOption.notAvailable = true
            takeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            takeOption.toolTip.description = getText("Tooltip_UB_NoFuelInBarrel")
        end

        if SandboxVars.UsefulBarrels.RequireHoseForTake and not hasHoseNearby then 
            takeOption.notAvailable = true
            takeOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            takeOption.toolTip.description = getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose"))
        else
            local takeMenu = ISContextMenu:getNew(context)
            context:addSubMenu(takeOption, takeMenu)
    
            if pourInto:size() > 1 then
                local containerOption = takeMenu:addGetUpOption(getText("ContextMenu_UB_PourToAll"), squareToApproach, OnTransferFuel, self.barrelObj, allContainers, playerNum);
            end
    
            for _, destContainer in pairs(allContainers) do
                local fuelContainerList = {}
                table.insert(fuelContainerList, destContainer)
                local containerOption = takeMenu:addGetUpOption(destContainer:getName(), squareToApproach, OnTransferFuel, self.barrelObj, fuelContainerList, playerNum);
                containerOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                containerOption.toolTip.maxLineWidth = 512
                containerOption.toolTip.description = getText("ContextMenu_UB_GasAmount") .. string.format("%d / %d", destContainer:getFluidContainer():getAmount(), destContainer:getFluidContainer():getCapacity())
            end
        end
    end

    function DoAddFluidMenu()
        local hasFunnelNearby = playerHasItem(self.loot.inventory, "Funnel") or playerHasItem(playerInv, "Funnel")
        local addOption = context:addOption(getText("ContextMenu_UB_AddGas"))
        if allContainersWithFuel:isEmpty() then
            addOption.notAvailable = true
            addOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            addOption.toolTip.description = getText("Tooltip_UB_NoFuelInInventory")
        end
        if SandboxVars.UsefulBarrels.RequireFunnelForFill and not hasFunnelNearby then
            addOption.notAvailable = true
            addOption.toolTip = ISWorldObjectContextMenu.addToolTip()
            addOption.toolTip.description = getText("Tooltip_UB_FunnelMissing", getItemName("Base.Funnel"))
        else
            local addMenu = ISContextMenu:getNew(context)
            context:addSubMenu(addOption, addMenu)

            if allContainersWithFuel:size() > 1 then
                local fuelContainerTable = {}
                for i=0, allContainersWithFuel:size() - 1 do
                    local container = allContainersWithFuel:get(i)
                    table.insert(fuelContainerTable, container)
                end
                local containerOption = addMenu:addGetUpOption(getText("ContextMenu_UB_AddFromAll"), squareToApproach, OnTransferFuel, self.barrelObj, fuelContainerTable, playerNum, true, hasFunnelNearby);
            end
            for i=0, allContainersWithFuel:size()-1 do
                local fuelContainerTable = {}
                destContainer = allContainersWithFuel:get(i)
                table.insert(fuelContainerTable, destContainer)
                local containerOption = addMenu:addGetUpOption(destContainer:getName(), squareToApproach, OnTransferFuel, self.barrelObj, fuelContainerTable, playerNum, true, hasFunnelNearby);
                containerOption.toolTip = ISWorldObjectContextMenu.addToolTip()
                containerOption.toolTip.maxLineWidth = 512
                containerOption.toolTip.description = getText("ContextMenu_UB_GasAmount") .. string.format("%d / %d", destContainer:getFluidContainer():getAmount(), destContainer:getFluidContainer():getCapacity())
            end
        end
    end

    function GetAllPlayerFluidContainers()
        -- return all containers empty or not? is this need
    end

    function GetPlayerFluidContainers() 
        --return all items with fluids inside
    end

    function GetPlayerEmptyContainers() 
        -- return only empty fluid containers
    end

    function GetPlayerFluidContainersForBarrel(fluidInBarrel)
        -- return only items with fluidcontainers and fluid in them are already in barrel
    end

    local allContainers = {}
    local allContainerTypes = {}
    local allContainersOfType = {}

    local allContainersWithFuel = self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateFluid(item, Fluid.Petrol) end)

    local pourInto = self.playerInv:getAllEvalRecurse(function (item) return  UBUtils.predicateStoreFluid(item, Fluid.Petrol) end)

    local hasContainerWithFuel = false

    -- player does not have any containers in inventory to work with
    if pourInto:isEmpty() and allContainersWithFuel:isEmpty() then
        local missionOption = context:addOption(getText("ContextMenu_UB_NoContainers"))
        missionOption.notAvailable = true
        return
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

    -- take fuel from barrel section
    DoTakeFluidMenu()

    -- pour fuel to barrel section
    DoAddFluidMenu()
end
-- >> end recreated functions from vanilla pz

function UBContextMenu:DoBarrelUncap()
    if luautils.walkAdj(self.playerObj, self.barrelObj:getSquare(), true) then
        local allowUncap = true

        if SandboxVars.UsefulBarrels.RequirePipeWrench and self.wrench then
            ISWorldObjectContextMenu.equip(self.playerObj, self.playerObj:getPrimaryHandItem(), self.wrench, true)
        else
            allowUncap = false
        end

        if allowUncap then ISTimedActionQueue.add(ISUBDoBarrelUncap:new(self.playerObj, self.barrelObj, self.wrench)) end
    end
end

function UBContextMenu:AddInfoOption(context)
    local infoOption = context:addOption(getText("Fluid_UB_Show_Info"))
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local fluidAmount = self.barrelObj:getFluidContainer():getAmount()
    local fluidMax = self.barrelObj:getFluidContainer():getCapacity()
    local fluidName = self.barrelObj:getFluidContainer():getPrimaryFluid():getTranslatedName()
    local tx = getTextManager():MeasureStringX(tooltip.font, fluidName .. ":") + 20
    tooltip.description = tooltip.description .. UBUtils.FormatFluidAmount(tx, fluidAmount, fluidMax, fluidName);
    infoOption.toolTip = tooltip
end

function UBContextMenu:RemoveVanillaOptions(context, subcontext)
    if context:getOptionFromName(getText("ContextMenu_AddWaterFromItem")) then context:removeOptionByName(getText("ContextMenu_AddWaterFromItem")) end
    if subcontext:getOptionFromName(getText("Fluid_Show_Info")) then subcontext:removeOptionByName(getText("Fluid_Show_Info")) end
    if subcontext:getOptionFromName(getText("Fluid_Transfer_Fluids")) then subcontext:removeOptionByName(getText("Fluid_Transfer_Fluids")) end
    if subcontext:getOptionFromName(getText("ContextMenu_Drink")) then subcontext:removeOptionByName(getText("ContextMenu_Drink")) end
    if subcontext:getOptionFromName(getText("ContextMenu_Fill")) then subcontext:removeOptionByName(getText("ContextMenu_Fill")) end
    if subcontext:getOptionFromName(getText("ContextMenu_Wash")) then subcontext:removeOptionByName(getText("ContextMenu_Wash")) end
end

function UBContextMenu:MainMenu(player, context, worldobjects, test)
    local fetch = ISWorldObjectContextMenu.fetchVars or {}

    if not self.barrelHasFluidContainer then
        local openBarrelOption = context:addOptionOnTop(getText("ContextMenu_UB_UncapBarrel", self.objectLabel), nil, function() return UBContextMenu:DoBarrelUncap() end);
        if not self.playerHasPipeWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
            openBarrelOption.notAvailable = true;
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            openBarrelOption.toolTip = tooltip
            openBarrelOption.toolTip.description = getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench"));
        end
    end

    if self.hasFluidContainer then
        -- get vanilla FluidContainer object option
        local barrelOption = context:getOptionFromName(self.objectLabel)
        if not barrelOption then
            barrelOption = context:getOptionFromName(self.objectName)
        end

        if barrelOption then
            local barrelMenu = context:getSubMenu(barrelOption.subOption)
            self:RemoveVanillaOptions(context, barrelMenu)
            self:AddInfoOption(barrelMenu) -- info option instead of a whole UI window
            UBContextMenu:DoFluidMenu(player, barrelMenu) -- add our own menu
        end
    end
end

function UBContextMenu:Bootstrap(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.loot = getPlayerLoot(player)
    o.playerInv = o.playerObj:getInventory()
    o.wrench = playerGetItem(o.playerInv, "PipeWrench") -- FIXME check for broken
    o.playerHasPipeWrench = playerHasItem(o.playerInv, "PipeWrench")
    o.barrelObj = UBUtils:GetValidBarrelObject(worldobjects)
    
    if not o.barrelObj then return end

    o.barrelHasFluidContainer = o.barrelObj:hasComponent(ComponentType.FluidContainer)
    o.objectName = o.barrelObj:getSprite():getProperties():Val("CustomName")
    o.objectLabel = UBUtils:getMoveableDisplayName(o.barrelObj)
    -- do I actually need all that shit? try the vanilla one
    return self:MainMenu(player, context, worldobjects, test)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBContextMenu:Bootstrap(player, context, worldobjects, test) end)

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