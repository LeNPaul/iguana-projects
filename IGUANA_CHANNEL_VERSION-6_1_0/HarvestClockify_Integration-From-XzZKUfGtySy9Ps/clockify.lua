require 'net.http.cache'

-- Clockify Configuration

local clockifyApiToken = 'XpuKcKJoa2me1Srx'

-- Helper Functions for Clockify

local clockify = {}

function clockify.clockifyApiGetCall(uri)
   return net.http.get{
      url='https://api.clockify.me/api/v1/'..uri,
      headers = {
         ['content-type'] = 'application/json',
         ['X-Api-Key'] = clockifyApiToken
      },
      cache_time = 0,
      live = true
   }
end

function clockify.clockifyApiPostCall(uri, post_body)
   return net.http.post{
      url='https://api.clockify.me/api/v1/'..uri,
      headers = {
         ['content-type'] = 'application/json',
         ['X-Api-Key'] = clockifyApiToken
      },
      body = json.serialize{data=post_body},
      cache_time = 0,
      live = true
   }
end

return clockify