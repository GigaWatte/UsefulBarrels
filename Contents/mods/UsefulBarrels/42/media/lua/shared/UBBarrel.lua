---@class UBBarrel
local UBBarrel = ISBaseObject:derive("UBBarrel")

-- object TTL is current context menu lifetime and recreates every time

function UBBarrel:Uncap()
    function getInitialFluid()
        local fluidTable = {}
        local fluids = luautils.split(SandboxVars.UsefulBarrels.InitialFluidPool)
        for _,fluidStr in ipairs(fluids, " ") do
            if Fluid.Get(fluidStr) then table.insert(fluidTable, Fluid.Get(fluidStr)) end
        end
    
        if #fluidTable == 1 then return nil end
        local index = ZombRand(#fluidTable) + 1
    
        return fluidTable[index]
    end
    
    function getInitialFluidAmount()
        if SandboxVars.UsefulBarrels.InitialFluidMaxAmount > 0 then
            return PZMath.clamp(ZombRand(SandboxVars.UsefulBarrels.InitialFluidMaxAmount), 0, SandboxVars.UsefulBarrels.BarrelCapacity)
        end
        return 0
    end
    
    function shouldSpawn()
        if SandboxVars.UsefulBarrels.InitialFluidSpawnChance == 100 then return true end
        if SandboxVars.UsefulBarrels.InitialFluidSpawnChance > 0 then
            return ZombRand(0,100) <= SandboxVars.UsefulBarrels.InitialFluidSpawnChance
        end
        return false
    end

    if not self:hasFluidContainer() then
		local component = ComponentType.FluidContainer:CreateComponent()
		local barrelCapacity = SandboxVars.UsefulBarrels.BarrelCapacity
		component:setCapacity(barrelCapacity)
		component:setContainerName("UB_" .. self.barrel.objectName)
		
		local modData = self.isoObject:getModData()

		local shouldSpawn = shouldSpawn()
		if SandboxVars.UsefulBarrels.InitialFluid and shouldSpawn then
			local fluid = getInitialFluid()
			if fluid then
				local amount = getInitialFluidAmount()
				component:addFluid(fluid, amount)
				modData["UB_Initial_fluid"] = tostring(fluid)
				modData["UB_Initial_amount"] = tostring(amount)
			end
		end

		GameEntityFactory.AddComponent(self.isoObject, true, component)

		if not modData["UB_Uncapped"] then
			modData["UB_Uncapped"] = true
		end
		
		self.isoObject:setModData(modData)
	end

	buildUtil.setHaveConstruction(self.square, true)
end

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

function UBBarrel:GetBarrelInfo(playerInv)
    local output = string.format("Barrel object: %s\n", tostring(self.isoObject))
    output = output .. string.format("hasFluidContainer: %s\n", tostring(self:hasFluidContainer()))

    if self:hasFluidContainer() then
        local fluidAmount = self:getAmount()
        local fluidMax = self:getCapacity()
        local barrelFluid = self:getPrimaryFluid()
        local addfluidContainerItems = playerInv:getAllEvalRecurse(
            function (item) return UBUtils.predicateAnyFluid(item) and not UBBarrel:new(item) end
        )
        local addfluidContainerItemsTable = UBUtils.ConvertToTable(addfluidContainerItems)
        local addallContainers = self:CanTransferFluid(addfluidContainerItemsTable)
        local takefluidContainerItems = playerInv:getAllEvalRecurse(
            function (item) return (UBUtils.predicateFluid(item, barrelFluid) or UBUtils.predicateHasFluidContainer(item)) and not UBBarrel:new(item) end
        )
        local takefluidContainerItemsTable = UBUtils.ConvertToTable(takefluidContainerItems)
        local takeallContainers = self:CanTransferFluid(takefluidContainerItemsTable, true)

        output = output .. string.format(
            [[Fluid: %s\n
            Fluid amount: %s\n
            Fluid capacity: %s\n
            All containers to add: %s\n
            Valid containers to add: %s\n
            All containers for pouring: %s\n
            Valid containers for pouring: %s\n
            isInputLocked: %s\n
            canPlayerEmpty: %s\n]],
            tostring(barrelFluid),
            tostring(fluidAmount),
            tostring(fluidMax),
            tostring(#addfluidContainerItemsTable),
            tostring(#addallContainers),
            tostring(#takefluidContainerItemsTable),
            tostring(#takeallContainers),
            tostring(self.fluidContainer:isInputLocked()),
            tostring(self.fluidContainer:canPlayerEmpty())
        )
    end

    if self.isoObject:hasModData() then
        local modData = self.isoObject:getModData()

        output = output .. string.format(
            [[UB_Uncapped: %s\n
            UB_Initial_fluid: %s\n
            UB_Initial_amount: %s\n]],
            tostring(modData["UB_Uncapped"]),
            tostring(modData["UB_Initial_amount"]),
            tostring(modData["UB_Initial_amount"])

        )

        if modData["modData"] then
            output = output .. string.format(
            [[Nested modData options
            UB_Uncapped: %s\n
            UB_Initial_fluid: %s\n
            UB_Initial_amount: %s\n]],
            tostring(modData["modData"]["UB_Uncapped"]),
            tostring(modData["modData"]["UB_Initial_amount"]),
            tostring(modData["modData"]["UB_Initial_amount"])
            )
        end
    end
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

function UBBarrel:hasFluidContainer()
    --return self.isoObject:hasComponent(ComponentType.FluidContainer)
    return self.fluidContainer ~= nil
end

function UBBarrel:getAmount()
    if self.fluidContainer ~= nil then self.fluidContainer:getAmount() else return nil end  
end

function UBBarrel:getCapacity()
    return self.fluidContainer:getCapacity()
end

function UBBarrel:getPrimaryFluid()
    if self:getAmount() > 0 then return self.fluidContainer:getPrimaryFluid() else return nil end
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

    if self:hasFluidContainer() then
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
                o.objectLabel = nil
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
                o.objectLabel = UBBarrel.GetMoveableDisplayName(isoObject)
                return o 
            end
        end
    end
end