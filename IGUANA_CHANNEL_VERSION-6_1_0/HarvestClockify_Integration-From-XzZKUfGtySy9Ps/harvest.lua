require 'net.http.cache'

-- Harvest Configuration

local harvestApiToken = '1319743.pt.nKEHbMvFWJv4EyPsolrIIvH6rW7fLVxQxeMMx3y-i2Nd5cVkf_J1bzlHM3izsLyN6VYCsbEnXR2KPCn6A-dNTQ'
local accountId = '620684'
local harvestUrl = 'https://api.harvestapp.com/v2/'

-- Helper Functions for Harvest

local harvest = {}

function harvest.harvestApiGetCall(uri)
   return net.http.get{
      url = harvestUrl..uri, 
      headers = {
         ['Authorization'] = 'Bearer '..harvestApiToken, 
         ['Harvest-Account-Id'] = accountId,
         ['User-Agent'] = 'Personal'
      },
      cache_time = 0,
      live = true
   }
end

function harvest.harvestApiPostCall(uri, post_body)
   return net.http.post{
      url = harvestUrl..uri, 
      headers = {
         ['Authorization'] = 'Bearer '..harvestApiToken, 
         ['Harvest-Account-Id'] = accountId,
         ['User-Agent'] = 'Personal',
         ['Content-Type'] = 'application/json'
      },
      body = json.serialize{data=post_body},
      cache_time = 0,
      live = true
   }
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