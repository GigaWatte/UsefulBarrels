
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UB_GeneratorContextMenu = {}


function UB_GeneratorContextMenu.doAddFuelGenerator(worldobjects, generator, barrel, playerObj)
	if luautils.walkAdj(playerObj, generator:getSquare()) then
        if generator:getFuel() < 100 then
            ISTimedActionQueue.add(UB_RefuelGeneratorAction:new(playerObj, generator, barrel));
        end
	end
end

function UB_GeneratorContextMenu:CreateBarrelOption(containerMenu, barrel, hasHoseNearby, player)
    local containerOption = containerMenu:addGetUpOption(
        barrel.objectLabel, nil, UB_GeneratorContextMenu.doAddFuelGenerator, self.generator, barrel, self.playerObj
    )
    if containerOption and barrel.icon then
        containerOption.iconTexture = barrel.icon
    end

    if SandboxVars.UsefulBarrels.GeneratorRefuelRequiresHose and not hasHoseNearby then 
        UBUtils.DisableOptionAddTooltip(containerOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
        return       
    end

    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip.maxLineWidth = 512
    tooltip.description = barrel:GetTooltipText(tooltip.font)
    tooltip.object = barrel.isoObject
    containerOption.toolTip = tooltip
end

function UB_GeneratorContextMenu.CanCreateRefuelMenu(generatorSquare, playerObj)
    if not generatorSquare or not AdjacentFreeTileFinder.Find(generatorSquare, playerObj) then
        -- if the player can reach the tile, populate the submenu, otherwise don't bother
        return false
    end

    return true
end

function UB_GeneratorContextMenu:DoRefuelMenu(player, context)
    local fillOption

    if context:getOptionFromName(getText("ContextMenu_GeneratorAddFuel")) then 
        fillOption = context:insertOptionAfter(getText("ContextMenu_GeneratorAddFuel"), getText("ContextMenu_UB_RefuelFromBarrel"))
    elseif context:getOptionFromName(getText("ContextMenu_GeneratorInfo")) then
        fillOption = context:insertOptionAfter(getText("ContextMenu_GeneratorInfo"), getText("ContextMenu_UB_RefuelFromBarrel"))
    end

    if not fillOption then return end

    local containerMenu = ISContextMenu:getNew(context)
    context:addSubMenu(fillOption, containerMenu) 

    for _,barrel in ipairs(self.barrels) do
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
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

function UB_GeneratorContextMenu:new(player, context, worldobjects, test)
    local o = self
    o.playerObj = getSpecificPlayer(player)
    o.playerInv = o.playerObj:getInventory()
    o.generator = ISWorldObjectContextMenu.fetchVars.generator

    if not o.generator or o.playerObj:getVehicle() then return end
    if o.generator:isActivated() or o.generator:getFuel() >= 100 then return end

    o.barrels = UBUtils.GetBarrelsNearby(o.generator:getSquare(), UBConst.GENERATOR_SCAN_DISTANCE, Fluid.Petrol)

    if not SandboxVars.UsefulBarrels.EnableGeneratorRefuel then return end

    if #o.barrels == 0 then return end
    if not UB_GeneratorContextMenu.CanCreateRefuelMenu(o.generator:getSquare(), o.playerObj) then return end
    return self:DoRefuelMenu(player, context)
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UB_GeneratorContextMenu:new(player, context, worldobjects, test) end)
