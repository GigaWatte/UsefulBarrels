
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UBBarrel = require "UBBarrel"

local function onCutBarrelLid(player, barrel, blowTorch)
	if luautils.walkAdj(player, barrel.square, true) then
		--ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), predicateBlowTorch, true);
		--local mask = player:getInventory():getFirstEvalRecurse(predicateWeldingMask);
		--if mask then
		--	ISInventoryPaneContextMenu.wearItem(mask, player:getPlayerNum());
		--end
		ISTimedActionQueue.add(UB_CutBarrelLidAction:new(player, barrel, blowTorch, UBConst.BlowTorchUses));
	end
end

local function CutLidBarrelContextMenu(player, context, worldobjects, test)
    local barrel = UBUtils.GetValidBarrel(worldobjects)
    -- UBBarrel or UBFluidBarrel is valid here in context
    if not barrel then return end
    
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local hasWeldingMask = UBUtils.playerHasItem(playerInv, "WeldingMask")
    local blowTorch = UBUtils.playerGetBestItem(playerInv, "BlowTorch", function (a,b) return a:getCurrentUses() - b:getCurrentUses() end)
    local hasBlowTorch = blowTorch ~= nil

    local cutLidBarrelOption = context:addOptionOnTop(
        getText("ContextMenu_UB_CutLid", barrel.altLabel), 
        playerObj,
        onCutBarrelLid,
        barrel, blowTorch
    )

    if not hasWeldingMask and SandboxVars.UsefulBarrels.RequireWeldingMask then
        UBUtils.DisableOptionAddTooltip(cutLidBarrelOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.WeldingMask") .. " 0/1")
    end

    if SandboxVars.UsefulBarrels.RequireBlowTorch then
        if hasBlowTorch then
            if not UBUtils.itemHasUses(blowTorch, UBConst.BlowTorchUses) then
                UBUtils.DisableOptionAddTooltip(cutLidBarrelOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.BlowTorch") .. " < 2 uses")
            end
        else
            UBUtils.DisableOptionAddTooltip(cutLidBarrelOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.BlowTorch") .. " is required")
        end
    end

    if SandboxVars.UsefulBarrels.DebugMode then
        --DoDebugOption(player, context, hasValidWrench, barrel)
    end
end

Events.OnFillWorldObjectContextMenu.Add(CutLidBarrelContextMenu)