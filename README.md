The `schem-handler` library has been made to parse and utilize `.schematic` files for OpenComputers' Holographic Projector

### Usage
```lua
local component = require("component")
local projector = component.hologram
local serial = require("serialization")
local schemHandler = require("schem-handler")

-- The provided arguments aren't necessary
-- args[1] is a `.schematic` file location
-- colorIndex is for customizing how the byte array provided by schematicNBTtoByteArray is created ({[blockID] = paletteColor})
local args = {...}
-- Converts .schematic files to table versions of the ocntained NBT data
local schemNBT = schemHandler.schematicToNBT(args[1])
local colorIndex = serial.unserialize(args[2] or "{}")

projector.clear()
-- Converts the schematic NBT data to a byte array that a Holographic Projector would accept
-- the second argument is unnecessary but useful in customizing how certain blocks are represented
local byteData = schemHandler.schematicNBTtoByteArray(schemNBT, colorIndex)
projector.setRaw(byteData)
```

### Libraries:
- [zzlib](https://github.com/zerkman/zzlib)
- [Original libnbt](https://github.com/OpenPrograms/Magik6k-Programs/blob/master/libnbt/nbt.lua)
  - *NOTE: Currently used `nbt.lua` version was edited by Claude AI*