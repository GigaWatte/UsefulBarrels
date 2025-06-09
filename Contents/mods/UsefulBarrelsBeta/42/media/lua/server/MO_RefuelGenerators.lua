if isClient() then return end

require "UB_RefuelSystem/SRefuelSystem"

local PRIORITY = 5

local function NewGeneratorBinding(isoObject)

end

MapObjects.OnNewWithSprite("appliances_misc_01_0", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_1", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_2", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_3", NewGeneratorBinding, PRIORITY)

MapObjects.OnNewWithSprite("appliances_misc_01_4", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_5", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_6", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_7", NewGeneratorBinding, PRIORITY)

MapObjects.OnNewWithSprite("appliances_misc_01_8", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_9", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_10", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_11", NewGeneratorBinding, PRIORITY)

MapObjects.OnNewWithSprite("appliances_misc_01_12", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_13", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_14", NewGeneratorBinding, PRIORITY)
MapObjects.OnNewWithSprite("appliances_misc_01_15", NewGeneratorBinding, PRIORITY)


local function LoadGeneratorBinding(isoObject)
    if SRefuelSystem.instance:isValidModData(isoObject:getModData()) and SRefuelSystem.instance:isValidIsoObject(isoObject) then
        SRefuelSystem.instance:loadIsoObject(isoObject)
    end
end

MapObjects.OnLoadWithSprite("appliances_misc_01_0", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_1", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_2", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_3", LoadGenerator, PRIORITY)

MapObjects.OnLoadWithSprite("appliances_misc_01_4", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_5", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_6", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_7", LoadGenerator, PRIORITY)

MapObjects.OnLoadWithSprite("appliances_misc_01_8", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_9", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_10", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_11", LoadGenerator, PRIORITY)

MapObjects.OnLoadWithSprite("appliances_misc_01_12", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_13", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_14", LoadGenerator, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_misc_01_15", LoadGenerator, PRIORITY)