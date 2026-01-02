local UB_Barrel = require "UB_Barrel"
local UB_Const  = require "UB_Const"

local UB_FluidBarrel = UB_Barrel:derive("UB_FluidBarrel")

function UB_FluidBarrel.ValidateFluidCategoty(fluidContainer)
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

function UB_FluidBarrel:OnPickup()
    self.fluidContainer:setInputLocked(true)
    self.fluidContainer:setCanPlayerEmpty(false)
    if false then--instanceof(self.isoObject, "IsoThumpable") then
        if self:GetModData("UB_MaxHealth") then
            self:SetModData("UB_MaxHealth", self.isoObject:getMaxHealth())
        end
        if self:GetModData("UB_Health") then
            self:SetModData("UB_Health", self.isoObject:getHealth())
        end
    end
end

function UB_FluidBarrel:OnPlace()
    self.fluidContainer:setInputLocked(false)
    self.fluidContainer:setCanPlayerEmpty(true)
    if false then--instanceof(self.isoObject, "IsoThumpable") then
        self.isoObject:setThumpDmg(2) --zeds needed to hurt obj

        if self:GetModData("UB_MaxHealth") then
            self.isoObject:setMaxHealth(tonumber(self:GetModData("UB_MaxHealth")))
        else
            self.isoObject:setMaxHealth(50)
            self:SetModData("UB_MaxHealth", 50)
        end

        if self:GetModData("UB_Health") then
            self.isoObject:setHealth(tonumber(self:GetModData("UB_Health")))
        else
            self.isoObject:setHealth(50)
            self:SetModData("UB_Health", 50)
        end
    end
end

function UB_FluidBarrel:GetTooltipText(font_size)
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

function UB_FluidBarrel:CanTransferFluid(fluidContainers, transferToContainers)
    local toContainers = false
    if transferToContainers ~= nil then
        toContainers = transferToContainers
    end

    local allContainers = {}
    for _,container in pairs(fluidContainers) do
        local fluidContainer = container:getComponent(ComponentType.FluidContainer)
        if not toContainers and FluidContainer.CanTransfer(fluidContainer, self.fluidContainer) then
            if UB_FluidBarrel.ValidateFluidCategoty(fluidContainer) then
                table.insert(allContainers, container)
            end
        elseif toContainers and FluidContainer.CanTransfer(self.fluidContainer, fluidContainer) then
            table.insert(allContainers, container)
        end
    end
    return allContainers
end

function UB_FluidBarrel:canAddFluid(fluid)
    return self.fluidContainer:canAddFluid(fluid)
end

function UB_FluidBarrel:addFluid(fluid, amount)
    local result = self.fluidContainer:addFluid(fluid, amount)
    self:UpdateWaterLevel()
    return result
end

function UB_FluidBarrel:adjustSpecificFluidAmount(fluid, amount)
    local result = self.fluidContainer:adjustSpecificFluidAmount(fluid, amount)
    self:UpdateWaterLevel()
    return result
end

function UB_FluidBarrel:ContainsFluid(fluid)
    return self.fluidContainer:contains(fluid)
end


function UB_FluidBarrel:hasFluidContainer()
    --return self.isoObject:hasComponent(ComponentType.FluidContainer)
    return self.fluidContainer ~= nil
end

function UB_FluidBarrel:getAmount()
    return self.fluidContainer:getAmount()
end

function UB_FluidBarrel:getCapacity()
    return self.fluidContainer:getCapacity()
end

function UB_FluidBarrel:getFreeCapacity()
    return self.fluidContainer:getFreeCapacity()
end

function UB_FluidBarrel:adjustAmount(amount)
    local result = self.fluidContainer:adjustAmount(amount)
    self:UpdateWaterLevel()
    return result
end

function UB_FluidBarrel:isEmpty()
    return not self.isoObject:hasFluid()
end

function UB_FluidBarrel:hasFluid()
    return self.isoObject:hasFluid()
end

function UB_FluidBarrel:getPrimaryFluid()
    if self:getAmount() > 0 then
        return self.fluidContainer:getPrimaryFluid()
    else
        return nil
    end
end

function UB_FluidBarrel:GetTranslatedFluidNameOrEmpty()
    local fluidObject = self:getPrimaryFluid()

    if fluidObject then
        return fluidObject:getTranslatedName()
    else
        return getText("ContextMenu_Empty")
    end
end

function UB_FluidBarrel:setWaterType(type)
    local sprite = self:getWaterType(type)
    --print("setting type: ", type)
    --print("overlay sprite: ", tostring(sprite))
    if not sprite then return end
    self.isoObject:setOverlaySprite(sprite)
    
    local color = self.fluidContainer:getColor()

    self.isoObject:setOverlaySpriteColor(
        color:getRedFloat(),
        color:getGreenFloat(),
        color:getBlueFloat(),
        0.9
    )
end

function UB_FluidBarrel:removeWaterType()
    self.isoObject:setOverlaySprite("")
end

function UB_FluidBarrel:UpdateWaterLevel()
    if self:getSprite() ~= self:getSpriteType(UB_Const.LIDLESS) then return end

    local current_level = (self:getAmount() / self:getCapacity())
    --print("current fill level ", current_level)
    if current_level >= (UB_Const.WATER_FULL_LEVEL) then
        self:setWaterType(UB_Const.WATER_FULL)
        --print("apply full level sprite: ", UBBarrel.WATER_FULL_LEVEL)
    elseif current_level >= (UB_Const.WATER_HALF_LEVEL) then
        self:setWaterType(UB_Const.WATER_HALF)
        --print("apply half level sprite: ", UBBarrel.WATER_HALF_LEVEL)
    elseif current_level >= (UB_Const.WATER_LOW_LEVEL) then
        self:setWaterType(UB_Const.WATER_LOW)
        --print("apply low level sprite: ", UBBarrel.WATER_LOW_LEVEL)
    else
        self:removeWaterType()
        --print("remove all levels")
    end
end

function UB_FluidBarrel:GetWeight()
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

function UB_FluidBarrel:new(isoObject)
    local o = UB_Barrel.new(self, isoObject)
    if not o then return nil end
    if not isoObject:hasComponent(ComponentType.FluidContainer) then return nil end

    o.fluidContainer = isoObject:getComponent(ComponentType.FluidContainer)

    return o
end

return UB_FluidBarrel