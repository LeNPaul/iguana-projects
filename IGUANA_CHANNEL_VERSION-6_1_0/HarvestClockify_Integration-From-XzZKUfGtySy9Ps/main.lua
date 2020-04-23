local sync = require 'sync.class'

function main()

   -- Initialize some data first
   sync:init()

   -- Synchronize projects
   sync:projects()

   -- Synchronize tasks
   sync:tasks()

   -- Synchronize time entries
   sync:timeEntries()

end