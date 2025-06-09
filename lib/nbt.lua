local math = math
local computer = require("computer")


local function toSigned16(value)
  if value >= 32768 then
    return value - 65536
  end
  return value
end

local function toSigned32(value)
  if value >= 2147483648 then
    return value - 4294967296
  end
  return value
end

local function createDataReader(rawData)
  local reader = {
    raw = {},
    pointer = 1,
    size = 0
  }
  
  for i = 1, #rawData do
    reader.raw[i] = rawData:sub(i, i)
  end
  reader.size = #reader.raw
  
  reader.move = function(self, size)
    size = size or 1
    self.pointer = self.pointer + size
  end

  reader.read = function(self, size)
    size = size or 1
    local result = 0
    for i = 1, size do
      if self.pointer > self.size then
        error("Attempting to read beyond end of data")
      end
      result = result * 256 + self.raw[self.pointer]:byte()
      self:move()
    end
    return result
  end
  
  reader.get = function(self, n)
    n = n or 1
    if self.pointer + n - 1 > self.size then
      error("Attempting to access beyond end of data")
    end
    return self.raw[self.pointer + n - 1]:byte()
  end

  reader.readByte = function(self)
    local result = self:read()
    if result >= 128 then
      return result - 256
    end
    return result
  end

  reader.readShort = function(self)
    local result = self:read(2)
    return toSigned16(result)
  end

  reader.readInt = function(self)
    local result = self:read(4)
    return toSigned32(result)
  end

  reader.readLong = function(self)
    local high = self:readInt()
    local low = self:read(4)
    
    if high < 0 then
      return high * 4294967296 + low - 4294967296
    end
    return high * 4294967296 + low
  end

  reader.readFloat = function(self)
    local bytes = {}
    for i = 1, 4 do
      bytes[i] = self:get(i)
    end
    self:move(4)
    
    local sign = bytes[1] >= 128 and -1 or 1
    local exponent = ((bytes[1] % 128) * 2) + math.floor(bytes[2] / 128)
    local mantissa = ((bytes[2] % 128) * 65536) + (bytes[3] * 256) + bytes[4]
    
    if exponent == 0 and mantissa == 0 then
      return 0
    elseif exponent == 255 then
      return mantissa == 0 and (sign * math.huge) or (0/0)
    end
    
    if exponent == 0 then
      return sign * math.ldexp(mantissa / 8388608, -126)
    else
      return sign * math.ldexp(1 + mantissa / 8388608, exponent - 127)
    end
  end

  reader.readDouble = function(self)
    local bytes = {}
    for i = 1, 8 do
      bytes[i] = self:get(i)
    end
    self:move(8)
    
    local sign = bytes[1] >= 128 and -1 or 1
    local exponent = ((bytes[1] % 128) * 16) + math.floor(bytes[2] / 16)
    
    local mantissa = 0
    mantissa = (bytes[2] % 16)
    for i = 3, 8 do
      mantissa = mantissa * 256 + bytes[i]
    end
    
    if exponent == 0 and mantissa == 0 then
      return 0
    elseif exponent == 2047 then
      return mantissa == 0 and (sign * math.huge) or (0/0)
    end
    
    if exponent == 0 then
      return sign * math.ldexp(mantissa / 4503599627370496, -1022)
    else
      return sign * math.ldexp(1 + mantissa / 4503599627370496, exponent - 1023)
    end
  end

  reader.readString = function(self)
    local length = self:readShort()
    if length < 0 then
      length = length + 65536
    end
    local result = ""
    for i = 1, length do
      result = result .. string.char(self:read())
    end
    return result
  end

  reader.readByteArray = function(self)
    local result = {}
    local length = self:readInt()
    if length < 0 then
      error("Invalid byte array length: " .. length)
    end
    for i = 1, length do
      result[i] = self:readByte()
    end
    return result
  end

  reader.readList = function(self)
    local result = {}
    local typeId = self:read()
    local length = self:readInt()
    
    if length < 0 then
      error("Invalid list length: " .. length)
    end
    
    local fun = reader.readFun[typeId]
    if not fun then
      error("Unknown NBT type ID: " .. typeId)
    end
    
    for i = 1, length do
      result[i] = fun(self)
    end
    return result
  end

  reader.readIntArray = function(self)
    local result = {}
    local length = self:readInt()
    if length < 0 then
      error("Invalid int array length: " .. length)
    end
    for i = 1, length do
      result[i] = self:readInt()
    end
    return result
  end

  reader.readCompound = function(self)
    local result = {}
    while self.pointer <= self.size do
      local id = self:read()
      if id == 0 then return result end
      local name = self:readString()
      local fun = self.readFun[id]
      if not fun then
        error("Unknown NBT type ID: " .. id .. " for field '" .. name .. "'")
      end
      result[name] = fun(self)
    end
    return result
  end

  reader.readFun = {
    [1] = reader.readByte,
    [2] = reader.readShort,
    [3] = reader.readInt,
    [4] = reader.readLong,
    [5] = reader.readFloat,
    [6] = reader.readDouble,
    [7] = reader.readByteArray,
    [8] = reader.readString,
    [9] = reader.readList,
    [10] = reader.readCompound,
    [11] = reader.readIntArray
  }
  
  return reader
end

return {
  readFromNBT = function(rawData)
    local reader = createDataReader(rawData)
    return reader:readCompound()
  end
}