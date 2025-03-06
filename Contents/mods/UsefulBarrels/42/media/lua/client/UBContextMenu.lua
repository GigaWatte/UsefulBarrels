
local UBUtils = require "UBUtils"

local UBContextMenu = {}

-- << recreated vanilla functions 
function UBContextMenu:OnTransferFluid(squareToApproach, fluidContainer, fluidContainerItems, canAddToBarrel)
    local addToBarrel = canAddToBarrel ~= nil

    local didWalk = false
    for i,item in ipairs(fluidContainerItems) do
        if not didWalk and (not squareToApproach or not luautils.walkAdj(self.playerObj, squareToApproach, true)) then
			return
		end
		didWalk = true

        local returnToContainer = item:getContainer():isInCharacterInventory(self.playerObj) and item:getContainer()
		ISWorldObjectContextMenu.transferIfNeeded(self.playerObj, item)
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, self.playerObj:getPlayerNum())

        if not addToBarrel then
            ISTimedActionQueue.add(ISUBTransferFluid:new(self.playerObj, fluidContainer, item:getFluidContainer(), squareToApproach, item))
        else
            local hasFunnelNearby = UBUtils.playerHasItem(self.loot.inventory, "Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")
            local speedModifierApply = SandboxVars.UsefulBarrels.FunnelSpeedUpFillModifier > 0 and hasFunnelNearby
            ISTimedActionQueue.add(ISUBTransferFluid:new(self.playerObj, item:getFluidContainer(), fluidContainer, squareToApproach, item, speedModifierApply))
        end

        if returnToContainer and (returnToContainer ~= self.playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, item, self.playerInv, returnToContainer))
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
        local hasHoseNearby = UBUtils.playerHasItem(self.loot.inventory, "RubberHose") or UBUtils.playerHasItem(self.playerInv, "RubberHose")
        -- find all items that contain fluid from barrel or empty
        local fluidContainerItems = self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateFluid(item, self.barrelFluid) or UBUtils.predicateHasEmptyFluidContainer(item) end)
        -- convert to table
        local fluidContainerItemsTable = UBUtils.ConvertToTable(fluidContainerItems)
        -- get only items that can be filled
        local filteredFromBarrels = UBUtils.FilterMyBarrels(fluidContainerItemsTable)
        local allContainers = UBUtils.CanTransferFluid(filteredFromBarrels, self.barrelFluidContainer, true)
        local allContainerTypes = UBUtils.SortContainers(allContainers)
        local takeOption = context:insertOptionAfter(getText("Fluid_UB_Show_Info", self.fluidName), getText("ContextMenu_Fill"))
        if #allContainers == 0 then
            UBUtils.DisableOptionAddTooltip(takeOption, getText("Tooltip_UB_NoProperFluidInBarrel"))
            return
        end
        if takeOption and SandboxVars.UsefulBarrels.RequireHoseForTake and not hasHoseNearby then 
            UBUtils.DisableOptionAddTooltip(takeOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
            return
        end
        local takeMenu = ISContextMenu:getNew(context)
        context:addSubMenu(takeOption, takeMenu)
        if #allContainers > 1 and #allContainerTypes > 1 then
            local containerOption = takeMenu:addGetUpOption(
                getText("ContextMenu_FillAll"),
                self,
                UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, allContainers
            )
        end
        for _,containerType in pairs(allContainerTypes) do
            local destItem = containerType[1]
            if #containerType > 1 then
                local containerOption = takeMenu:addOption(destItem:getName() .. " (" .. #containerType ..")")
                local containerTypeMenu = ISContextMenu:getNew(takeMenu)
                takeMenu:addSubMenu(containerOption, containerTypeMenu)
                local addOneContainerOption = containerTypeMenu:addGetUpOption(
                    getText("ContextMenu_FillOne"), 
                    self, 
                    UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, { destItem }
                )
                if containerType[2] ~= nil then
                    local addAllContainerOption = containerTypeMenu:addGetUpOption(
                        getText("ContextMenu_FillAll"), 
                        self, 
                        UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, containerType
                    )
                end
            else
                local containerOption = takeMenu:addGetUpOption(
                    destItem:getName(),
                    self,
                    UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, { destItem }
                )
            end
        end
    end
    -- from inventory containers add to barrel
    function DoAddFluidMenu()
        local hasFunnelNearby = UBUtils.playerHasItem(self.loot.inventory, "Funnel") or UBUtils.playerHasItem(self.playerInv, "Funnel")
        -- find all items that hold greater than 0 fluid
        local fluidContainerItems = self.playerInv:getAllEvalRecurse(function (item) return UBUtils.predicateAnyFluid(item) end)
        -- convert to table
        local fluidContainerItemsTable = UBUtils.ConvertToTable(fluidContainerItems)
        local filteredFromBarrels = UBUtils.FilterMyBarrels(fluidContainerItemsTable)
        -- get only items that can be poured into target
        local allContainers = UBUtils.CanTransferFluid(filteredFromBarrels, self.barrelFluidContainer)
        local allContainerTypes = UBUtils.SortContainers(allContainers)
        local addOption = context:insertOptionAfter(getText("Fluid_UB_Show_Info", self.fluidName), getText("ContextMenu_UB_AddFluid"))
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
                UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, allContainers, true
            )
        end
        for _,containerType in pairs(allContainerTypes) do
            local destItem = containerType[1]
            if #containerType > 1 then
                local containerOption = addMenu:addOption(destItem:getName() .. " (" .. #containerType ..")")
                local containerTypeMenu = ISContextMenu:getNew(addMenu)
                addMenu:addSubMenu(containerOption, containerTypeMenu)
                local addOneContainerOption = containerTypeMenu:addGetUpOption(
                    getText("ContextMenu_AddOne"), 
                    self, 
                    UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, { destItem }, true
                )
                if containerType[2] ~= nil then
                    local addAllContainerOption = containerTypeMenu:addGetUpOption(
                        getText("ContextMenu_AddAll"), 
                        self, 
                        UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, containerType, true
                    )
                end
            else
                local containerOption = addMenu:addGetUpOption(
                    destItem:getName(),
                    self,
                    UBContextMenu.OnTransferFluid, squareToApproach, self.barrelFluidContainer, { destItem }, true
                )
            end
        end
    end

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
    local fluidAmount = self.barrelFluidContainer:getAmount()
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local fluidMax = self.barrelFluidContainer:getCapacity()
    if fluidAmount > 0 then
        self.barrelFluid = self.barrelFluidContainer:getPrimaryFluid()
    else
        self.barrelFluid = nil
    end
    self.fluidName = UBUtils.GetTranslatedFluidNameOrEmpty(self.barrelFluid)
    local tx = getTextManager():MeasureStringX(tooltip.font, self.fluidName .. ":") + 20
    tooltip.maxLineWidth = 512
    tooltip.description = tooltip.description .. UBUtils.FormatFluidAmount(tx, fluidAmount, fluidMax, self.fluidName)
    local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info", self.fluidName))
    infoOption.toolTip = tooltip
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
            UBContextMenu:DoFluidMenu(barrelMenu)
        end
    end
end

function UBContextMenu:new(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.loot = getPlayerLoot(player)
    o.playerInv = o.playerObj:getInventory()
    o.barrelObj = UBUtils.GetValidBarrelObject(worldobjects)
    
    if not o.barrelObj then return end

    o.wrench = UBUtils.playerGetItem(o.playerInv, "PipeWrench")
    o.isValidWrench = o.wrench ~= nil and UBUtils.predicateNotBroken(o.wrench)

    o.barrelHasFluidContainer = o.barrelObj:hasComponent(ComponentType.FluidContainer)
    o.objectName = o.barrelObj:getSprite():getProperties():Val("CustomName")
    o.objectLabel = UBUtils.getMoveableDisplayName(o.barrelObj)

    return self:MainMenu(player, context, worldobjects, test)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBContextMenu:new(player, context, worldobjects, test) end)
