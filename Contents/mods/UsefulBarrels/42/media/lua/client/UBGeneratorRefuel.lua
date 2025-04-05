
local UBUtils = require "UBUtils"

local UBRefuel = {}
local TOOL_SCAN_DISTANCE = 2
local BARREL_SCAN_DISTANCE = 2

function UBRefuel.doAddFuelGenerator(worldobjects, generator, barrel, player)
	local playerObj = getSpecificPlayer(player)
	if luautils.walkAdj(playerObj, generator:getSquare()) then
        if generator:getFuel() < 100 then
            ISTimedActionQueue.add(ISUBAddFuelFromBarrel:new(playerObj, generator, barrel));
        end
	end
end

function UBRefuel:CreateBarrelOption(containerMenu, barrel, hasHoseNearby, player)
    local containerOption = containerMenu:addGetUpOption(UBUtils.getMoveableDisplayName(barrel), nil, UBRefuel.doAddFuelGenerator, self.generator, barrel, player)

    if SandboxVars.UsefulBarrels.GeneratorRefuelRequiresHose and not hasHoseNearby then 
        UBUtils.DisableOptionAddTooltip(containerOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
        return       
    end

    local barrelFluidContainer = barrel:getComponent(ComponentType.FluidContainer)
    local fluidAmount = barrelFluidContainer:getAmount()
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    local fluidMax = barrelFluidContainer:getCapacity()
    local barrelFluid
    if fluidAmount > 0 then
        barrelFluid = barrelFluidContainer:getPrimaryFluid()
    else
        barrelFluid = nil
    end
    local fluidName = UBUtils.GetTranslatedFluidNameOrEmpty(barrelFluid)
    local tx = getTextManager():MeasureStringX(tooltip.font, fluidName .. ":") + 20
    tooltip.maxLineWidth = 512
    tooltip.description = tooltip.description .. UBUtils.FormatFluidAmount(tx, fluidAmount, fluidMax, fluidName)
    tooltip.object = barrel
    containerOption.toolTip = tooltip
end

function UBRefuel.CanCreateRefuelMenu(generatorSquare, playerObj)
    if not generatorSquare or not AdjacentFreeTileFinder.Find(generatorSquare, playerObj) then
        -- if the player can reach the tile, populate the submenu, otherwise don't bother
        return false
    end

    return true
end

function UBRefuel:DoRefuelMenu(player, context)
    local fillOption
    -- add option after vanilla add option and only if it exists
    if context:getOptionFromName(getText("ContextMenu_GeneratorAddFuel")) then 
        fillOption = context:insertOptionAfter(getText("ContextMenu_GeneratorAddFuel"), getText("ContextMenu_UB_RefuelFromBarrel"))
    elseif context:getOptionFromName(getText("ContextMenu_GeneratorInfo")) then
        fillOption = context:insertOptionAfter(getText("ContextMenu_GeneratorInfo"), getText("ContextMenu_UB_RefuelFromBarrel"))
    end
    -- add option if no canisters but barrel
    if not fillOption then return end

    local containerMenu = ISContextMenu:getNew(context)
    context:addSubMenu(fillOption, containerMenu) 

    for _,barrel in ipairs(self.barrels) do
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel:getSquare(), TOOL_SCAN_DISTANCE)
        local hasHoseNearby = UBUtils.TableContainsItem(worldObjects, "Base.RubberHose") or UBUtils.playerHasItem(self.playerInv, "RubberHose")
        self:CreateBarrelOption(containerMenu, barrel, hasHoseNearby, player)
    end

    local hc = getCore():getObjectHighlitedColor()
    --highlight the object on tile while the tooltip is showing
    containerMenu.showTooltip = function(_subMenu, _option)
        ISContextMenu.showTooltip(_subMenu, _option)
        if _subMenu.toolTip.object ~= nil then
            _option.toolTip:setVisible(false)
            _option.toolTip.object:setHighlightColor(hc)
            _option.toolTip.object:setHighlighted(true, false)
        end
    end

    --stop highlighting the object when the tooltip is not showing
    containerMenu.hideToolTip = function(_subMenu)
        if _subMenu.toolTip and _subMenu.toolTip.object then
            _subMenu.toolTip.object:setHighlighted(false)
        end
        ISContextMenu.hideToolTip(_subMenu)
    end
end

function UBRefuel:DoDebugOption(player, context, worldobjects, test)
    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    debugOption.toolTip = tooltip
    local generator = ISWorldObjectContextMenu.fetchVars.generator
    tooltip.description = tooltip.description .. string.format("Generator: %s", tostring(generator ~= nil)) .. "\n"
    local playerObj = getSpecificPlayer(player)
    tooltip.description = tooltip.description .. string.format("Player vehicle: %s", tostring(playerObj:getVehicle() ~= nil)) .. "\n"
    local playerInv = playerObj:getInventory()

    if not generator then return end

    local barrels = UBUtils.GetBarrelsNearby(generator:getSquare(), BARREL_SCAN_DISTANCE, Fluid.Petrol)
    tooltip.description = tooltip.description .. string.format("SVGeneratorRequireHose: %s", tostring(SandboxVars.UsefulBarrels.GeneratorRefuelRequiresHose)) .. "\n"
    tooltip.description = tooltip.description .. string.format("Gen isActivated: %s", tostring(generator:isActivated())) .. "\n"
    tooltip.description = tooltip.description .. string.format("Gen fuel >= 100: %s", tostring(generator:getFuel() >= 100)) .. "\n"
    tooltip.description = tooltip.description .. string.format("Barrels available: %s", tostring(#barrels)) .. "\n"
    tooltip.description = tooltip.description .. string.format("Can create menu: %s", tostring(UBRefuel.CanCreateRefuelMenu(generator:getSquare(), playerObj))) .. "\n"

    for _,barrel in ipairs(barrels) do
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel:getSquare(), TOOL_SCAN_DISTANCE)
        local hasHoseNearby = UBUtils.TableContainsItem(worldObjects, "Base.RubberHose") or UBUtils.playerHasItem(playerInv, "RubberHose")
        tooltip.description = tooltip.description .. string.format("Barrel object: %s", tostring(barrel)) .. "\n"
        tooltip.description = tooltip.description .. string.format("hasHoseNearby: %s", tostring(hasHoseNearby)) .. "\n"

        local barrelFluidContainer = barrel:getComponent(ComponentType.FluidContainer)
        local fluidAmount = barrelFluidContainer:getAmount()
        local fluidMax = barrelFluidContainer:getCapacity()
        local barrelFluid
        if fluidAmount > 0 then
            barrelFluid = barrelFluidContainer:getPrimaryFluid()
        else
            barrelFluid = nil
        end
        tooltip.description = tooltip.description .. string.format("Fluid: %s", tostring(barrelFluid)) .. "\n"
        tooltip.description = tooltip.description .. string.format("Fluid amount: %s", tostring(fluidAmount)) .. "\n"
        tooltip.description = tooltip.description .. string.format("Fluid capacity: %s", tostring(fluidMax)) .. "\n"
        tooltip.description = tooltip.description .. string.format("isInputLocked: %s", tostring(barrelFluidContainer:isInputLocked())) .. "\n"
        tooltip.description = tooltip.description .. string.format("canPlayerEmpty: %s", tostring(barrelFluidContainer:canPlayerEmpty())) .. "\n"
    end
end

function UBRefuel:new(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.playerInv = o.playerObj:getInventory()
    o.generator = ISWorldObjectContextMenu.fetchVars.generator

    if SandboxVars.UsefulBarrels.DebugMode then
        self:DoDebugOption(player, context, worldobjects, test)
    end

    if not o.generator or o.playerObj:getVehicle() then return end
    if o.generator:isActivated() or o.generator:getFuel() >= 100 then return end

    o.barrels = UBUtils.GetBarrelsNearby(o.generator:getSquare(), BARREL_SCAN_DISTANCE, Fluid.Petrol)

    if #o.barrels == 0 then return end
    if not UBRefuel.CanCreateRefuelMenu(o.generator:getSquare(), o.playerObj) then return end
    return self:DoRefuelMenu(player, context)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBRefuel:new(player, context, worldobjects, test) end)
