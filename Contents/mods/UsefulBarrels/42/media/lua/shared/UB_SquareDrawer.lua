-- Code by Rodriguo

local enabled = true
local highlightsSquares = {}

function AddHighlightSquare(square, ISColors)
    if not square or not ISColors then return end
    table.insert(highlightsSquares, {square = square, color = ISColors})
end

local function RenderHighLights()
    if not enabled then return end

    if #highlightsSquares == 0 then return end
    for _, highlight in ipairs(highlightsSquares) do
        if highlight.square ~= nil and instanceof(highlight.square, "IsoGridSquare") then
            local x,y,z = highlight.square:getX(), highlight.square:getY(), highlight.square:getZ()
            local r,g,b,a = highlight.color.r, highlight.color.g, highlight.color.b, 0.8

            local floorSprite = IsoSprite.new()
            floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
            floorSprite:RenderGhostTileColor(x, y, z, r, g, b, a)
        else
            print("Invalid square")
        end
    end
end

Events.OnPostRender.Add(RenderHighLights)