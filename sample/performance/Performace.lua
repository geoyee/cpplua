perfCpp = require("libperformance")

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