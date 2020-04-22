local harvest = require 'api.harvest'
local clockify = require 'api.clockify'
local syncer = require 'sync.run'

local sync = {}

function sync.init(self)

   self.harvest = {}
   local projects = harvest.get('projects').projects
   self.harvest.activeProjects = harvest.getActiveProjects(projects)

   self.clockify = {}
   local workspace = clockify.get('workspaces')
   self.clockify.workspaceId = workspace[1].id
   self.clockify.userId = workspace[1].memberships[1].userId
   
   self.projects = syncer.syncProjects
   self.tasks = syncer.syncTasks
   self.timeEntries = syncer.syncTimeEntries

end

return sync