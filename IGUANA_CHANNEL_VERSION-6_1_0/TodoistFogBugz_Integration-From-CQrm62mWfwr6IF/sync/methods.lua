local config = require 'config'
local fogbugz = require 'api.fogbugz'
local todoist = require 'api.todoist'
local database = require 'db.procedures'

local function addTodoistTask(fogbugzTicket)
   -- If task not currently in database then add task to Todoist
   local ticketNumber = fogbugzTicket.ixBug:nodeValue()
   if #database.getTicket(ticketNumber) == 0 then 
      -- Create Todoist task
      local postBody = {
         ['content'] = 'Support | '..fogbugzTicket.sTitle[1]:nodeValue()..' - '..
         ' http://fogbugz.interfaceware.com/default.asp?'..
         ticketNumber..' ('..ticketNumber..')',
         ['due_string'] = 'today'
      }
      local taskId = todoist.post('tasks', postBody).id
      -- Insert task to database
      database.insertNewTicket(fogbugzTicket.sTitle[1]:nodeValue(), taskId, fogbugzTicket.ixBug:nodeValue())
      -- Log the task/ticket creation
      iguana.logInfo('The following ticket was added as a task to Todoist: '..
         fogbugzTicket.sTitle[1]:nodeValue()..' #'..fogbugzTicket.ixBug:nodeValue())
   end
end

local function closeFogbugzTicket(activeTicket, activeTodoistTasks)
   -- If active ticket is not an active Todoist task then task has been completed
   local completed = true
   for i=1, #activeTodoistTasks do 
      if activeTodoistTasks[i].content:find(activeTicket.fogbugz_ticket_number:nodeValue()) then 
         completed = false
         break
      end
   end
   -- If task is completed then close FogBugz ticket
   if completed then
      -- Resolve ticket on FogBugz
      local params = {
         ['cmd'] = 'resolve', 
         ['ixBug'] = activeTicket.fogbugz_ticket_number:nodeValue()
      }
      fogbugz.post(params)
      -- Close ticket on FogBugz
      local params = {
         ['cmd'] = 'close', 
         ['ixBug'] = activeTicket.fogbugz_ticket_number:nodeValue()
      }
      fogbugz.post(params)
      -- Mark the status in the database to 1 for completed
      database.markTicketComplete(activeTicket.fogbugz_ticket_number:nodeValue())
      -- Log the FogBugz ticket being closed
      iguana.logInfo('The following ticket was closed on FogBugz: '..
         activeTicket.ticket_name:nodeValue()..' #'..activeTicket.fogbugz_ticket_number:nodeValue())
   end
end

local run = {}

function run.syncTasks(self)
   -- Get active FogBugz tickets
   local params = {
      ['cmd'] = 'search', 
      ['ixPersonAssignedTo'] = config.fogbugz.user,
      ['cols'] = 'sTitle,sTicket'
   }
   local activeFogbugzTickets = fogbugz.get(params).response.cases
   -- Loop through active FogBugz tickets
   for i=1, activeFogbugzTickets:childCount("case") do
      -- Add task to Todoist
      addTodoistTask(activeFogbugzTickets:child("case", i))
   end
end

function run.syncTickets(self)
   -- Get open tasks/tickets from database
   local activeTickets = database.getAllTickets()
   -- Get all active tasks on Todoist
   local activeTodoistTasks = todoist.get('tasks')
   -- Loop through active FogBugz tickets
   for i=1, #activeTickets do 
      -- If Todoist task is completed then close ticket on FogBugz
      closeFogbugzTicket(activeTickets[i], activeTodoistTasks)
   end
end

return run