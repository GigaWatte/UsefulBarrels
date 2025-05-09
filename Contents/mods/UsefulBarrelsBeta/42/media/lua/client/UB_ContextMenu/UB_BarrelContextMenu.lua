
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

    for i,curr in ipairs(fluidContainerItems) do
        local item
        local itemFluidContainer
        if instanceof(curr, "IsoWorldInventoryObject") then
            item = curr:getItem()
            itemFluidContainer = curr:getFluidContainer()
        else
            item = curr
            itemFluidContainer = curr:getFluidContainer()
        end

        -- this returns item back to container it's taken. example: backpack
        local containerToReturn = item:getContainer()
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
            ISTimedActionQueue.add(
                UB_TransferFluidAction:new(playerObj, itemFluidContainer, fluidContainer, barrelSquare, item, speedModifierApply)
            )
        else
            ISTimedActionQueue.add(
                UB_TransferFluidAction:new(playerObj, fluidContainer, itemFluidContainer, barrelSquare, item)
            )
        end
        -- return item back to container
        if containerToReturn and (containerToReturn ~= playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, playerInv, containerToReturn))
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
		
        ISTimedActionQueue.add(UB_SiphonFromVehicleAction:new(playerObj, part, barrel))
	end
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

function UB_BarrelContextMenu:DoFluidMenu(subMenu, optionsTable, isGroundMenu)
    if not isGroundMenu then isGroundMenu = false end

    local containers
    if isGroundMenu then
        containers = optionsTable.groundContainers
    else
        containers = optionsTable.containers
    end
    local allContainers = self.barrel:CanTransferFluid(containers, optionsTable.addToBarrel == false)
    local allContainerTypes = UBUtils.SortContainers(allContainers)

    local optionText
    if isGroundMenu then
        optionText = optionsTable.groundOptionText
    else
        optionText = optionsTable.optionText
    end

    local menuOption = subMenu:addOption(optionText)

    if SandboxVars.UsefulBarrels.DebugMode then
        local description = string.format(
            [[
            action: %s from %s
            containers: %s
            valid conteiners: %s
            --------------------
            ]],
            tostring(optionsTable.addToBarrel and "add" or "fill"),
            tostring(isGroundMenu and "ground" or "inventory"),
            tostring(#containers),
            tostring(#allContainers)
        )
    
        self.debugOption.toolTip.description = self.debugOption.toolTip.description .. description
    end

    if optionsTable.noToolPredicate == true then
        UBUtils.DisableOptionAddTooltip(menuOption, optionsTable.noToolTooltip)
        return
    end
    if #allContainers == 0 then
        if isGroundMenu then
            UBUtils.DisableOptionAddTooltip(menuOption, optionsTable.noGroundContainersTooltip)
        else
            UBUtils.DisableOptionAddTooltip(menuOption, optionsTable.noContainersNooltip)
        end
        return
    end

    local newSubMenu = ISContextMenu:getNew(subMenu)
    subMenu:addSubMenu(menuOption, newSubMenu)
    self:DoAllItemsMenu(newSubMenu, allContainers, allContainerTypes, optionsTable.addToBarrel, optionsTable.actionAllText)
    self:DoCategoryList(newSubMenu, allContainerTypes, optionsTable.addToBarrel, optionsTable.actionOneText, optionsTable.actionAllText)
end

function UB_BarrelContextMenu:DoSiphonFromVehicleMenu(context, hasHoseNearby)
    if not SandboxVars.UsefulBarrels.EnableFillBarrelFromVehicles then return end

    local vehicles = UBUtils.GetVehiclesNeaby(self.barrel.square, UBConst.VEHICLE_SCAN_DISTANCE)

    local description = string.format(
        [[
        SVFillBarrelFromVehiclesRequiresHose: %s
        hasHoseNearby: %s
        vehicles: %s
        ]],
        tostring(SandboxVars.UsefulBarrels.FillBarrelFromVehiclesRequiresHose),
        tostring(hasHoseNearby),
        tostring(#vehicles)
    )

    if not (#vehicles > 0) then return end

    local vehicleOption = context:addOption(getText("ContextMenu_UB_RefuelFromVehicle"))

    if SandboxVars.UsefulBarrels.FillBarrelFromVehiclesRequiresHose and not hasHoseNearby then
        UBUtils.DisableOptionAddTooltip(vehicleOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
        return
    end

    local vehicleMenu = ISContextMenu:getNew(context)
    context:addSubMenu(vehicleOption, vehicleMenu)
    for _,vehicle in ipairs(vehicles) do
        --string.find(vehicle:getScriptName(), "Trailer") ~= nil
        local carName = vehicle:getScript():getCarModelName() or vehicle:getScript():getName()
        description = description .. string.format(
            [[
            vehicle: %s (%s)
            ]], 
            tostring(carName), 
            tostring(vehicle:getPartCount())
        )
        local vehicle_gas_part_found = false
        for i=1,vehicle:getPartCount() do
            local part = vehicle:getPartByIndex(i-1)
            local partCategory = part:getCategory()
            if part and partCategory and part:isContainer() and string.find(partCategory, "gastank")~=nil then
                description = description .. string.format(
                    [[
                    gas amount: %sL
                    ]], 
                    tostring(math.ceil(part:getContainerContentAmount()))
                )
                vehicle_gas_part_found = true
                local vehicle_option = vehicleMenu:addOption(getText("IGUI_VehicleName" .. carName), self.playerObj, UB_BarrelContextMenu.OnVehicleTransferFluid, part, self.barrel)
                if part:getContainerContentAmount() > 0 then
                    local tooltip = ISWorldObjectContextMenu.addToolTip()
                    tooltip.maxLineWidth = 512
                    tooltip.description = getText("Fluid_UB_Show_Info", tostring(math.ceil(part:getContainerContentAmount())) .. "L")
                    vehicle_option.toolTip = tooltip
                else
                    UBUtils.DisableOptionAddTooltip(vehicle_option, getText("ContextMenu_Empty"))
                end
            end
        end
        if not vehicle_gas_part_found then
            description = description .. string.format([[
                no proper gas part found
            ]])
        end
    end

    if SandboxVars.UsefulBarrels.DebugMode then
        self.debugOption.toolTip.description = self.debugOption.toolTip.description .. description
    end
end

function UB_BarrelContextMenu:AddInfoOption(context)
    local fluidName = self.barrel:GetTranslatedFluidNameOrEmpty()

    local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info", fluidName))

    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.maxLineWidth = 512
    tooltip.description = self.barrel:GetTooltipText(tooltip.font)
    infoOption.toolTip = tooltip
    if self.barrelFluid and self.barrelFluid:isPoisonous() then
        infoOption.iconTexture = getTexture("media/ui/Skull2.png")
        tooltip.description = tooltip.description .. "\n" .. getText("Fluid_Poison")
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

    if SandboxVars.UsefulBarrels.DebugMode then
        self.debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
        self.debugOption.toolTip = ISWorldObjectContextMenu.addToolTip()

        local description = self.barrel:GetBarrelInfo()
        
        description = description .. string.format(
            [[
            SVRequireHose: %s
            SVRequireFunnel: %s
            contextMenuHasOption: %s
            CanCreateFluidMenu: %s
            ]],
            tostring(SandboxVars.UsefulBarrels.RequireHoseForTake),
            tostring(SandboxVars.UsefulBarrels.RequireFunnelForFill),
            tostring(barrelOption ~= nil),
            tostring(UBUtils.CanCreateBarrelFluidMenu(self.playerObj, self.barrel.square))
        )
    
        self.debugOption.toolTip.description = description
    end

    if barrelOption then
        local barrelMenu = context:getSubMenu(barrelOption.subOption)
        self:RemoveVanillaOptions(context, barrelMenu)
        if UBUtils.CanCreateBarrelFluidMenu(self.playerObj, self.barrel.square, barrelOption) then
            self:AddInfoOption(barrelMenu)
            local worldObjects = UBUtils.GetWorldItemsNearby(self.barrel.square, UBConst.TOOL_SCAN_DISTANCE)
            local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
            local hasFunnelNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.Funnel")
            -- TODO if too far from barrel - red all options

            local addMenuOpts = {
                addToBarrel=true,
                containers=UBUtils.getPlayerFluidContainers(self.playerInv),
                optionText=getText("ContextMenu_UB_AddFluid"),
                noToolPredicate=SandboxVars.UsefulBarrels.RequireFunnelForFill == true and hasFunnelNearby == false,
                noToolTooltip=getText("Tooltip_UB_FunnelMissing", getItemName("Base.Funnel")),
                noContainersNooltip=getText("Tooltip_UB_NoProperFluidInInventory"),
                actionAllText=getText("ContextMenu_AddAll"),
                actionOneText=getText("ContextMenu_AddOne"),

                groundOptionText=getText("ContextMenu_UB_AddFluid_FromGround"),
                groundContainers=UBUtils.GetWorldFluidContainersNearby(
                    self.barrel.square, 
                    UBConst.WORLD_ITEMS_DISTANCE,
                    function(worldInventoryObject) return UBUtils.predicateAnyFluid(worldInventoryObject) end
                ),
                noGroundContainersTooltip=getText("Tooltip_UB_NoProperFluidOnGround"),
            }

            local takeMenuOpts = {
                addToBarrel=false,
                containers=UBUtils.getPlayerFluidContainersWithFluid(self.playerInv, self.barrelFluid),
                optionText=getText("ContextMenu_Fill"),
                noToolPredicate=SandboxVars.UsefulBarrels.RequireHoseForTake == true and hasHoseNearby == false,
                noToolTooltip=getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")),
                noContainersNooltip=getText("Tooltip_UB_NoProperContainerInInventory"),
                actionAllText=getText("ContextMenu_FillAll"),
                actionOneText=getText("ContextMenu_FillOne"),
                
                groundOptionText=getText("ContextMenu_UB_AddFluid_OnGround"),
                groundContainers=UBUtils.GetWorldFluidContainersNearby(
                    self.barrel.square, 
                    UBConst.WORLD_ITEMS_DISTANCE,
                    function(worldInventoryObject) return UBUtils.predicateFluid(worldInventoryObject, self.barrelFluid) or UBUtils.predicateHasFluidContainer(worldInventoryObject) end
                ),
                noGroundContainersTooltip=getText("Tooltip_UB_NoProperContainerOnGround"),
            }
            
            if SandboxVars.UsefulBarrels.DebugMode then
                local description = string.format(
                    [[
                    hasHoseNearby: %s
                    hasFunnelNearby: %s
                    ]],
                    tostring(hasHoseNearby),
                    tostring(hasFunnelNearby)
                )
            
                self.debugOption.toolTip.description = self.debugOption.toolTip.description .. description
            end

            -- add menu
            self:DoFluidMenu(barrelMenu, addMenuOpts)
            -- take menu
            self:DoFluidMenu(barrelMenu, takeMenuOpts)

            -- add from ground menu
            self:DoFluidMenu(barrelMenu, addMenuOpts, true)
            -- add to ground menu
            self:DoFluidMenu(barrelMenu, takeMenuOpts, true)

            if SandboxVars.UsefulBarrels.DebugMode then
                self.debugOption.toolTip.description = self.debugOption.toolTip.description .. string.format(
                [[
                SVEnableFillBarrelFromVehicles: %s
                ]],
                tostring(SandboxVars.UsefulBarrels.EnableFillBarrelFromVehicles)
                )
            end

            self:DoSiphonFromVehicleMenu(barrelMenu, hasHoseNearby)
        end
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