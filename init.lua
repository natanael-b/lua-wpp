local Pages = _ENV.Pages
local Extensions = _ENV.Extensions
local ExtensionPages = {}
local RegisteredPlugins = {}
local Watch = _ENV.Watch
local RenderedPages = {}
local type = _ENV.type
local pairs = _ENV.pairs
local getmetatable = _ENV.getmetatable
local setmetatable = _ENV.setmetatable

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
_ENV["Server"] = nil
package.loaded._G = nil
package.loaded.package = nil
setmetatable(_ENV,nil)

local cleanENV = cloneTable(_ENV)

local function dirname(name)
    local directory = {}
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

local function setupNewEnv(page)
    -- Cleanup _ENV for next interaction
    cleanENV.setmetatable(_ENV,nil)
    for key in cleanENV.pairs(_ENV) do
        _ENV[key] = nil
    end
    -- Repopulate _ENV with default lua functions and namespaces
    for key, value in cleanENV.pairs(cleanENV) do
        if type(value) == "table" or type(value) == "object" then
            local meta = cleanENV.getmetatable(value)
            _ENV[key] = cloneTable(value)
            cleanENV.setmetatable(_ENV[key],meta and (cloneTable(meta)) or nil)
        else
            _ENV[key] = value
        end
    end

    dofile(lua4webapps.."/LuaTML.lua")
    for _, name in ipairs(Extensions or {}) do
        require(lua4webapps..".extensions."..name)
        if _ENV.RegisterPlugin and RegisteredPlugins[name] == nil then
            _ENV.RegisterPlugin(ExtensionPages)
            RegisteredPlugins[name] = true
        end
    end

    f = cleanENV.io.open(page..".lua")
    if f == nil then
        mkdir(page)
        f = cleanENV.io.open(page..".lua","w")
        f:write("---@diagnostic disable: lowercase-global, undefined-global\n\n"..
                "html {\n"..
                "  head {\n"..
                "    title 'Your page title',\n"..
                "   --script {src='my-preload.js'},\n",
                "  };\n"..
                "  body {\n"..
                "    h1 'Hello world!',\n"..
                "   -- script {src='my-postload.js'},\n",
                "  }\n"..
                " }\n")
    end
    f:close()
    dofile(page..".lua")
end

local function generateExtensionPages()
    for fileName, content in pairs(ExtensionPages) do
        mkdir(Pages.output.."/"..fileName)
        cleanENV.print(Pages.output.."/"..fileName,nil)
        local file = cleanENV.io.open(Pages.output.."/"..fileName,"w")
        if file then
            file:write(tostring(content or ""))
            file:close()
        else
            cleanENV.error("Failed to write extension generated page '"..fileName.."'",0)
        end
    end
end

local first = true
while true do
    for i, page in cleanENV.ipairs(Pages) do
        local writeFile = true

        setupNewEnv(Pages.sources.."/"..page)
        __HTML__ = type(__HTML__) == "string" and __HTML__ or (RenderedPages[page] or "")

        if first then
            print("Generating "..i.."/"..#Pages..": "..page..".html")
        else
            if __HTML__ == RenderedPages[page] then
                writeFile = false
            else
                print("Updating "..page.."...")
            end
        end

        if writeFile then
            mkdir(Pages.output.."/"..page)
            local htmlFile = cleanENV.io.open(Pages.output.."/"..page..".html","w")
            if htmlFile then
                htmlFile:write(__HTML__)
                htmlFile:close()

                generateExtensionPages()
                RenderedPages[page] = __HTML__
            else
                cleanENV.error("Failed to write generated page '"..page.."'",0)
            end

            writeFile = false
        end
    end
    if Watch ~= true then
        break
    end
    if first then
        first = false
        print "\n.-------------------------------------------------."
        print "|  Info:                                          |"
        print "|-------------------------------------------------|"
        print "|  Watch mode is active to exit press CTRL+C      |"
        print "'-------------------------------------------------'\n"
    end
end

print("Done :)")
