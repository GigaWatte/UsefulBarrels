
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UB_GeneratorContextMenu = {}


function UB_GeneratorContextMenu.doAddFuelGenerator(generator, barrel, playerObj)
    if luautils.walkAdj(playerObj, generator:getSquare()) then
        if generator:getFuel() < 100 then
            ISTimedActionQueue.add(UB_RefuelGeneratorAction:new(playerObj, generator, barrel));
        end
    end
end

function UB_GeneratorContextMenu.doBindGenerator(generator, barrel, playerObj, hose)
    if luautils.walkAdj(playerObj, generator:getSquare()) then
        SRefuelSystem.bindGeneratorToBarrel(generator, barrel, playerObj, hose)
    end
end

function UB_GeneratorContextMenu.doUnbindGenerator(generator, playerObj)
    if luautils.walkAdj(playerObj, generator:getSquare()) then
        SRefuelSystem.unbindGeneratorFromBarrel(generator, playerObj)
    end
end

function UB_GeneratorContextMenu:CreateBarrelOption(containerMenu, barrel, hasHoseNearby, player)
    local containerOption = containerMenu:addGetUpOption(
        barrel.objectLabel, 
        self.generator, 
        UB_GeneratorContextMenu.doAddFuelGenerator, barrel, self.playerObj
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

function UB_GeneratorContextMenu:CreateBindOption(bindMenu, barrel, hose, player)
    local bindOption = bindMenu:addGetUpOption(
        barrel.objectLabel, 
        self.generator, 
        UB_GeneratorContextMenu.doBindGenerator, barrel, self.playerObj, hose
    )
    if bindOption and barrel.icon then
        bindOption.iconTexture = barrel.icon
    end
    if hose == nil then 
        UBUtils.DisableOptionAddTooltip(bindOption, getText("Tooltip_UB_HoseMissing", getItemName("Base.RubberHose")))
        return       
    end

    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip.maxLineWidth = 512
    tooltip.description = barrel:GetTooltipText(tooltip.font)
    tooltip.object = barrel.isoObject
    bindOption.toolTip = tooltip
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
        local hose = UBUtils.getItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
        local hasHoseNearby = hose ~= nil
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

function UB_GeneratorContextMenu:DoBindMenu(player, context)
    local bindOption

    if context:getOptionFromName(getText("ContextMenu_GeneratorAddFuel")) then
        bindOption = context:insertOptionAfter(getText("ContextMenu_GeneratorAddFuel"), getText("ContextMenu_UB_BindBarrel"))
    elseif context:getOptionFromName(getText("ContextMenu_GeneratorInfo")) then
        bindOption = context:insertOptionAfter(getText("ContextMenu_GeneratorInfo"), getText("ContextMenu_UB_BindBarrel"))
    end

    if not bindOption then return end

    local bindMenu = ISContextMenu:getNew(context)
    context:addSubMenu(bindOption, bindMenu)
    
    for _,barrel in ipairs(self.barrels) do
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
        local hose = UBUtils.getItemNearbyOrInInv(worldObjects, self.playerInv, "Base.RubberHose")
        local hasHoseNearby = hose ~= nil
        self:CreateBindOption(bindMenu, barrel, hose, player)
    end

    local hc = getCore():getObjectHighlitedColor()
    --highlight the object on tile while the tooltip is showing
    bindMenu.showTooltip = function(_subMenu, _option)
        ISContextMenu.showTooltip(_subMenu, _option)
        if _subMenu.toolTip.object ~= nil then
            _option.toolTip:setVisible(false)
            _option.toolTip.object:setHighlightColor(hc)
            _option.toolTip.object:setHighlighted(true, false)
        end
    end

    --stop highlighting the object when the tooltip is not showing
    bindMenu.hideToolTip = function(_subMenu)
        if _subMenu.toolTip and _subMenu.toolTip.object then
            _subMenu.toolTip.object:setHighlighted(false)
        end
        ISContextMenu.hideToolTip(_subMenu)
    end
end

function UB_GeneratorContextMenu:DoUnbindMenu(player, context)
    local bindOption

    if context:getOptionFromName(getText("ContextMenu_GeneratorAddFuel")) then
        bindOption = context:insertOptionAfter(
            getText("ContextMenu_GeneratorAddFuel"), getText("ContextMenu_UB_UnbindBarrel"),
            self.generator, 
            UB_GeneratorContextMenu.doUnbindGenerator, self.playerObj
        )
    elseif context:getOptionFromName(getText("ContextMenu_GeneratorInfo")) then
        bindOption = context:insertOptionAfter(
            getText("ContextMenu_GeneratorInfo"), getText("ContextMenu_UB_UnbindBarrel"),
            self.generator, 
            UB_GeneratorContextMenu.doUnbindGenerator, self.playerObj
        )
    end
end

function UB_GeneratorContextMenu:new(player, context, worldobjects, test)
    local o = self
    o.player = player
    o.playerObj = getSpecificPlayer(player)
    o.playerInv = o.playerObj:getInventory()
    o.generator = ISWorldObjectContextMenu.fetchVars.generator

    if not o.generator or o.playerObj:getVehicle() then return end
    if o.generator:isActivated() or o.generator:getFuel() >= 100 then return end

    o.barrels = UBUtils.GetBarrelsNearby(o.generator:getSquare(), UBConst.GENERATOR_SCAN_DISTANCE, Fluid.Petrol)

    if not SandboxVars.UsefulBarrels.EnableGeneratorRefuel then return end

    if #o.barrels == 0 then return end
    if not UBUtils.CanCreateGeneratorMenu(o.generator:getSquare(), o.playerObj) then return end
    
    if SRefuelSystem.instance:getLuaObjectOnSquare(self.generator:getSquare()) then
        local generatorAddFuelOption = context:getOptionFromName(getText("ContextMenu_GeneratorAddFuel"))
        print(tostring(generatorAddFuelOption))
        if generatorAddFuelOption then
            UBUtils.DisableOptionAddTooltip(generatorAddFuelOption, getText("Tooltip_UB_HatchBlocked"))
            generatorAddFuelOption.subOption = nil
        end
        self:DoUnbindMenu(player, context)
    else
        self:DoRefuelMenu(player, context)
        self:DoBindMenu(player, context)
    end
end

Events.OnFillWorldObjectContextMenu.Add(function (player, context, worldobjects, test) return UB_GeneratorContextMenu:new(player, context, worldobjects, test) end)
