local db2 = require 'db2'
local config = require 'config'

local conn = db2.connect{api = db.SQLITE, name = config.sql.name}

local function execute(sqlCommand)
   return conn:execute{sql = sqlCommand, live = config.global.isLive}
end

local database = {}

function database.getAllTickets()
   return execute([[SELECT * FROM tickets WHERE status = 0]])
end

function database.getTicket(ticketNumber)
   return execute([[SELECT * FROM tickets WHERE fogbugz_ticket_number= ']]..ticketNumber..[[';]])
end

function database.insertNewTicket(ticketName, todoistTaskId, fogbugzTicketNumber)
   return execute([[INSERT INTO tickets (ticket_name, todoist_task_id, fogbugz_ticket_number, status) VALUES(']]..
      ticketName..[[', ']]..
      todoistTaskId..[[', ']]..
      fogbugzTicketNumber..[[', 0);]])
end

function database.markTicketComplete(fogbugzTicketNumber)
   return execute([[UPDATE tickets SET status = 1 WHERE fogbugz_ticket_number = ']]..fogbugzTicketNumber..[[';]])
end

return database