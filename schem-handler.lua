local nbt = require("nbt") or error("Needs 'nbt' library to function")
local zzlib = require("zzlib") or error("Needs 'zzlib' library to function")

local handler = {
    MAX_WIDTH = 48,
    MAX_LENGTH = 48,
    MAX_HEIGHT = 32,
    
    AIR_BLOCK_ID = 0
}

handler.schematicToNBT = function(schemLocation)
    assert(schemLocation, "Missing '.schematic' file argument")
    assert(string.find(schemLocation, ".schematic"), "The first argument must be a '.schematic.' filetype")

    local schemFile = io.open(schemLocation, "rb")
    local rawData = schemFile:read("*all")
    schemFile:close()
    local decompressed = zzlib.gunzip(rawData)
    return nbt.readFromNBT(decompressed)
end

handler.schematicNBTtoByteArray = function(nbt, colorIndex)
    assert(nbt, "Missing Schematic NBT table")
    assert(nbt.Schematic, "Malformed Schematic NBT")

    colorIndex = colorIndex or {}

    local width = nbt.Schematic.Width
    local length = nbt.Schematic.Length
    local height = nbt.Schematic.Height
    local blocks = nbt.Schematic.Blocks

    local byteData = ""

    for x = 0, handler.MAX_WIDTH - 1, 1 do
        for z = 0, handler.MAX_LENGTH - 1, 1 do
            for y = 0, handler.MAX_HEIGHT - 1, 1 do
                if x >= width or y >= height or z >= length then
                    byteData = byteData .. "\0"
                else
                    local index = ((y * length + z) * width + x) + 1
                    local block = blocks[index]

                    if (block ~= handler.AIR_BLOCK_ID) then
                        byteData = byteData .. string.char(colorIndex[block] or 1)
                    else
                        byteData = byteData .. "\0"
                    end
                end
            end
        end
    end

    return byteData
end

return handler