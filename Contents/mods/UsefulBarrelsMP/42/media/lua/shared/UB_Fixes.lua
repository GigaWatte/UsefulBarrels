local UB_Barrel = require "UB_Barrel"
local UB_Utils = require "UB_Utils"

local ISMoveableSpriteProps_canPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal
function ISMoveableSpriteProps:canPickUpMoveableInternal( _character, _square, _object, _isMulti)
    local canPickUp = ISMoveableSpriteProps_canPickUpMoveableInternal(self, _character, _square, _object, _isMulti)
    if _object then
        if UB_Barrel.validate(_object) and _object:hasComponent(ComponentType.FluidContainer) then
            local barrel = UB_Utils.GetValidBarrelFromWorldObjects({_object})
            canPickUp = _character:getInventory():hasRoomFor(_character, barrel:GetWeight())
        end
    end
    return canPickUp
end
local ISMoveableSpriteProps_getInfoPanelFlagsGeneral = ISMoveableSpriteProps.getInfoPanelFlagsGeneral
function ISMoveableSpriteProps:getInfoPanelFlagsGeneral( _square, _object, _player, _mode )
    ISMoveableSpriteProps_getInfoPanelFlagsGeneral(self, _square, _object, _player, _mode )
    if _object then
        if UB_Barrel.validate(_object) and _object:hasComponent(ComponentType.FluidContainer) then
            local barrel = UB_Utils.GetValidBarrelFromWorldObjects({_object})
            local barrel_weight = barrel:GetWeight()
            InfoPanelFlags.weight = tostring(round(barrel_weight, 2))
            if _mode == "pickup" then
                InfoPanelFlags.tooHeavy = not _player:getInventory():hasRoomFor(_player, barrel_weight)
            end
        end
    end
end
local ISMoveableSpriteProps_canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal
function ISMoveableSpriteProps:canScrapObjectInternal(_result, _object)
    -- cache flag value before changes
    local InfoPanelFlags_hasWater = InfoPanelFlags.hasWater
    if _object then
        if UB_Barrel.validate(_object) and _object:hasComponent(ComponentType.FluidContainer) and not _object:getComponent(ComponentType.FluidContainer):isEmpty() then
            InfoPanelFlags.hasWater = true
            return false
        end
    end

    InfoPanelFlags.hasWater = InfoPanelFlags_hasWater
    return ISMoveableSpriteProps_canScrapObjectInternal(self, _result, _object)
end
local ISMoveableSpriteProps_pickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
function ISMoveableSpriteProps:pickUpMoveableInternal( _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating )
    if _object then
        if UB_Barrel.validate(_object) and _object:hasComponent(ComponentType.FluidContainer) then
            local barrel = UB_Utils.GetValidBarrelFromWorldObjects({_object})
            barrel:OnPickup()
        end
    end
    return ISMoveableSpriteProps_pickUpMoveableInternal(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
end

--local ISMoveableSpriteProps_placeMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
--function ISMoveableSpriteProps:placeMoveableInternal( _square, _item, _spriteName )
--    local _object = ISMoveableSpriteProps_placeMoveableInternal(self, _square, _item, _spriteName)
--    if _object then
--        if UB_Barrel.validate(_object) and _object:hasComponent(ComponentType.FluidContainer) then
--            local barrel = UB_Utils.GetValidBarrelFromWorldObjects({_object})
--            barrel:OnPlace()
--        end
--    end
--    return _object
--end
local function OnObjectPlaced(_object)
    if _object then
        if UB_Barrel.validate(_object) and _object:hasComponent(ComponentType.FluidContainer) then
            local barrel = UB_Utils.GetValidBarrelFromWorldObjects({_object})
            barrel:OnPlace()
        end
    end
end
Events.OnObjectAdded.Add(OnObjectPlaced)

local function UB_OnGameBoot()
    local instance = ScriptManager.instance
    instance:getItem("Base.Funnel"):DoParam("Tags", "UB_Barrels:FUNNEL")
    instance:getItem("Base.RubberHose"):DoParam("Tags", "UB_Barrels:RUBBER_HOSE")
    --instance:getItem("Base.BlowTorch"):DoParam("Tags", "UB_Barrels:BLOW_TORCH")
    --instance:getItem("Base.Funnel"):DoParam("Tags", string(ItemTag.get(ResourceLocation.of("UB_Barrels:FUNNEL"))))
    --instance:getItem("Base.RubberHose"):DoParam("Tags", string(ItemTag.get(ResourceLocation.of("UB_Barrels:RUBBER_HOSE"))))

    instance:getItem("Base.MetalDrum"):DoParam("Weight", "10")
    instance:getItem("Base.Mov_LightGreenBarrel"):DoParam("Weight", "10")
    instance:getItem("Base.Mov_OrangeBarrel"):DoParam("Weight", "10")
    instance:getItem("Base.Mov_DarkGreenBarrel"):DoParam("Weight", "10")
end

Events.OnGameBoot.Add(UB_OnGameBoot)