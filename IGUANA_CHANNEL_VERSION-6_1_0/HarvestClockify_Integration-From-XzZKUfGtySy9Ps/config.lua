local file = require 'filesUtil'

local config = json.parse{data=file.readFile(os.getenv('HARVEST_CLOCKIFY_INTEGRATION_CONFIG'))}

return config