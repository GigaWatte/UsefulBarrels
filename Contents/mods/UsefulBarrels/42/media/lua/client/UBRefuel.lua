
local UBUtils = require "UBUtils"

local UBRefuel = {}

function UBRefuel.doAddFuelGenerator(worldobjects, generator, barrel, player)
	-- print("Size : " .. tostring(fuelContainerList))
	local playerObj = getSpecificPlayer(player)
	if luautils.walkAdj(playerObj, generator:getSquare()) then
        if generator:getFuel() < 100 then
            ISTimedActionQueue.add(ISUBAddFuelFromBarrel:new(playerObj, generator, barrel, 70 + (barrel:getFluidContainer():getAmount() * 40)));
        end
	end
end

function UBRefuel:MainMenu(player, context, barrels)
    -- get vanilla AddFuel option or create new
    local fillOption = context:getOptionFromName(getText("ContextMenu_GeneratorAddFuel"))
    if not fillOption then fillOption = context:addOption(getText("ContextMenu_GeneratorAddFuel")) end

    if not self.generator:getSquare() or not AdjacentFreeTileFinder.Find(self.generator:getSquare(), self.playerObj) then
        fillOption.notAvailable = true;
        -- if the player can reach the tile, populate the submenu, otherwise don't bother
        return;
    end

    --add the fill menu
    local containerMenu = context:getSubMenu(fillOption.subOption)
    if not containerMenu then 
        containerMenu = ISContextMenu:getNew(context)
        context:addSubMenu(fillOption, containerMenu) 
    end

    local containerOption

    for _,barrel in ipairs(barrels) do
        containerOption = containerMenu:addGetUpOption(UBUtils.getMoveableDisplayName(barrel), nil, UBRefuel.doAddFuelGenerator, self.generator, barrel, player)
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
        --local infoOption = context:addOptionOnTop(getText("Fluid_UB_Show_Info", fluidName))
        --infoOption.toolTip = tooltip

        --local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.object = barrel
        containerOption.toolTip = tooltip
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
            --_subMenu.toolTip.object = nil
        end
        ISContextMenu.hideToolTip(_subMenu)
    end
    -- context:addGetUpOption(getText("ContextMenu_GeneratorAddFuel"), worldobjects, ISWorldObjectContextMenu.onAddFuelGenerator, petrolCan, fetch.generator, player, context);
    --ISWorldObjectContextMenu.onAddFuelGenerator(worldobjects, petrolCan, fetch.generator, player, context)

end

function UBRefuel:new(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    --o.loot = getPlayerLoot(player)
    o.playerInv = o.playerObj:getInventory()
    --o.barrelObj = UBUtils.GetValidBarrelObject(worldobjects)
    o.generator = ISWorldObjectContextMenu.fetchVars.generator

    if not o.generator or o.playerObj:getVehicle() then return end
    if o.generator:isActivated() or o.generator:getFuel() >= 100 then return end

    local barrels = UBUtils.GetBarrelsNearby(o.generator:getSquare(), 2, Fluid.Petrol)

    --o.wrench = UBUtils.playerGetItem(o.playerInv, "PipeWrench")
    --o.isValidWrench = o.wrench ~= nil and UBUtils.predicateNotBroken(o.wrench)
--
    --o.barrelHasFluidContainer = o.barrelObj:hasComponent(ComponentType.FluidContainer)
    --o.objectName = o.barrelObj:getSprite():getProperties():Val("CustomName")
    --o.objectLabel = UBUtils.getMoveableDisplayName(o.barrelObj)

    return self:MainMenu(player, context, barrels)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBRefuel:new(player, context, worldobjects, test) end)
