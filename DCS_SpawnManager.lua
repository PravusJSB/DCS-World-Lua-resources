local readme = [[
  application: DCS World specific class, used to register, manage and spawn assets from pre-made Mission Editor objects or dynamically created objects
  
  Variables

  usage:

  call the file into your code with dofile or copy / paste the code below. MUST also use deepCopy function provided.
]]

-- your custom log function here
local log_func

-- create global table, useful if using more than one of my snippets
if not JSB then JSB = {} end
JSB.jsbLog = log_func or env.info

if not JSB.jsbLog or not (tostring and type and coalition) or (not table or not table.concat) then return end

-- SPM
    JSB.Spm = {}
    local spm = {}
    local spm_methods = {}
    local spm_objects = {}
    local spm_idx = 0
    local newIdx = function() spm_idx = spm_idx + 1 return tostring("-"..spm_idx) end
    local deepCopy = JSB.deepCopy
    local _log = JSB.jsbLog

    -- no_new @bool, true if want to retain the name and replace any existing objects
    -- return: @DCS_Group
    function spm_methods:spawn(no_new)
        if not no_new then
            self.name = self.name .. newIdx()
            for i = 1,#self.units do
                self.units[i].name = self.name .. "-unit" .. newIdx()
            end
        end
        self.lateActivation = false
        return coalition.addGroup( self.CountryID, self.CategoryID, self )
    end

    -- change the starting location of object
    -- x, y @number, coordinates
    -- alt @number, altitude in metres
    -- park @bool, is the object parked
    -- ground @table: { action: DCS waypoint action, type: DCS waypoint type}
    -- return: self
    function spm_methods:change_location(x,y,alt,park,ground)
        if not ground then ground = {} end
        self.route.points[1].x = x
        self.route.points[1].y = y
        self.route.points[1].alt = alt
        if park or ground.action then
            self.route.points[1].ETA_locked = false
            self.route.points[1].speed_locked = false
            self.route.points[1].speed = 138
            self.route.points[1].action = ground.action or "From Parking Area Hot"
            self.route.points[1].type = ground.type or "TakeOffParkingHot"
            self.units[1].parking = 1
            self.parked = park
        end
        self.x = x
        self.y = y
        self.units[1].x = x
        self.units[1].y = y
        return self
    end

    -- Replace the route of the object
    -- route @DCS_Waypoints, any number of ...
    -- return: self
    function spm_methods:init_route(route)
        for i = 1,#route do
            self.route.points[#self.route.points+1] = route[i]
        end
        return self
    end

    -- Change the rope length of a helicopter
    -- WARNING, no exception handling
    -- len @number, rope length in metres
    -- return: self
    function spm_methods:rope_length(len)
        self.units[1].ropeLength = len
        return self
    end

    -- Change the rope length of a helicopter
    -- WARNING, no exception handling
    -- has_hp @bool, false or nil to remove
    -- return: self
    function spm_methods:hard_points(has_hp)
        self.units[1].hardpoint_racks = has_hp or false
        return self
    end

    -- Change the first [2] waypoint and option to clear 3+
    -- WARNING, no exception handling
    -- waypoint @DCS_Waypoint
    -- clear @bool true to clear any other waypoints further to this one
    -- return: self
    function spm_methods:first_waypoint(waypoint, clear)
        self.route.points[2] = waypoint
        if clear and self.route.points[3] then
            repeat
                table.remove(self.route.points,3)
            until not self.route.points[3]
        end
        return self
    end

    -- return: @table, a copy of the template including methods
    function spm_methods:copy()
        return deepCopy(self)
    end

    spm.side = { "neutrals", "red", "blue" }

    -- internal function
    -- ME object name, side as an enum
    -- cats are string, plane, helicopter, ship, vehicle, static
    function spm.find(name,side,cat)
        if not side then return false end
        local data = env.mission.coalition[spm.side[side+1]]
        for j = 1,#data.country do
            if data.country[j][cat] then
                local Data = data.country[j][cat].group
                for i = 1,#Data do
                    if Data[i].name == name then
                        return deepCopy(Data[i])
                    end
                end
            end
        end
        return false
    end

    -- internal function
    -- overload of search
    function spm.search_internal(side,cat)
        local res = {}
        local data = env.mission.coalition[spm.side[side+1]]
        for j = 1,#data.country do
            if data.country[j][cat] then
                local Data = data.country[j][cat].group
                for i = 1,#Data do
                    res[Data[i].name] = {
                        ['LA'] = Data[i].lateActivation,
                        ['units'] = {},
                    }
                    for u = 1,#Data[i].units do
                        res[Data[i].name].units[Data[i].units[u].name] = {
                            ['type'] = Data[i].units[u].type,
                            ['skill'] = Data[i].units[u].skill,
                        }
                    end
                end
            end
        end
        return res
    end

    -- ME object name, side as an enum
    -- cats are string, plane, helicopter, ship, vehicle, static
    -- returns string by default for report, or if int (#bool) returns as a table
    function spm.search(side,cat,int)
        if not side then return false elseif int then return spm.search_internal(side,cat) end
        local fmt = string.format
        local res = {}
        local data = env.mission.coalition[spm.side[side+1]]
        for j = 1,#data.country do
            if data.country[j][cat] then
                local Data = data.country[j][cat].group
                for i = 1,#Data do
                    res[#res+1] = fmt(" %s : %d of untis (LA = %s);\n",Data[i].name,#Data[i].units,tostring(Data[i].lateActivation))
                    for u = 1,#Data[i].units do
                        res[#res+1] = fmt("   %s of type %s with skill %s\n",Data[i].units[u].name,Data[i].units[u].type,Data[i].units[u].skill)
                    end
                end
            end
        end
        return table.concat(res)
    end

    -- return: crude report on all client aircraft
    function spm.clientReport()
        local fmt = string.format
        local res = {}
        res[#res+1] = "Client slot report\n\n"
        local data = env.mission.coalition.blue
        for j = 1,#data.country do
            if data.country[j]['plane'] then
                local Data = data.country[j]['plane'].group
                for i = 1,#Data do
                    if Data[i].units[1].skill == 'Client' then
                        res[#res+1] = fmt(" Client slot :: %s :: %s\n",Data[i].name,Data[i].units[1].type)
                    end
                end
            elseif data.country[j]['helicopter'] then
                local Data = data.country[j]['helicopter'].group
                for i = 1,#Data do
                    if Data[i].units[1].skill == 'Client' then
                        res[#res+1] = fmt(" Client slot :: %s :: %s\n",Data[i].name,Data[i].units[1].type)
                    end
                end
            end
        end
        return table.concat(res)
    end

    -- global access to search function
    JSB.Spm.search = spm.search
    JSB.Spm.client_report = spm.clientReport

    -- ME object name, side as an enum
    -- cats are string, plane, helicopter, ship, vehicle, static
    -- newname string to save template as new object : initial search on ME name
    function JSB.Spm.get(name,side,cat,newname)
        if not name then return end
        if spm_objects[newname or name] then return spm_objects[newname or name] end
        local template = spm.find(name,side,cat)
        if not template then
            return
        else
            if newname then
                template.name = newname .. newIdx()
                for i = 1,#template.units do
                    template.units[i].name = "spm_unit" .. newIdx()
                end
            end
            spm_objects[newname or name] = template
            setmetatable(spm_objects[newname or name],{__index = spm_methods})
            return spm_objects[newname or name]
        end
    end

    -- Spm Build from code, code...
        local random_name_seed = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        local grp_idx = math.random(5000)
        local unit_idx = math.random(3000)

        local function random_name()
            local name = {}
            for i = 1,3 do
                local rand = math.random(36)
                name[#name+1] = random_name_seed:sub(rand - 1, rand)
            end
            return table.concat(name)
        end

        local function build_unit(raw_tbl, tran)
            unit_idx = unit_idx + 1
            return {
                ["type"] = raw_tbl.type,
                ["transportable"] = {["randomTransportable"] = tran or false},
                ["skill"] = "High",
                ["y"] = raw_tbl.y,
                ["x"] = raw_tbl.x,
                ["name"] = raw_tbl.name or string.format("%s-%d", random_name(), unit_idx),
                ["heading"] = raw_tbl.heading,
                ["playerCanDrive"] = tran or false,
            }
        end

        -- {
        --     x = 0,
        --     y = 0,
        --     heading = 0,
        --     type = "",
        --     name = "",
        --     country = 0,
        -- }

        local function unit_gen(data, tran)
            local unit_return = {}
            for i = 2,#data do
                unit_return[#unit_return+1] = build_unit(data[i], tran)
            end
            return unit_return
        end

        local function build_group(country, group_data, group_name) -- TODO
            grp_idx = grp_idx + 1
            return
            {
                --
                ["task"] = "Ground Nothing",
                ["name"] = group_name or string.format("%s-%d", random_name(), grp_idx),
                --
                ["units"] = unit_gen(group_data, country == 2),
                --
                ["tasks"] = {},
                ["country"] = country,
            }
        end

            function JSB.Spm.buildGroundGroup(country, group_data, group_name)
                if not group_data then return _log("Spm: Error building group, no data!") end
                return build_group(country, group_data, group_name)
            end
    --
--