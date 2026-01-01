local UB_Utils = require "UB_Utils"
local UB_Barrel = require "UB_Barrel"

local function DoBarrelUnscrew(playerObj, ub_barrel, wrench, hasValidWrench)
    if luautils.walkAdj(playerObj, ub_barrel.square, true) then
        local containerToReturn = nil
        local playerInv = playerObj:getInventory()

        if SandboxVars.UsefulBarrels.RequirePipeWrench and hasValidWrench then
            containerToReturn = wrench:getContainer()
            -- transfer item to player inventory
            if luautils.haveToBeTransfered(playerObj, wrench) then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, wrench, wrench:getContainer(), playerInv))
            end
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, wrench, 25, true))
        end

        ISTimedActionQueue.add(UB_BarrelUnscrewAction:new(playerObj, ub_barrel.isoObject, wrench))

        -- return item back to container
        if containerToReturn and (containerToReturn ~= playerInv) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, wrench, playerInv, containerToReturn))
        end
    end
end

local function VanillaBarrelContextMenu(player, context, worldobjects, test)
    local ub_barrel = UB_Utils.GetValidBarrelFromWorldObjects(worldobjects)

    if not ub_barrel then return end
    if ub_barrel.Type ~= UB_Barrel.Type then return end

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local pipeWrench = UB_Utils.PlayerGetItem(playerInv, ItemTag.PIPE_WRENCH)
    local hasValidWrench = pipeWrench ~= nil

    local openBarrelOption = context:addOptionOnTop(
        getText("ContextMenu_UB_UnscrewPlug", ub_barrel.altLabel),
        playerObj,
        DoBarrelUnscrew,
        ub_barrel, pipeWrench, hasValidWrench
    )
    if openBarrelOption then
        local itemScript = getItem("Base.PipeWrench")
        openBarrelOption.iconTexture = itemScript and itemScript:getNormalTexture()
    end

    if not hasValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
        UB_Utils.DisableOptionAddTooltip(
            openBarrelOption,
            "<RGB:1,0,0> " .. getItemNameFromFullType("Base.PipeWrench") .. " 0/1"
        )
    end

end

Events.OnFillWorldObjectContextMenu.Add(VanillaBarrelContextMenu)