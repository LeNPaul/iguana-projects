local database = {}

function database.executeSql(sql_command)
   local connection = db.connect{api=db.SQLITE, name = '/Users/paul.le/Desktop/harvest_clockify.db'}
   return connection:execute{sql=sql_command, live = true}
end

return database