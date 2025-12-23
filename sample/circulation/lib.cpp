#include <sol/sol.hpp>
#include <cmath>

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

struct LIB_API Point
{
    double x, y;

    Point(double x = 0, double y = 0) : x(x), y(y) { }

    double distance(const Point& p) const
    {
        return std::hypot(x - p.x, y - p.y);
    }

    double bearing(const Point& p) const
    {
        return std::atan2(p.y - y, p.x - x);
    }

    Point destination(double d, double b) const
    {
        return {x + d * std::cos(b), y + d * std::sin(b)};
    }
};

// Export the module to Lua
extern "C" LIB_API int luaopen_point(lua_State *L)
{
    sol::state_view lua(L);

    return sol::stack::call_lua(L,
                                1,
                                [&]()
                                {
                                    sol::table module = lua.create_table();

                                    module.new_usertype<Point>("Point",
                                                               sol::call_constructor,
                                                               sol::constructors<Point(), Point(double, double)>(),
                                                               "x",
                                                               &Point::x,
                                                               "y",
                                                               &Point::y,
                                                               "distance",
                                                               &Point::distance,
                                                               "bearing",
                                                               &Point::bearing,
                                                               "destination",
                                                               &Point::destination);

                                    return module;
                                });
}