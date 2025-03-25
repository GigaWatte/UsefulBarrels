---@class UBBarrel
local UBBarrel = ISBaseObject:derive("UBBarrel")

function UBBarrel:hasFluidContainer()
    --return self.isoObject:hasComponent(ComponentType.FluidContainer)
    return self.fluidContainer ~= nil
end

function UBBarrel:getMoveableDisplayName()
    if not self.isoObject:getSprite() then return nil end
    local props = self.isoObject:getSprite():getProperties()
    if props:Is("CustomName") then
        local name = props:Val("CustomName")
        if props:Is("GroupName") then
            name = props:Val("GroupName") .. " " .. name
        end
        return Translator.getMoveableDisplayName(name)
    end
    return nil
end

---@param isoObject IsoObject
function UBBarrel:new(isoObject)
    local o = {};
    setmetatable(o, self)
    self.__index = self

    if not isoObject then return nil end

    -- Moveable is subclass of InventoryItem
    if instanceof(isoObject, "Moveable") then
        local valid_item_names = {
            Translator.getItemNameFromFullType("Base.MetalDrum"),
            Translator.getItemNameFromFullType("Base.Mov_LightGreenBarrel"),
            Translator.getItemNameFromFullType("Base.Mov_OrangeBarrel"),
            Translator.getItemNameFromFullType("Base.Mov_DarkGreenBarrel"),
        }
        for i = 1, #valid_item_names do
            if isoObject:getName() == valid_item_names[i] then 
                o.isoObject = isoObject
                o.fluidContainer = isoObject:getComponent(ComponentType.FluidContainer)
                o.square = nil
                o.objectName = nil
                return o 
            end
        end
    end
    -- IsoObject is base class for any world object
    if instanceof(isoObject, "IsoObject") then 
        local valid_barrel_moveable_names = {
            "Base.MetalDrum",
            "Base.Mov_LightGreenBarrel",
            "Base.Mov_OrangeBarrel",
            "Base.Mov_DarkGreenBarrel",
        }
        if not isoObject:getSquare() then return end
        if not isoObject:getSprite() then return end
        local props = isoObject:getSprite():getProperties()
        if props and not props:Val("CustomItem") then return end

        for i = 1, #valid_barrel_moveable_names do
            -- CustomItem is Moveable item
            if props:Val("CustomItem") == valid_barrel_moveable_names[i] then 
                o.isoObject = isoObject
                o.fluidContainer = isoObject:getComponent(ComponentType.FluidContainer)
                o.square = isoObject:getSquare()
                o.objectName = props:Val("CustomName")
                return o 
            end
        end
    end

end