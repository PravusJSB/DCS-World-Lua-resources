local readme = [[
  application: Not DCS Specific, copies a table and respects any metamethods, if shallow true only shallow copy
  
  object must be a table

  usage: JSB.deepCopy({...})
  return: exact copy of table object with methods

  call the file into your code with dofile or copy / paste the code below.
]]

-- create global table, useful if using more than one of my snippets
if not JSB then JSB = {} end

if not (pairs and setmetatable and type and getmetatable) then return end

local type_local, pairs_local, setmt_local, getmt_local = type, pairs, setmetatable, getmetatable
local lookup_table = {}

local function copy_function(object, shallow)
  if type_local(object) ~= "table" then
    return object
  elseif lookup_table[object] then
    return lookup_table[object]
  end
  local new_table = {}
  lookup_table[object] = new_table
  for index, value in pairs_local(object) do
    new_table[copy_function(index)] = copy_function(value)
  end
  if shallow then return new_table end
  return setmt_local(new_table, getmt_local(object))
end
 
JSB.deepCopy = function(table_object, shallow)
  lookup_table = {}
  return copy_function(table_object, shallow)
end
