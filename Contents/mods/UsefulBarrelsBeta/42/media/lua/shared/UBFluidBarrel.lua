require "UBBarrel"

-- object TTL is current context menu lifetime and recreates every time
---@class UBBarrel
local UBFluidBarrel = UBBarrel:derive("UBFluidBarrel")

function UBFluidBarrel.ValidateFluidCategoty(fluidContainer)
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

function UBFluidBarrel:OnPickup()
    self.fluidContainer:setInputLocked(true)
    self.fluidContainer:setCanPlayerEmpty(false)

    if instanceof(self.isoObject, "IsoThumpable") then
        if self:GetModData("UB_MaxHealth") then
            self:SetModData("UB_MaxHealth", self.isoObject:getMaxHealth())
        end
        if self:GetModData("UB_Health") then
            self:SetModData("UB_Health", self.isoObject:getHealth())
        end
    end
end

function UBFluidBarrel:OnPlace()
    self.fluidContainer:setInputLocked(false)
    self.fluidContainer:setCanPlayerEmpty(true)
    if instanceof(self.isoObject, "IsoThumpable") then
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

function UBFluidBarrel:GetTooltipText(font_size)
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

function UBFluidBarrel:GetBarrelInfo()
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
            UB_Uncapped:       %s
            UB_Initial_fluid:  %s
            UB_Initial_amount: %s
            UB_Health:         %s
            UB_MaxHealth:      %s
            ]],
            tostring(modData["UB_Uncapped"]),
            tostring(modData["UB_Initial_amount"]),
            tostring(modData["UB_Initial_amount"]),
            tostring(modData["UB_Health"]),
            tostring(modData["UB_MaxHealth"])
        )

        if modData["modData"] then
            output = output .. string.format(
            [[
            Nested modData options
            UB_Uncapped:       %s
            UB_Initial_fluid:  %s
            UB_Initial_amount: %s
            UB_Health:         %s
            UB_MaxHealth:      %s
            ]],
            tostring(modData["modData"]["UB_Uncapped"]),
            tostring(modData["modData"]["UB_Initial_amount"]),
            tostring(modData["modData"]["UB_Initial_amount"]),
            tostring(modData["modData"]["UB_Health"]),
            tostring(modData["modData"]["UB_MaxHealth"])
            )
        end
    end
    return output
end

function UBFluidBarrel:CanTransferFluid(fluidContainers, transferToContainers)
    local toContainers = false
    if transferToContainers ~= nil then
        toContainers = transferToContainers
    end
    
    local allContainers = {}
    for _,container in pairs(fluidContainers) do
        local fluidContainer = container:getComponent(ComponentType.FluidContainer)
        if not toContainers and FluidContainer.CanTransfer(fluidContainer, self.fluidContainer) then
            if UBFluidBarrel.ValidateFluidCategoty(fluidContainer) then
                table.insert(allContainers, container)
            end
        elseif toContainers and FluidContainer.CanTransfer(self.fluidContainer, fluidContainer) then
            table.insert(allContainers, container)
        end
    end
    return allContainers
end

function UBFluidBarrel:ContainsFluid(fluid)
    return self.fluidContainer~=nil and self.fluidContainer:contains(fluid)
end

function UBFluidBarrel:hasFluidContainer()
    --return self.isoObject:hasComponent(ComponentType.FluidContainer)
    return self.fluidContainer ~= nil
end

function UBFluidBarrel:getAmount()
    if self.fluidContainer~=nil then return self.fluidContainer:getAmount() else return 0 end  
end

function UBFluidBarrel:getCapacity()
    if self.fluidContainer~=nil then return self.fluidContainer:getCapacity() else return 0 end
end

function UBFluidBarrel:getPrimaryFluid()
    if self.fluidContainer~=nil and self:getAmount() > 0 then 
        return self.fluidContainer:getPrimaryFluid() 
    else 
        return nil 
    end
end

function UBFluidBarrel:GetTranslatedFluidNameOrEmpty()
    local fluidObject = self:getPrimaryFluid()

    if fluidObject then
        return fluidObject:getTranslatedName()
    else
        return getText("ContextMenu_Empty")
    end
end

function UBFluidBarrel:GetWeight()
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

function UBFluidBarrel:new(isoObject)
    if not isoObject then return nil end
    if not isoObject:hasComponent(ComponentType.FluidContainer) then return nil end
    if not UBFluidBarrel.validate(isoObject) then return nil end
    local o = UBFluidBarrel.construct(isoObject)

    setmetatable(o, self)
    self.__index = self

    o.fluidContainer = isoObject:getComponent(ComponentType.FluidContainer)

    return o
end
