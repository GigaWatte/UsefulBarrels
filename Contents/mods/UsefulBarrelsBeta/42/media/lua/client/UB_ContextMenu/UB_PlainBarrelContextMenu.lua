
local UBUtils = require "UBUtils"
local UBBarrel = require "UBBarrel"

local function DoBarrelUncap(playerObj, ub_barrel, wrench, hasValidWrench)
    if luautils.walkAdj(playerObj, ub_barrel.square, true) then
        local containerToReturn = wrench:getContainer()
        local playerInv = playerObj:getInventory()
        
        if SandboxVars.UsefulBarrels.RequirePipeWrench and hasValidWrench then
            -- transfer item to player inventory
            if luautils.haveToBeTransfered(playerObj, wrench) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, wrench, wrench:getContainer(), playerInv))
            end
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, wrench, 25, true))
        end

        ISTimedActionQueue.add(UB_BarrelUncapAction:new(playerObj, ub_barrel, wrench))
        -- this worked..
        -- return item back to container
        if containerToReturn and (containerToReturn ~= playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, wrench, playerInv, containerToReturn))
        end
    end
end

local function PlainBarrelContextMenu(player, context, worldobjects, test)
    local ub_barrel = UBUtils.GetValidBarrel(worldobjects)

    if not ub_barrel then return end
    if ub_barrel.Type ~= UBBarrel.Type then return end

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local wrench = UBUtils.playerGetItem(playerInv, "PipeWrench")
    local hasValidWrench = wrench ~= nil and UBUtils.predicateNotBroken(wrench)

    local openBarrelOption = context:addOptionOnTop(
        getText("ContextMenu_UB_UncapBarrel", ub_barrel.altLabel), 
        playerObj,
        DoBarrelUncap,
        ub_barrel, wrench, hasValidWrench
    )
    if openBarrelOption and hasValidWrench then
        openBarrelOption.iconTexture = wrench:getIcon()
    end

    if not hasValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
        UBUtils.DisableOptionAddTooltip(openBarrelOption, "<RGB:1,0,0> " .. getItemNameFromFullType("Base.PipeWrench") .. " 0/1")
    end
end

Events.OnFillWorldObjectContextMenu.Add(PlainBarrelContextMenu)