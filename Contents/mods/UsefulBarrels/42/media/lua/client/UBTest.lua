local function UBTestContext(player, context, worldobjects, test)


    --local componentScript = ComponentType.FluidContainer:CreateComponentScript()

    --local component = ComponentType.FluidContainer:CreateComponent()
    
    --local fluidFilter = FluidFilter.new()

    --component.whitelist = fluidFilter
    local scriptManager = getScriptManager()

    local gameEntityScript = scriptManager:getSpecificEntity("UB.Barrel")

    gameEntityScript:OnPostWorldDictionaryInit()

    local fluidContainerScript = gameEntityScript:getComponentScriptFor(ComponentType.FluidContainer)

    --local componentFromScript = ComponentType.FluidContainer:CreateComponentFromScript(componentScript)
 
    abe()
end

Events.OnFillWorldObjectContextMenu.Add(UBTestContext)