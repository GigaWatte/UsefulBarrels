
local UBUtils = require "UBUtils"

local UBContextMenu = {}
local TOOL_SCAN_DISTANCE = 2

function UBContextMenu:OnTransferFluid(fluidContainer, fluidContainerItems, addToBarrel)
    local primaryItem = self.playerObj:getPrimaryHandItem()
    local secondaryItem = self.playerObj:getSecondaryHandItem()
    local twohanded = (primaryItem == secondaryItem) and primaryItem ~= nil
    -- reequip items if it is not our fluidContainers
    local reequipPrimary = primaryItem and not luautils.tableContains(fluidContainerItems, primaryItem)
    local reequipSecondary = secondaryItem and not luautils.tableContains(fluidContainerItems, secondaryItem)
    -- Drop corpse or generator
	if isForceDropHeavyItem(primaryItem) then
		ISTimedActionQueue.add(ISUnequipAction:new(self.playerObj, primaryItem, 50));
	end

    if not luautils.walkAdj(self.playerObj, self.barrelSquare, true) then return end
    -- sort to remove unnecesary equip action if proper container already equipped
    table.sort(fluidContainerItems, function(a,b) return a == primaryItem and not (b == primaryItem) end)

    for i,item in ipairs(fluidContainerItems) do
        -- this returns item back to container it's taken. example: backpack
        local returnToContainer = item:getContainer():isInCharacterInventory(self.playerObj) and item:getContainer()
        local isEquippedOnBody = item:isEquipped()
        --local isEquippedOnBody = self.playerObj:isEquippedClothing(self.item)
        -- if item not in player main inventory
        if luautils.haveToBeTransfered(self.playerObj, item) then
            -- transfer item to player inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, item, item:getContainer(), self.playerObj:getInventory()))
        end
        -- action: equip items to primary hand
        if item ~= primaryItem then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, item, 25, true))
        end

        if addToBarrel ~= nil and addToBarrel == true then
            local worldObjects = UBUtils.GetWorldItemsNearby(self.barrelObj:getSquare(), TOOL_SCAN_DISTANCE)
            local hasFunnelNearby = UBUtils.TableContainsItem(worldObjects, "Base.Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")
            local speedModifierApply = SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier > 0 and hasFunnelNearby
            ISTimedActionQueue.add(ISUBTransferFluid:new(self.playerObj, item:getFluidContainer(), fluidContainer, self.barrelSquare, item, speedModifierApply))
        else
            ISTimedActionQueue.add(ISUBTransferFluid:new(self.playerObj, fluidContainer, item:getFluidContainer(), self.barrelSquare, item))
        end
        -- return item back to container
        if returnToContainer and (returnToContainer ~= self.playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, item, self.playerInv, returnToContainer))
        end

        if isEquippedOnBody then
            ISTimedActionQueue.add(ISWearClothing:new(self.playerObj, item, 25))
        end
    end

    if twohanded then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, primaryItem, 25, true, twohanded))
    elseif reequipPrimary and reequipSecondary then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, primaryItem, 25, true))
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, secondaryItem, 25, false))
    else
        if reequipPrimary then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, primaryItem, 25, true))
        end
        if reequipSecondary then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, secondaryItem, 25, false))
        end
    end
end

function UBContextMenu.CanCreateFluidMenu(playerObj, barrelObj)
    local squareToApproach = barrelObj:getSquare()
    -- thats from vanilla method. it seems to verify target square room and current player room
    if squareToApproach:getBuilding() ~= playerObj:getBuilding() then
        return false
    end
    --if the player can reach the tile, populate the submenu, otherwise don't bother
    if not squareToApproach or not AdjacentFreeTileFinder.Find(squareToApproach, playerObj) then
        return false
    end

    return true
end

function UBContextMenu:DoCategoryList(subMenu, allContainerTypes, addToBarrel, oneOptionText, allOptionText)
    for _,containerType in pairs(allContainerTypes) do
        local destItem = containerType[1]
        if #containerType > 1 then
            local containerOption = subMenu:addOption(destItem:getName() .. " (" .. #containerType ..")")
            local containerTypeMenu = ISContextMenu:getNew(subMenu)
            subMenu:addSubMenu(containerOption, containerTypeMenu)
            local addOneContainerOption = containerTypeMenu:addGetUpOption(
                oneOptionText, 
                self, 
                UBContextMenu.OnTransferFluid, self.barrelFluidContainer, { destItem }, addToBarrel
            )
            if containerType[2] ~= nil then
                local addAllContainerOption = containerTypeMenu:addGetUpOption(
                    allOptionText, 
                    self, 
                    UBContextMenu.OnTransferFluid, self.barrelFluidContainer, containerType, addToBarrel
                )
            end
        else
            local containerOption = subMenu:addGetUpOption(
                destItem:getName(),
                self,
                UBContextMenu.OnTransferFluid, self.barrelFluidContainer, { destItem }, addToBarrel
            )
        end
    end
end

function UBContextMenu:DoTakeFluidMenu(context, hasHoseNearby)
    -- find all items that contain fluid from barrel or empty
    local fluidContainerItems = self.playerInv:getAllEvalRecurse(
        function (item) return (UBUtils.predicateFluid(item, self.barrelFluid) or UBUtils.predicateHasFluidContainer(item)) and not UBUtils.IsUBBarrel(item) end
    )
    -- convert to table
    local fluidContainerItemsTable = UBUtils.ConvertToTable(fluidContainerItems)
    -- get only items that can be filled
    local allContainers = UBUtils.CanTransferFluid(fluidContainerItemsTable, self.barrelFluidContainer, true)
    local allContainerTypes = UBUtils.SortContainers(allContainers)
    local takeOption = context:addOption(getText("ContextMenu_Fill"))
    if #allContainers == 0 then
        UBUtils.DisableOptionAddTooltip(takeOption, getText("Tooltip_UB_NoProperFluidInBarrel"))
        return
    end
    if SandboxVars.UsefulBarrels.RequireHoseForTake and not hasHoseNearby then 
        UBUtils.DisableOptionAddTooltip(takeOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
        return
    end
    local takeMenu = ISContextMenu:getNew(context)
    context:addSubMenu(takeOption, takeMenu)
    if #allContainers > 1 and #allContainerTypes > 1 then
        local containerOption = takeMenu:addGetUpOption(
            getText("ContextMenu_FillAll"),
            self,
            UBContextMenu.OnTransferFluid, self.barrelFluidContainer, allContainers
        )
    end
    self:DoCategoryList(takeMenu, allContainerTypes, false, getText("ContextMenu_FillOne"),getText("ContextMenu_FillAll"))
end

function UBContextMenu:DoAddFluidMenu(context, hasFunnelNearby)
    -- find all items in player inv that hold greater than 0 fluid
    local fluidContainerItems = self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateAnyFluid(item) and not UBUtils.IsUBBarrel(item) end)
    -- convert to table
    local fluidContainerItemsTable = UBUtils.ConvertToTable(fluidContainerItems)
    -- get only items that can be poured into target
    local allContainers = UBUtils.CanTransferFluid(fluidContainerItemsTable, self.barrelFluidContainer)
    local allContainerTypes = UBUtils.SortContainers(allContainers)
    local addOption = context:addOption(getText("ContextMenu_UB_AddFluid"))
    if #allContainers == 0 then
        UBUtils.DisableOptionAddTooltip(addOption, getText("Tooltip_UB_NoProperFluidInInventory"))
        return
    end
    if SandboxVars.UsefulBarrels.RequireFunnelForFill and not hasFunnelNearby then
        UBUtils.DisableOptionAddTooltip(addOption, getText("Tooltip_UB_FunnelMissing", getItemName("Base.Funnel")))
        return
    end
    local addMenu = ISContextMenu:getNew(context)
    context:addSubMenu(addOption, addMenu)
    if #allContainers > 1 and #allContainerTypes > 1 then
        local containerOption = addMenu:addGetUpOption(
            getText("ContextMenu_AddAll"), 
            self, 
            UBContextMenu.OnTransferFluid, self.barrelFluidContainer, allContainers, true
        )
    end
    self:DoCategoryList(addMenu, allContainerTypes, true, getText("ContextMenu_AddOne"), getText("ContextMenu_AddAll"))
end

function UBContextMenu:DoBarrelUncap()
    if luautils.walkAdj(self.playerObj, self.barrelObj:getSquare(), true) then
        if SandboxVars.UsefulBarrels.RequirePipeWrench and self.isValidWrench then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, self.wrench, 25, true))
        end
        ISTimedActionQueue.add(ISUBDoBarrelUncap:new(self.playerObj, self.barrelObj, self.wrench, self.objectLabel))
    end
end

function UBContextMenu:AddInfoOption(context)
    local fluidAmount = self.barrelFluidContainer:getAmount()
    local fluidMax = self.barrelFluidContainer:getCapacity()
    if fluidAmount > 0 then
        self.barrelFluid = self.barrelFluidContainer:getPrimaryFluid()
    else
        self.barrelFluid = nil
    end
    local fluidName = UBUtils.GetTranslatedFluidNameOrEmpty(self.barrelFluid)
    local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info", fluidName))
    if self.playerObj:DistToSquared(self.barrelObj:getX() + 0.5, self.barrelObj:getY() + 0.5) < 2 * 2 then
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        local tx = getTextManager():MeasureStringX(tooltip.font, fluidName .. ":") + 20
        --tooltip.maxLineWidth = 512
        tooltip.description = tooltip.description .. UBUtils.FormatFluidAmount(tx, fluidAmount, fluidMax, fluidName)
        infoOption.toolTip = tooltip
        if self.barrelFluid and self.barrelFluid:isPoisonous() then
            infoOption.iconTexture = getTexture("media/ui/Skull2.png")
            tooltip.description = tooltip.description .. "\n" .. getText("Fluid_Poison")
        end
    end

end

function UBContextMenu:RemoveVanillaOptions(context, subcontext)
    -- remove default add water menu coz I want to handle all fluids not just water
    if context:getOptionFromName(getText("ContextMenu_AddWaterFromItem")) then context:removeOptionByName(getText("ContextMenu_AddWaterFromItem")) end
    -- a whole UI pannel just to know what fluid and amount inside? ... I will replace it on option with tooltip
    if subcontext:getOptionFromName(getText("Fluid_Show_Info")) then subcontext:removeOptionByName(getText("Fluid_Show_Info")) end
    -- remove transfer because I want to implement tools requirements
    if subcontext:getOptionFromName(getText("Fluid_Transfer_Fluids")) then subcontext:removeOptionByName(getText("Fluid_Transfer_Fluids")) end
    -- drink? from barrel? no
    if subcontext:getOptionFromName(getText("ContextMenu_Drink")) then subcontext:removeOptionByName(getText("ContextMenu_Drink")) end
    -- vanilla fill is to silly, I will recreate it
    if subcontext:getOptionFromName(getText("ContextMenu_Fill")) then subcontext:removeOptionByName(getText("ContextMenu_Fill")) end
    -- the same as above
    if subcontext:getOptionFromName(getText("ContextMenu_Wash")) then subcontext:removeOptionByName(getText("ContextMenu_Wash")) end
end

function UBContextMenu:DoDebugOption(player, context, worldobjects, test)
    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local worldObjects = UBUtils.GetWorldItemsNearby(self.barrelObj:getSquare(), TOOL_SCAN_DISTANCE)
    local hasHoseNearby = UBUtils.TableContainsItem(worldObjects, "Base.RubberHose") or UBUtils.playerHasItem(self.playerInv, "RubberHose")
    local hasFunnelNearby = UBUtils.TableContainsItem(worldObjects, "Base.Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")

    tooltip.description = tooltip.description .. string.format("Barrel object: %s", tostring(self.barrelObj)) .. "\n"
    tooltip.description = tooltip.description .. string.format("isValidWrench: %s", tostring(self.isValidWrench)) .. "\n"
    tooltip.description = tooltip.description .. string.format("hasFluidContainer: %s", tostring(self.barrelHasFluidContainer)) .. "\n"
    tooltip.description = tooltip.description .. string.format("SVRequirePipeWrench: %s", tostring(SandboxVars.UsefulBarrels.RequirePipeWrench)) .. "\n"
    tooltip.description = tooltip.description .. string.format("SVRequireFunnel: %s", tostring(SandboxVars.UsefulBarrels.RequireFunnelForFill)) .. "\n"
    tooltip.description = tooltip.description .. string.format("hasHoseNearby: %s", tostring(hasHoseNearby)) .. "\n"
    tooltip.description = tooltip.description .. string.format("hasFunnelNearby: %s", tostring(hasFunnelNearby)) .. "\n"
    tooltip.description = tooltip.description .. string.format("Can Create Menu: %s", tostring(UBContextMenu.CanCreateFluidMenu(self.playerObj, self.barrelObj))) .. "\n"

    if self.barrelHasFluidContainer then
        local fluidAmount = self.barrelFluidContainer:getAmount()
        local fluidMax = self.barrelFluidContainer:getCapacity()
        if fluidAmount > 0 then
            self.barrelFluid = self.barrelFluidContainer:getPrimaryFluid()
        else
            self.barrelFluid = nil
        end
        tooltip.description = tooltip.description .. string.format("Fluid: %s", tostring(self.barrelFluid)) .. "\n"
        tooltip.description = tooltip.description .. string.format("Fluid amount: %s", tostring(fluidAmount)) .. "\n"
        tooltip.description = tooltip.description .. string.format("Fluid capacity: %s", tostring(fluidMax)) .. "\n"
        local addfluidContainerItems = self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateAnyFluid(item) and not UBUtils.IsUBBarrel(item) end)
        local addfluidContainerItemsTable = UBUtils.ConvertToTable(addfluidContainerItems)
        tooltip.description = tooltip.description .. string.format("All containers to add: %s", tostring(#addfluidContainerItemsTable)) .. "\n"
        local addallContainers = UBUtils.CanTransferFluid(addfluidContainerItemsTable, self.barrelFluidContainer)
        tooltip.description = tooltip.description .. string.format("Valid containers to add: %s", tostring(#addallContainers)) .. "\n"
        local takefluidContainerItems = self.playerInv:getAllEvalRecurse(
            function (item) return (UBUtils.predicateFluid(item, self.barrelFluid) or UBUtils.predicateHasFluidContainer(item)) and not UBUtils.IsUBBarrel(item) end
        )
        local takefluidContainerItemsTable = UBUtils.ConvertToTable(takefluidContainerItems)
        tooltip.description = tooltip.description .. string.format("All containers for pouring: %s", tostring(#takefluidContainerItemsTable)) .. "\n"
        local takeallContainers = UBUtils.CanTransferFluid(takefluidContainerItemsTable, self.barrelFluidContainer, true)
        tooltip.description = tooltip.description .. string.format("Valid containers for pouring: %s", tostring(#takeallContainers)) .. "\n"

        tooltip.description = tooltip.description .. string.format("isInputLocked: %s", tostring(self.barrelFluidContainer:isInputLocked())) .. "\n"
        tooltip.description = tooltip.description .. string.format("canPlayerEmpty: %s", tostring(self.barrelFluidContainer:canPlayerEmpty())) .. "\n"
    end

    if self.barrelObj:hasModData() then
        local modData = self.barrelObj:getModData()
        if modData["UB_Uncapped"] then tooltip.description = tooltip.description .. string.format("UB_Uncapped: %s", tostring(modData["UB_Uncapped"])) .. "\n" end
        if modData["UB_Initial_fluid"] then tooltip.description = tooltip.description .. string.format("UB_Initial_fluid: %s", tostring(modData["UB_Initial_fluid"])) .. "\n" end
        if modData["UB_Initial_amount"] then tooltip.description = tooltip.description .. string.format("UB_Initial_amount: %s", tostring(modData["UB_Initial_amount"])) .. "\n" end
        if modData["modData"] then
            tooltip.description = tooltip.description .. "Nested modData options"
            if modData["modData"]["UB_Uncapped"] then tooltip.description = tooltip.description .. string.format("UB_Uncapped: %s", tostring(modData["modData"]["UB_Uncapped"])) .. "\n" end
            if modData["modData"]["UB_Initial_fluid"] then tooltip.description = tooltip.description .. string.format("UB_Initial_fluid: %s", tostring(modData["modData"]["UB_Initial_fluid"])) .. "\n" end
            if modData["modData"]["UB_Initial_amount"] then tooltip.description = tooltip.description .. string.format("UB_Initial_amount: %s", tostring(modData["modData"]["UB_Initial_amount"])) .. "\n" end
        end
    end
    debugOption.toolTip = tooltip
end

function UBContextMenu:MainMenu(player, context, worldobjects, test)
    if not self.barrelHasFluidContainer then
        local openBarrelOption = context:addOptionOnTop(getText("ContextMenu_UB_UncapBarrel", self.objectLabel), self, UBContextMenu.DoBarrelUncap);
        if not self.isValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
            UBUtils.DisableOptionAddTooltip(openBarrelOption, getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench")))
        end
    end

    if self.barrelHasFluidContainer then
        self.barrelFluidContainer = self.barrelObj:getComponent(ComponentType.FluidContainer)
        -- get vanilla FluidContainer object option
        local barrelOption = context:getOptionFromName(self.objectLabel)
        if not barrelOption then
            barrelOption = context:getOptionFromName(self.objectName)
        end

        if barrelOption then
            local barrelMenu = context:getSubMenu(barrelOption.subOption)
            self:RemoveVanillaOptions(context, barrelMenu)
            self:AddInfoOption(barrelMenu)
            if UBContextMenu.CanCreateFluidMenu(self.playerObj, self.barrelObj) then
                local worldObjects = UBUtils.GetWorldItemsNearby(self.barrelObj:getSquare(), TOOL_SCAN_DISTANCE)
                local hasHoseNearby = UBUtils.TableContainsItem(worldObjects, "Base.RubberHose") or UBUtils.playerHasItem(self.playerInv, "RubberHose")
                local hasFunnelNearby = UBUtils.TableContainsItem(worldObjects, "Base.Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")
                self:DoAddFluidMenu(barrelMenu, hasFunnelNearby)
                self:DoTakeFluidMenu(barrelMenu, hasHoseNearby)
            end
        end
    end

    if SandboxVars.UsefulBarrels.DebugMode then
        self:DoDebugOption(player, context, worldobjects, test)
    end
end

function UBContextMenu:new(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.playerInv = o.playerObj:getInventory()
    o.barrelObj = UBUtils.GetValidBarrelObject(worldobjects)
    
    if not o.barrelObj then return end

    o.wrench = UBUtils.playerGetItem(o.playerInv, "PipeWrench")
    o.isValidWrench = o.wrench ~= nil and UBUtils.predicateNotBroken(o.wrench)

    o.barrelHasFluidContainer = o.barrelObj:hasComponent(ComponentType.FluidContainer)
    o.objectName = o.barrelObj:getSprite():getProperties():Val("CustomName")
    o.objectLabel = UBUtils.getMoveableDisplayName(o.barrelObj)
    o.barrelSquare = o.barrelObj:getSquare()

    return self:MainMenu(player, context, worldobjects, test)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBContextMenu:new(player, context, worldobjects, test) end)
