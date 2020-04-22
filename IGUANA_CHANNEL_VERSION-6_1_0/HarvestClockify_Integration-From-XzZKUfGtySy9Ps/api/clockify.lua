local config = require 'config'
require 'net.http.cache'

local clockify = {}

function clockify.get(uri)
   local response, code = net.http.get{
      url = config.clockify.baseUrl..uri,
      headers = {
         ['content-type'] = 'application/json',
         ['X-Api-Key'] = config.clockify.apiToken
      },
      cache_time = config.global.cacheTime,
      live = config.global.isLive
   }
   return json.parse{data=response}, code
end

function clockify.post(uri, postBody)
   local response, code = net.http.post{
      url = config.clockify.baseUrl..uri,
      headers = {
         ['content-type'] = 'application/json',
         ['X-Api-Key'] = config.clockify.apiToken
      },
      body = json.serialize{data = postBody},
      cache_time = config.global.cacheTime,
      live = config.global.isLive
   }
   return json.parse{data=response}, code
end

return clockify