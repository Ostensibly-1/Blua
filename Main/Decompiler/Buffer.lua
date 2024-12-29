local Reader = {}
Reader.__index = Reader

function Reader:New(Buffer)
    return setmetatable({
        Buffer = Buffer,
        Pos = 1,
        IntSize = 4,
        SizeTSize = 4,
        LittleEndian = true
    }, Reader)
end

function Reader:ReadInt8()
    local ReturnValue = string.byte(self.Buffer, self.Pos, self.Pos)
    self.Pos = self.Pos + 1
    return ReturnValue
end

function Reader:ReadInt32()
    local R1, R2, R3, R4 = string.byte(self.Buffer, self.Pos, self.Pos + 3)
    self.Pos = self.Pos + 4

    if self.LittleEndian then
        return (R4 * 16777216) + (R3 * 65536) + (R2 * 256) + R1
    else
        return (R1 * 16777216) + (R2 * 65536) + (R3 * 256) + R4
    end
end

function Reader:ReadInt64()
    local R1 = self:ReadInt32()
    local R2 = self:ReadInt32()

    if self.LittleEndian then
        return (R2 * 2^32) + R1
    else
        return (R1 * 2^32) + R2
    end
end

-- Read IEEE 754 Double (Little Endian)
function Reader:ReadDoubleLE()
    local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(self.Buffer, self.Pos, self.Pos + 7)
    self.Pos = self.Pos + 8

    local i = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216 +
              b5 * 2^32 + b6 * 2^40 + b7 * 2^48 + b8 * 2^56

    local sign = ((i >> 63) == 1) and -1 or 1
    local exponent = ((i >> 52) & 0x7FF) - 1023
    local mantissa = i & 0xFFFFFFFFFFFFF

    if exponent == 1024 then
        return (mantissa == 0) and (sign * math.huge) or (0 / 0) -- Infinity or NaN
    elseif exponent == -1023 then
        return sign * (mantissa / 2^52) * 2^-1022
    else
        return sign * (1 + mantissa / 2^52) * 2^exponent
    end
end

-- Read IEEE 754 Double (Big Endian)
function Reader:ReadDoubleBE()
    local b8, b7, b6, b5, b4, b3, b2, b1 = string.byte(self.Buffer, self.Pos, self.Pos + 7)
    self.Pos = self.Pos + 8

    local i = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216 +
              b5 * 2^32 + b6 * 2^40 + b7 * 2^48 + b8 * 2^56

    local sign = ((i >> 63) == 1) and -1 or 1
    local exponent = ((i >> 52) & 0x7FF) - 1023
    local mantissa = i & 0xFFFFFFFFFFFFF

    if exponent == 1024 then
        return (mantissa == 0) and (sign * math.huge) or (0 / 0) -- Infinity or NaN
    elseif exponent == -1023 then
        return sign * (mantissa / 2^52) * 2^-1022
    else
        return sign * (1 + mantissa / 2^52) * 2^exponent
    end
end

function Reader:ReadDouble()
    if (self.LittleEndian == true) then
        return self:ReadDoubleLE()
    else
        return self:ReadDoubleBE()
    end
end;

function Reader:ReadInt()
    if (self.IntSize == 4) then
        return self:ReadInt32()
    elseif (self.IntSize == 8) then
        return self:ReadInt64()
    else
        error("[BLUA] - Reading error, Int size is denied by Int reader! This was not supposed to happen", 1)
    end
end;

function Reader:ReadSizeT()
    if (self.SizeTSize == 4) then
        return self:ReadInt32()
    elseif (self.SizeTSize == 8) then
        return self:ReadInt64()
    else
        error("[BLUA] - Reading error, size_t size is denied by size_t reader! This was not supposed to happen", 1)
    end
end;

function Reader:ReadStringLen(Len)
    local String = string.sub(self.Buffer, self.Pos, self.Pos + Len - 1)
    self.Pos = self.Pos + Len;
    return String;
end

function Reader:ReadString()
    local Len = self:ReadSizeT()
    return self:ReadStringLen(Len)
end

return Reader;