#include "lib.h"
#include <sol/sol.hpp>
#include <chrono>
#include <iostream>
#include <functional>

template<typename Func, typename... Args>
auto measureExecutionTime(Func func, Args&&...args) -> std::pair<decltype(func(std::forward<Args>(args)...)), long long>
{
    auto start = std::chrono::high_resolution_clock::now();
    auto result = func(std::forward<Args>(args)...);
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    return {std::move(result), duration.count()};
}

int main()
{
    sol::state lua;
    luaL_openlibs(lua);

    constexpr int count = 24;

    try
    {
        lua.script_file("Performace.lua");
        sol::function fibonacciNLua = lua["fibonacciN"];
        sol::function fibonacciNLuaC = lua["fibonacciNCpp"];

        auto [rCpp, tCpp] = measureExecutionTime(fibonacciN, count);
        auto [rLua, tLua] = measureExecutionTime(fibonacciNLua, count);
        auto [rLC, tLC] = measureExecutionTime(fibonacciNLuaC, count);

        if (rLua.valid() && rLC.valid())
        {
            std::cout << "[  Native C++  ] fibonacciN use time " << tCpp << "ms and get result " << rCpp << "\n"
                      << "[  Native Lua  ] fibonacciN use time " << tLua << "ms and get result "
                      << rLua.get<long long>() << "\n"
                      << "[Lua C++ Export] fibonacciN use time " << tLC << "ms and get result " << rLC.get<long long>()
                      << std::endl;
        }
        else
        {
            sol::error err = rLua;
            std::cerr << "Lua function error: " << err.what() << std::endl;
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
