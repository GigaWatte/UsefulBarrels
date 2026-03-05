require "ISBaseObject"

local UB_Const = require "UB_Const"

-- object TTL is current context menu lifetime and recreates every time
local UB_Barrel = ISBaseObject:derive("UB_Barrel")

function UB_Barrel.AddFluidContainer(ub_barrel)
    if ub_barrel.isoObject:hasComponent(ComponentType.FluidContainer) then
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
    component:setContainerName(string.format("UB_%s", ub_barrel.shortName))

    local shouldSpawn = shouldSpawn()
    local amount = getInitialFluidAmount()
    if SandboxVars.UsefulBarrels.InitialFluid and shouldSpawn then
        local fluid = getInitialFluid()
        if fluid then
            component:addFluid(fluid, amount)
            ub_barrel:SetModData("UB_Initial_fluid", tostring(fluid))
            ub_barrel:SetModData("UB_Initial_amount", tostring(amount))
        end
    end

    GameEntityFactory.AddComponent(ub_barrel.isoObject, true, component)

    if shouldSpawn and amount > 0 then
        LuaEventManager.triggerEvent("OnWaterAmountChange", ub_barrel.isoObject, -1)
    end

    ub_barrel:SetModData("UB_Unscrewed", true)

    buildUtil.setHaveConstruction(ub_barrel.square, true)

    return true
end

function UB_Barrel:EnableRainFactor()
    if self.isoObject:hasComponent(ComponentType.FluidContainer) then
        local component = self.isoObject:getComponent(ComponentType.FluidContainer)
        component:setRainCatcher(UB_Const.RAIN_CATCHER_FACTOR)
    end
end

function UB_Barrel:CutLid()
    local addFluidContainerSuccess = UB_Barrel.AddFluidContainer(self)
    if not addFluidContainerSuccess then return false end

    local newSprite = self:getSpriteType(UB_Const.LIDLESS)

    if newSprite then
        self:SetModData("UB_OriginalSprite", self:getSprite())
        self:SetModData("UB_CurrentSprite", newSprite)
        self:setSprite(newSprite)

        self:EnableRainFactor()
    else
        print(string.format("Missing sprite %s for %s", UB_Const.LIDLESS), self:getSprite())
        return false
    end

    self:SetModData("UB_CutLid", true)
    
    buildUtil.setHaveConstruction(self.square, true)

    return true
end

function UB_Barrel:getSpriteType(type)
    if not UB_Const.SPRITE_MAP[self.baseName] then return end
    if not UB_Const.SPRITE_MAP[self.baseName][self.facing] then return nil end
    if not UB_Const.SPRITE_MAP[self.baseName][self.facing][type] then return nil end
    return UB_Const.SPRITE_MAP[self.baseName][self.facing][type]
end

function UB_Barrel:getWaterType(type)
    if not UB_Const.SPRITE_MAP[self.baseName] then return end
    if not UB_Const.SPRITE_MAP[self.baseName][type] then return nil end
    return UB_Const.SPRITE_MAP[self.baseName][type]
end

function UB_Barrel:getSprite()
    return self.isoObject:getSpriteName()
end

function UB_Barrel:setSprite(sprite)
    self.isoObject:setSprite(sprite)
end

function UB_Barrel:OnPickup()
end

function UB_Barrel:OnPlace()
end

function UB_Barrel:GetModData(key)
    local modData = self.isoObject:getModData()

    if modData[key] then
        return modData[key]
    end
    return nil
end

function UB_Barrel:SetModData(key, value)
    local modData = self.isoObject:getModData()
    modData[key] = value
    self.isoObject:setModData(modData)
end

function UB_Barrel:GetTooltipText(font_size)
    return ""
end

function UB_Barrel:GetWeight()
    local weight = 0

    if instanceof(self.isoObject, "Moveable") then
        weight = weight + self.isoObject:getActualWeight()
    end
    if instanceof(self.isoObject, "IsoObject") then 
        local sprite = self.isoObject:getSprite()
        local props = sprite:getProperties()
        if props and props:has("CustomItem")  then
            local customItem = props:get("CustomItem")
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

local function isBarrel(baseName)
    if not baseName then return false end
    for i = 1, #UB_Const.VALID_BARREL_NAMES do
        if baseName == UB_Const.VALID_BARREL_NAMES[i] then return true end
    end
    return false
end

local function getObjectBaseName(object)
    -- Moveable is subclass of InventoryItem
    -- Check if clicked object is in inventory
    if instanceof(object, "Moveable") then
        local scriptItem = object:getScriptItem()
        return scriptItem:getFullName()
    -- IsoObject is base class for any world object
    -- Check if clicked object is in world
    elseif instanceof(object, "IsoObject") then
        if not object:getSquare() then return end
        if not object:getSprite() then return end
        if not object:getSprite():getProperties() then return end
        local props = object:getSprite():getProperties()
        if not props:has("CustomItem") then return end

        -- CustomItem is Moveable item name
        return props:get("CustomItem")
    else
        return nil
    end
end

function UB_Barrel.validate(isoObject)
    if not isoObject then return false end
    local objectBaseName = getObjectBaseName(isoObject)
    return isBarrel(objectBaseName)
end

function UB_Barrel:init()
    self.baseName = getObjectBaseName(self.isoObject)
    self.shortName = string.gsub(self.baseName, "Base.", "")

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
        local scriptItem = getScriptManager():FindItem(props:get("CustomItem"))
        -- CustomItem is fullname Moveable item

        self.square = self.isoObject:getSquare()

        local name
        if props:has("CustomName") then
            name = props:get("CustomName")
            if props:has("GroupName") then
                name = props:get("GroupName") .. " " .. name
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

        self.facing = props:get("Facing") or UB_Const.FACING_N
    end
end

function UB_Barrel:new(isoObject)
    local o = ISBaseObject:new()
    setmetatable(o, self)
    self.__index = self

    --if not isoObject then return nil end
    --if not UB_Barrel.validate(isoObject) then return nil end

    o.isoObject = isoObject
    o:init()

    return o
end


return UB_Barrel