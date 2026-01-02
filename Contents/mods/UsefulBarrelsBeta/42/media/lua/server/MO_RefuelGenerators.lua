if isClient() then return end

require "UB_RefuelSystem/SRefuelSystem"

local UBUtils = require("UBUtils")

local PRIORITY = 5

--local function NewGeneratorBinding(isoObject)
--end
--
--MapObjects.OnNewWithSprite("appliances_misc_01_0", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_1", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_2", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_3", NewGeneratorBinding, PRIORITY)
--
--MapObjects.OnNewWithSprite("appliances_misc_01_4", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_5", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_6", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_7", NewGeneratorBinding, PRIORITY)
--
--MapObjects.OnNewWithSprite("appliances_misc_01_8", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_9", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_10", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_11", NewGeneratorBinding, PRIORITY)
--
--MapObjects.OnNewWithSprite("appliances_misc_01_12", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_13", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_14", NewGeneratorBinding, PRIORITY)
--MapObjects.OnNewWithSprite("appliances_misc_01_15", NewGeneratorBinding, PRIORITY)


local function LoadGeneratorBinding(isoObject)
    local modData = isoObject:getModData()
    local square = isoObject:getSquare()

    --print("loading: " .. tostring(isoObject) .. "\n is valid mod data: " .. tostring(SRefuelSystem.instance:isValidModData(modData)) .. "\n is valid isoObject: " .. tostring(SRefuelSystem.instance:isValidIsoObject(isoObject)))
    if not SRefuelSystem.instance:isValidModData(modData) then return end
    if not SRefuelSystem.instance:isValidIsoObject(isoObject) then return end
    --print("validation passed: " .. tostring(isoObject))

    local ub_barrel = UBUtils.GetBarrelAtCoords(modData.barrelX, modData.barrelY, modData.barrelZ)

    --print("barrel found: " .. tostring(ub_barrel))
    if not ub_barrel then
        local luaObject = SRefuelSystem.instance:getLuaObjectOnSquare(square)
        if luaObject then
            SCampfireSystem.instance:removeLuaObject(luaObject)
        end
    else
        SRefuelSystem.instance:loadIsoObject(isoObject)
    end
end

MapObjects.OnLoadWithSprite("appliances_misc_01_0", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_1", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_2", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_3", LoadGeneratorBinding, PRIORITY)

MapObjects.OnLoadWithSprite("appliances_misc_01_4", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_5", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_6", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_7", LoadGeneratorBinding, PRIORITY)

MapObjects.OnLoadWithSprite("appliances_misc_01_8", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_9", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_10", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_11", LoadGeneratorBinding, PRIORITY)

MapObjects.OnLoadWithSprite("appliances_misc_01_12", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_13", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_14", LoadGeneratorBinding, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_15", LoadGeneratorBinding, PRIORITY)