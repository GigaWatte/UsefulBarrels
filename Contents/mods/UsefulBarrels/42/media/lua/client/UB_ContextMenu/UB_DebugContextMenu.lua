local UBUtils = require "UBUtils"
local UBConst = require "UBConst"
local UBBarrel = require "UBBarrel"
local UBFluidBarrel = require "UBFluidBarrel"

local ISVehicleMenu_FillPartMenu = ISVehicleMenu.FillPartMenu
function ISVehicleMenu.FillPartMenu(playerIndex, context, slice, vehicle)
    ISVehicleMenu_FillPartMenu(playerIndex, context, slice, vehicle)
    if not SandboxVars.UsefulBarrels.DebugMode then return end
    if not context then return end

    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    debugOption.toolTip = ISWorldObjectContextMenu.addToolTip()

    local playerObj = getSpecificPlayer(playerIndex)
    local description = string.format(
        [[
        distance: %s
        isEngineStarted: %s
        ]],
        tostring(playerObj:DistToProper(vehicle)),
        tostring(vehicle:isEngineStarted())
    )

    local part_found = false
    for i=1,vehicle:getPartCount() do
        local part = vehicle:getPartByIndex(i-1)
        local partCategory = part:getCategory()
        if part 
            and partCategory 
            and part:isContainer() 
            and string.find(partCategory, "gastank")~=nil 
            and string.find(part:getContainerContentType(), "Gasoline")
            and part:getContainerContentAmount() < part:getContainerCapacity() then
                local partSquare = UBUtils.GetVehiclePartSquare(vehicle, part)
                local barrels = UBUtils.GetBarrelsNearby(partSquare, UBConst.VEHICLE_SCAN_DISTANCE, Fluid.Petrol, true)
                part_found = true
                description = description .. string.format(
                    [[
                    tank capacity: %s
                    tank content amount: %s
                    barrels: %s
                    ]],
                    tostring(part:getContainerCapacity()),
                    tostring(part:getContainerContentAmount()),
                    tostring(#barrels)
                )
                if #barrels > 0 then
                    local barrel = barrels[1]
                    local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
                    local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerObj:getInventory(), "Base.RubberHose")
                    
                    description = description .. string.format(
                        [[
                        SVCarRefuelRequiresHose %s
                        hasHoseNearby: %s
                        ]],
                        tostring(SandboxVars.UsefulBarrels.CarRefuelRequiresHose),
                        tostring(hasHoseNearby)
                    )
                end
        end
    end

    if not part_found then
        description = description .. string.format(
            [[
            gas tank not found
            ]]
        )
    end
    debugOption.toolTip.description = description
end

local function GeneratorDebugContextMenu(player, context, worldobjects, test)
    if not SandboxVars.UsefulBarrels.DebugMode then return end
    if not ISWorldObjectContextMenu.fetchVars.generator then return end

    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    debugOption.toolTip = ISWorldObjectContextMenu.addToolTip()

    local generator = ISWorldObjectContextMenu.fetchVars.generator
    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local barrels = UBUtils.GetBarrelsNearby(generator:getSquare(), UBConst.GENERATOR_SCAN_DISTANCE, Fluid.Petrol)
    local description = string.format(
        [[
        SVEnableGeneratorRefuel: %s
        SVGeneratorRequireHose: %s
        Gen isActivated: %s
        Gen fuel >= 100: %s
        Barrels available: %s
        CanCreateMenu: %s
        ]],
        tostring(SandboxVars.UsefulBarrels.EnableGeneratorRefuel),
        tostring(SandboxVars.UsefulBarrels.GeneratorRefuelRequiresHose),
        tostring(generator:isActivated()),
        tostring(generator:getFuel() >= 100),
        tostring(#barrels),
        tostring(UBUtils.CanCreateGeneratorMenu(generator:getSquare(), playerObj))
    )
    for _,barrel in ipairs(barrels) do
        local worldObjects = UBUtils.GetWorldItemsNearby(barrel.square, UBConst.TOOL_SCAN_DISTANCE)
        local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerInv, "Base.RubberHose")
        description = description .. string.format("hasHoseNearby: %s", tostring(hasHoseNearby))
        description = description .. barrel:GetBarrelInfo()
    end

    debugOption.toolTip.description = description
end

--local function CreateWaterTypeMenu(debugMenu, ub_barrel)
--    debugMenu:addOptionOnTop(
--        getText("UB_Remove_Water_Level_Sprite"), 
--        ub_barrel,
--        UBFluidBarrel.removeWaterType
--    )
--    local waterLevelOption = debugMenu:addOptionOnTop(
--        getText("UB_Add_Water_Level_Sprite")
--    )
--    local waterMenu = ISContextMenu:getNew(debugMenu)
--    debugMenu:addSubMenu(waterLevelOption, waterMenu)
--
--    for _,waterType in ipairs({UBBarrel.WATER_LOW, UBBarrel.WATER_HALF, UBBarrel.WATER_FULL}) do
--        waterMenu:addOption(
--            getText(waterType), 
--            ub_barrel, 
--            UBFluidBarrel.setWaterType, waterType
--        )
--    end
--end

local function GetFluidTransferDebugText(optionsTable, isGroundMenu, ub_barrel)
    local containers
    if isGroundMenu then
        containers = optionsTable.groundContainers
    else
        containers = optionsTable.containers
    end
    local allContainers = ub_barrel:CanTransferFluid(containers, optionsTable.addToBarrel == false)

    return string.format(
        [[
        action: %s from %s
        containers: %s
        valid conteiners: %s
        --------------------
        ]],
        tostring(optionsTable.addToBarrel and "add" or "fill"),
        tostring(isGroundMenu and "ground" or "inventory"),
        tostring(#containers),
        tostring(#allContainers)
    )
end

local function BarrelDebugContextMenu(player, context, worldobjects, test)
    if not SandboxVars.UsefulBarrels.DebugMode then return end
    if ISWorldObjectContextMenu.fetchVars.generator then return end

    local ub_barrel = UBUtils.GetValidBarrel(worldobjects)

    if not ub_barrel then return end

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()

    local debugOption = context:addOptionOnTop(getText("ContextMenu_UB_DebugOption"))
    debugOption.toolTip = ISWorldObjectContextMenu.addToolTip()

    local description = ub_barrel:GetBarrelInfo()

    local barrelOption = context:getOptionFromName(ub_barrel.objectLabel)
    --if barrelOption and ub_barrel.icon then
    --    barrelOption.iconTexture = ub_barrel.icon
    --end
    
    local debugMenu = ISContextMenu:getNew(context)
    context:addSubMenu(debugOption, debugMenu) 
    --CreateWaterTypeMenu(debugMenu, ub_barrel)
    
    local worldObjects = UBUtils.GetWorldItemsNearby(ub_barrel.square, UBConst.TOOL_SCAN_DISTANCE)
    local hasHoseNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerInv, "Base.RubberHose")
    local hasFunnelNearby = UBUtils.hasItemNearbyOrInInv(worldObjects, playerInv, "Base.Funnel")
    local wrench = UBUtils.playerGetItem(playerInv, "PipeWrench")
    local hasValidWrench = wrench ~= nil and UBUtils.predicateNotBroken(wrench)
    local weldingMask = UBUtils.playerGetItem(playerInv, "WeldingMask")
    local hasWeldingMask = weldingMask ~= nil
    local blowTorch = UBUtils.playerGetBestItem(playerInv, "BlowTorch", function (a,b) return a:getCurrentUses() - b:getCurrentUses() end)
    local hasBlowTorch = blowTorch ~= nil

    description = description .. string.format(
        [[
        SVRequireHose: %s
        SVRequireFunnel: %s
        SVEnableFillBarrelFromVehicles: %s
        contextMenuHasOption: %s
        CanCreateFluidMenu: %s
        SVRequirePipeWrench: %s
        hasValidWrench: %s
        hasHoseNearby: %s
        hasFunnelNearby: %s
        SVRequireWeldingMask: %s
        SVRequireBlowTorch: %s
        hasWeldingMask: %s
        hasBlowTorch: %s
        ]],
        tostring(SandboxVars.UsefulBarrels.RequireHoseForTake),
        tostring(SandboxVars.UsefulBarrels.RequireFunnelForFill),
        tostring(SandboxVars.UsefulBarrels.EnableFillBarrelFromVehicles),
        tostring(barrelOption ~= nil),
        tostring(UBUtils.CanCreateBarrelFluidMenu(playerObj, ub_barrel.square)),
        tostring(SandboxVars.UsefulBarrels.RequirePipeWrench),
        tostring(hasValidWrench),
        tostring(hasHoseNearby),
        tostring(hasFunnelNearby),
        tostring(SandboxVars.UsefulBarrels.RequireWeldingMask),
        tostring(SandboxVars.UsefulBarrels.RequireBlowTorch),
        tostring(hasWeldingMask),
        tostring(hasBlowTorch)
    )

    local vehicles = UBUtils.GetVehiclesNeaby(ub_barrel.square, UBConst.VEHICLE_SCAN_DISTANCE)

    description = description .. string.format(
        [[
        SVFillBarrelFromVehiclesRequiresHose: %s
        hasHoseNearby: %s
        vehicles: %s
        ]],
        tostring(SandboxVars.UsefulBarrels.FillBarrelFromVehiclesRequiresHose),
        tostring(hasHoseNearby),
        tostring(#vehicles)
    )

    for _,vehicle in ipairs(vehicles) do
        --string.find(vehicle:getScriptName(), "Trailer") ~= nil
        local carName = vehicle:getScript():getCarModelName() or vehicle:getScript():getName()
        description = description .. string.format(
            [[
            vehicle: %s (%s)
            ]], 
            tostring(carName), 
            tostring(vehicle:getPartCount())
        )
        local vehicle_gas_part_found = false
        for i=1,vehicle:getPartCount() do
            local part = vehicle:getPartByIndex(i-1)
            local partCategory = part:getCategory()
            if part and partCategory and part:isContainer() and string.find(partCategory, "gastank")~=nil then
                description = description .. string.format(
                    [[
                    gas amount: %sL
                    ]], 
                    tostring(math.ceil(part:getContainerContentAmount()))
                )
                vehicle_gas_part_found = true
            end
        end
        if not vehicle_gas_part_found then
            description = description .. string.format([[
                no proper gas part found
            ]])
        end
    end

    if ub_barrel.Type == UBFluidBarrel.Type then
        local addMenuOpts = {
            addToBarrel=true,
            containers=UBUtils.getPlayerFluidContainers(playerInv),
            noToolPredicate=SandboxVars.UsefulBarrels.RequireFunnelForFill == true and hasFunnelNearby == false,
            groundContainers=UBUtils.GetWorldFluidContainersNearby(
                ub_barrel.square, 
                UBConst.WORLD_ITEMS_DISTANCE,
                function(worldInventoryObject) return UBUtils.predicateAnyFluid(worldInventoryObject) end
            ),
        }

        local takeMenuOpts = {
            addToBarrel=false,
            containers=UBUtils.getPlayerFluidContainersWithFluid(playerInv, ub_barrel:getPrimaryFluid()),
            noToolPredicate=SandboxVars.UsefulBarrels.RequireHoseForTake == true and hasHoseNearby == false,
            groundContainers=UBUtils.GetWorldFluidContainersNearby(
                ub_barrel.square, 
                UBConst.WORLD_ITEMS_DISTANCE,
                function(worldInventoryObject) return UBUtils.predicateFluid(worldInventoryObject, ub_barrel:getPrimaryFluid()) or UBUtils.predicateHasFluidContainer(worldInventoryObject) end
            ),
        }

        description = description .. GetFluidTransferDebugText(addMenuOpts, false, ub_barrel)
        description = description .. GetFluidTransferDebugText(takeMenuOpts, false, ub_barrel)
        description = description .. GetFluidTransferDebugText(addMenuOpts, true, ub_barrel)
        description = description .. GetFluidTransferDebugText(takeMenuOpts, true, ub_barrel)
    end

    debugOption.toolTip.description = description
end

Events.OnFillWorldObjectContextMenu.Add(BarrelDebugContextMenu)
Events.OnFillWorldObjectContextMenu.Add(GeneratorDebugContextMenu)


local function TilesTest(player, context, worldobjects, test)
    --local instance = getTileOverlays()

    -- SpriteConfigManager
    -- SpriteConfigManager.TileInfo
    -- SpriteConfigScript.TileScript

    -- local room = adjacentSquare:getRoom()
    -- if room then
    --     local roomDef = room:getRoomDef()
    --     local roomId = roomDef:getID()
    --     newSquare:setRoom(room)
    --     newSquare:setRoomID(roomId)
    --     room:addSquare(newSquare)
    -- end

    -- local IsoBarricade_addPlank = {}
    -- function IsoBarricade_addPlank.GetClass()
    --     local class, methodName = IsoBarricade.class, "addPlank"
    --     local metatable = __classmetatables[class]
    --     local metatable__index = metatable.__index
    --     local original_function = metatable__index[methodName]
    --     metatable__index[methodName] = IsoBarricade_addPlank.PatchClass(original_function)
    -- end

    -- local index = __classmetatables[IsoBarricade.class].__index

    -- local old_addPlank = index.addPlank
    -- index.addPlank = function(...)
    --     
    --     return old_addPlank(...)
    -- end

    --IsoPushableObject pushableObject = new IsoPushableObject(
    --    IsoWorld.instance.getCell(), IsoPlayer.getInstance().getCurrentSquare(), IsoSpriteManager.instance.getSprite("trashcontainers_01_16")
    --);
    --WorldSimulation.instance.physicsObjectMap.put(int0, pushableObject);
end
Events.OnFillWorldObjectContextMenu.Add(TilesTest)