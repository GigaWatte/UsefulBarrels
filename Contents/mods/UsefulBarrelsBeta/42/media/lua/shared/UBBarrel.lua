-- object TTL is current context menu lifetime and recreates every time
---@class UBBarrel
local UBBarrel = ISBaseObject:derive("UBBarrel")

function UBBarrel:OnPickup()
end

function UBBarrel:OnPlace()
end

function UBBarrel:GetModData(key)
    local modData = self.isoObject:getModData()

    if modData[key] then
        return modData[key]
    end
    return nil
end

function UBBarrel:SetModData(key, value)
    local modData = self.isoObject:getModData()
    modData[key] = value
    self.isoObject:setModData(modData)
end

function UBBarrel:GetTooltipText(font_size)
    return ""
end

function UBBarrel:GetBarrelInfo()
    local output = string.format("Barrel object: %s\n", tostring(self.isoObject))
    return output
end

function UBBarrel:GetWeight()
    local weight = 0

    if instanceof(self.isoObject, "Moveable") then
        weight = weight + self.isoObject:getActualWeight()
    end
    if instanceof(self.isoObject, "IsoObject") then 
        local sprite = self.isoObject:getSprite()
        local props = sprite:getProperties()
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
                weight = weight + itemInstance:getActualWeight()
            end
        end
    end        
 
    return weight
end

function UBBarrel:getSprite(type)
    if not UBBarrel.spriteMap[self.baseName][self.facing] then return nil end
    if not UBBarrel.spriteMap[self.baseName][self.facing][type] then return nil end
    return UBBarrel.spriteMap[self.baseName][self.facing][type]
end

function UBBarrel.GetMoveableDisplayName(isoObject)
    if not isoObject then return nil end
    if not isoObject:getSprite() then return nil end
    local props = isoObject:getSprite():getProperties()
    if props and props:Is("CustomName") then
        local name = props:Val("CustomName")
        if props:Is("GroupName") then
            name = props:Val("GroupName") .. " " .. name
        end
        return Translator.getMoveableDisplayName(name)
    end
    return nil
end

UBBarrel.VALID_BARREL_NAMES = {
    "Base.MetalDrum",
    "Base.Mov_LightGreenBarrel",
    "Base.Mov_OrangeBarrel",
    "Base.Mov_DarkGreenBarrel",
}

local function isBarrel(baseName)
    for i = 1, #UBBarrel.VALID_BARREL_NAMES do
        if baseName == UBBarrel.VALID_BARREL_NAMES[i] then return true end
    end
    return false
end

local function getObjectBaseName(object)
    -- Moveable is subclass of InventoryItem
    if instanceof(object, "Moveable") then
        local scriptItem = object:getScriptItem()
        return scriptItem:getFullName()
    end
    -- IsoObject is base class for any world object
    if instanceof(object, "IsoObject") then 
        if not object:getSquare() then return end
        if not object:getSprite() then return end
        if not object:getSprite():getProperties() then return end
        local props = object:getSprite():getProperties()
        if not props:Val("CustomItem") then return end

        -- CustomItem is Moveable item name
        return props:Val("CustomItem")
    end

    error("If you read this something went wrong...")
    return object:getName()
end

function UBBarrel.validate(object)
    if not object then return false end
    return isBarrel(getObjectBaseName(object))
end

function UBBarrel.construct(isoObject)
    local o = {}

    o.isoObject = isoObject
    o.baseName = getObjectBaseName(isoObject)

    -- Moveable is subclass of InventoryItem
    if instanceof(isoObject, "Moveable") then
        --local scriptItem = getScriptManager():FindItem(isoObject.customItem)

        --object:getDisplayName()
        o.square = nil
        o.altLabel = nil
        o.objectLabel = isoObject:getName()
        o.icon = isoObject:getIcon()
        o.facing = nil
    end
    -- IsoObject is base class for any world object
    if instanceof(isoObject, "IsoObject") then 
        local props = isoObject:getSprite():getProperties()
        local scriptItem = getScriptManager():FindItem(props:Val("CustomItem"))
        -- CustomItem is fullname Moveable item

        o.square = isoObject:getSquare()

        local name
        if props:Is("CustomName") then
            name = props:Val("CustomName")
            if props:Is("GroupName") then
                name = props:Val("GroupName") .. " " .. name
            end
        end

        o.altLabel = Translator.getMoveableDisplayName(name)
        o.objectLabel = scriptItem:getDisplayName()
        
        local icon = scriptItem:getIcon()
        if scriptItem:getIconsForTexture() and not scriptItem:getIconsForTexture():isEmpty() then
            icon = scriptItem:getIconsForTexture():get(0)
        end
        if icon then
            local texture = tryGetTexture("Item_" .. icon)
            if texture then
                o.icon = texture
            end
        end

        o.facing = props:Val("Facing")
    end
    
    return o
end

function UBBarrel:new(isoObject)
    if not isoObject then return nil end
    if not UBBarrel.validate(isoObject) then return nil end

    local o = UBBarrel.construct(isoObject)
    
    setmetatable(o, self)
    self.__index = self

    return o
end

-- sprite facing
UBBarrel.N = "N"
UBBarrel.S = "S"
-- sprite type
UBBarrel.DEFAULT = "default"
UBBarrel.LIDLESS = "lidless"
UBBarrel.LIDLESS_WATER = "lidless_water"
UBBarrel.LIDLESS_RUSTY = "lidless_rusty"

local spriteMap = {}
spriteMap["Base.MetalDrum"] = {}
spriteMap["Base.MetalDrum"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "crafted_01_32",
    [UBBarrel.LIDLESS] = "crafted_01_24",
    [UBBarrel.LIDLESS_WATER] = "crafted_01_25",
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_56"
}
spriteMap["Base.MetalDrum"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "crafted_01_32"
}

spriteMap["Base.Mov_LightGreenBarrel"] = {}
spriteMap["Base.Mov_LightGreenBarrel"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_6",
    [UBBarrel.LIDLESS] = nil,
    [UBBarrel.LIDLESS_WATER] = nil,
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_28"
}
spriteMap["Base.Mov_LightGreenBarrel"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_7"
}

spriteMap["Base.Mov_OrangeBarrel"] = {}
spriteMap["Base.Mov_OrangeBarrel"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "industry_01_22",
    [UBBarrel.LIDLESS] = "crafted_01_28",
    [UBBarrel.LIDLESS_WATER] = "crafted_01_29",
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_60"
}
spriteMap["Base.Mov_OrangeBarrel"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "industry_01_23"
}

spriteMap["Base.Mov_DarkGreenBarrel"] = {}
spriteMap["Base.Mov_DarkGreenBarrel"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_14",
    [UBBarrel.LIDLESS] = nil,
    [UBBarrel.LIDLESS_WATER] = nil,
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_65"
}
spriteMap["Base.Mov_DarkGreenBarrel"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_15"
}

return UBBarrel