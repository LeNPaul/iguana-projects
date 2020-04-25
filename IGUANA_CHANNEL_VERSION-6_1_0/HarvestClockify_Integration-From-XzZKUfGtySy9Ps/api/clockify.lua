require 'net.http.cache'
local config = require 'config'
local retry = require 'retry'

local clockify = {}

function clockify.get(uri)
   local response = retry.call{
      funcname = 'clockify.get',
      func = net.http.get,
      arg1 = {
         url = config.clockify.baseUrl..uri,
         headers = {
            ['content-type'] = 'application/json',
            ['X-Api-Key'] = config.clockify.apiToken
         },
         cache_time = config.global.cacheTime,
         live = config.global.isLive
      },
      retry = config.global.retryCount, pause = config.global.pauseTime
   }
   return json.parse{data = response}
end

function clockify.post(uri, postBody)
   local response = retry.call{
      funcname = 'clockify.post',
      func = net.http.post,
      arg1 = {
         url = config.clockify.baseUrl..uri,
         headers = {
            ['content-type'] = 'application/json',
            ['X-Api-Key'] = config.clockify.apiToken
         },
         body = json.serialize{data = postBody},
         cache_time = config.global.cacheTime,
         live = config.global.isLive
      },
      retry = config.global.retryCount, pause = config.global.pauseTime
   }
   return json.parse{data = response}
end

return clockify