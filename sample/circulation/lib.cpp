#include "lib.h"
#include <cmath>

Point::Point(double x, double y) : x(x), y(y) { }

double Point::distance(const Point& p) const
{
    return std::hypot(x - p.x, y - p.y);
}

double Point::bearing(const Point& p) const
{
    return std::atan2(p.y - y, p.x - x);
}

Point Point::destination(double d, double b) const
{
    return {x + d * std::cos(b), y + d * std::sin(b)};
}

extern "C" int luaopen_libcirculation(lua_State *L)
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