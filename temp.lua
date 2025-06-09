local component = require("component")
local projector = component.hologram
local nbt = require("nbt")
local zzlib = require("zzlib")
local args = {...}

local function convertSchematicToNBT(location)
    local schemFile = io.open(location, "rb")
    local rawData = schemFile:read("*all")
    schemFile:close()
    local decompressed = zzlib.gunzip(rawData)
    return nbt.readFromNBT(decompressed)
end

local function displayToHologram(schem)
    local width = schem.Schematic.Width
    local length = schem.Schematic.Length
    local height = schem.Schematic.Height
    local blocks = schem.Schematic.Blocks

    projector.clear()

    local byteData = ""

    for x = 0, 47, 1 do
        for z = 0, 47, 1 do
            for y = 0, 31, 1 do
                if x >= width or y >= height or z >= length then
                    byteData = byteData .. "\0"
                else
                    local index = ((y * length + z) * width + x) + 1
                    local block = blocks[index]

                    if (block ~= 0) then
                        byteData = byteData .. "\1"
                    else
                        byteData = byteData .. "\0"
                    end
                end
            end
        end
    end

    projector.setRaw(byteData)
end

local schemLocation = assert(args[1], "Missing '.schematic' file argument")
assert(string.find(schemLocation, ".\.schematic"), "The first argument must be a '.schematic.' filetype")
local schem = convertSchematicToNBT(schemLocation)
displayToHologram(schem)