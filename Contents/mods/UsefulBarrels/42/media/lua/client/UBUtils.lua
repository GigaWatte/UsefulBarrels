
local UBUtils = {}

-- << functions from vanilla pz

function UBUtils.predicateFluid(item, fluid)
	return item:getFluidContainer() and item:getFluidContainer():contains(fluid) and (item:getFluidContainer():getAmount() >= 0.5)
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

-- >> end functions from vanilla pz

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


return UBUtils