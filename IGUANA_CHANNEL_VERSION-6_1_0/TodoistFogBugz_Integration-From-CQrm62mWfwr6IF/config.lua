local file = require 'filesUtil'

local config = json.parse{data=file.readFile(os.getenv('TODOIST_FOGBUGZ_INTEGRATION_CONFIG'))}

return config