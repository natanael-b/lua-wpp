
-- Prevent Prompt changing on REPL
_PROMPT = _ENV["_PROMT"] or "> "

local selfClosableTags = {
    area    = true,
    base    = true,
    br      = true,
    col     = true,
    command = true,
    embed   = true,
    hr      = true,
    img     = true,
    input   = true,
    keygen  = true,
    link    = true,
    meta    = true,
    param   = true,
    source  = true,
    track   = true,
    wbr     = true,
}

-- To simplify logic, childdrens of extended elements will share this metatable
-- this will allow direct detect and allows new plain div syntax
local sharedMetatable = {}

-- In HTML we need encode certains characters
local function toHTMLEncode(v)
  return tostring(v):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#039;")
end

-- Generic function to serialize tag childrens
local function serializeChildrens(self)
    local result = ""
    for i, element in ipairs(self) do
      result = result..tostring(element)
    end
    return result
end

local function serializeProperties(properties)
    local HTML = ""
  -- Let's ensure that property order is same across builds
  -- this avoids commit pollution

  local propertiesList = {}
  for property in pairs(properties) do
    propertiesList[#propertiesList+1] = property
  end
  table.sort(propertiesList)
  
  for i, property in ipairs(propertiesList) do
    local value = properties[property]
    HTML = HTML..property..'="'..toHTMLEncode(tostring(value))..'" '
  end
  return (HTML == "" and "" or " ")..HTML
end

local function processChildren(element,properties)
    if getmetatable(element) == sharedMetatable then
      -- We get a children of extended elements
      local bindings = element.bindings
      local elementWrapped = element.element

      for childrenProperty, parentProperty in pairs(bindings) do
        if type(childrenProperty) ~= "number"  then
          rawget(elementWrapped,"__lua4webapps_properties")[childrenProperty] = tostring(properties[parentProperty])
        else
          local childrens = rawget(elementWrapped,"__lua4webapps_childrens")
          for i = 1, childrenProperty, 1 do
            childrens[i] =childrens[i] or ""
          end
          childrens[childrenProperty] = tostring(properties[parentProperty])
        end
      end
      return elementWrapped
    end
    if type(element) == "table" and getmetatable(element) == nil then
      -- we got a plain div , let's create a custom element
      local newDiv = _ENV[{"div"}]
      for key, value in pairs(element) do
        newDiv[key] = value
      end
      return newDiv
    end
    return element
end

local function destructure(self)
    local childrens  = {}
    local properties = {}

    -- To allow extendable tags we need clone properties and childrens
    for _, scope in ipairs {rawget(self,"__lua4webapps_hardcodeProperties"),rawget(self,"__lua4webapps_properties")} do
      for property, value in pairs(scope) do
        properties[property] = properties[property] == nil and value or properties[property].." "..value
      end
    end

    for _, scope in ipairs {
                              (rawget(self,"__lua4webapps_hardcodeChildrens") or {}).first or {},  -- Retrocompatibility
                              (rawget(self,"__lua4webapps_hardcodeChildrens") or {}),
                              (rawget(self,"__lua4webapps_childrens") or {}).first or {},
                              (rawget(self,"__lua4webapps_childrens") or {}),
                              (rawget(self,"__lua4webapps_childrens") or {}).last or {},
                              (rawget(self,"__lua4webapps_hardcodeChildrens") or {}).last or {}
                           } do
      for _, children in ipairs(scope) do
        childrens[#childrens+1] = processChildren(children,properties)
      end
    end

    return childrens,properties
end

-- lets avoid redeclare functions
local elementCommonMetatableEvents = {
    __newindex =
      function (self,k,v)
        if type(k == "number") then
            local childrens = rawget(self,"__lua4webapps_childrens")
            childrens[#childrens+1] = v
            return
        end
        local properties = rawget(self,"__lua4webapps_properties")
        properties[k] = v
      end
    ,
    __mul =
      function (self,n)
        local block = {}

        for i = 1, n do
          block[i] = self
        end

        return setmetatable(block, {__tostring = serializeChildrens})
      end
    ;
    __pow =
      function (self,items)
        local block = {}

        items = type(items) == "table" and items or {items}

        for i, item in ipairs(items) do
          local element = {tag = self.tag,properties = {}}
          for property, value in pairs(self.properties or {}) do
            element.properties[property] = value
          end
          element = setmetatable(element,getmetatable(self))
          element.properties[1] = tostring(item)
          block[#block+1] = element
        end

        return setmetatable(block, {__tostring = setmetatable(block, {__tostring = serializeChildrens})})
      end
    ;
    __tostring =
      function (self)
        local tagName    = rawget(self,"__lua4webapps_tagName")
        local childrens,properties = destructure(self)

        local HTML = "<"..tagName..serializeProperties(properties)..((#childrens == 0 and selfClosableTags[tagName]) and "" or ">\n")
        HTML = HTML..serializeChildrens(childrens or {})

        return HTML..((#childrens == 0 and selfClosableTags[tagName]) and "/>\n" or "</"..tagName..">\n")
      end
    ;
    __call =
      function (self,t)
        t = type(t) == "table" and t or {tostring(t)}
        for key, value in pairs(t) do
            if type(key) ~= "number" then
                rawset(rawget(self,"__lua4webapps_properties"),key,value)
            else
                rawset(rawget(self,"__lua4webapps_childrens"),key,value)
            end
        end
        return self
      end
    ;
}

-- Some elements must have a special __tostring, __newindex and __call for convenience
local elementSpecificMetatableEvents = {
    html = {
      __tostring =
        function (self)
          return "<!DOCTYPE html>\n"..elementCommonMetatableEvents.__tostring(self)
        end
      ;
    },
    table = {

    },
    select = {
      __newindex =
        function (self,k,v)
          if type(k) =="number" then
            if type(v) == "table" and getmetatable(v) == nil then
              v = option {value = tostring(v[2]),tostring(v[1])}
            elseif (type(v) == "table" or type(v) == "object") and getmetatable(v)  then
              v = v
            else
              v = option {value = tostring(v),tostring(v)}
            end
            elementCommonMetatableEvents.__newindex(self,k,v)
          end
        end
      ,
      __call =
        function (self,t)
          for i, element in ipairs(t) do
            if type(element) == "table" and getmetatable(element) == nil then
              t[i] = option {value = tostring(element[2]),tostring(element[1])}
            elseif (type(element) == "table" or type(element) == "object") and getmetatable(element)  then
              t[i] = element
            else
              t[i] = option {value = tostring(element),tostring(element)}
            end
          end
          return (elementCommonMetatableEvents.__call(self,t))
        end
      ,
    },
}

local function processExtendedTagChildren(children)
  if #children == 0 and (type(children) == "table" and children.element or false) and getmetatable(children) == nil then
    setmetatable(children,sharedMetatable)
  end
  return children
end

local function extends(self,descriptor)
  local element   = _ENV[{rawget(self,"__lua4webapps_tagName")}] -- create a dummy element
  local childrens = descriptor.childrens or {}

  local hardcodeProperties     = (rawget(self,"__lua4webapps_hardcodeProperties") or {}).first or {}
  local hardcodeChildrensFirst = (rawget(self,"__lua4webapps_hardcodeChildrens") or {}).first  or {}
  local hardcodeChildrens      = (rawget(self,"__lua4webapps_hardcodeChildrens") or {})
  local hardcodeChildrensLast  = (rawget(self,"__lua4webapps_hardcodeChildrens") or {}).last   or {}

  local newHardcodeProperties     = {}
  local newHardcodeChildrensFirst = {}
  local newHardcodeChildrens      = {}
  local newHardcodeChildrensLast  = {}

  descriptor.childrens = nil

  -- Merge hardcoded properties
  for _, scope in ipairs {hardcodeProperties,descriptor} do
    for key, value in pairs(scope) do
      newHardcodeProperties[key] = newHardcodeProperties[key] == nil and value or newHardcodeProperties[key].." "..value
    end
  end

  -- Merge hardcoded head childrens
  for _, scope in ipairs {hardcodeChildrensFirst or {},childrens.first or {}} do
    for _,children in ipairs(scope) do
      newHardcodeChildrensFirst[#newHardcodeChildrensFirst+1] = processExtendedTagChildren(children)
    end
  end

  --Merge hardcoded body childrens (syntatic sugar for first)
  for _, scope in ipairs {hardcodeChildrens or {},childrens or {}} do
    for _,children in ipairs(scope) do
      newHardcodeChildrens[#newHardcodeChildrens+1] = processExtendedTagChildren(children)
    end
  end

  -- Merge hardcoded footer childrens
  for _, scope in ipairs {childrens.last or {},hardcodeChildrensLast or {}} do
    for _,children in ipairs(scope) do
      newHardcodeChildrensLast[#newHardcodeChildrensLast+1] = processExtendedTagChildren(children)
    end
  end

  newHardcodeChildrens.first = newHardcodeChildrensFirst or {}
  newHardcodeChildrens.last  = newHardcodeChildrensLast  or {}

  rawset(element,"__lua4webapps_hardcodeProperties",newHardcodeProperties)
  rawset(element,"__lua4webapps_hardcodeChildrens",newHardcodeChildrens)

  return element
end

local function createElement(tag,__index)
    tag = tostring(tag):lower()

    return setmetatable({
        __lua4webapps_tagName    = tag,
        __lua4webapps_properties = {},
        __lua4webapps_hardcodeProperties = {},
        __lua4webapps_hardcodeChildrens = {},
        __lua4webapps_childrens = {},
        extends = extends,
    },{
        __index    = __index,
        __newindex = (elementSpecificMetatableEvents[tag] or {}).__newindex or elementCommonMetatableEvents.__newindex;
        __name     = "table", -- Iasy support
        __mul      = elementCommonMetatableEvents.__mul,
        __pow      = elementCommonMetatableEvents.__pow,
        __tostring = (elementSpecificMetatableEvents[tag] or {}).__tostring or elementCommonMetatableEvents.__tostring,
        __call     = (elementSpecificMetatableEvents[tag] or {}).__call     or elementCommonMetatableEvents.__call;
    })
end

local envMetatable = {
    __index =
      function (self,k)
        -- if something doesn't exists, return an HTML element
        return rawget(self,k) or createElement(type(k)=="table" and table.concat(k) or tostring(k))
      end
    ;
}

-- Let's do the trick
setmetatable(_ENV,envMetatable)

-- Lua already uses table name
table = createElement("table",table)

-- Select in lua is already declared a function,
-- since we want to keep Lua untouched, is need
-- to encapsulate then

select = _ENV[{}]
rawset(select,"__lua4webapps_tagName","select")

local luaSelect = select
local selectMetatable = getmetatable(_ENV[{}])

function selectMetatable.__call(self,...)
  if type(({...})[1]) == "number" then
    return luaSelect(...)
  end
  return elementSpecificMetatableEvents.select.__call(self,...)
end

setmetatable(select,selectMetatable)

-- For convenience let's reduce head tag boilerplate

head = head:extends {
  childrens = {
    meta {charset="UTF-8"},
    meta {content="width=device-width,initial-scale=1.0", name="viewport"},
    style "body {font-family: sans-serif;}",
  }
}
