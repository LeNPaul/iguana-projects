require 'net.http.cache'
local config = require 'config'
local retry = require 'retry'

local todoist = {}

function todoist.get(uri)
   local response = retry.call{
      funcname = 'todoist.get',
      func = net.http.get,
      arg1 = {
         url = config.todoist.baseUrl..uri,
         headers = {['Authorization'] = 'Bearer '..config.todoist.apiToken},
         live = config.global.isLive,
         cache_time = config.global.cacheTime
      },
      retry = config.global.retryCount, pause = config.global.pauseTime
   }
   return json.parse{data = response}
end

function todoist.post(uri, postBody)
   local response = retry.call{
      funcname = 'todoist.post',
      func = net.http.post,
      arg1 = {
         url = config.todoist.baseUrl..uri, 
         headers = {
            ['Authorization'] = 'Bearer '..config.todoist.apiToken, 
            ['Content-Type'] = 'application/json'
         },
         body = json.serialize{data = postBody},
         cache_time = config.global.cacheTime,
         live = config.global.isLive
      },
      retry = config.global.retryCount, pause = config.global.pauseTime 
   }
   return json.parse{data = response}
end

return todoist