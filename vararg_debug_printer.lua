local readme = [[
  application: not DCS World specific if log function is provided

  can be used to output a readable error into log file which rather than print out a single message
  will print out the passed arguments. 
  
  Variables can be tables, arrays or vararg with nested tables in vararg, and 'overloaded' 3rd argument.

  usage: JSB.debug_print("module_name", "func_name", {args = arg}, variable1, variable2 ...) or JSB.debug_print("module_name", "func_name", variable1, variable2 ...)

  call the file into your code with dofile or copy / paste the code below.
]]

-- your custom log function here
local log_func

-- create global table, useful if using more than one of my snippets
if not JSB then JSB = {} end
JSB.jsbLog = log_func or env.info

if not JSB.jsbLog or not tostring or not type or (not table or not table.concat) then return end

local function debug_key_value(args)
  local to_string = tostring
  if not args or type(args) ~= 'table' then return "\n" end
  local debug_msg_table = {}
  for k, v in pairs (args) do
    debug_msg_table[#debug_msg_table+1] = to_string(k)
    debug_msg_table[#debug_msg_table+1] = " = "
    debug_msg_table[#debug_msg_table+1] = to_string(v)
    debug_msg_table[#debug_msg_table+1] = "\n"
  end
  return table.concat(debug_msg_table)
end

-- module_name @string
-- func_name @string
-- args @key,value table or variable (any)
-- ... @single vararg or array
function JSB.debug_print(module_name, func_name, args, ...)
  if (not module_name or not func_name) or not args then JSB.jsbLog(module_name .. " :: debug print error (wrong args passed) in function: " .. func_name)
    return
  end
  local vars = {...}
  local to_string = tostring
  local idx = 0
  local debug_msg = {}
  debug_msg[#debug_msg+1] = module_name
  debug_msg[#debug_msg+1] = " :: debug in function: "
  debug_msg[#debug_msg+1] = func_name
  debug_msg[#debug_msg+1] = "\n"
  if type(args) == 'table' then
    debug_msg[#debug_msg+1] = debug_key_value(args)
  else
    debug_msg[#debug_msg+1] = to_string(idx)
    debug_msg[#debug_msg+1] = " = "
    debug_msg[#debug_msg+1] = to_string(args)
    debug_msg[#debug_msg+1] = "\n"
    idx = 1
  end
  if vars then
    for i = 1, #vars do
      if type(vars[i]) == 'table' then
        debug_msg[#debug_msg+1] = debug_key_value(vars[i])
      else
        debug_msg[#debug_msg+1] = to_string(i+idx)
        debug_msg[#debug_msg+1] = " = "
        debug_msg[#debug_msg+1] = to_string(vars[i])
        debug_msg[#debug_msg+1] = "\n"
      end
    end
  elseif vars then
    debug_msg[#debug_msg+1] = to_string(vars)
  end
  JSB.jsbLog(table.concat(debug_msg))
end