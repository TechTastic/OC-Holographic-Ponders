local component = require("component")
local projector = component.hologram
local nbt = require("nbt_ai")
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
    local width = math.min(schem.Schematic.Width, 64)
    local length = math.min(schem.Schematic.Length, 64)
    local height = math.min(schem.Schematic.Height, 48)
    local blocks = schem.Schematic.Blocks

    projector.clear()

    for x = 1, width + 1, 1 do
        for z = 1, length + 1, 1 do
            for y = 1, height + 1, 1 do
                local index = (((y - 1) * length + (z - 1)) * width + (x - 1)) + 1
                local block = blocks[index] or 0

                if (block ~= 0) then
                    print("Block ID " .. tostring(block) .. " at " .. tostring(index))
                    print("X: " .. tostring(x) .. ", Y: " .. tostring(y) .. ", Z: " .. tostring(z))

                    projector.set(x, y, z, 1)
                end
            end
        end
    end
end

local schemLocation = assert(args[1], "Missing .schematic file argument")
local schem = convertSchematicToNBT(schemLocation)
displayToHologram(schem)