_ENV = _ENV

local Interpret, New

-- local Config = require("Config")

-- Helpers // Thanks fione!
local function CloseUpvals(list, index)
    for i, uv in pairs(list) do
        if uv.index >= index then
            uv.value = uv.store[uv.index]
            uv.store = uv
            uv.index = 'value'
            list[i] = nil
        end
    end
end

local function OpenUpval(list, index, memory)
    local prev = list[index]

    if not prev then
        prev = { index = index, store = memory }
        list[index] = prev
    end

    return prev
end

function Interpret(State, Upvalues)
    local INSTRUCTION_LIST = State.Instructions
    local PROTOTYPE_LIST = State.Prototypes
    local VARARG = State.Vararg

    local Top = -1
    local OpenList = {}
    local Stack = State.Stack;
    local Pc = State.ProgramCounter;

    while true do
        local Instruction = INSTRUCTION_LIST[Pc]
        local Op = Instruction["OP_NAME"]
        Pc = Pc + 1

        if Op == "RETURN" then
            local Length;

            if Instruction.OP_REGISTER_B == 0 then
                Length = Top - Instruction.OP_REGISTER_A + 1
            else
                Length = Instruction.OP_REGISTER_B - 1
            end

            CloseUpvals(OpenList, 0)

            return table.unpack(Stack, Instruction.OP_REGISTER_A, Instruction.OP_REGISTER_A + Length - 1);
        elseif Op == "MOVE" then
            Stack[Instruction.OP_REGISTER_A] = Stack[Instruction.OP_REGISTER_B]
        elseif Op == "LOADNIL" then
            for Idx = Instruction.OP_REGISTER_A, Instruction.OP_REGISTER_B do
                Stack[Idx] = nil;
            end
        elseif Op == "LOADK" then
            Stack[Instruction.OP_REGISTER_A] = Instruction.OP_CONSTANT.K_DATA
        elseif Op == "LOADBOOL" then
            Stack[Instruction.OP_REGISTER_A] = Instruction.OP_REGISTER_B == 1 and true or false;
            if Instruction.OP_REGISTER_C ~= 0 then
                Pc = Pc + 1
            end
        elseif Op == "GETGLOBAL" then
            Stack[Instruction.OP_REGISTER_A] = _ENV[Instruction.OP_CONSTANT.K_DATA]
        elseif Op == "SETGLOBAL" then
            _ENV[Instruction.OP_CONSTANT.K_DATA] = Instruction.OP_REGISTER_A
        elseif Op == "GETUPVAL" then
            Stack[Instruction.OP_REGISTER_A] = Upvalues[Instruction.OP_REGISTER_B].store
            [Upvalues[Instruction.OP_REGISTER_B].index]
        elseif Op == "SETUPVAL" then
            Upvalues[Instruction.OP_REGISTER_B].store[Upvalues[Instruction.OP_REGISTER_B].index] = Stack
            [Instruction.OP_REGISTER_A]
        elseif Op == "GETTABLE" then
            Stack[Instruction.OP_REGISTER_A] = Stack[Instruction.OP_REGISTER_B][(Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA) or (Stack[Instruction.OP_REGISTER_C])]
        elseif Op == "SETTABLE" then
            Stack[Instruction.OP_REGISTER_A][(
                Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]
            )] = (
                Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C]
            )
        elseif Op == "ADD" then
            Stack[Instruction.OP_REGISTER_A] = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]) +
            (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
        elseif Op == "SUB" then
            Stack[Instruction.OP_REGISTER_A] = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]) -
            (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
        elseif Op == "MUL" then
            Stack[Instruction.OP_REGISTER_A] = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]) *
            (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
        elseif Op == "DIV" then
            Stack[Instruction.OP_REGISTER_A] = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]) /
            (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
        elseif Op == "MOD" then
            Stack[Instruction.OP_REGISTER_A] = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]) %
            (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
        elseif Op == "POW" then
            Stack[Instruction.OP_REGISTER_A] = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B.K_DATA or Stack[Instruction.OP_REGISTER_B]) ^
            (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
        elseif Op == "UNM" then
            Stack[Instruction.OP_REGISTER_A] = -Stack[Instruction.OP_REGISTER_B]
        elseif Op == "NOT" then
            Stack[Instruction.OP_REGISTER_A] = not Stack[Instruction.OP_REGISTER_B]
        elseif Op == "LEN" then
            Stack[Instruction.OP_REGISTER_A] = #Stack[Instruction.OP_REGISTER_B]
        elseif Op == "CONCAT" then
            for Idx = Instruction.OP_REGISTER_B + 1, Instruction.OP_REGISTER_C do
                Stack[Instruction.OP_REGISTER_B] = Stack[Instruction.OP_REGISTER_B] .. Stack[Idx]
            end
            Stack[Instruction.OP_REGISTER_A] = Stack[Instruction.OP_REGISTER_B]
        elseif Op == "JMP" then
            Pc = Pc + Instruction.OP_REGISTER_B;
        elseif Op == "CALL" then
            local Parameters;

            if Instruction.OP_REGISTER_B == 0 then
                Parameters = Top - Instruction.OP_REGISTER_A
            else
                Parameters = Instruction.OP_REGISTER_B - 1;
            end

            local ReturnList = table.pack(
                Stack[Instruction.OP_REGISTER_A](
                    table.unpack(
                        Stack,
                        Instruction.OP_REGISTER_A + 1,
                        Instruction.OP_REGISTER_A + Parameters
                    )
                )
            )
            local RLn = ReturnList.n

            if Instruction.OP_REGISTER_C == 0 then
                Top = Instruction.OP_REGISTER_A + RLn - 1
            else
                RLn = Instruction.OP_REGISTER_C - 1
            end

            table.move(ReturnList, 1, RLn, Instruction.OP_REGISTER_A, Stack)
        elseif Op == "TAILCALL" then
            local Parameters = Instruction.OP_REGISTER_B == 0 and Top - Instruction.OP_REGISTER_A or
            Instruction.OP_REGISTER_B - 1

            CloseUpvals(OpenList, 0)

            return Stack[Instruction.OP_REGISTER_A](
                table.unpack(
                    Stack,
                    Instruction.OP_REGISTER_A + 1,
                    Instruction.OP_REGISTER_A + Parameters
                )
            )
        elseif Op == "VARARG" then
            if Instruction.OP_REGISTER_B == 0 then
                Instruction.OP_REGISTER_B = VARARG.Length;
                Top = Instruction.OP_REGISTER_A + Instruction.OP_REGISTER_B - 1
            end

            table.move(VARARG.List, 1, Instruction.OP_REGISTER_B, Instruction.OP_REGISTER_A, Stack)
        elseif Op == "SELF" then
            local Index = (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C.K_DATA or Stack[Instruction.OP_REGISTER_C])
            Stack[Instruction.OP_REGISTER_A + 1] = Stack[Instruction.OP_REGISTER_B]
            Stack[Instruction.OP_REGISTER_A] = Stack[Instruction.OP_REGISTER_B][Index]
        elseif Op == "EQ" then
            local LHS, RHS = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B or Stack[Instruction.OP_REGISTER_B]), (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C or Stack[Instruction.OP_REGISTER_C])

            if (LHS == RHS) == (Instruction.OP_REGISTER_A ~= 0) then Pc = Pc + INSTRUCTION_LIST[Pc].OP_REGISTER_B end

            Pc = Pc + 1
        elseif Op == "LT" then
            local LHS, RHS = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B or Stack[Instruction.OP_REGISTER_B]), (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C or Stack[Instruction.OP_REGISTER_C])

            if (LHS < RHS) == (Instruction.OP_REGISTER_A ~= 0) then Pc = Pc + INSTRUCTION_LIST[Pc].OP_REGISTER_B end

            Pc = Pc + 1
        elseif Op == "LE" then
            local LHS, RHS = (Instruction.OP_IS_KB and Instruction.OP_CONSTANT_B or Stack[Instruction.OP_REGISTER_B]), (Instruction.OP_IS_KC and Instruction.OP_CONSTANT_C or Stack[Instruction.OP_REGISTER_C])

            if (LHS <= RHS) == (Instruction.OP_REGISTER_A ~= 0) then Pc = Pc + INSTRUCTION_LIST[Pc].OP_REGISTER_B end

            Pc = Pc + 1
        elseif Op == "TEST" then
            if (not Stack[Instruction.OP_REGISTER_A]) ~= (Instruction.OP_REGISTER_C ~= 0) then
                Pc = Pc + INSTRUCTION_LIST[Pc].OP_REGISTER_B
            end
            Pc = Pc + 1
        elseif Op == "TESTSET" then
            if (not Stack[Instruction.OP_REGISTER_B]) ~= (Instruction.OP_REGISTER_C ~= 0) then
                Stack[Instruction.OP_REGISTER_A] = Stack[Instruction.OP_REGISTER_B]
                Pc = Pc + INSTRUCTION_LIST[Pc].OP_REGISTER_B
            end
            Pc = Pc + 1
        elseif Op == "FORPREP" then
            local A = Instruction.OP_REGISTER_A
            local RangeStart, RangeEnd, RangeStep;

            RangeStart = assert(tonumber(Stack[A]), '[BLUA] - `for` initial value must be a number')
            RangeEnd = assert(tonumber(Stack[A + 1]), '[BLUA] - `for` limit must be a number')
            RangeStep = assert(tonumber(Stack[A + 2]), '[BLUA] - `for` step must be a number')

            Stack[A] = RangeStart - RangeStep
            Stack[A + 1] = RangeEnd
            Stack[A + 2] = RangeStep

            Pc = Pc + Instruction.OP_REGISTER_B;
        elseif Op == "FORLOOP" then
            local A = Instruction.OP_REGISTER_A
            local RangeStep = Stack[A + 2]
            local Index = Stack[A] + RangeStep
            local RangeEnd = Stack[A + 1]
            local Loops

            if RangeStep >= 0 then
                Loops = Index <= RangeEnd
            else
                Loops = Index >= RangeEnd
            end

            if Loops then
                Stack[A] = Index;
                Stack[A + 3] = Index;
                Pc = Pc + Instruction.OP_REGISTER_B
            end
        elseif Op == "TFORLOOP" then
            local A = Instruction.OP_REGISTER_A
            local Base = A + 3

            local Values = {
                Stack[A](
                    Stack[A + 1],
                    Stack[A + 2]
                )
            }

            table.move(Values, 1, Instruction.OP_REGISTER_C, Base, Stack)

            if Stack[Base] ~= nil then
                Stack[A + 2] = Stack[Base]
                Pc = Pc + INSTRUCTION_LIST[Pc].OP_REGISTER_B
            end

            Pc = Pc + 1
        elseif Op == "NEWTABLE" then
            Stack[Instruction.OP_REGISTER_A] = {}
        elseif Op == "SETLIST" then
            local Tab = Stack[Instruction.OP_REGISTER_A]
            local Offset

            if Instruction.OP_REGISTER_B == 0 then
                Instruction.OP_REGISTER_B = Top - Instruction.OP_REGISTER_A
            end

            if Instruction.OP_REGISTER_C == 0 then
                Instruction.OP_REGISTER_C = INSTRUCTION_LIST[Pc].OP_DATA;
                Pc = Pc + 1;
            end

            Offset = (Instruction.OP_REGISTER_C - 1) * 50

            table.move(Stack, Instruction.OP_REGISTER_A + 1, Instruction.OP_REGISTER_A + Instruction.OP_REGISTER_B, Offset + 1, Tab);
        elseif Op == "CLOSURE" then
            local Prototype = PROTOTYPE_LIST[Instruction.OP_REGISTER_B]
            local UpvalueCount = Prototype.UPVALUE_COUNT;
            local UVList;

            if UpvalueCount ~= 0 then
                UVList = {}

                for Idx = 1, UpvalueCount do
                    local Pseudo = INSTRUCTION_LIST[Pc + Idx - 1]
                    if Pseudo.OP_NAME == "MOVE" then
                        UVList[Idx - 1] = OpenUpval(OpenList, Pseudo.OP_REGISTER_B, Stack)
                    elseif Pseudo.OP_NAME == "GETUPVAL" then
                        UVList[Idx - 1] = Upvalues[Pseudo.OP_REGISTER_B]
                    end
                end

                Pc = Pc + UpvalueCount
            end

            Stack[Instruction.OP_REGISTER_A] = New(Prototype, UVList)
        elseif Op == "CLOSE" then
            CloseUpvals(OpenList, Instruction.OP_REGISTER_A)
        end
    end
end;

function New(Chunk, Upvalues)
    local function Wrap(...)
        local Passed = table.pack(...)
        local Stack = {}
        local Vararg = {
            List = {},
            Length = 0
        }
    
        table.move(Passed, 1, Chunk.PARAMETER_COUNT, 0, Stack)
    
        if Chunk.PARAMETER_COUNT < Passed.n then
            local Start = Chunk.PARAMETER_COUNT + 1
            local Length = Passed.n - Chunk.PARAMETER_COUNT
    
            Vararg.Length = Length
            table.move(Passed, Start, Start + Length - 1, 1, Vararg.List)
        end
    
        if Chunk.NEEDS_ARG then
            Stack[Chunk.PARAMETER_COUNT] = {
                n = Vararg.Length,
                table.unpack(Vararg.List, 1, Vararg.Length)
            }
        end
    
        local State = {
            Vararg = Vararg,
            Stack = Stack,
            Instructions = Chunk.INSTRUCTION_LIST,
            Prototypes = Chunk.PROTOTYPE_LIST,
            ProgramCounter = 1
        }
    
        return Interpret(State, Upvalues)
    end;

    return Wrap;
end

return New