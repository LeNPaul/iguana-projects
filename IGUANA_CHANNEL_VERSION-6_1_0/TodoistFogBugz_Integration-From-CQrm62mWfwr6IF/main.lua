local sync = require 'sync.class'

function main()

   -- Initialize some data first
   sync:init()

   -- Add FogBugz tickets as Todoist tasks
   sync:tasks()

   -- Close FogBugz tickets when Todoist task complete
   sync:tickets()

end