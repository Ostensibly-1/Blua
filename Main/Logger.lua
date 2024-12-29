-- Logger.lua
-- Copyright OxidaneDev 2024
-- This module imitates "console.log" from javascript
-- Usage: require("Logger").log("Hello World", 2, {Hi = "Hello"})

local console = {}
console.__index = console

function console.log(...)
    local printValue
    local function printTable(t, indent)
        indent = indent or ""
        if type(t) ~= "table" then
            io.write(tostring(t))
            return
        end
        io.write("{\n")
        for k, v in pairs(t) do
            io.write(indent, "  ", tostring(k), ": ")
            if type(v) == "table" then
                printTable(v, indent .. "  ")
            else
                printValue(v)
            end
            io.write(",\n")
        end
        io.write(indent, "}")
    end

    printValue = function (value)
        if type(value) == "string" then
            io.write("\27[32m\"" .. tostring(value) .. "\"\27[0m")
        elseif type(value) == "number" then
            io.write("\27[33m" .. tostring(value) .. "\27[0m")
        else
            io.write(tostring(value))
        end
    end

    local args = {...}
    for i = 1, #args do
        if type(args[i]) == "table" then
            printTable(args[i])
        else
            printValue(args[i])
        end
        if i < #args then
            io.write(" ")
        end
    end
    io.write("\n")
end

return console