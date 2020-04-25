local db2 = require 'db2'
local config = require 'config'

local conn = db2.connect{api = db.SQLITE, name = config.sql.name}

local function execute(sqlCommand)
   return conn:execute{sql = sqlCommand, live = config.global.isLive}
end

local database = {}

function database.insertNewProject(projectName, harvestProjectId, clockifyProjectId)
   return execute([[INSERT INTO projects (name, harvest_project_id, clockify_project_id) VALUES(']]..
      projectName..[[', ']]..
      harvestProjectId..[[', ']]..
      clockifyProjectId..[[');]])
end

function database.insertNewTask(projectName, taskName, harvestTaskId, clockifyTaskId)
   return execute([[INSERT INTO tasks (project_name, task_name, harvest_task_id, clockify_task_id) VALUES(']]..
      projectName..[[', ']]..
      taskName..[[', ']]..
      harvestTaskId..[[', ']]..
      clockifyTaskId..[[');]])
end

function database.insertNewTimeEntry(projectName, taskName, entryDate, duraction, harvestTimeEntryId, clockifyTimeEntryId)
   return execute([[INSERT INTO time_entries (project_name, task_name, entry_date, duration, harvest_time_entry_id, clockify_time_entry_id) VALUES(']]..
      projectName..[[', ']]..
      taskName..[[', ']]..
      entryDate..[[', ']]..
      duraction..[[', ']]..
      harvestTimeEntryId..[[', ']]..
      clockifyTimeEntryId..[[');]])
end

function database.getHarvestProjects(harvestProjectId)
   return execute([[SELECT * FROM projects WHERE harvest_project_id = ']]..harvestProjectId..[[';]])
end

function database.getHarvestTasks(taskName, harvestTaskId)
   return execute([[SELECT * FROM tasks WHERE task_name = ']]..
      taskName..[[' AND harvest_task_id = ']]..
      harvestTaskId..[[';]])
end

function database.getClockifyProjects(clockifyProjectId)
   return execute([[SELECT * FROM projects WHERE clockify_project_id = ']]..clockifyProjectId..[[';]])
end

function database.getClockifyTasks(clockifyTaskId)
   return execute([[SELECT * FROM tasks WHERE clockify_task_id = ']]..clockifyTaskId..[[';]])
end

function database.getClockifyTimeEntries(clockifyTimeEntryId)
   return execute([[SELECT * FROM time_entries WHERE clockify_time_entry_id = ']]..clockifyTimeEntryId..[[';]])
end

return database