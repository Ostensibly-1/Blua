local console = require("Logger")

local Compiler = require("Compiler")
local Decompiler = require("Decompiler")
local Interpret = require("Interpreter")

local State = {}

return function(LuaCode)
    local Compiled = Compiler(LuaCode, "BluaTemp.lua");
    local DecompileProc = Decompiler:New(Compiled)
    local TopFunc = DecompileProc:Decompile()
    
    -- console.log(TopFunc)

    return Interpret(TopFunc)()
end;