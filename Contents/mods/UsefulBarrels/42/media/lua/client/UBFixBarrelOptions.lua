
local UBUtils = require "UBUtils"
local ISMoveableSpriteProps_canPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal
function ISMoveableSpriteProps:canPickUpMoveableInternal( _character, _square, _object, _isMulti)
    local canPickUp = ISMoveableSpriteProps_canPickUpMoveableInternal(self, _character, _square, _object, _isMulti)
    if _object then
        local modData = _object:getModData()
        if modData and modData["UB_Uncapped"] ~= nil then
            canPickUp = _character:getInventory():hasRoomFor(_character, UBUtils.CalculateTooltipWeight(_object))
        end
    end
    return canPickUp
end
local ISMoveableSpriteProps_getInfoPanelFlagsGeneral = ISMoveableSpriteProps.getInfoPanelFlagsGeneral
function ISMoveableSpriteProps:getInfoPanelFlagsGeneral( _square, _object, _player, _mode )
    ISMoveableSpriteProps_getInfoPanelFlagsGeneral(self, _square, _object, _player, _mode )
    if _object then
        local modData = _object:getModData()
        if modData and modData["UB_Uncapped"] ~= nil then
            InfoPanelFlags.weight = tostring(round(UBUtils.CalculateTooltipWeight(_object), 3))
            InfoPanelFlags.tooHeavy = not _player:getInventory():hasRoomFor(_player, UBUtils.CalculateTooltipWeight(_object))
        end
    end
end
-- patch fuel menu to remove my barrels from it
local ISWorldObjectContextMenu_doFillFuelMenu = ISWorldObjectContextMenu.doFillFuelMenu
ISWorldObjectContextMenu.doFillFuelMenu = function(source, playerNum, context)
    ISWorldObjectContextMenu_doFillFuelMenu(source, playerNum, context)
    UBUtils.CleanMenuFromBarrels(context, getText("ContextMenu_TakeGasFromPump"))
end
local ISWorldObjectContextMenu_doFillFluidMenu = ISWorldObjectContextMenu.doFillFluidMenu
ISWorldObjectContextMenu.doFillFluidMenu = function(sink, playerNum, context)
    ISWorldObjectContextMenu_doFillFluidMenu(sink, playerNum, context)
    UBUtils.CleanMenuFromBarrels(context, getText("ContextMenu_Fill"))
end
-- also need to remove my barrels from containers lists
local ISWorldObjectContextMenu_onTakeFuelNew = ISWorldObjectContextMenu.onTakeFuelNew
ISWorldObjectContextMenu.onTakeFuelNew = function(worldobjects, fuelObject, fuelContainerList, fuelContainer, player)
    local filteredContainerList = UBUtils.CleanItemContainersFromBarrels(fuelContainerList, fuelContainer)
    return ISWorldObjectContextMenu_onTakeFuelNew(worldobjects, fuelObject, filteredContainerList, nil, player)
end
local ISWorldObjectContextMenu_onTakeWater = ISWorldObjectContextMenu.onTakeWater
ISWorldObjectContextMenu.onTakeWater = function(worldobjects, waterObject, waterContainerList, waterContainer, player)
    local filteredContainerList = UBUtils.CleanItemContainersFromBarrels(waterContainerList, waterContainer)
    return ISWorldObjectContextMenu_onTakeWater(worldobjects, waterObject, filteredContainerList, nil, player)
end
-- patch disassemble to prevent it if barrel not empty
local ISMoveableSpriteProps_canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal
function ISMoveableSpriteProps:canScrapObjectInternal(_result, _object)
    -- cache flag value before changes
    local InfoPanelFlags_hasWater = InfoPanelFlags.hasWater
    if _object and _object:getFluidContainer() and not _object:getFluidContainer():isEmpty() then
        local modData = _object:getModData()
        if modData["UB_Uncapped"] ~= nil then
            InfoPanelFlags.hasWater = true
            return false
        end
    end

    InfoPanelFlags.hasWater = InfoPanelFlags_hasWater
    return ISMoveableSpriteProps_canScrapObjectInternal(self, _result, _object)
end
