
local UBUtils = {}

function UBUtils.predicateFluid(item, fluid)
	return item:getFluidContainer() and item:getFluidContainer():contains(fluid) and (item:getFluidContainer():getAmount() >= 0.5)
end

function UBUtils.predicateHasEmptyFluidContainer(item)
	return item:hasComponent(ComponentType.FluidContainer) and item:getComponent(ComponentType.FluidContainer):isEmpty()
end

function UBUtils.predicateAnyFluid(item)
	return item:getFluidContainer() and (item:getFluidContainer():getAmount() >= 0.5)
end

function UBUtils.predicateStoreFluid(item, fluid)
	local fluidContainer = item:getFluidContainer()
	if not fluidContainer then return false end
	-- our item can store fluids and is empty
	if fluidContainer:isEmpty() then --and not item:isBroken()
		return true
	end
	-- or our item is already storing fuel but is not full
	if fluidContainer:contains(fluid) and (fluidContainer:getAmount() < fluidContainer:getCapacity()) and not item:isBroken() then
		return true
	end
	return false
end

function UBUtils.getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

function UBUtils.predicateNotBroken(item)
	return not item:isBroken()
end

function UBUtils.FormatFluidAmount(setX, amount, max, fluidName)
	if max >= 9999 then
		return string.format("%s: <SETX:%d> %s", getText(fluidName), setX, getText("Tooltip_WaterUnlimited"))
	end
	return string.format("%s: <SETX:%d> %s / %s", getText(fluidName), setX, luautils.round(amount, 2) .. "L", max .. "L")
end

function UBUtils.GetValidBarrelObject(worldobjects)
    local valid_barrel_moveable_names = {
        "Base.MetalDrum",
		"Base.Mov_LightGreenBarrel",
		"Base.Mov_OrangeBarrel",
		"Base.Mov_DarkGreenBarrel",
    }

    for i,isoobject in ipairs(worldobjects) do
		if not isoobject or not isoobject:getSquare() then return end
        if not isoobject:getSprite() then return end
        if not isoobject:getSpriteName() then return end
        for i = 1, #valid_barrel_moveable_names do
            if isoobject:getSprite():getProperties():Val("CustomItem") == valid_barrel_moveable_names[i] then return isoobject end
        end
    end
end

function UBUtils.playerHasItem(playerInv, itemName) return playerInv:containsTypeEvalRecurse(itemName, UBUtils.predicateNotBroken) or playerInv:containsTagEvalRecurse(itemName, UBUtils.predicateNotBroken) end

function UBUtils.playerGetItem(playerInv, itemName) return playerInv:getFirstTypeEvalRecurse(itemName, UBUtils.predicateNotBroken) or playerInv:getFirstTagEvalRecurse(itemName, UBUtils.predicateNotBroken) end

function UBUtils.ConvertToTable(list)
	local tbl = {}
	for i=0, list:size() - 1 do
		local item = list:get(i)
		table.insert(tbl, item)
	end
	return tbl
end

--function UBUtils.GetFluidContainersFromItems(items)
--	local fluidContainers = {}
--	for i=0, items:size() - 1 do
--		local item = items:get(i)
--		if (item:hasComponent(ComponentType.FluidContainer)) then
--			table.insert(fluidContainers, item:getComponent(ComponentType.FluidContainer))
--		end
--	end
--	return fluidContainers
--end
function UBUtils.ValidateFluidCategoty(fluidContainer)
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

function UBUtils.CanTransferFluid(sourceContainers, targetFluidContainer, transferToSource)

	local toSource = transferToSource ~= nil
	local allContainers = {}
	-- TODO validate on categories also!!
	--make a table of all containers
	for _,container in pairs(sourceContainers) do
		local fluidContainer = container:getComponent(ComponentType.FluidContainer)
		if not toSource and FluidContainer.CanTransfer(fluidContainer, targetFluidContainer) then
			-- verify is that fluid caregory is allowed
			if UBUtils.ValidateFluidCategoty(fluidContainer) then
				table.insert(allContainers, container)
			end
		elseif toSource and FluidContainer.CanTransfer(targetFluidContainer, fluidContainer) then
			table.insert(allContainers, container)
		end
	end
	return allContainers
end

function UBUtils.SortContainers(allContainers)
	local allContainerTypes = {}
	if #allContainers == 0 then return allContainerTypes end
	local allContainersOfType = {}
	----the table can have small groups of identical containers		eg: 1, 1, 2, 3, 1, 3, 2
	----so it needs sorting to group them all together correctly		eg: 1, 1, 1, 2, 2, 3, 3
	table.sort(allContainers, function(a,b) return not string.sort(a:getName(), b:getName()) end)
	----once sorted, we can use it to make smaller tables for each item type
	local previousContainer = nil;
	for _,container in pairs(allContainers) do
		if previousContainer ~= nil and container:getName() ~= previousContainer:getName() then
			table.insert(allContainerTypes, allContainersOfType)
			allContainersOfType = {}
		end
		table.insert(allContainersOfType, container)
		previousContainer = container
	end
	table.insert(allContainerTypes, allContainersOfType)
	return allContainerTypes
end

function UBUtils.DisableOptionAddTooltip(option, description)
	if option then
		option.notAvailable = true
		option.toolTip = ISWorldObjectContextMenu.addToolTip()
		if description then option.toolTip.description = description else option.toolTip.description = "" end
	end
end

function UBUtils.GetFontSize()
	local font = UIFont.FromString(getCore():getOptionContextMenuFont())
	if font then return font else return UIFont.Medium end
end

function UBUtils.GetTranslatedFluidNameOrEmpty(fluidObject)
	if fluidObject then
		return fluidObject:getTranslatedName()
	else
		return getText("ContextMenu_Empty")
	end
end

return UBUtils