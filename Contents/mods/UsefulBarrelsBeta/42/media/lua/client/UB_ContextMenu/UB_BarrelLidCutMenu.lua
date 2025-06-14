
local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UBBarrel = require "UBBarrel"

local function DuBarrelLidCut(playerObj, barrel, blowTorch, weldingMask)
    if luautils.walkAdj(playerObj, barrel.square, true) then
        local blowTorchContainerToReturn = nil
        local weldingMaskContainerToReturn = nil
        local playerInv = playerObj:getInventory()

        if SandboxVars.UsefulBarrels.RequireWeldingMask and weldingMask ~= nil then
            weldingMaskContainerToReturn = weldingMask:getContainer()
            -- transfer item to player inventory
            if luautils.haveToBeTransfered(playerObj, weldingMask) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, weldingMask, weldingMask:getContainer(), playerInv))
            end
            ISTimedActionQueue.add(ISWearClothing:new(playerObj, weldingMask, 25))
        end

        if SandboxVars.UsefulBarrels.RequireBlowTorch and blowTorch ~= nil then
            blowTorchContainerToReturn = blowTorch:getContainer()
            -- transfer item to player inventory
            if luautils.haveToBeTransfered(playerObj, blowTorch) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, blowTorch, blowTorch:getContainer(), playerInv))
            end
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, blowTorch, 25, true))
        end

        ISTimedActionQueue.add(UB_BarrelLidCutAction:new(playerObj, barrel, blowTorch, UBConst.BLOW_TORCH_USES))

        if SandboxVars.UsefulBarrels.RequireWeldingMask and weldingMask ~= nil then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, weldingMask, 25))
            -- return item back to container
            if weldingMaskContainerToReturn and (weldingMaskContainerToReturn ~= playerInv) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, weldingMask, playerInv, weldingMaskContainerToReturn))
            end
        end
        
        if SandboxVars.UsefulBarrels.RequireBlowTorch and blowTorch ~= nil then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, blowTorch, 25))
            -- return item back to container
            if blowTorchContainerToReturn and (blowTorchContainerToReturn ~= playerInv) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, blowTorch, playerInv, blowTorchContainerToReturn))
            end
        end
    end
end

local function BarrelLidCutContextMenu(player, context, worldobjects, test)
    local ub_barrel = UBUtils.GetValidBarrel(worldobjects)
    -- UBBarrel or UBFluidBarrel is valid here in context
    if not ub_barrel then return end
    -- if barrel has not lidless sprite
    if not ub_barrel:getSpriteType(UBBarrel.LIDLESS) then return end
    -- if barrel already lidless
    if ub_barrel:getSprite() == ub_barrel:getSpriteType(UBBarrel.LIDLESS) then return end
    
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local weldingMask = UBUtils.playerGetItem(playerInv, "WeldingMask")
    local hasWeldingMask = weldingMask ~= nil
    local blowTorch = UBUtils.playerGetBestItem(playerInv, "BlowTorch", function (a,b) return a:getCurrentUses() - b:getCurrentUses() end)
    local hasBlowTorch = blowTorch ~= nil

    -- get vanilla FluidContainer object option
    local barrelOption = context:getOptionFromName(ub_barrel.objectLabel)
    if barrelOption and ub_barrel.icon then
        barrelOption.iconTexture = ub_barrel.icon
    end

    local barrelLidCutOption
    if barrelOption then
        if barrelOption.subOption then
        local barrelMenu = context:getSubMenu(barrelOption.subOption)
            barrelLidCutOption = barrelMenu:addOption(
                getText("ContextMenu_UB_BarrelLidCut", ub_barrel.altLabel), 
                playerObj,
                DuBarrelLidCut,
                ub_barrel, blowTorch, weldingMask
            )
        end
    else
        barrelLidCutOption = context:addOptionOnTop(
            getText("ContextMenu_UB_BarrelLidCut", ub_barrel.altLabel), 
            playerObj,
            DuBarrelLidCut,
            ub_barrel, blowTorch, weldingMask
        )
    end

    if barrelLidCutOption then
        if hasBlowTorch then
            barrelLidCutOption.iconTexture = blowTorch:getIcon()
        end

        if not hasWeldingMask and SandboxVars.UsefulBarrels.RequireWeldingMask then
            UBUtils.DisableOptionAddTooltip(barrelLidCutOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.WeldingMask") .. " 0/1")
        end

        if SandboxVars.UsefulBarrels.RequireBlowTorch then
            if hasBlowTorch then
                if not UBUtils.itemHasUses(blowTorch, UBConst.BLOW_TORCH_USES) then
                    UBUtils.DisableOptionAddTooltip(barrelLidCutOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.BlowTorch") .. " < 2 uses")
                end
            else
                UBUtils.DisableOptionAddTooltip(barrelLidCutOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.BlowTorch") .. " is required")
            end
        end
    end
    
end

Events.OnFillWorldObjectContextMenu.Add(BarrelLidCutContextMenu)