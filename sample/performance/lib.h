#pragma once

#if defined(_MSC_VER) || defined(__CYGWIN__) || defined(__MINGW32__) || defined(__BCPLUSPLUS__) || defined(__MWERKS__)
#if defined(LIBRART_STATIC)
#define LIB_API
#elif defined(LIBRART_EXPORTS) // LIBRART_SHARED
#define LIB_API __declspec(dllimport)
#else
#define LIB_API __declspec(dllexport)
#endif // LIBRART_STATIC
#else
#if __GNUC__ >= 4
#define LIB_API __attribute__((visibility("default")))
#else
#define LIB_API
#endif // __GNUC__ >= 4
#endif // _MSC_VER || __CYGWIN__ || __MINGW32__ || __BCPLUSPLUS__ || __MWERKS__

#include <sol/sol.hpp>

int LIB_API fibonacci(int n);

long long LIB_API fibonacciN(int m);

// Export the module to Lua
extern "C" LIB_API int luaopen_libperformance(lua_State *L);