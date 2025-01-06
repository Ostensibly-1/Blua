local Reader = require("Buffer")
local Enums = require("Enums")

local Decompiler = {}
Decompiler.__index = Decompiler

function Decompiler:New(Bytecode)
    return setmetatable({
        Bytecode = Bytecode,
        Stream = Reader:New(Bytecode)
    }, Decompiler)
end

function Decompiler:Decompile()
    local Header = {
        self.Stream:ReadStringLen(4), -- Signature
        self.Stream:ReadInt8(),       -- Lua Version
        self.Stream:ReadInt8(),       -- Format Version
        self.Stream:ReadInt8(),       -- Endianness
        self.Stream:ReadInt8(),       -- Int size 4/8
        self.Stream:ReadInt8(),       -- size_t size 4/8
        self.Stream:ReadInt8(),       -- Inst size
        self.Stream:ReadInt8(),       -- lua_number size
        self.Stream:ReadInt8(),       -- integral flag
    }

    -- print(table.concat(Header, ", "))

    assert(Header[1] == "\27Lua", "[BLUA] - This is not lua bytecode")
    assert(Header[2] == 0x51, "[BLUA] - This is not the correct lua version")
    assert(Header[3] == 0, "[BLUA] - This format version is not supported or not available by lua")

    self.Stream.LittleEndian = Header[4] == 1
    self.Stream.IntSize = Header[5]
    self.Stream.SizeTSize = Header[6]

    local function DecompileInstruction(Data)
        local OpNum = Data & 0x3F
        local OpCode = Enums.Opcodes[OpNum + 1]
        local IsConstantB = false
        local IsConstantC = false
        local RegisterA = ((Data >> 6) & 0xFF)
        local RegisterB = -1
        local RegisterC = -1

        if OpCode.Type == "iABC" then
            RegisterB = ((Data >> 23) & 0x1FF)
            RegisterC = ((Data >> 14) & 0x1FF)

            if OpCode.Mask.B == "RK" then
                IsConstantB = (RegisterB & 0x100) ~= 0
                if IsConstantB then
                    RegisterB = RegisterB & 0xFF
                end
            end

            if OpCode.Mask.C == "RK" then
                IsConstantC = (RegisterC & 0x100) ~= 0
                if IsConstantC then
                    RegisterC = RegisterC & 0xFF
                end
            end
        elseif OpCode.Type == "iABx" then
            RegisterB = ((Data >> 14) & 0x3FFFF)
            ---@diagnostic disable-next-line: cast-local-type
            RegisterC = nil
            IsConstantB = OpCode.Mask.Bx == "K"
        elseif OpCode.Type == "iAsBx" then
            RegisterB = ((Data >> 14) & 0x3FFFF) - 131071
        end

        return {
            OP_NAME = OpCode.Opcode,
            OP_TYPE = OpCode.Type,
            OP_MASK = { [string.format("%s", OpCode.Type == "iABC" and "B" or OpCode.Type == "iABx" and "Bx" or "sBx")] = OpCode.Mask.B or OpCode.Mask.Bx, C = OpCode.Type == "iABC" and OpCode.Mask.C or -math.huge },
            OP_DATA = Data,
            OP_REGISTER_A = RegisterA,
            OP_REGISTER_B = RegisterB,
            OP_REGISTER_C = RegisterC,
            [string.format("%s", OpCode.Type == "iABC" and "OP_IS_KB" or "OP_IS_K")] = IsConstantB,
            OP_IS_KC = IsConstantC,
        }
    end

    local function DecompileConstant(TypeCode)
        local K

        if TypeCode == 0 then
            K = "nil"
        elseif TypeCode == 1 then
            K = self.Stream:ReadInt8() == 1
        elseif TypeCode == 3 then
            K = self.Stream:ReadDouble()
        elseif TypeCode == 4 then
            K = self.Stream:ReadString()
            K = string.sub(K, 1, #K - 1)
        end

        return {
            K_DATA = K,
            K_TYPE = TypeCode,
        }
    end;

    local function DecompileChunk()
        local Chunk = { -- at the main code, this would be the top function
            SOURCE_NAME = self.Stream:ReadString(),
            STARTING_LINE = self.Stream:ReadInt(),
            ENDING_LINE = self.Stream:ReadInt(),
            UPVALUE_COUNT = self.Stream:ReadInt8(),
            PARAMETER_COUNT = self.Stream:ReadInt8(),
            VARARG_FLAG = self.Stream:ReadInt8(),
            MAX_STACK_SIZE = self.Stream:ReadInt8(),
            INSTRUCTION_LIST = {},
            CONSTANT_LIST = {},
            PROTOTYPE_LIST = {},
            SOURCE_LINE_LIST = {},
            LOCAL_VARIABLES_LIST = {},
            UPVALUE_NAMES_LIST = {}
        }

        local InstrLength = self.Stream:ReadInt()
        for Idx = 1, InstrLength do
            local Data = self.Stream:ReadInt()
            Chunk.INSTRUCTION_LIST[Idx] = DecompileInstruction(Data)
        end

        local ConstLength = self.Stream:ReadInt()
        for Idx = 1, ConstLength do
            local TypeCode = self.Stream:ReadInt8()
            Chunk.CONSTANT_LIST[Idx - 1] = DecompileConstant(TypeCode)
        end

        local ProtoLength = self.Stream:ReadInt()
        for Idx = 1, ProtoLength do
            Chunk.PROTOTYPE_LIST[Idx - 1] = DecompileChunk()
        end

        -- Debug
        do
            local SLineLength = self.Stream:ReadInt()
            for Idx = 1, SLineLength do
                Chunk.SOURCE_LINE_LIST[Idx] = self.Stream:ReadInt()
            end

            local LocalLength = self.Stream:ReadInt()
            for IDx = 1, LocalLength do
                Chunk.LOCAL_VARIABLES_LIST[IDx] = {
                    VAR_NAME = self.Stream:ReadString(),
                    STARTING_POSITION = self.Stream:ReadInt(),
                    ENDING_POSITION = self.Stream:ReadInt()
                }
            end

            local UpvalLength = self.Stream:ReadInt()
            for Idx = 1, UpvalLength do
                Chunk.UPVALUE_NAMES_LIST[Idx] = UpvalLength
            end
        end

        do -- post process optimization
            Chunk.NEEDS_ARG = (Chunk.VARARG_FLAG & 0x5) == 0x5
            for Idx, Instruction in ipairs(Chunk.INSTRUCTION_LIST) do
                if Instruction.OP_IS_K == true then
                    Instruction.OP_CONSTANT = Chunk.CONSTANT_LIST[Instruction.OP_REGISTER_B]
                else
                    if Instruction.OP_IS_KB == true then
                        if Instruction.OP_MASK.B == "RK" then -- i made a silly oppsie here before...
                            Instruction.OP_CONSTANT_B = Chunk.CONSTANT_LIST[Instruction.OP_REGISTER_B - 0xFF]
                        elseif Instruction.OP_MASK.B == "K" then
                            Instruction.OP_CONSTANT_B = Chunk.CONSTANT_LIST[Instruction.OP_REGISTER_B]
                        end
                    end

                    if Instruction.OP_IS_KC == true then
                        if Instruction.OP_MASK.C == "RK" then
                            Instruction.OP_CONSTANT_C = Chunk.CONSTANT_LIST[Instruction.OP_REGISTER_C - 0xFF]
                        elseif Instruction.OP_MASK.C == "K" then
                            Instruction.OP_CONSTANT_C = Chunk.CONSTANT_LIST[Instruction.OP_REGISTER_C]
                        end
                    end
                end
            end
        end

        return Chunk;
    end;

    return DecompileChunk()
end;

return Decompiler
