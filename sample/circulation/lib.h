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

struct LIB_API Point
{
    double x, y;

    Point(double x = 0, double y = 0);

    double distance(const Point& p) const;

    double bearing(const Point& p) const;

    Point destination(double d, double b) const;
};

// Export the module to Lua
extern "C" LIB_API int luaopen_libcirculation(lua_State *L);