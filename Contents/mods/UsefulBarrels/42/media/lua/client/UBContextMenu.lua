
local UBUtils = require "UBUtils"

local UBContextMenu = {}
local TOOL_SCAN_DISTANCE = 2

function UBContextMenu.OnTransferFluid(playerObj, barrelSquare, fluidContainer, fluidContainerItems, addToBarrel)
    local playerInv = playerObj:getInventory()
    local primaryItem = playerObj:getPrimaryHandItem()
    local secondaryItem = playerObj:getSecondaryHandItem()
    local twohanded = (primaryItem == secondaryItem) and primaryItem ~= nil
    -- reequip items if it is not our fluidContainers
    local reequipPrimary = primaryItem and not luautils.tableContains(fluidContainerItems, primaryItem)
    local reequipSecondary = secondaryItem and not luautils.tableContains(fluidContainerItems, secondaryItem)
    -- Drop corpse or generator
	if isForceDropHeavyItem(primaryItem) then
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, primaryItem, 50));
	end

    if not luautils.walkAdj(playerObj, barrelSquare, true) then return end
    -- sort to remove unnecesary equip action if proper container already equipped
    table.sort(fluidContainerItems, function(a,b) return a == primaryItem and not (b == primaryItem) end)

    for i,item in ipairs(fluidContainerItems) do
        -- this returns item back to container it's taken. example: backpack
        local returnToContainer = item:getContainer():isInCharacterInventory(playerObj) and item:getContainer()
        local isEquippedOnBody = item:isEquipped()
        --local isEquippedOnBody = self.playerObj:isEquippedClothing(self.item)
        -- if item not in player main inventory
        if luautils.haveToBeTransfered(playerObj, item) then
            -- transfer item to player inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerInv))
        end
        -- action: equip items to primary hand
        if item ~= primaryItem then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, item, 25, true))
        end

        if addToBarrel ~= nil and addToBarrel == true then
            local worldObjects = UBUtils.GetWorldItemsNearby(barrelSquare, TOOL_SCAN_DISTANCE)
            local hasFunnelNearby = UBUtils.TableContainsItem(worldObjects, "Base.Funnel") or UBUtils.playerHasItem(playerInv, "Funnel")
            local speedModifierApply = SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier > 0 and hasFunnelNearby
            ISTimedActionQueue.add(ISUBTransferFluid:new(playerObj, item:getFluidContainer(), fluidContainer, barrelSquare, item, speedModifierApply))
        else
            ISTimedActionQueue.add(ISUBTransferFluid:new(playerObj, fluidContainer, item:getFluidContainer(), barrelSquare, item))
        end
        -- return item back to container
        if returnToContainer and (returnToContainer ~= playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, playerInv, returnToContainer))
        end

        if isEquippedOnBody then
            ISTimedActionQueue.add(ISWearClothing:new(playerObj, item, 25))
        end
    end

    if twohanded then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, primaryItem, 25, true, twohanded))
    elseif reequipPrimary and reequipSecondary then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, primaryItem, 25, true))
        ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, secondaryItem, 25, false))
    else
        if reequipPrimary then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, primaryItem, 25, true))
        end
        if reequipSecondary then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, secondaryItem, 25, false))
        end
    end
end

function UBContextMenu.CanCreateFluidMenu(playerObj, barrelSquare)
    -- thats from vanilla method. it seems to verify target square room and current player room
    if barrelSquare:getBuilding() ~= playerObj:getBuilding() then
        return false
    end
    --if the player can reach the tile, populate the submenu, otherwise don't bother
    if not barrelSquare or not AdjacentFreeTileFinder.Find(barrelSquare, playerObj) then
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
                self.playerObj, 
                UBContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, { destItem }, addToBarrel
            )
            if containerType[2] ~= nil then
                local addAllContainerOption = containerTypeMenu:addGetUpOption(
                    allOptionText, 
                    self.playerObj, 
                    UBContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, containerType, addToBarrel
                )
            end
        else
            local containerOption = subMenu:addGetUpOption(
                destItem:getName(),
                self.playerObj,
                UBContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, { destItem }, addToBarrel
            )
        end
    end
end

function UBContextMenu:DoAllItemsMenu(subMenu, allContainers, allContainerTypes, addToBarrel, optionText)
    if #allContainers > 1 and #allContainerTypes > 1 then
        local containerOption = subMenu:addGetUpOption(
            optionText, 
            self.playerObj, 
            UBContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, allContainers, addToBarrel
        )
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
    local allContainers = self.barrel:CanTransferFluid(fluidContainerItemsTable, true)
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
    self:DoAllItemsMenu(takeMenu, allContainers, allContainerTypes, false, getText("ContextMenu_FillAll"))
    self:DoCategoryList(takeMenu, allContainerTypes, false, getText("ContextMenu_FillOne"),getText("ContextMenu_FillAll"))
end

function UBContextMenu:DoAddFluidMenu(context, hasFunnelNearby)
    -- find all items in player inv that hold greater than 0 fluid
    local fluidContainerItems = self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateAnyFluid(item) and not UBUtils.IsUBBarrel(item) end)
    -- convert to table
    local fluidContainerItemsTable = UBUtils.ConvertToTable(fluidContainerItems)
    -- get only items that can be poured into target
    local allContainers = self.barrel:CanTransferFluid(fluidContainerItemsTable)
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
    self:DoAllItemsMenu(addMenu, allContainers, allContainerTypes, true, getText("ContextMenu_AddAll"))
    self:DoCategoryList(addMenu, allContainerTypes, true, getText("ContextMenu_AddOne"), getText("ContextMenu_AddAll"))
end

function UBContextMenu:DoBarrelUncap()
    if luautils.walkAdj(self.playerObj, self.barrel.square, true) then
        if SandboxVars.UsefulBarrels.RequirePipeWrench and self.isValidWrench then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.playerObj, self.wrench, 25, true))
        end
        ISTimedActionQueue.add(ISUBDoBarrelUncap:new(self.playerObj, self.barrel, self.wrench))
    end
end

function UBContextMenu:AddInfoOption(context)
    local fluidAmount = self.barrel:getAmount()
    local fluidMax = self.barrel:getCapacity()
    self.barrelFluid = self.barrel:getPrimaryFluid()
    local fluidName = self.barrel.GetTranslatedFluidNameOrEmpty()

    local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info", fluidName))
    if self.playerObj:DistToSquared(self.barrel.isoObject:getX() + 0.5, self.barrel.isoObject:getY() + 0.5) < 2 * 2 then
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
    local worldObjects = UBUtils.GetWorldItemsNearby(self.barrel.square, TOOL_SCAN_DISTANCE)
    local hasHoseNearby = UBUtils.TableContainsItem(worldObjects, "Base.RubberHose") or UBUtils.playerHasItem(self.playerInv, "RubberHose")
    local hasFunnelNearby = UBUtils.TableContainsItem(worldObjects, "Base.Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")

    local description = string.format(
        [[SVRequirePipeWrench: %s\n
SVRequireHose: %s\n
SVRequireFunnel: %s\n
hasHoseNearby: %s\n
hasFunnelNearby: %s\n
isValidWrench: %s\n
CanCreateFluidMenu: %s\n]],
        tostring(SandboxVars.UsefulBarrels.RequirePipeWrench),
        tostring(SandboxVars.UsefulBarrels.RequireHoseForTake),
        tostring(SandboxVars.UsefulBarrels.RequireFunnelForFill),
        tostring(hasHoseNearby),
        tostring(hasFunnelNearby),
        tostring(self.isValidWrench),
        UBContextMenu.CanCreateFluidMenu(self.playerObj, self.barrel.square)
    )

    tooltip.description = description .. self.barrel:GetBarrelInfo(self.playerInv)
    debugOption.toolTip = tooltip
end

function UBContextMenu:MainMenu(player, context, worldobjects, test)
    if not self.barrel:hasFluidContainer() then
        local openBarrelOption = context:addOptionOnTop(getText("ContextMenu_UB_UncapBarrel", self.barrel.objectLabel), self, UBContextMenu.DoBarrelUncap);
        if not self.isValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
            UBUtils.DisableOptionAddTooltip(openBarrelOption, getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench")))
        end
    end

    if self.barrel:hasFluidContainer() then
        -- get vanilla FluidContainer object option
        local barrelOption = context:getOptionFromName(self.barrel.objectLabel)
        if not barrelOption then
            barrelOption = context:getOptionFromName(self.barrel.objectName)
        end

        if barrelOption then
            local barrelMenu = context:getSubMenu(barrelOption.subOption)
            self:RemoveVanillaOptions(context, barrelMenu)
            self:AddInfoOption(barrelMenu)
            if UBContextMenu.CanCreateFluidMenu(self.playerObj, self.barrel.square) then
                local worldObjects = UBUtils.GetWorldItemsNearby(self.barrel.square, TOOL_SCAN_DISTANCE)
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
    -- TODO for what this?
    if test then return end

    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.playerInv = o.playerObj:getInventory()
    o.barrel = UBUtils.GetUBBarrel(worldobjects)
    
    if not o.barrel then return end

    o.wrench = UBUtils.playerGetItem(o.playerInv, "PipeWrench")
    o.isValidWrench = o.wrench ~= nil and UBUtils.predicateNotBroken(o.wrench)

    return self:MainMenu(player, context, worldobjects, test)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBContextMenu:new(player, context, worldobjects, test) end)
