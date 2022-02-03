local readme = [[
  application: DCS World specific, can be applied to other DCS API/SSE methods.

  Very simple performance method for calling attribute checks on mission assets at runtime using metatables.

  usage: Detailed in the .pdf file in the repo, and not required but i build the cache on initial mission load as I bring in my persistence like so;

    local attr_cache = JSB.has_att_cache()
    local units = spawn:getUnits()
    for a = 1,#units do
      attr_cache[units[a]:getName()] = deepCopy(units[a]:getDesc().attributes)
    end

  call the file into your code with dofile or copy / paste the code below.
]]

-- create global table, useful if using more than one of my snippets
if not JSB then JSB = {} end

-- hasAttribue cache
  local has_attribute = {
    spawned_groups = {},
  }
  setmetatable(has_attribute, { __call = function (self, object, attribute)
    if not object then return end
    local object_name = object:getName()
    if self[object_name] and self[object_name][attribute] ~= nil then
      return self[object_name][attribute]
    elseif not self[object_name] then
      self[object_name] = {}
    end
    self[object_name][attribute] = object:hasAttribute(attribute) or false
    return self[object_name][attribute]
  end })
--

-- API Access to caches
  JSB.has_att_cache = function() return has_attribute end
--