package.path = package.path .. ";./?.lua;./Main/?.lua;./Main/Compiler/?.lua;./Main/Decompiler/?.lua;./Main/VM/?.lua;./Main/Lua51Libs/?.lua"

local console = require("Logger")
local Blua = require("Blua")

local LuaFile = io.open("./Script.lua", "r")
if not LuaFile then error("[BLUA] - Missing Lua File 'Script.lua'!") end
local LuaCode = LuaFile:read("*a");
LuaFile:close()

return Blua(LuaCode)