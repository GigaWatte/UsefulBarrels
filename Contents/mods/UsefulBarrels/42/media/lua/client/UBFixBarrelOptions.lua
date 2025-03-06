
local UBUtils = require "UBUtils"
-- modify weight params to include fluid container weight also
local ISMoveableSpriteProps_canPickUpMoveable = ISMoveableSpriteProps.canPickUpMoveable
function ISMoveableSpriteProps:canPickUpMoveable( _character, _square, _object )
    if _object and _object:getFluidContainer() and not _object:getFluidContainer():isEmpty() then
        local modData = _object:getModData()
        if modData["UB_Uncapped"] ~= nil then
            local sprite = _object:getSprite()
            local props = sprite:getProperties()
            local itemWeight = _object:getFluidContainer():getAmount()
    
            if props and props:Is("CustomItem")  then
                local customItem = props:Val("CustomItem")
                local itemInstance = nil;
                if not ISMoveableSpriteProps.itemInstances[customItem] then
                    itemInstance = instanceItem(customItem);
                    if itemInstance then
                        ISMoveableSpriteProps.itemInstances[customItem] = itemInstance;
                    end
                else
                    itemInstance = ISMoveableSpriteProps.itemInstances[customItem];
                end
    
                if itemInstance then
                    itemWeight = itemWeight + itemInstance:getActualWeight()
                end
            end

            self.weight = itemWeight
            self.rawWeight = self.weight * 10
        end
    end

    return ISMoveableSpriteProps_canPickUpMoveable(self, _character, _square, _object)
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
