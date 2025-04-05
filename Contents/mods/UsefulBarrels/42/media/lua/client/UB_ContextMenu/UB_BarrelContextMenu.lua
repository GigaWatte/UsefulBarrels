
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UBBarrel = require "UBBarrel"
local UB_BarrelContextMenu = {}

function UB_BarrelContextMenu.OnTransferFluid(playerObj, barrelSquare, fluidContainer, fluidContainerItems, addToBarrel)
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
            local worldObjects = UBUtils.GetWorldItemsNearby(barrelSquare, UBConst.TOOL_SCAN_DISTANCE)
            local hasFunnelNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerInv, "Base.Funnel")
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

function UB_BarrelContextMenu.OnVehicleTransferFluid(playerObj, part, barrel)
    if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	if barrel then
		local action = ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea())
		action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
		ISTimedActionQueue.add(action)
		
        ISTimedActionQueue.add(ISUBSiphonFromVehicle:new(playerObj, part, barrel))
	end
end

function UB_BarrelContextMenu.CanCreateFluidMenu(playerObj, barrelSquare)
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

function UB_BarrelContextMenu:DoCategoryList(subMenu, allContainerTypes, addToBarrel, oneOptionText, allOptionText)
    for _,containerType in pairs(allContainerTypes) do
        local destItem = containerType[1]
        if #containerType > 1 then
            local containerOption = subMenu:addOption(destItem:getName() .. " (" .. #containerType ..")")
            local containerTypeMenu = ISContextMenu:getNew(subMenu)
            subMenu:addSubMenu(containerOption, containerTypeMenu)
            local addOneContainerOption = containerTypeMenu:addGetUpOption(
                oneOptionText, 
                self.playerObj, 
                UB_BarrelContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, { destItem }, addToBarrel
            )
            if containerType[2] ~= nil then
                local addAllContainerOption = containerTypeMenu:addGetUpOption(
                    allOptionText, 
                    self.playerObj, 
                    UB_BarrelContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, containerType, addToBarrel
                )
            end
        else
            local containerOption = subMenu:addGetUpOption(
                destItem:getName(),
                self.playerObj,
                UB_BarrelContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, { destItem }, addToBarrel
            )
        end
    end
end

function UB_BarrelContextMenu:DoAllItemsMenu(subMenu, allContainers, allContainerTypes, addToBarrel, optionText)
    if #allContainers > 1 and #allContainerTypes > 1 then
        local containerOption = subMenu:addGetUpOption(
            optionText, 
            self.playerObj, 
            UB_BarrelContextMenu.OnTransferFluid, self.barrel.square, self.barrel.fluidContainer, allContainers, addToBarrel
        )
    end
end

function UB_BarrelContextMenu:DoTakeFluidMenu(context, hasHoseNearby)
    -- find all items that contain fluid from barrel or empty
    local fluidContainerItems = UBUtils.getPlayerFluidContainersWithFluid(self.playerInv, self.barrelFluid)
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
    self:DoCategoryList(takeMenu, allContainerTypes, false, getText("ContextMenu_FillOne"), getText("ContextMenu_FillAll"))
end

function UB_BarrelContextMenu:DoAddFluidMenu(context, hasFunnelNearby)
    -- find all items in player inv that hold greater than 0 fluid
    local fluidContainerItems = UBUtils.getPlayerFluidContainers(self.playerInv)
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

function UB_BarrelContextMenu:DoSiphonFromVehicleMenu(context, hasHoseNearby)
    if not SandboxVars.UsefulBarrels.EnableFillBarrelFromVehicles then return end

    local vehicles = UBUtils.GetVehiclesNeaby(self.barrel.square, UBConst.VEHICLE_SCAN_DISTANCE)

    if not vehicles then return end
    if not (#vehicles > 0) then return end

    local vehicleOption = context:addOption(getText("ContextMenu_RefuelFromVehicle"))

    if SandboxVars.UsefulBarrels.UsefulBarrelsFillBarrelFromVehiclesRequiresHose and not hasHoseNearby then
        UBUtils.DisableOptionAddTooltip(vehicleOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
        return
    end
    local vehicleMenu = ISContextMenu:getNew(context)
    context:addSubMenu(vehicleOption, vehicleMenu)
    for _,vehicle in ipairs(vehicles) do
        --string.find(vehicle:getScriptName(), "Trailer") ~= nild
        for i=1,vehicle:getPartCount() do
            local part = vehicle:getPartByIndex(i-1)
            local partCategory = part:getCategory()
            if part and partCategory and part:isContainer() and string.find(partCategory, "gastank")~=nil and part:getContainerContentAmount() > 0 then
                local carName = vehicle:getScript():getCarModelName() or vehicle:getScript():getName()
                local vehicle_option = vehicleMenu:addOption(getText("IGUI_VehicleName" .. carName), self.playerObj, UB_BarrelContextMenu.OnVehicleTransferFluid, part, self.barrel)
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip.maxLineWidth = 512
                tooltip.description = getText("Fluid_UB_Show_Info", tostring(math.ceil(part:getContainerContentAmount())) .. "L")
                vehicle_option.toolTip = tooltip

            end
        end
    end

end

function UB_BarrelContextMenu:AddInfoOption(context)
    local fluidName = self.barrel:GetTranslatedFluidNameOrEmpty()

    local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info", fluidName))
    if self.playerObj:DistToSquared(self.barrel.isoObject:getX() + 0.5, self.barrel.isoObject:getY() + 0.5) < 2 * 2 then
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.maxLineWidth = 512
        tooltip.description = self.barrel:GetTooltipText(tooltip.font)
        infoOption.toolTip = tooltip
        if self.barrelFluid and self.barrelFluid:isPoisonous() then
            infoOption.iconTexture = getTexture("media/ui/Skull2.png")
            tooltip.description = tooltip.description .. "\n" .. getText("Fluid_Poison")
        end
    end

end

function UB_BarrelContextMenu:RemoveVanillaOptions(context, subcontext)
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

function UB_BarrelContextMenu:DoDebugOption(context)
    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local worldObjects = UBUtils.GetWorldItemsNearby(self.barrel.square, UBConst.TOOL_SCAN_DISTANCE)
    local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
    local hasFunnelNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.Funnel")

    local description = string.format(
        [[
        SVRequireHose: %s
        SVRequireFunnel: %s
        hasHoseNearby: %s
        hasFunnelNearby: %s
        CanCreateFluidMenu: %s
        ]],
        tostring(SandboxVars.UsefulBarrels.RequireHoseForTake),
        tostring(SandboxVars.UsefulBarrels.RequireFunnelForFill),
        tostring(hasHoseNearby),
        tostring(hasFunnelNearby),
        tostring(UB_BarrelContextMenu.CanCreateFluidMenu(self.playerObj, self.barrel.square))
    )

    description = description .. self.barrel:GetBarrelInfo()

    local addfluidContainerItems = UBUtils.getPlayerFluidContainers(self.playerInv)
    local addfluidContainerItemsTable = UBUtils.ConvertToTable(addfluidContainerItems)
    local addallContainers = self.barrel:CanTransferFluid(addfluidContainerItemsTable)
    local takefluidContainerItems = UBUtils.getPlayerFluidContainersWithFluid(self.playerInv, self.barrel:getPrimaryFluid())
    local takefluidContainerItemsTable = UBUtils.ConvertToTable(takefluidContainerItems)
    local takeallContainers = self.barrel:CanTransferFluid(takefluidContainerItemsTable, true)

    description = description .. string.format(
        [[
        All containers to add: %s
        Valid containers to add: %s
        All containers for pouring: %s
        Valid containers for pouring: %s
        ]],
        tostring(#addfluidContainerItemsTable),
        tostring(#addallContainers),
        tostring(#takefluidContainerItemsTable),
        tostring(#takeallContainers)
    )

    tooltip.description = description
    debugOption.toolTip = tooltip
end

function UB_BarrelContextMenu:new(player, context, ub_barrel)
    local o = self

    self.barrel = ub_barrel
    self.playerObj = getSpecificPlayer(player)
    self.playerInv = self.playerObj:getInventory()
    self.barrelFluid = self.barrel:getPrimaryFluid()

    -- get vanilla FluidContainer object option
    local barrelOption = context:getOptionFromName(self.barrel.objectLabel)
    if barrelOption and self.barrel.icon then
        barrelOption.iconTexture = self.barrel.icon
    end

    if barrelOption then
        local barrelMenu = context:getSubMenu(barrelOption.subOption)
        self:RemoveVanillaOptions(context, barrelMenu)
        self:AddInfoOption(barrelMenu)
        if UB_BarrelContextMenu.CanCreateFluidMenu(self.playerObj, self.barrel.square) then
            local worldObjects = UBUtils.GetWorldItemsNearby(self.barrel.square, UBConst.TOOL_SCAN_DISTANCE)
            local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
            local hasFunnelNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.Funnel")
            self:DoAddFluidMenu(barrelMenu, hasFunnelNearby)
            self:DoTakeFluidMenu(barrelMenu, hasHoseNearby)
            self:DoSiphonFromVehicleMenu(barrelMenu, hasHoseNearby)
        end
    end

    if SandboxVars.UsefulBarrels.DebugMode then
        self:DoDebugOption(context)
    end
end

local function BarrelContextMenu(player, context, worldobjects, test)
    local barrel = UBUtils.GetValidBarrel(worldobjects)
    
    if not barrel then return end
    if not barrel:hasComponent(ComponentType.FluidContainer) then return end

    local ub_barrel = UBBarrel:new(barrel)

    if not ub_barrel then return end

    return UB_BarrelContextMenu:new(player, context, ub_barrel)
end

Events.OnFillWorldObjectContextMenu.Add(BarrelContextMenu)
