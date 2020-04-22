local harvest = require 'api.harvest'
local clockify = require 'api.clockify'
local database = require 'db.procedures'

local controller = {}

function controller.syncProjects(self)
   -- Get active Harvest projects
   local activeProjects = self.harvest.activeProjects
   -- Loop through each active Harvest project
   for i=1, #activeProjects do 
      -- If project ID not already in database, then it is not synced
      local harvestProjectId = tostring(activeProjects[i].id)
      if #database.getHarvestProjects(harvestProjectId) == 0 then
         local projectName = activeProjects[i].name
         local apiBody = {
            ['name']     = projectName,
            ['color']    = '#3498DB',
            ['billable'] = true
         }
         -- Make Post to create project in Clockify
         local clockifyProject = clockify.post('workspaces/'..self.clockify.workspaceId..'/projects', apiBody)
         -- Insert project into database to indicate that it is synced
         database.insertNewProject(projectName, harvestProjectId, clockifyProject.id)
         -- Log the Clockify project creation
         iguana.logInfo('The following project was added to Clockify: '..projectName)
      end
   end
end

function controller.syncTasks(self)
   -- Get active Harvest projects
   local activeProjects = self.harvest.activeProjects
   -- Loop through each active Harvest project
   for i=1, #activeProjects do 
      -- Get all tasks for a project on Harvest
      local harvestProjectId = activeProjects[i].id
      local harvestTasks     = harvest.get('projects/'..harvestProjectId..'/task_assignments').task_assignments
      -- Loop through each task on Harvest
      for j=1, #harvestTasks do 
         -- If task ID not already in database, then it is not synced
         if #database.getHarvestTasks(harvestTasks[j].task.name, harvestTasks[j].task.id..[[-]]..harvestProjectId) == 0 then 
            local clockifyProjectId = database.getHarvestProjects(harvestProjectId)[1].clockify_project_id:nodeValue()
            local api_body = {
               ['name']      = harvestTasks[j].task.name,
               ['projectId'] = clockifyProjectId
            }
            -- Make Post to create task in Clockify for corresponding project
            local clockifyTaskId = clockify.post('/workspaces/'..self.clockify.workspaceId..'/projects/'..clockifyProjectId..'/tasks', api_body).id
            -- Insert task into database to indicate that is is synced
            database.insertNewTask(
               harvestTasks[j].project.name, 
               harvestTasks[j].task.name, 
               harvestTasks[j].task.id..[[-]]..harvestProjectId, 
               clockifyTaskId
            )
            -- Log the Clockify task creation
            iguana.logInfo(
               'The following task was added to Clockify:   '..harvestTasks[j].task.name..'\n'..
               'The task belonged to the following project: '..activeProjects[i].name)
         end
      end
   end
end

-- Convert Clockify duration format to Harvest hours format
local function convertDurationFormat(duration)
   local seconds = duration:match("%a(%d+)S") or 0
   local minutes = duration:match("%a(%d+)M") or 0
   local hours   = duration:match("%a(%d+)H") or 0
   return tostring((seconds / 60 + minutes) / 60 + hours)
end

-- Convert GMT to ET time zone
local function convertTimezone(dateTime)
   return os.ts.date("%Y-%m-%d", os.ts.time{
         year  = dateTime:sub(1,4), 
         month = dateTime:sub(6,7), 
         day   = dateTime:sub(9,10), 
         hour  = dateTime:sub(12,13), 
         min   = dateTime:sub(15,16),
         sec   = dateTime:sub(18,19)} - 14400)
end

function controller.syncTimeEntries(self)
   -- Get time entries from Clockify
   local userId              = self.clockify.userId
   local clockifyTimeEntries = clockify.get('/workspaces/'..self.clockify.workspaceId..'/user/'..userId..'/time-entries')
   -- Loop through each time entry
   for i=1, #clockifyTimeEntries do
      local isTaskExists
      if tostring(clockifyTimeEntries[i].taskId) ~= 'NULL' then 
         isTaskExists = database.getClockifyTasks(clockifyTimeEntries[i].taskId)
      end
      local isProjectExists
      if tostring(clockifyTimeEntries[i].projectId) ~= 'NULL' then
         isProjectExists = database.getClockifyProjects(clockifyTimeEntries[i].projectId)
      end
      if isTaskExists ~= nil and #isProjectExists ~= 0 and #database.getClockifyTimeEntries(clockifyTimeEntries[i].id) == 0 then 
         local entryDate = convertTimezone(clockifyTimeEntries[i].timeInterval.start)
         if tostring(clockifyTimeEntries[i].timeInterval.duration) ~= 'NULL' then
            local harvestHours = convertDurationFormat(clockifyTimeEntries[i].timeInterval.duration)
            local api_body = {
               ['user_id']    = tonumber(userId),
               ['project_id'] = tonumber(isProjectExists[1].harvest_project_id:nodeValue()),
               ['task_id']    = tonumber(isTaskExists[1].harvest_task_id:split('-')[1]),
               ['spent_date'] = entryDate,
               ['hours']      = harvestHours
            }
            -- Make Post to create time entry in Harvest
            local harvestTimeEntryId = harvest.post('time_entries', api_body).id
            -- Insert time entry into database to indicate that it is synced
            database.insertNewTimeEntry(
               isProjectExists[1].name:nodeValue(),
               isTaskExists[1].task_name:nodeValue(), 
               entryDate, 
               harvestHours, 
               harvestTimeEntryId, 
               clockifyTimeEntries[i].id
            )
            -- Log the Harvest time entry creation
            iguana.logInfo(
               'The following time entry was added to Harvest: '..harvestHours..' hours'..'\n'..
               'The time entry was for the following project:  '..isProjectExists[1].name:nodeValue()..'\n'..
               'The time entry was for the following task:     '..isTaskExists[1].task_name:nodeValue())
         end
      end
   end
end

return controller