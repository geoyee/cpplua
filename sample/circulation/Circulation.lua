require("libcirculation")

function circulat(point)
    return point:destination(2, math.rad(45))
end