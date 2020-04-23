local harvest = require 'api.harvest'
local clockify = require 'api.clockify'
local methods = require 'sync.methods'

local sync = {}

function sync.init(self)

   self.harvest = {}
   local projects = harvest.get('projects').projects
   self.harvest.harvestActiveProjects = harvest.getActiveProjects(projects)

   self.clockify = {}
   local workspace = clockify.get('workspaces')
   self.clockify.workspaceId = workspace[1].id
   self.clockify.userId = workspace[1].memberships[1].userId

   self.projects = methods.syncProjects
   self.tasks = methods.syncTasks
   self.timeEntries = methods.syncTimeEntries

end

return sync