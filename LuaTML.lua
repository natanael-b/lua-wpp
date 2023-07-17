local _ENV_metatable = getmetatable(_ENV) or {}

_PROMPT = _ENV["_PROMT"] or "> "  -- Prevent from changing prompt on interactive mode

__JAVASCRIPT__ = ""

function _ENV_metatable.__index (self,name)
  local content = rawget(self,name)

  if content ~= nil then
    return content
  end

  return setmetatable({
    tag=name,
    extends =
      function (self,descriptor)
        local element = {tag = rawget(self,"tag"),hard_properties={}}
        for property, value in pairs(descriptor) do
          if type(property) ~= "number" and type(value) == "string" then
            element.hard_properties[property] = tostring(value):gsub("\"","&quot;")
          else
            element.hard_properties[property] = value
          end
        end
        return setmetatable(element,getmetatable(_ENV[{}]))
      end
    ;
  }, {
    __mul =
      function (self,number)
        local block = {}

        for i = 1, number do
          block[#block+1] = self
        end

        return setmetatable(block, {
          __tostring =
            function (self)
              local result = ""
              for i, element in ipairs(self) do
                result = result..tostring(element)
              end
              return result
            end
        })
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

        return setmetatable(block, {
          __tostring =
            function (self)
              local result = ""
              for i, element in ipairs(self) do
                result = result..tostring(element)
              end
              return result
            end
        })
    end,

    __tostring =
      function (self)
        self.tag = self.tag:lower()

        local html = "<"..self.tag
        
        self.properties = self.properties or {}

        if self.tag == "html" and type(_ENV["Language"]) == "string" then
          self.properties.lang = _ENV["Language"]
        end

        if self.tag == "head"  then
          if _ENV["DISABLE_UTF8"] ~= true then
            table.insert(self.properties,1,meta { charset="utf8" })
          end
          
          if _ENV["DISABLE_GENERATOR"] ~= true then
            self.properties[#self.properties+1] = meta {
                                                         name="generator",
                                                         content="lua-wpp"
                                                       }
          end

          if _ENV["DISABLE_VIEWPORT"] ~= true then
            self.properties[#self.properties+1] = meta {
                                                         name="viewport",
                                                         content="width=device-width,initial-scale=1.0"
                                                       }
          end

          if type(__JAVASCRIPT_FILE__) == "string" then
            self.properties[#self.properties+1] = script {
              scr=__JAVASCRIPT_FILE__
            }
          end
        end

        self.hard_properties = self.hard_properties or {}
        self.childrens       = self.hard_properties.childrens or {}
        self.childrens.first = self.childrens.first or {}
        self.childrens.last  = self.childrens.last  or {}

        self.hard_properties.childrens = nil
        local hard_properties = {}

        for property, value in pairs(self.hard_properties) do
          hard_properties[property] = value
          if self.properties[property] == nil then
            self.properties[property] = value
            self.hard_properties[property] = nil
          end
        end

        for property, value in pairs(self.properties or {}) do
          if type(property) ~= "number" then
            if type(value) and getmetatable(value) == nil and property:sub(1,2) == "on" then
              if type(__JAVASCRIPT__) == "string" then
                local old_uuid = tostring(UniqueID)
                self.properties.id = tostring(self.properties.id or UniqueID())
                rawset(UniqueID,"value",old_uuid)
                break
              end
            end
          end
        end

        local innerHTML = ""

        for j, content in ipairs {self.childrens.first,self.properties,self.childrens.last} do
          for i, children in ipairs(content or {}) do
            if content == self.properties then
              if type(children) == "table" and getmetatable(children) == nil and self.tag == "table" then
                local result = ""
                for i,element  in ipairs(children) do
                  if type(element) == "table" then
                    if element.tag == "td" or element.tag == "th" then
                      result = result..tostring(element)
                    else
                      result = result.."<td>"..tostring(element).."</td>"
                    end
                  else
                    result = result.."<td>"..tostring(element).."</td>"
                  end
                end
                innerHTML = innerHTML.."<tr>"..result.."</tr>"
              else
                innerHTML = innerHTML..tostring(children)
              end
              goto skip
            end

            if getmetatable(children) or type(children) == "string" then
              innerHTML = innerHTML..tostring(children)
            else
              local bindings        = children.bindings
              local element         = children.element
              local tag             = element.tag
              local properties      = element.properties
              local hard_properties = element.hard_properties
  
              local obj = {
                tag = tag,
                properties = {},
                hard_properties = hard_properties
              }
  
              for property, value in pairs(properties or {}) do
                obj.properties[property] = value
              end
  
              for children_property, parent_property in pairs(bindings or {}) do
                local value = self.properties[parent_property]
                if value ~= nil then
                  self.properties[parent_property] = nil
                  obj.properties[children_property] = tostring(value)
                end
              end
              innerHTML = innerHTML..tostring(setmetatable(obj,getmetatable(element)))
            end
            ::skip::
          end
        end

        for property, value in pairs(self.properties or {}) do
          if type(property) ~= "number" then
            if type(value) and getmetatable(value) == nil and property:sub(1,2) == "on" then
              if type(__JAVASCRIPT__) == "string" then
                local function_name = "when_"..property:sub(3,-1).."_on_"..self.properties.id.."()"
                __JAVASCRIPT__ = __JAVASCRIPT__.."\n\n\nfunction "..function_name.." {\n"
                __JAVASCRIPT__ = __JAVASCRIPT__.."  var self = event.target;\n\n  "
                __JAVASCRIPT__ = __JAVASCRIPT__..table.concat(value,";\n  ").."\n}"
                value = function_name..";"
              else
                  value = table.concat(value,";"):gsub("\"","&quot;")
              end
            end
            html = html.." "..property.."=\""..(self.hard_properties[property] and self.hard_properties[property].." " or "")..tostring(value):gsub("\"","&quot;").."\""
          end
        end

        for property, value in pairs(hard_properties) do
          self.hard_properties[property] = value
        end
      
        self.hard_properties.childrens = self.childrens

        if (#(self.properties or {}) == 0) and self.tag:lower() ~= "script" and self.tag:lower() ~= "html" and #self.childrens.first+#self.childrens.first == 0 then
          return html.."/>"
        end

        html = html..">"..innerHTML

        if self.tag:lower() == "body" and __JAVASCRIPT__ ~= "" then
          html = html..tostring(script{type="text/javascript","\n"..__JAVASCRIPT__.."\n\n"})
          __JAVASCRIPT__ = ""
        end

        -- No body TAG, but has Javascript events, we need to fix this weird HTML
        if __JAVASCRIPT__ ~= "" and self.tag:lower() == "html" then
          html = html.."<body>"..tostring(script{type="text/javascript","\n"..__JAVASCRIPT__.."\n\n"}).."</body>"
          __JAVASCRIPT__ = ""
        end

        return html.."</"..self.tag..">"
      end
    ;

    __call =
      function (self,properties)
        self.properties = type(properties) == "table" and properties or {tostring(properties)}

        if self.tag:lower() == "html" then
          __HTML__ = tostring("<!DOCTYPE html>"..tostring(self))
          return __HTML__
        end

        local obj = {
          tag = self.tag,
          properties = self.properties,
          extends = self.extends,
          hard_properties = {}
        }

        for property, value in pairs(self.hard_properties or {}) do
          obj.hard_properties[property] = value
        end

        return setmetatable(obj,getmetatable(self))
      end
    ;
  })
end

setmetatable(_ENV,_ENV_metatable)

table.tag='table'
table.extends = rawget(_ENV[{}],"extends")
setmetatable(table,getmetatable(_ENV[{}]))

UniqueID = {}
UniqueID = setmetatable(UniqueID,{
  __index = UniqueID,
  __call =
    function (self)
      local result = ""
      for i=1,9 do
        if math.random(1,2) == 1 then
          result = result..string.char(math.random(97, 97 + 25))
        else
          result = result..string.char(math.random(65, 65 + 25))
        end
      end
      self.value = result
      return self
    end
  ;
  __tostring =
    function (self)
      return self.value
    end
  ;
})

UniqueID()
