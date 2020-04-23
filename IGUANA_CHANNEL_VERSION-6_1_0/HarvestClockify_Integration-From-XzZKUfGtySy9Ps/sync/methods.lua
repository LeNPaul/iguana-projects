local harvest = require 'api.harvest'
local clockify = require 'api.clockify'
local database = require 'db.procedures'

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

local function addTimeEntry(clockifyTimeEntry)
   local project
   if tostring(clockifyTimeEntry.projectId) ~= 'NULL' then
      project = database.getClockifyProjects(clockifyTimeEntry.projectId)
   end
   if tostring(clockifyTimeEntry.timeInterval.duration) ~= 'NULL' and
      tostring(clockifyTimeEntry.taskId) ~= 'NULL' and 
      #database.getClockifyTimeEntries(clockifyTimeEntry.id) == 0 and
      #project ~= 0 then
      -- Time entry must have taskId, be in a project, have a duration and not be in database
      local task = database.getClockifyTasks(clockifyTimeEntry.taskId)
      local entryDate = convertTimezone(clockifyTimeEntry.timeInterval.start)
      local harvestHours = convertDurationFormat(clockifyTimeEntry.timeInterval.duration)
      local api_body = {
         ['user_id']    = tonumber(clockifyTimeEntry.userId),
         ['project_id'] = tonumber(project[1].harvest_project_id:nodeValue()),
         ['task_id']    = tonumber(task[1].harvest_task_id:split('-')[1]),
         ['spent_date'] = entryDate,
         ['hours']      = harvestHours
      }
      -- Make Post to create time entry in Harvest
      local harvestTimeEntryId = harvest.post('time_entries', api_body).id
      -- Insert time entry into database to indicate that it is synced
      database.insertNewTimeEntry(
         project[1].name:nodeValue(),
         task[1].task_name:nodeValue(), 
         entryDate, 
         harvestHours, 
         harvestTimeEntryId, 
         clockifyTimeEntry.id
      )
      -- Log the Harvest time entry creation
      iguana.logInfo(
         'The following time entry was added to Harvest: '..harvestHours..' hours'..'\n'..
         'The time entry was for the following project:  '..project[1].name:nodeValue()..'\n'..
         'The time entry was for the following task:     '..task[1].task_name:nodeValue())
   end
end

local function addTask(harvestActiveProject, harvestTask, clockifyWorkspaceId)
   -- If task ID not already in database, then it is not synced
   if #database.getHarvestTasks(harvestTask.task.name, harvestTask.task.id..[[-]]..harvestActiveProject.id) == 0 then 
      local clockifyProjectId = database.getHarvestProjects(harvestActiveProject.id)[1].clockify_project_id:nodeValue()
      local api_body = {
         ['name']      = harvestTask.task.name,
         ['projectId'] = clockifyProjectId
      }
      -- Make Post to create task in Clockify for corresponding project
      local clockifyTaskId = clockify.post('/workspaces/'..clockifyWorkspaceId..'/projects/'..clockifyProjectId..'/tasks', api_body).id
      -- Insert task into database to indicate that is is synced
      database.insertNewTask(
         harvestTask.project.name, 
         harvestTask.task.name, 
         harvestTask.task.id..[[-]]..harvestActiveProject.id, 
         clockifyTaskId
      )
      -- Log the Clockify task creation
      iguana.logInfo(
         'The following task was added to Clockify:   '..harvestTask.task.name..'\n'..
         'The task belonged to the following project: '..harvestActiveProject.name)
   end
end

local function addProject(harvestActiveProject, clockifyWorkspaceId)
   -- If project ID not already in database, then it is not synced
   local harvestProjectId = tostring(harvestActiveProject.id)
   if #database.getHarvestProjects(harvestProjectId) == 0 then
      local projectName = harvestActiveProject.name
      local apiBody = {
         ['name']     = projectName,
         ['color']    = '#3498DB',
         ['billable'] = true
      }
      -- Make Post to create project in Clockify
      local clockifyProject = clockify.post('workspaces/'..clockifyWorkspaceId..'/projects', apiBody)
      -- Insert project into database to indicate that it is synced
      database.insertNewProject(projectName, harvestProjectId, clockifyProject.id)
      -- Log the Clockify project creation
      iguana.logInfo('The following project was added to Clockify: '..projectName)
   end
end

local function loopHarvestProjectTasks(harvestActiveProject, clockifyWorkspaceId)
   -- Get all tasks for a project on Harvest
   local harvestTasks = harvest.get('projects/'..harvestActiveProject.id..'/task_assignments').task_assignments
   -- Loop through each task on Harvest
   for j=1, #harvestTasks do 
      addTask(harvestActiveProject, harvestTasks[j], clockifyWorkspaceId)
   end
end

local function loopActiveHarvestProjects(func, args)
   for i=1, #args[1] do 
      func(args[1][i], args[2])
   end
end

local run = {}

function run.syncProjects(self)
   loopActiveHarvestProjects(addProject, {self.harvest.harvestActiveProjects, self.clockify.workspaceId})
end

function run.syncTasks(self)
   loopActiveHarvestProjects(loopHarvestProjectTasks, {self.harvest.harvestActiveProjects, self.clockify.workspaceId})
end

function run.syncTimeEntries(self)
   -- Get time entries from Clockify
   local clockifyTimeEntries = clockify.get('/workspaces/'..self.clockify.workspaceId..'/user/'..self.clockify.userId..'/time-entries')
   -- Loop through each time entry
   for i=1, #clockifyTimeEntries do
      addTimeEntry(clockifyTimeEntries[i])
   end
end

return run