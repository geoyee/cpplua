#include "lib.h"
#include <sol/sol.hpp>
#include <iostream>

int main()
{
    sol::state lua;
    luaL_openlibs(lua);

    try
    {
        lua.script_file("Circulation.lua");
        sol::function circulatFunc = lua["circulat"];
        if (!circulatFunc.valid())
        {
            std::cerr << "Lua function 'circulat' not found" << std::endl;
            return -1;
        }

        Point p1{0, 0}, p2;
        sol::protected_function_result result = circulatFunc(p1);
        if (result.valid())
        {
            p2 = result.get<Point>();
            double dis = p1.distance(p2);
            std::cout << "p1(0,0) => p2(" << p2.x << "," << p2.y << ") and distance is " << dis << std::endl;
        }
        else
        {
            std::cerr << "Failed of call Lua function 'circulat'" << std::endl;
            return -1;
        }
    }
    catch (const sol::error& e)
    {
        std::cerr << "Lua error: " << e.what() << std::endl;
        return -1;
    }

    return 0;
}