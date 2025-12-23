function inspect(data)
    return data.mode == 3
    
    --[[ local centerX = 150
    local centerY = 25
    local radius = 0.00001
    local distanceSquared = (data.x - centerX)^2 + (data.y - centerY)^2
    return distanceSquared <= radius^2 ]]
end