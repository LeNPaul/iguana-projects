local harvest = require 'api.harvest'
local clockify = require 'api.clockify'
local database = require 'db.procedures'

local controller = {}

function controller.syncProjects(active_projects, workspace_id)
   for i=1, #active_projects do 
      local project_name = active_projects[i].name
      local project_id = tostring(active_projects[i].id)
      local current_projects = database.executeSql([[SELECT * FROM projects WHERE name = ']]..project_name..[[' AND harvest_project_id = ']]..project_id..[[';]])
      if #current_projects == 0 then 
         -- Post to Clockify and get the project_id for Clockify
         local api_body = {
            ['name'] = project_name,
            ['color'] = '#3498DB',
            ['billable'] = true
         }
         local response = clockify.post('workspaces/'..workspace_id..'/projects', api_body)
         local clockify_project_id = json.parse{data=response}.id 
         database.executeSql([[INSERT INTO projects (name, harvest_project_id, clockify_project_id) VALUES(']]..
            project_name..[[', ']]..
            project_id..[[', ']]..
            clockify_project_id..[[');]])
      end
   end
end

function controller.syncTasks(active_projects, workspace_id)
   for i=1, #active_projects do 

      local project_id = active_projects[i].id

      local task_assignments = json.parse{data=harvest.get('projects/'..project_id..'/task_assignments')}

      trace(task_assignments)

      for j=1, #task_assignments.task_assignments do 

         local current_task_assignments = database.executeSql([[SELECT * FROM tasks WHERE task_name = ']]..
            task_assignments.task_assignments[j].task.name..[[' AND harvest_task_id = ']]..
            task_assignments.task_assignments[j].task.id..[[-]]..project_id..[[';]])

         trace(task_assignments.task_assignments[j].project.name)
         trace(task_assignments.task_assignments[j].task.name)
         trace(#current_task_assignments)

         if #current_task_assignments == 0 then 

            local current_projects = database.executeSql([[SELECT * FROM projects WHERE harvest_project_id = ']]..project_id..[[';]])

            local clockify_project_id = current_projects[1].clockify_project_id:nodeValue()

            local api_body = {
               ['name'] = task_assignments.task_assignments[j].task.name,
               ['projectId'] = clockify_project_id
            }
            local clockify_task_id = json.parse{data=clockify.post('/workspaces/'..workspace_id..'/projects/'..clockify_project_id..'/tasks', api_body)}.id 

            database.executeSql([[INSERT INTO tasks (project_name, task_name, harvest_task_id, clockify_task_id) VALUES(']]..
               task_assignments.task_assignments[j].project.name..[[', ']]..
               task_assignments.task_assignments[j].task.name..[[', ']]..
               task_assignments.task_assignments[j].task.id..[[-]]..project_id..[[', ']]..
               clockify_task_id..[[');]])

         end
      end
   end
end

function controller.syncTimeEntries(workspace_id, user_id)
   local time_entries = json.parse{data=clockify.get('/workspaces/'..workspace_id..'/user/'..user_id..'/time-entries')}
   for i=1, #time_entries do 
      trace(time_entries)
      local isTaskExists
      if tostring(time_entries[i].taskId) ~= 'NULL' then 
         isTaskExists = database.executeSql([[SELECT * FROM tasks WHERE clockify_task_id = ']]..time_entries[i].taskId..[[';]])
      end
      local isProjectExists
      if tostring(time_entries[i].projectId) ~= 'NULL' then
         isProjectExists = database.executeSql([[SELECT * FROM projects WHERE clockify_project_id = ']]..time_entries[i].projectId..[[';]])
      end
      local current_time_entries = database.executeSql([[SELECT * FROM time_entries WHERE clockify_time_entry_id = ']]..time_entries[i].id..[[';]])

      if isTaskExists ~= nil and #isProjectExists ~= 0 and #current_time_entries == 0 then 

         local time_entry = trace(time_entries[i])
         local entry_date = time_entries[i].timeInterval.start:sub(1,10)
         local duration = time_entries[i].timeInterval.duration

         local seconds = duration:match("%a(%d+)S") or 0
         local minutes = duration:match("%a(%d+)M") or 0
         local hours = duration:match("%a(%d+)H") or 0

         local harvest_hours = tostring((seconds / 60 + minutes) / 60 + hours)

         local api_body = {
            ['user_id'] = tonumber(user_id),
            ['project_id'] = tonumber(isProjectExists[1].harvest_project_id:nodeValue()),
            ['task_id'] = tonumber(isTaskExists[1].harvest_task_id:split('-')[1]),
            ['spent_date'] = entry_date,
            ['hours'] = harvest_hours
         }
         local harvest_time_entry = json.parse{data=harvest.post('time_entries', api_body)}.id
         database.executeSql([[INSERT INTO time_entries (project_name, task_name, entry_date, duration, harvest_time_entry_id, clockify_time_entry_id) VALUES(']]..
            isProjectExists[1].name:nodeValue()..[[', ']]..
            time_entries[i].description..[[', ']]..
            entry_date..[[', ']]..
            harvest_hours..[[', ']]..
            harvest_time_entry..[[', ']]..
            time_entries[i].id..[[');]])
      end

   end
end

return controller