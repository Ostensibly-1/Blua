return {
    Opcodes = {
        { Opcode = "MOVE",       Type = "iABC",  Mask = { B = "R", C = "N" } }, -- Copy a value between registers
        { Opcode = "LOADK",      Type = "iABx",  Mask = { Bx = "K" } },        -- Load a constant into a register
        { Opcode = "LOADBOOL",   Type = "iABC",  Mask = { B = "N", C = "N" } },-- Load a boolean into a register
        { Opcode = "LOADNIL",    Type = "iABC",  Mask = { B = "N", C = "N" } },-- Set a range of registers to nil
        { Opcode = "GETUPVAL",   Type = "iABC",  Mask = { B = "U", C = "N" } },-- Read an upvalue into a register
        { Opcode = "GETGLOBAL",  Type = "iABx",  Mask = { Bx = "K" } },        -- Read a global variable into a register
        { Opcode = "GETTABLE",   Type = "iABC",  Mask = { B = "R", C = "RK" } },-- Read a table element into a register
        { Opcode = "SETGLOBAL",  Type = "iABx",  Mask = { Bx = "K" } },        -- Write a register value into a global variable
        { Opcode = "SETUPVAL",   Type = "iABC",  Mask = { B = "U", C = "N" } },-- Write a register value into an upvalue
        { Opcode = "SETTABLE",   Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Write a register value into a table element
        { Opcode = "NEWTABLE",   Type = "iABC",  Mask = { B = "N", C = "N" } },-- Create a new table
        { Opcode = "SELF",       Type = "iABC",  Mask = { B = "R", C = "RK" } },-- Prepare an object method for calling
        { Opcode = "ADD",        Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Perform addition
        { Opcode = "SUB",        Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Perform subtraction
        { Opcode = "MUL",        Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Perform multiplication
        { Opcode = "DIV",        Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Perform division
        { Opcode = "MOD",        Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Perform modulus
        { Opcode = "POW",        Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Perform exponentiation
        { Opcode = "UNM",        Type = "iABC",  Mask = { B = "R", C = "N" } },-- Perform unary minus
        { Opcode = "NOT",        Type = "iABC",  Mask = { B = "R", C = "N" } },-- Perform logical NOT
        { Opcode = "LEN",        Type = "iABC",  Mask = { B = "R", C = "N" } },-- Get the length of a value
        { Opcode = "CONCAT",     Type = "iABC",  Mask = { B = "R", C = "R" } },-- Concatenate a range of registers
        { Opcode = "JMP",        Type = "iAsBx", Mask = { sBx = "N" } },       -- Perform an unconditional jump
        { Opcode = "EQ",         Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Test for equality
        { Opcode = "LT",         Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Test for less than
        { Opcode = "LE",         Type = "iABC",  Mask = { B = "RK", C = "RK" } },-- Test for less than or equal
        { Opcode = "TEST",       Type = "iABC",  Mask = { B = "N", C = "N" } },-- Boolean test, with conditional jump
        { Opcode = "TESTSET",    Type = "iABC",  Mask = { B = "R", C = "N" } },-- Boolean test with assignment
        { Opcode = "CALL",       Type = "iABC",  Mask = { B = "N", C = "N" } },-- Call a closure
        { Opcode = "TAILCALL",   Type = "iABC",  Mask = { B = "N", C = "N" } },-- Perform a tail call
        { Opcode = "RETURN",     Type = "iABC",  Mask = { B = "N", C = "N" } },-- Return from function call
        { Opcode = "FORLOOP",    Type = "iAsBx", Mask = { sBx = "N" } },       -- Iterate a numeric for loop
        { Opcode = "FORPREP",    Type = "iAsBx", Mask = { sBx = "N" } },       -- Initialization for a numeric for loop
        { Opcode = "TFORLOOP",   Type = "iABC",  Mask = { B = "N", C = "N" } },-- Iterate a generic for loop
        { Opcode = "SETLIST",    Type = "iABC",  Mask = { B = "N", C = "N" } },-- Set array elements in a table
        { Opcode = "CLOSE",      Type = "iABC",  Mask = { B = "N", C = "N" } },-- Close local variables used as upvalues
        { Opcode = "CLOSURE",    Type = "iABx",  Mask = { Bx = "N" } },       -- Create a closure
        { Opcode = "VARARG",     Type = "iABC",  Mask = { B = "N", C = "N" } },-- Assign vararg function arguments
    },
    Environment = _ENV;
}
