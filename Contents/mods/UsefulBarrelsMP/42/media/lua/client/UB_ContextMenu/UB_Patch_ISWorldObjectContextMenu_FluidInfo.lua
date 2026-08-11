local _onFluidInfo = ISWorldObjectContextMenu.onFluidInfo

function ISWorldObjectContextMenu.onFluidInfo(player, fluidcontainer)
    if not fluidcontainer then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local entity = fluidcontainer:getGameEntity()
    if entity and instanceof(entity, "IsoObject") then
        if luautils.walkAdjObject(playerObj, entity, true) then
            local c = ISFluidContainer:new(fluidcontainer)
            ISTimedActionQueue.add(ISFluidPanelAction:new(playerObj, c, ISFluidInfoUI))
        end
        return
    end

    return _onFluidInfo(player, fluidcontainer)
end