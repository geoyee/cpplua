--[[
    If require doesn't use local variables to save, and uses global variables instead
    Can be used in C++ with `sol::function fibonacciNLuaC = lua["perfCpp"]["fibonacciNC"]`
]]
local perfCpp = require("libperformance")

function fibonacci(n)
    if n <= 1 then
        return n
    end
    return fibonacci(n - 1) + fibonacci(n - 2)
end

function fibonacciN(m)
    local res = 0
    for i = 1, m do
        res = res + fibonacci(i)
    end
    return res
end

function fibonacciCpp(n)
    return perfCpp.fibonacciC(n)
end

function fibonacciNCpp(m)
    return perfCpp.fibonacciNC(m)
end