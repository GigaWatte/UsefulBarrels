
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UBRefuel = {}


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
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel:getSquare(), UBConst.TOOL_SCAN_DISTANCE)
        local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
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
    local description = string.format(
        [[SVGeneratorRequireHose: %s\n
        Gen isActivated: %s\n
        Gen fuel >= 100: %s\n
        Barrels available: %s\n
        CanCreateMenu: %s\n
        ]],
        tostring(SandboxVars.UsefulBarrels.GeneratorRefuelRequiresHose),
        tostring(self.generator:isActivated()),
        tostring(self.generator:getFuel() >= 100),
        tostring(#self.barrels),
        tostring(UBRefuel.CanCreateRefuelMenu(self.generator:getSquare(), self.playerObj))
    )
    for _,barrel in ipairs(self.barrels) do
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel:getSquare(), UBConst.TOOL_SCAN_DISTANCE)
        local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
        description = description .. string.format("hasHoseNearby: %s\n", tostring(hasHoseNearby))
        description = description .. barrel:GetBarrelInfo()
    end
    tooltip.description = description
    debugOption.toolTip = tooltip
end

function UBRefuel:new(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.playerInv = o.playerObj:getInventory()
    o.generator = ISWorldObjectContextMenu.fetchVars.generator

    if not o.generator or o.playerObj:getVehicle() then return end
    if o.generator:isActivated() or o.generator:getFuel() >= 100 then return end

    o.barrels = UBUtils.GetBarrelsNearby(o.generator:getSquare(), UBConst.BARREL_SCAN_DISTANCE, Fluid.Petrol)

    if SandboxVars.UsefulBarrels.DebugMode then
        self:DoDebugOption(player, context, worldobjects, test)
    end

    if #o.barrels == 0 then return end
    if not UBRefuel.CanCreateRefuelMenu(o.generator:getSquare(), o.playerObj) then return end
    return self:DoRefuelMenu(player, context)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UBRefuel:new(player, context, worldobjects, test) end)
