#include "lib.h"
#include <cmath>

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

extern "C" int luaopen_libperformance(lua_State *L)
{
    sol::state_view lua(L);

    return sol::stack::call_lua(L,
                                1,
                                [&]()
                                {
                                    sol::table module = lua.create_table();

                                    module.set_function("fibonacciC", &fibonacci);
                                    module.set_function("fibonacciNC", &fibonacciN);

                                    return module;
                                });
}