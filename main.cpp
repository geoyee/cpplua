#include "lua.hpp"
#include <iostream>
#include <string>

class LuaExecutor final
{
public:
    LuaExecutor(const LuaExecutor &) = delete;
    LuaExecutor &operator=(const LuaExecutor &) = delete;

    static LuaExecutor &getInstance()
    {
        static LuaExecutor instance;
        return instance;
    }

    bool dostring(const std::string &luaCode)
    {
        return checkLuaErr(luaL_dostring(m_LuaState, luaCode.c_str()));
    }

    lua_State *getLuaState() { return m_LuaState; }

private:
    LuaExecutor() : m_LuaState(luaL_newstate())
    {
        if (m_LuaState)
        {
            luaL_openlibs(m_LuaState);
        }
        else
        {
            std::cerr << "Failed to create Lua state!" << std::endl;
        }
    }

    ~LuaExecutor()
    {
        if (m_LuaState)
        {
            lua_close(m_LuaState);
        }
    }

    bool checkLuaErr(int result)
    {
        if (result != LUA_OK)
        {
            std::string errMsg = lua_tostring(m_LuaState, -1);
            std::cout << "Error of Lua: " << errMsg << std::endl;
            return false;
        }
        return true;
    }

    lua_State *m_LuaState;
};

int main()
{
    auto &luaExecutor = LuaExecutor::getInstance();
    luaExecutor.dostring("print('Hello World, lua!')");

    return 0;
}