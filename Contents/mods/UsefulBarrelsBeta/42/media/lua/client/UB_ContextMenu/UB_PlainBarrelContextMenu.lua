
local UBUtils = require "UBUtils"
local UBBarrel = require "UBBarrel"

local function DoDebugOption(player, context, hasValidWrench, barrel)
    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    local tooltip = ISWorldObjectContextMenu.addToolTip()

    local description = string.format(
        [[
        SVRequirePipeWrench: %s
        hasValidWrench: %s
        isoObject: %s
        ]],
        tostring(SandboxVars.UsefulBarrels.RequirePipeWrench),
        tostring(hasValidWrench),
        tostring(barrel)
    )

    tooltip.description = description
    debugOption.toolTip = tooltip
end

local function DoBarrelUncap(playerObj, ub_barrel, wrench, hasValidWrench)
    if luautils.walkAdj(playerObj, ub_barrel.square, true) then
        if SandboxVars.UsefulBarrels.RequirePipeWrench and hasValidWrench then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, wrench, 25, true))
        end
        ISTimedActionQueue.add(UB_BarrelUncapAction:new(playerObj, ub_barrel, wrench))
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
    if not hasValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
        UBUtils.DisableOptionAddTooltip(openBarrelOption, getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench")))
    end

    if SandboxVars.UsefulBarrels.DebugMode then
        DoDebugOption(player, context, hasValidWrench, ub_barrel)
    end
end

Events.OnFillWorldObjectContextMenu.Add(PlainBarrelContextMenu)