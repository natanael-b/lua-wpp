
function icons(sizes)
   local links = ""
   for size, uri in pairs(sizes) do
     for _, rel in ipairs {"icon","apple-touch-icon"} do
       links = links..'<link rel=rel type="image/png" sizes='..(size.."x"..size)..' href="'..uri..'"/>\n'
     end
   end
   return links
 end

local base = _ENV[{}]
local metatable = getmetatable(base)
local metatable__tostring = metatable.__tostring
local defaultValues = {
   manifest = "manifest.json",
   statusbar = "default",
}
function metatable:__tostring()
   if rawget(self,"__lua4webapps_tagName") == "meta" then
      local name = rawget(self,"__lua4webapps_properties").name
      local content = rawget(self,"__lua4webapps_properties").content
      rawget(self,"__lua4webapps_properties").content = content or defaultValues[name]
      return rawget(self,"__lua4webapps_properties").content and metatable__tostring(self) or ""
   end
   local href = rawget(self,"__lua4webapps_properties").href
   rawget(self,"__lua4webapps_properties").href = href or "manifest.json"
   return metatable__tostring(self)
 end

local function metatag(d)
   local meta = _ENV['meta']
   return setmetatable(meta,metatable)(d)
end

local function linktag(d)
   local meta = _ENV['link']
   return setmetatable(meta,metatable)(d)
end

head = head:extends {
   childrens = {
     last = {
         metatag {
            name="mobile-web-app-capable",
            content="yes"
         },

        {
           element = metatag {
             name="theme-color"
           },
           bindings = {
              ['content'] = 'theme_color',
           }
        },

        {
           element = metatag {
              name="apple-mobile-web-app-status-bar-style"
           },
           bindings = {
              ['content'] = 'statusbar',
           }
        },
        {
         element = linktag {
            name="manifest"
         },
         bindings = {
            ['href'] = 'manifest',
         }
      },
     }
   }
}
