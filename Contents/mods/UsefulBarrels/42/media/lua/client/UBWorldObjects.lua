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
    local option = context:getOptionFromName(getText("ContextMenu_TakeGasFromPump"))
    
    if option then
        local subMenu = context:getSubMenu(option.subOption)
        if subMenu then
            local namesToSearch = {
                Translator.getItemNameFromFullType("Base.MetalDrum"),
                Translator.getItemNameFromFullType("Base.Mov_LightGreenBarrel"),
                Translator.getItemNameFromFullType("Base.Mov_OrangeBarrel"),
                Translator.getItemNameFromFullType("Base.Mov_DarkGreenBarrel"),
            }
            -- remove barrel options from sub menu
            for i = 1, #namesToSearch do
                if subMenu:getOptionFromName(namesToSearch[i]) then subMenu:removeOptionByName(namesToSearch[i]) end
            end
            -- remove fill all button if there is only one container left
            if subMenu.numOptions <= 3 and subMenu:getOptionFromName(getText("ContextMenu_FillAll")) then 
                subMenu:removeOptionByName(getText("ContextMenu_FillAll")) 
            end
            -- remove entire option if there is no options at all
            if subMenu.numOptions == 1 then
                context:removeOptionByName(getText("ContextMenu_TakeGasFromPump"))
            end 
        end
    end
end
-- also need to remove my barrels from Fill All container list
local ISWorldObjectContextMenu_onTakeFuelNew = ISWorldObjectContextMenu.onTakeFuelNew
ISWorldObjectContextMenu.onTakeFuelNew = function(worldobjects, fuelObject, fuelContainerList, fuelContainer, player)
    local filteredFuelContainerList = {}
    for _,container in pairs(fuelContainerList) do
        if container:hasModData() then
            local modData = container:getModData()
            if modData["modData"] ~= nil and modData["modData"]["UB_Uncapped"] ~= nil then
                -- skip my barrels
            else
                table.insert(filteredFuelContainerList, container)
            end
        end
    end
    return ISWorldObjectContextMenu_onTakeFuelNew(worldobjects, fuelObject, filteredFuelContainerList, fuelContainer, player)
end
-- patch disassemble to prevent it if barrel not empty
local ISMoveableSpriteProps_canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal
local InfoPanelFlags_hasWater = InfoPanelFlags.hasWater
function ISMoveableSpriteProps:canScrapObjectInternal(_result, _object)
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