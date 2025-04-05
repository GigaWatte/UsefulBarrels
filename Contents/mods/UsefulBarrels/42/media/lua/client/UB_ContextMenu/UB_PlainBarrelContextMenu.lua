
local UBUtils = require "UBUtils"

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

local function DoBarrelUncap(player, barrel, plain_barrel_label, wrench, hasValidWrench)
    local playerObj = getSpecificPlayer(player)

    if luautils.walkAdj(playerObj, barrel:getSquare(), true) then
        if SandboxVars.UsefulBarrels.RequirePipeWrench and hasValidWrench then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, wrench, 25, true))
        end
        ISTimedActionQueue.add(ISUBDoBarrelUncap:new(playerObj, barrel, wrench, plain_barrel_label))
    end
end

local function PlainBarrelContextMenu(player, context, worldobjects, test)
    local barrel = UBUtils.GetValidBarrel(worldobjects)
    
    if not barrel then return end
    if barrel:hasComponent(ComponentType.FluidContainer) then return end

    local props = barrel:getSprite():getProperties()
    local name

    if props:Is("CustomName") then
        name = props:Val("CustomName")
        if props:Is("GroupName") then
            name = props:Val("GroupName") .. " " .. name
        end
    end
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local wrench = UBUtils.playerGetItem(playerInv, "PipeWrench")
    local hasValidWrench = wrench ~= nil and UBUtils.predicateNotBroken(wrench)

    local barrel_label = Translator.getMoveableDisplayName(name)
    local openBarrelOption = context:addOptionOnTop(
        getText("ContextMenu_UB_UncapBarrel", barrel_label), 
        player,
        DoBarrelUncap,
        barrel_label, wrench, hasValidWrench
    )
    if not hasValidWrench and SandboxVars.UsefulBarrels.RequirePipeWrench then
        UBUtils.DisableOptionAddTooltip(openBarrelOption, getText("Tooltip_UB_WrenchMissing", getItemName("Base.PipeWrench")))
    end

    if SandboxVars.UsefulBarrels.DebugMode then
        DoDebugOption(player, context, hasValidWrench, barrel)
    end
end

Events.OnFillWorldObjectContextMenu.Add(PlainBarrelContextMenu)