local todoist = require 'api.todoist'
local fogbugz = require 'api.fogbugz'
local methods = require 'sync.methods'

local sync = {}

function sync.init(self)

   self.tasks = methods.syncTasks
   self.tickets = methods.syncTickets
   
end

return sync