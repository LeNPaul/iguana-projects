local harvest = require 'api.harvest'
local clockify = require 'api.clockify'
local controller = require 'sync.run'

local sync = {}

function sync.init(self)

   self.harvest = {}
   local projects = harvest.get('projects').projects
   self.harvest.activeHarvestProjects = harvest.getActiveProjects(projects)

   self.clockify = {}
   local workspace = clockify.get('workspaces')
   self.clockify.workspaceId = workspace[1].id
   self.clockify.userId = workspace[1].memberships[1].userId
   
   self.projects = controller.syncProjects
   self.tasks = controller.syncTasks
   self.timeEntries = controller.syncTimeEntries

end

return sync