require "ISBaseObject"

-- object TTL is current context menu lifetime and recreates every time
local UBBarrel = ISBaseObject:derive("UBBarrel")

function UBBarrel:AddFluidContainerToBarrel()
    if self.isoObject:hasComponent(ComponentType.FluidContainer) then
        return true
    end

    local function getInitialFluid()
        local fluidTable = {}
        local fluids = luautils.split(SandboxVars.UsefulBarrels.InitialFluidPool)
        for _,fluidStr in ipairs(fluids, " ") do
            if Fluid.Get(fluidStr) then table.insert(fluidTable, Fluid.Get(fluidStr)) end
        end
    
        if #fluidTable == 1 then return nil end
        local index = ZombRand(#fluidTable) + 1
    
        return fluidTable[index]
    end
    
    local function getInitialFluidAmount()
        if SandboxVars.UsefulBarrels.InitialFluidMaxAmount > 0 then
            return PZMath.clamp(ZombRand(SandboxVars.UsefulBarrels.InitialFluidMaxAmount), 0, SandboxVars.UsefulBarrels.BarrelCapacity)
        end
        return 0
    end
    
    local function shouldSpawn()
        if SandboxVars.UsefulBarrels.InitialFluidSpawnChance == 100 then return true end
        if SandboxVars.UsefulBarrels.InitialFluidSpawnChance > 0 then
            return ZombRand(0,100) <= SandboxVars.UsefulBarrels.InitialFluidSpawnChance
        end
        return false
    end

    local component = ComponentType.FluidContainer:CreateComponent()
    local barrelCapacity = SandboxVars.UsefulBarrels.BarrelCapacity
    component:setCapacity(barrelCapacity)
    component:setContainerName("UB_Barrel")
    
    local shouldSpawn = shouldSpawn()
    if SandboxVars.UsefulBarrels.InitialFluid and shouldSpawn then
        local fluid = getInitialFluid()
        if fluid then
            local amount = getInitialFluidAmount()
            component:addFluid(fluid, amount)
            self:SetModData("UB_Initial_fluid", tostring(fluid))
            self:SetModData("UB_Initial_amount", tostring(amount))
        end
    end

    GameEntityFactory.AddComponent(self.isoObject, true, component)

    self:SetModData("UB_Uncapped", true)

    buildUtil.setHaveConstruction(self.square, true)

    return true
end

function UBBarrel:EnableRainFactor()
    if self.isoObject:hasComponent(ComponentType.FluidContainer) then
        local component = self.isoObject:getComponent(ComponentType.FluidContainer)
        component:setRainCatcher(0.4)
    end
end

function UBBarrel:CutLid()
    local addFluidContainerSuccess = self:AddFluidContainerToBarrel()
    if not addFluidContainerSuccess then return false end

    local newSprite = self:getSprite(UBBarrel.LIDLESS)

    if newSprite then
        self:SetModData("UB_OriginalSprite", self.isoObject:getSprite():getName())
        self:SetModData("UB_CurrentSprite", newSprite)
        self:setSprite(newSprite)

        self:EnableRainFactor()
    else
        print(string.format("Missing sprite %s for %s", UBBarrel.LIDLESS), self.isoObject:getSprite():getName())
        return false
    end

    self:SetModData("UB_CutLid", true)
    
    buildUtil.setHaveConstruction(self.square, true)

    return true
end

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

-- sprite facing
UBBarrel.N = "N"
UBBarrel.S = "S"
-- sprite type
UBBarrel.DEFAULT = "default"
UBBarrel.LIDLESS = "lidless"
UBBarrel.LIDLESS_WATER = "lidless_water"
UBBarrel.LIDLESS_RUSTY = "lidless_rusty"

local SPRITE_MAP = {}
SPRITE_MAP["Base.MetalDrum"] = {}
SPRITE_MAP["Base.MetalDrum"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "crafted_01_32",
    [UBBarrel.LIDLESS] = "crafted_01_24",
    [UBBarrel.LIDLESS_WATER] = "crafted_01_25",
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_56"
}
SPRITE_MAP["Base.MetalDrum"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "crafted_01_32"
}

SPRITE_MAP["Base.Mov_LightGreenBarrel"] = {}
SPRITE_MAP["Base.Mov_LightGreenBarrel"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_6",
    [UBBarrel.LIDLESS] = nil,
    [UBBarrel.LIDLESS_WATER] = nil,
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_28"
}
SPRITE_MAP["Base.Mov_LightGreenBarrel"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_7"
}

SPRITE_MAP["Base.Mov_OrangeBarrel"] = {}
SPRITE_MAP["Base.Mov_OrangeBarrel"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "industry_01_22",
    [UBBarrel.LIDLESS] = "crafted_01_28",
    [UBBarrel.LIDLESS_WATER] = "crafted_01_29",
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_60"
}
SPRITE_MAP["Base.Mov_OrangeBarrel"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "industry_01_23"
}

SPRITE_MAP["Base.Mov_DarkGreenBarrel"] = {}
SPRITE_MAP["Base.Mov_DarkGreenBarrel"][UBBarrel.N] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_14",
    [UBBarrel.LIDLESS] = nil,
    [UBBarrel.LIDLESS_WATER] = nil,
    [UBBarrel.LIDLESS_RUSTY] = "crafted_05_65"
}
SPRITE_MAP["Base.Mov_DarkGreenBarrel"][UBBarrel.S] = {
    [UBBarrel.DEFAULT] = "location_military_generic_01_15"
}

function UBBarrel:getSprite(type)
    if not SPRITE_MAP[self.baseName] then return end
    if not SPRITE_MAP[self.baseName][self.facing] then return nil end
    if not SPRITE_MAP[self.baseName][self.facing][type] then return nil end
    return SPRITE_MAP[self.baseName][self.facing][type]
end

function UBBarrel:setSprite(sprite)
    self.isoObject:setSprite(sprite)
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
    if not baseName then return false end
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
    -- IsoObject is base class for any world object
    elseif instanceof(object, "IsoObject") then 
        if not object:getSquare() then return end
        if not object:getSprite() then return end
        if not object:getSprite():getProperties() then return end
        local props = object:getSprite():getProperties()
        if not props:Val("CustomItem") then return end

        -- CustomItem is Moveable item name
        return props:Val("CustomItem")
    else
        return nil
    end
end

function UBBarrel.validate(object)
    if not object then return false end
    return isBarrel(getObjectBaseName(object))
end

function UBBarrel:init()
    self.baseName = getObjectBaseName(self.isoObject)

    -- Moveable is subclass of InventoryItem
    if instanceof(self.isoObject, "Moveable") then
        --local scriptItem = getScriptManager():FindItem(isoObject.customItem)

        --object:getDisplayName()
        self.square = nil
        self.altLabel = nil
        self.objectLabel = self.isoObject:getName()
        self.icon = self.isoObject:getIcon()
        self.facing = nil
    end
    -- IsoObject is base class for any world object
    if instanceof(self.isoObject, "IsoObject") then 
        local props = self.isoObject:getSprite():getProperties()
        local scriptItem = getScriptManager():FindItem(props:Val("CustomItem"))
        -- CustomItem is fullname Moveable item

        self.square = self.isoObject:getSquare()

        local name
        if props:Is("CustomName") then
            name = props:Val("CustomName")
            if props:Is("GroupName") then
                name = props:Val("GroupName") .. " " .. name
            end
        end

        self.altLabel = Translator.getMoveableDisplayName(name)
        self.objectLabel = scriptItem:getDisplayName()
        
        local icon = scriptItem:getIcon()
        if scriptItem:getIconsForTexture() and not scriptItem:getIconsForTexture():isEmpty() then
            icon = scriptItem:getIconsForTexture():get(0)
        end
        if icon then
            local texture = tryGetTexture("Item_" .. icon)
            if texture then
                self.icon = texture
            end
        end

        self.facing = props:Val("Facing")
    end
end

function UBBarrel:new(isoObject)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    if not isoObject then return nil end
    if not UBBarrel.validate(isoObject) then return nil end

    o.isoObject = isoObject
    o:init()

    return o
end

return UBBarrel