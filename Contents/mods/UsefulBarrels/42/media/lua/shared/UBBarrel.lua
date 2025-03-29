-- object TTL is current context menu lifetime and recreates every time
---@class UBBarrel
local UBBarrel = ISBaseObject:derive("UBBarrel")

function UBBarrel.ValidateFluidCategoty(fluidContainer)
    local allowList = {
        [FluidCategory.Industrial] = SandboxVars.UsefulBarrels.AllowIndustrial,
        [FluidCategory.Fuel]       = SandboxVars.UsefulBarrels.AllowFuel,
        [FluidCategory.Hazardous]  = SandboxVars.UsefulBarrels.AllowHazardous,
        [FluidCategory.Alcoholic]  = SandboxVars.UsefulBarrels.AllowAlcoholic,
        [FluidCategory.Beverage]   = SandboxVars.UsefulBarrels.AllowBeverage,
        [FluidCategory.Medical]    = SandboxVars.UsefulBarrels.AllowMedical,
        [FluidCategory.Colors]     = SandboxVars.UsefulBarrels.AllowColors,
        [FluidCategory.Dyes]       = SandboxVars.UsefulBarrels.AllowDyes,
        [FluidCategory.HairDyes]   = SandboxVars.UsefulBarrels.AllowHairDyes,
        [FluidCategory.Poisons]    = SandboxVars.UsefulBarrels.AllowPoisons,
        [FluidCategory.Water]      = SandboxVars.UsefulBarrels.AllowWater,
    }
    local fluid = fluidContainer:getPrimaryFluid()
    if not fluid then return true end
    for category, allowed in pairs(allowList) do
        if fluid:isCategory(category) and allowed then return true end
    end
    return false
end

function UBBarrel:OnPickup()
    self.fluidContainer:setInputLocked(true)
    self.fluidContainer:setCanPlayerEmpty(false)
end

function UBBarrel:OnPlace()
    self.fluidContainer:setInputLocked(false)
    self.fluidContainer:setCanPlayerEmpty(true)
    if instanceof(self.isoObject, "IsoThumpable") then
        --TODO restore it from modData

        --obj:setMaxHealth(self:getObjectHealth());
        --obj:setHealth(obj:getMaxHealth());
        self.isoObject:setThumpDmg(8); --zeds needed to hurt obj
        --obj:setIsThumpable(true);
        --obj:setBlockAllTheSquare(true);
        --obj:setCanPassThrough(false);
        --obj:setHoppable(false);
        --obj:setBreakSound(IsoThumpable.GetBreakFurnitureSound(itemSprite));
    end
end

function UBBarrel:GetTooltipText(font_size)
    function FormatFluidAmount(setX, amount, max, fluidName)
        if max >= 9999 then
            return string.format("%s: <SETX:%d> %s", getText(fluidName), setX, getText("Tooltip_WaterUnlimited"))
        end
        return string.format("%s: <SETX:%d> %s / %s", getText(fluidName), setX, luautils.round(amount, 2) .. "L", max .. "L")
    end

    local fluidAmount = self:getAmount()
    local fluidMax = self:getCapacity()
    local fluidName = self:GetTranslatedFluidNameOrEmpty()

    local tx = getTextManager():MeasureStringX(font_size, fluidName .. ":") + 20
    return FormatFluidAmount(tx, fluidAmount, fluidMax, fluidName)
end

function UBBarrel:GetBarrelInfo()
    local output = string.format("Barrel object: %s\n", tostring(self.isoObject))
    output = output .. string.format("hasFluidContainer: %s\n", tostring(self:hasFluidContainer()))

    if self.fluidContainer~=nil then
        local fluidAmount = self:getAmount()
        local fluidMax = self:getCapacity()
        local barrelFluid = self:getPrimaryFluid()


        output = output .. string.format(
            [[
            Fluid: %s
            Fluid amount: %s
            Fluid capacity: %s
            isInputLocked: %s
            canPlayerEmpty: %s
            ]],
            tostring(barrelFluid),
            tostring(fluidAmount),
            tostring(fluidMax),
            tostring(self.fluidContainer:isInputLocked()),
            tostring(self.fluidContainer:canPlayerEmpty())
        )
    end

    if self.isoObject:hasModData() then
        local modData = self.isoObject:getModData()

        output = output .. string.format(
            [[
            UB_Uncapped: %s
            UB_Initial_fluid: %s
            UB_Initial_amount: %s
            ]],
            tostring(modData["UB_Uncapped"]),
            tostring(modData["UB_Initial_amount"]),
            tostring(modData["UB_Initial_amount"])

        )

        if modData["modData"] then
            output = output .. string.format(
            [[
            Nested modData options
            UB_Uncapped: %s
            UB_Initial_fluid: %s
            UB_Initial_amount: %s
            ]],
            tostring(modData["modData"]["UB_Uncapped"]),
            tostring(modData["modData"]["UB_Initial_amount"]),
            tostring(modData["modData"]["UB_Initial_amount"])
            )
        end
    end
    return output
end

function UBBarrel:CanTransferFluid(fluidContainers, transferToContainers)
    local toContainers = transferToContainers ~= nil
    local allContainers = {}
    for _,container in pairs(fluidContainers) do
        local fluidContainer = container:getComponent(ComponentType.FluidContainer)
        if not toContainers and FluidContainer.CanTransfer(fluidContainer, self.fluidContainer) then
            if UBBarrel.ValidateFluidCategoty(fluidContainer) then
                table.insert(allContainers, container)
            end
        elseif toContainers and FluidContainer.CanTransfer(self.fluidContainer, fluidContainer) then
            table.insert(allContainers, container)
        end
    end
    return allContainers
end

function UBBarrel:ContainsFluid(fluid)
    return self.fluidContainer~=nil and self.fluidContainer:contains(fluid)
end

function UBBarrel:hasFluidContainer()
    --return self.isoObject:hasComponent(ComponentType.FluidContainer)
    return self.fluidContainer ~= nil
end

function UBBarrel:getAmount()
    if self.fluidContainer~=nil then return self.fluidContainer:getAmount() else return 0 end  
end

function UBBarrel:getCapacity()
    if self.fluidContainer~=nil then return self.fluidContainer:getCapacity() else return 0 end
end

function UBBarrel:getPrimaryFluid()
    if self.fluidContainer~=nil and self:getAmount() > 0 then 
        return self.fluidContainer:getPrimaryFluid() 
    else 
        return nil 
    end
end

function UBBarrel:GetTranslatedFluidNameOrEmpty()
    local fluidObject = self:getPrimaryFluid()

    if fluidObject then
        return fluidObject:getTranslatedName()
    else
        return getText("ContextMenu_Empty")
    end
end

function UBBarrel:GetWeight()
    local weight = 0

    if self.fluidContainer~=nil then
        weight = weight + self:getAmount()
    end
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

function UBBarrel.validate(object)
    if not object then return false end
        -- Moveable is subclass of InventoryItem
    if instanceof(object, "Moveable") then
        local valid_item_names = {
            Translator.getItemNameFromFullType("Base.MetalDrum"),
            Translator.getItemNameFromFullType("Base.Mov_LightGreenBarrel"),
            Translator.getItemNameFromFullType("Base.Mov_OrangeBarrel"),
            Translator.getItemNameFromFullType("Base.Mov_DarkGreenBarrel"),
        }
        for i = 1, #valid_item_names do
            if object:getName() == valid_item_names[i] then return true end
        end
    end
    -- IsoObject is base class for any world object
    if instanceof(object, "IsoObject") then 
        local valid_barrel_moveable_names = {
            "Base.MetalDrum",
            "Base.Mov_LightGreenBarrel",
            "Base.Mov_OrangeBarrel",
            "Base.Mov_DarkGreenBarrel",
        }
        if not object:getSquare() then return end
        if not object:getSprite() then return end
        local props = object:getSprite():getProperties()
        if props and not props:Val("CustomItem") then return end

        for i = 1, #valid_barrel_moveable_names do
            -- CustomItem is Moveable item
            if props:Val("CustomItem") == valid_barrel_moveable_names[i] then 
                return true
            end
        end
    end
end

-- ScriptManager.instance.FindItem(customItem) <---
-- 	
--  local scriptItem = ScriptManager.instance:getItem(seedName)
--  option.iconTexture = getTexture("media/textures/Item_" .. scriptItem:getIcon())
--  local icon = item.item:getIcon()
--  if item.item:getIconsForTexture() and not item.item:getIconsForTexture():isEmpty() then
--      icon = item.item:getIconsForTexture():get(0)
--  end
--  if icon then
--      local texture = tryGetTexture("Item_" .. icon)
--      if texture then
--          self:drawTextureScaledAspect2(texture, self.columns[2].size + iconX, y + (self.itemheight - iconSize) / 2, iconSize, iconSize,  1, 1, 1, 1);
--      end
--  end

function UBBarrel:new(isoObject)
    local o = {};
    setmetatable(o, self)
    self.__index = self

    if not isoObject then return nil end
    if not UBBarrel.validate(isoObject) then return nil end

    

    -- Moveable is subclass of InventoryItem
    if instanceof(isoObject, "Moveable") then
        local scriptItem = getScriptManager():FindItem(isoObject:getName())

        o.isoObject = isoObject
        o.fluidContainer = isoObject:getComponent(ComponentType.FluidContainer)
        o.square = nil
        o.objectName = nil
        o.objectLabel = nil
        return o
    end
    -- IsoObject is base class for any world object
    if instanceof(isoObject, "IsoObject") then 
        local props = isoObject:getSprite():getProperties()
        if props and not props:Val("CustomItem") then return end

        local scriptItem = getScriptManager():FindItem(props:Val("CustomItem"))
        -- CustomItem is Moveable item

        o.isoObject = isoObject
        o.fluidContainer = isoObject:getComponent(ComponentType.FluidContainer)
        o.square = isoObject:getSquare()
        o.objectName = props:Val("CustomName")
        o.objectLabel = UBBarrel.GetMoveableDisplayName(isoObject)
        return o
    end
end

return UBBarrel