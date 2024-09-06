
function icon(id)
   return i {["data-lucide"]=id}
 end


head = head:extends {
   childrens = {
     first = {
         script { src="https://unpkg.com/lucide@latest" },
     }
   }
}

body = body:extends {
   childrens = {
     last = {
         script "lucide.createIcons();"
     }
   }
}
