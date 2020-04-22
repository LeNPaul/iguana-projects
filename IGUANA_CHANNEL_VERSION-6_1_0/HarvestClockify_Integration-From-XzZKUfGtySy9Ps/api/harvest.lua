local config = require 'config'
require 'net.http.cache'

local harvest = {}

function harvest.get(uri)
   local response, code = net.http.get{
      url = config.harvest.baseUrl..uri, 
      headers = {
         ['Authorization'] = 'Bearer '..config.harvest.apiToken, 
         ['Harvest-Account-Id'] = config.harvest.accountId,
         ['User-Agent'] = config.harvest.userAgent
      },
      cache_time = config.global.cacheTime,
      live = config.global.isLive
   }
   return json.parse{data=response}, code
end

function harvest.post(uri, postBody)
   local response, code = net.http.post{
      url = config.harvest.baseUrl..uri, 
      headers = {
         ['Authorization'] = 'Bearer '..config.harvest.apiToken, 
         ['Harvest-Account-Id'] = config.harvest.accountId,
         ['User-Agent'] = 'Personal',
         ['Content-Type'] = 'application/json'
      },
      body = json.serialize{data = postBody},
      cache_time = config.global.cacheTime,
      live = config.global.isLive
   }
   return json.parse{data=response}, code
end

function harvest.getActiveProjects(project_list)
   local active_projects = {}
   for i=1, #project_list do
      if project_list[i].is_active then 
         table.insert(active_projects, project_list[i])
      end
   end
   return active_projects
end

return harvest