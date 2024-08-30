local Pages = _ENV.Pages
local Extensions = _ENV.Extensions
local ExtensionPages = {}
local RegisteredPlugins = {}
local type = _ENV.type

local f = io.open("lua4webapps-framework/init.lua")
local lua4webapps = f and ({"lua4webapps-framework",f:close()})[1] or "lua4webapps"

local function cloneTable(orig)
    local copy = {}
    for key, value in pairs(orig) do
        if type(value) == "table" or type(value) == "object" then
            local meta = getmetatable(value)
            copy[key] = cloneTable(value)
            setmetatable(copy[key],meta and (cloneTable(meta)) or nil)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Cleanup _ENV before copy
_G = nil
_ENV["Pages"] = nil
_ENV["Extensions"] = nil
package.loaded._G = nil
package.loaded.package = nil
setmetatable(_ENV,nil)

local cleanENV = cloneTable(_ENV)

local function setupNewEnv(page)
    cleanENV.setmetatable(_ENV,nil)
    for key, value in cleanENV.pairs(cleanENV) do
        if type(value) == "table" or type(value) == "object" then
            local meta = cleanENV.getmetatable(value)
            _ENV[key] = cloneTable(value)
            cleanENV.setmetatable(_ENV[key],meta and (cloneTable(meta)) or nil)
        else
            _ENV[key] = value
        end
    end

    require(lua4webapps..".LuaTML")
    for _, name in ipairs(Extensions or {}) do
        require(lua4webapps..".extensions."..name)
        if _ENV.RegisterPlugin and RegisteredPlugins[name] == nil then
            _ENV.RegisterPlugin(ExtensionPages)
            RegisteredPlugins[name] = true
        end
    end

    require (page)
end

local function dirname(name)
    local directory = {Pages.output}
    for folder in cleanENV.string.gmatch(name,"[^/]+") do
        directory[#directory+1] = folder
    end
    cleanENV.table.remove(directory,#directory)

    return cleanENV.table.concat(directory,"/")
end

local function mkdir(path)
    path = dirname(path)
    -- Windows
    if package.config:sub(1,1) == "\\" then
        cleanENV.os.execute('md "'..path..'" >nul 2>nul')
        return
    end
    -- Any other OS in use since 2003
    cleanENV.os.execute("mkdir -p '"..path.."' >/dev/null 2>&1")
end

for i, page in cleanENV.ipairs(Pages) do
    setupNewEnv(Pages.sources.."."..page:gsub("/","."))
    print("Generating "..i.."/"..#Pages..": "..page..".html")
    mkdir(page)
    local htmlFile = cleanENV.io.open(Pages.output.."/"..page..".html","w")
    if htmlFile then
        __HTML__ = __HTML__ or nil
        htmlFile:write(type(__HTML__) == "string" and __HTML__ or "")
        htmlFile:close()
    else
        cleanENV.error("Failed to write extension generated page '"..page.."'",0)
    end
end

for fileName, content in pairs(ExtensionPages) do
    mkdir(fileName)
    local file = cleanENV.io.open(Pages.output.."/"..fileName,"w")
    if file then
        file:write(tostring(content or ""))
        file:close()
    else
        cleanENV.error("Failed to write extension generated page '"..fileName.."'",0)
    end
end

print("Done :)")
