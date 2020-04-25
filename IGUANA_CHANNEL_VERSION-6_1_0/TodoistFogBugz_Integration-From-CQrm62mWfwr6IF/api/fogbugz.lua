require 'net.http.cache'
local config = require 'config'
local retry = require 'retry'

local function getToken()
   local response = retry.call{
      funcname = 'getToken',
      func = net.http.get,
      arg1 = {
         url = config.fogbugz.baseUrl,
         parameters = {
            ['cmd'] = 'logon', 
            ['email'] = config.fogbugz.user, 
            ['password'] = config.fogbugz.password
         },
         live = config.global.isLive,
         cache_time = config.global.cacheTime
      },
      retry = config.global.retryCount, pause = config.global.pauseTime 
   }
   return xml.parse{data=response}.response.token[1]:nodeValue()
end

local fogbugzApiToken = getToken()

local fogbugz = {}

function fogbugz.get(params)
   local response = retry.call{
      funcname = 'fogbugz.get',
      func = net.http.get,
      arg1 = {
         url = config.fogbugz.baseUrl..'?token='..fogbugzApiToken,
         parameters = params,
         live = config.global.isLive,
         cache_time = config.global.cacheTime
      },
      retry = config.global.retryCount, pause = config.global.pauseTime 
   }
   return xml.parse{data=response}
end

function fogbugz.post(params)
   local response = retry.call{
      funcname = 'fogbugz.post',
      func = net.http.post,
      arg1 = {
         url = config.fogbugz.baseUrl..'?token='..fogbugzApiToken,
         parameters = params,
         live = config.global.isLive,
         cache_time = config.global.cacheTime
      },
      retry = config.global.retryCount, pause = config.global.pauseTime 
   }
   return xml.parse{data=response}
end

return fogbugz