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

int fibonacci(int n)
{
    if (n <= 1)
    {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

long long fibonacciN(int m)
{
    long long res = 0;
    for (int i = 1; i <= m; ++i)
    {
        res += fibonacci(i);
    }
    return res;
}

int main()
{
    sol::state lua;

    constexpr int count = 20;

    try
    {
        lua.script_file("Performace.lua");
        sol::function fibonacciNLua = lua["fibonacciN"];

        auto [rCpp, tCpp] = measureExecutionTime(fibonacciN, count);
        auto [rLua, tLua] = measureExecutionTime(fibonacciNLua, count);

        if (rLua.valid())
        {
            std::cout << "[C++] fibonacciN use time " << tCpp << "ms and get result " << rCpp << "\n"
                      << "[Lua] fibonacciN use time " << tLua << "ms and get result " << rLua.get<long long>()
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
