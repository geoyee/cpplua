#include <sol/sol.hpp>
#include <efsw/efsw.hpp>
#include <iostream>

class LuaFileReloader : public efsw::FileWatchListener
{
private:
    sol::state& lua;
    sol::table& tab;
    std::string luaFilePath;

public:
    LuaFileReloader(sol::state& luaState, sol::table& luaTab, const std::string& filePath)
        : lua(luaState)
        , tab(luaTab)
        , luaFilePath(filePath)
    {
    }

    void handleFileAction(efsw::WatchID watchid,
                          const std::string& dir,
                          const std::string& filename,
                          efsw::Action action,
                          std::string oldFilename = "") override
    {
        if (filename == luaFilePath && action == efsw::Actions::Modified)
        {
            try
            {
                lua.script_file(dir + luaFilePath);
                tab = lua["defindedAPIs"];
                std::cout << std::endl;
                for (const auto& [apiName, apiFunc] : tab)
                {
                    std::cout << "register api: " << apiName.as<std::string>() << std::endl;
                }
                std::cout << "Reload successful!" << std::endl;
                std::cout << "Please input an api name (Press 'q' to exit): ";
            }
            catch (const sol::error& e)
            {
                std::cerr << "Reload failed: " << e.what() << std::endl;
            }
        }
    }
};

int main()
{
    sol::state lua;
    luaL_openlibs(lua); // Load all Lua dependency libraries, such as math

    std::string luaFile = "Registration.lua";
    size_t pos = luaFile.find_last_of("/\\");
    std::string dir = (pos != std::string::npos) ? luaFile.substr(0, pos) : ".";

    char userInput[32];

    try
    {
        lua.script_file(luaFile);                // Load lua script
        sol::table apiTab = lua["defindedAPIs"]; // Read api table

        // Start monitoring
        LuaFileReloader reloader(lua, apiTab, luaFile);
        efsw::FileWatcher watcher;
        efsw::WatchID watchId = watcher.addWatch(dir, &reloader, false);
        if (watchId < 0)
        {
            std::cerr << "Unable to monitor: " << dir + "/" + luaFile << std::endl;
            return 1;
        }
        watcher.watch();

        for (const auto& [apiName, apiFunc] : apiTab)
        {
            std::cout << "register api: " << apiName.as<std::string>() << std::endl;
        }
        std::cout << "Load successful!" << std::endl;

        while (true)
        {
            std::cout << "Please input an api name (Press 'q' to exit): ";
            std::cin.getline(userInput, 32);
            std::string userInputStr(userInput);
            if (userInputStr == "q")
            {
                break;
            }

            sol::function useFunc = sol::nil;
            for (const auto& [apiName, apiFunc] : apiTab)
            {
                if (userInputStr == apiName.as<std::string>())
                {
                    useFunc = apiFunc.as<sol::function>();
                }
            }

            if (useFunc == sol::nil)
            {
                std::cerr << "Can not find this api: " << userInputStr << std::endl;
                continue;
            }
            else
            {
                std::cout << "Please enter two numbers separated by a space: ";
                std::cin.getline(userInput, 32);

                double num1, num2;
                std::istringstream iss(userInput);
                if (!(iss >> num1 >> num2))
                {
                    std::cerr << "Invalid input" << std::endl;
                    continue;
                }

                sol::variadic_results res = useFunc(num1, num2);
                if (!res.empty() && res[0].is<double>())
                {
                    std::cout << userInputStr << "(" << num1 << "," << num2 << ") = " << res[0].as<double>()
                              << std::endl;
                }
                else
                {
                    std::cerr << "Failed" << std::endl;
                }
            }
        }
    }
    catch (const sol::error& e)
    {
        std::cerr << "Lua error: " << e.what() << std::endl;
    }

    return 0;
}