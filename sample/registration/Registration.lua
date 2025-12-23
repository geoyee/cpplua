defindedAPIs = {
    Add = function(a, b) return a + b end,
    Subtract = function(a, b) return a - b end,
    Multiply = function(a, b) return a * b end,

    Divide = function(a, b) 
        if b == 0 then 
            return nil 
        else 
            return a / b 
        end 
    end,

    --[[ Connect = function(a, b)
        local intA = math.floor(a)
        local intB = math.floor(b)
        return tonumber(intA .. intB)
    end, ]]
}