local file = {}

-- Read a file
function file.readFile(filePath)
   local F = io.open(filePath, "r")
   local Content = F:read("*a")
   F:close()
   return Content
end

-- Write to a file where if isAppend is true, then append to the file 
-- and if isAppend is false, then overwrite file contents
function file.writeFile(filePath, content, isAppend)
   local F
   if isAppend then 
      F = io.open(filePath,'a')
   elseif not isAppend then
      F = io.open(filePath,'w')
   end
   F:write(content)
   F:close()
end

return file