#include <sol/sol.hpp>
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

struct CustomData
{
    int mode;
    double x;
    double y;
};

int main()
{
    sol::state lua;

    // 向Lua暴露CustomData类型
    lua.new_usertype<CustomData>("CustomData", "mode", &CustomData::mode, "x", &CustomData::x, "y", &CustomData::y);

    // 使用Lua脚本热重载检查方法
    auto checkWithLua = [&lua](const std::string& scriptPath, const CustomData& data)
    {
        try
        {
            if (!fs::exists(scriptPath))
            {
                std::cerr << "Lua script not found: " << scriptPath << std::endl;
                return false;
            }

            lua.script_file(scriptPath);
            sol::function inspectFunc = lua["inspect"];

            // 检查函数是否存在
            if (!inspectFunc.valid())
            {
                std::cerr << "Lua function 'inspect' not found" << std::endl;
                return false;
            }

            sol::protected_function_result result = inspectFunc(data);
            if (result.valid())
            {
                return result.get<bool>();
            }
            else
            {
                sol::error err = result;
                std::cerr << "Lua function error: " << err.what() << std::endl;
                return false;
            }
        }
        catch (const sol::error& e)
        {
            std::cerr << "Lua error: " << e.what() << std::endl;
            return false;
        }
    };

    // 测试
    CustomData testData{3, 103, 30};
    if (checkWithLua("Inspection.lua", testData))
    {
        std::cout << "Inspection passed" << std::endl;
    }
    else
    {
        std::cout << "Inspection failed" << std::endl;
    }

    return 0;
}