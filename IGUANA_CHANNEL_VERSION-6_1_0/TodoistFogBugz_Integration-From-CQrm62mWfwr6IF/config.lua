local file = require 'filesUtil'

-- Create a JSON file with the following structure and add in credentials and configurations
-- Configure an environment variable called "TODOIST_FOGBUGZ_INTEGRATION_CONFIG" with the path of the JSON file
--[[
{
   "fogbugz": {
      "password": "",
      "user": "",
      "baseUrl": ""
   },
   "global": {
      "retryCount": 3,
      "cacheTime": 0,
      "pauseTime": 10,
      "isLive": false
   },
   "sql": {
      "name": ""
   },
   "todoist": {
      "apiToken": "",
      "baseUrl": ""
   }
}
]]--

local config = json.parse{data=file.readFile(os.getenv('TODOIST_FOGBUGZ_INTEGRATION_CONFIG'))}

return config