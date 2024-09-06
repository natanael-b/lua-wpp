local title = _ENV['title']
local title_metatable = getmetatable(title)

function title_metatable.__tostring(self)
  local value = rawget(self,"__lua4webapps_childrens")[1]
  return '<meta property="og:title" content="'..value:gsub('"',"&quot;")..'"/>\n'..
         '<title>'..value:gsub("<","&lt;")..'</title>\n'
end

local base = _ENV[{}]
local metatable = getmetatable(base)
local metatable__tostring = metatable.__tostring

function metatable:__tostring()
   local name = rawget(self,"__lua4webapps_properties").name
   local content = rawget(self,"__lua4webapps_properties").content
   return rawget(self,"__lua4webapps_properties").content and metatable__tostring(self) or ""
 end

local function metatag(d)
   local meta = _ENV['meta']
   return setmetatable(meta,metatable)(d)
end


head = head:extends {
   childrens = {
     last = {
        {
           element = title,
           bindings = {
              [1] = 'title',
           }
        },
        {
            element = metatag {
               name="author"
            },
            bindings = {
               ['content'] = 'author',
            }
        },
        {
            element = metatag {
              name="description",
              property="og:description"
            },
            bindings = {
               ['content'] = 'description',
            }
        },
        {
            element = metatag {
              name="keywords"
            },
            bindings = {
               ['content'] = 'keywords',
            }
        },
        {
           element = metatag {
             name="og:url"
           },
           bindings = {
              ['content'] = 'url',
           }
        },
        {
           element = metatag {
             name="og:audio"
           },
           bindings = {
              ['content'] = 'audio',
           }
        },
        {
           element = metatag {
             name="og:video"
           },
           bindings = {
              ['content'] = 'video',
           }
        },
        {
           element = metatag {
             name="og:image"
           },
           bindings = {
              ['content'] = 'image',
           }
        },
     }
   }
}
