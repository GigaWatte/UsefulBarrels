local UB_Const = {}

UB_Const.VALID_BARREL_NAMES = {
    "Base.MetalDrum",
    "Base.Mov_LightGreenBarrel",
    "Base.Mov_OrangeBarrel",
    "Base.Mov_DarkGreenBarrel",
}

UB_Const.UNCAP_DURATION = 40

UB_Const.BASE_FUEL_TRANSFER_RATE = 50

UB_Const.TOOL_SCAN_DISTANCE = 1

UB_Const.WORLD_ITEMS_DISTANCE = 1

UB_Const.VEHICLE_SCAN_DISTANCE = 3

UB_Const.GENERATOR_SCAN_DISTANCE = 2

UB_Const.BLOW_TORCH_USES = 2

UB_Const.RAIN_CATCHER_FACTOR = 0.3

UB_Const.MAP_OBJECTS_DISTANCE = 3

UB_Const.FACING_N = "N"
UB_Const.FACING_S = "S"

UB_Const.DEFAULT = "default"
UB_Const.LIDLESS = "lidless"
UB_Const.WATER_LOW = "water_low"
UB_Const.WATER_LOW_LEVEL = 0.75
UB_Const.WATER_HALF = "water_half"
UB_Const.WATER_HALF_LEVEL = 0.80
UB_Const.WATER_FULL = "water_full"
UB_Const.WATER_FULL_LEVEL = 0.95
UB_Const.LIDLESS_RUSTY = "lidless_rusty"

local SPRITE_MAP = {}
SPRITE_MAP["Base.MetalDrum"] = {
    [UB_Const.WATER_LOW] = "useful_barrels_1_14",
    [UB_Const.WATER_HALF] = "useful_barrels_1_15",
    [UB_Const.WATER_FULL] = "useful_barrels_1_16",
}
SPRITE_MAP["Base.MetalDrum"][UB_Const.FACING_N] = {
    [UB_Const.DEFAULT] = "crafted_01_32",
    [UB_Const.LIDLESS] = "crafted_01_24",
    [UB_Const.LIDLESS_RUSTY] = "crafted_05_56"
}
SPRITE_MAP["Base.MetalDrum"][UB_Const.FACING_S] = {
    [UB_Const.DEFAULT] = "crafted_01_32",
    [UB_Const.LIDLESS] = "crafted_01_24"
}

SPRITE_MAP["Base.Mov_LightGreenBarrel"] = {
    [UB_Const.WATER_LOW] = "useful_barrels_1_11",
    [UB_Const.WATER_HALF] = "useful_barrels_1_12",
    [UB_Const.WATER_FULL] = "useful_barrels_1_13",
}
SPRITE_MAP["Base.Mov_LightGreenBarrel"][UB_Const.FACING_N] = {
    [UB_Const.DEFAULT] = "location_military_generic_01_6",
    [UB_Const.LIDLESS] = "useful_barrels_1_2",
    [UB_Const.LIDLESS_RUSTY] = "crafted_05_28"
}
SPRITE_MAP["Base.Mov_LightGreenBarrel"][UB_Const.FACING_S] = {
    [UB_Const.DEFAULT] = "location_military_generic_01_7",
    [UB_Const.LIDLESS] = "useful_barrels_1_3",
}

SPRITE_MAP["Base.Mov_OrangeBarrel"] = {
    [UB_Const.WATER_LOW] = "useful_barrels_1_5",
    [UB_Const.WATER_HALF] = "useful_barrels_1_6",
    [UB_Const.WATER_FULL] = "useful_barrels_1_7",
}
SPRITE_MAP["Base.Mov_OrangeBarrel"][UB_Const.FACING_N] = {
    [UB_Const.DEFAULT] = "industry_01_22",
    [UB_Const.LIDLESS] = "crafted_01_28",
    [UB_Const.LIDLESS_RUSTY] = "crafted_05_60"
}
SPRITE_MAP["Base.Mov_OrangeBarrel"][UB_Const.FACING_S] = {
    [UB_Const.DEFAULT] = "industry_01_23",
    [UB_Const.LIDLESS] = "useful_barrels_1_4",
}

SPRITE_MAP["Base.Mov_DarkGreenBarrel"] = {
    [UB_Const.WATER_LOW] = "useful_barrels_1_8",
    [UB_Const.WATER_HALF] = "useful_barrels_1_9",
    [UB_Const.WATER_FULL] = "useful_barrels_1_10",
}
SPRITE_MAP["Base.Mov_DarkGreenBarrel"][UB_Const.FACING_N] = {
    [UB_Const.DEFAULT] = "location_military_generic_01_14",
    [UB_Const.LIDLESS] = "useful_barrels_1_0",
    [UB_Const.LIDLESS_RUSTY] = "crafted_05_65"
}
SPRITE_MAP["Base.Mov_DarkGreenBarrel"][UB_Const.FACING_S] = {
    [UB_Const.DEFAULT] = "location_military_generic_01_15",
    [UB_Const.LIDLESS] = "useful_barrels_1_1",
}

UB_Const.SPRITE_MAP = SPRITE_MAP


return UB_Const