
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UBBarrel = require "UBBarrel"

local function DuBarrelLidCut(playerObj, barrel, blowTorch, weldingMask)
	if luautils.walkAdj(playerObj, barrel.square, true) then
        if SandboxVars.UsefulBarrels.RequireWeldingMask and weldingMask ~= nil then
            --local mask = player:getInventory():getFirstEvalRecurse(predicateWeldingMask);
            --if mask then
            --	ISInventoryPaneContextMenu.wearItem(mask, player:getPlayerNum());
            --end
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, weldingMask, 25, true))
        end
        if SandboxVars.UsefulBarrels.RequirePipeWrench and blowTorch ~= nil then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, blowTorch, 25, true))
        end
		ISTimedActionQueue.add(UB_BarrelLidCutAction:new(playerObj, barrel, blowTorch, UBConst.BlowTorchUses));
	end
end

local function BarrelLidCutContextMenu(player, context, worldobjects, test)
    -- maybe move it under existing barrel option
    -- also debug show be one and not two
    local ub_barrel = UBUtils.GetValidBarrel(worldobjects)
    -- UBBarrel or UBFluidBarrel is valid here in context
    if not ub_barrel then return end
    if not ub_barrel:getSprite(UBBarrel.LIDLESS) then return end
    
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local weldingMask = UBUtils.playerGetItem(playerInv, "WeldingMask")
    local hasWeldingMask = weldingMask ~= nil
    local blowTorch = UBUtils.playerGetBestItem(playerInv, "BlowTorch", function (a,b) return a:getCurrentUses() - b:getCurrentUses() end)
    local hasBlowTorch = blowTorch ~= nil

    -- get vanilla FluidContainer object option
    local barrelOption = context:getOptionFromName(self.barrel.objectLabel)
    if barrelOption and self.barrel.icon then
        barrelOption.iconTexture = self.barrel.icon
    end

    if barrelOption then
        local barrelMenu = context:getSubMenu(barrelOption.subOption)

        local barrelLidCutOption = barrelMenu:addOption(
            getText("ContextMenu_UB_BarrelLidCut", ub_barrel.altLabel), 
            playerObj,
            DuBarrelLidCut,
            ub_barrel, blowTorch, weldingMask
        )

        if not hasWeldingMask and SandboxVars.UsefulBarrels.RequireWeldingMask then
            UBUtils.DisableOptionAddTooltip(barrelLidCutOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.WeldingMask") .. " 0/1")
        end

        if SandboxVars.UsefulBarrels.RequireBlowTorch then
            if hasBlowTorch then
                if not UBUtils.itemHasUses(blowTorch, UBConst.BlowTorchUses) then
                    UBUtils.DisableOptionAddTooltip(barrelLidCutOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.BlowTorch") .. " < 2 uses")
                end
            else
                UBUtils.DisableOptionAddTooltip(barrelLidCutOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.BlowTorch") .. " is required")
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BarrelLidCutContextMenu)