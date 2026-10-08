local _, ns = ...
local cachedLib, cachedSource, mapping

local function foreverDB()
    local lib = _G.LibQuestieDB
    if type(lib) ~= "table" then return nil end
    local ok, accepted = ns.SafeCall(lib.RequireContract, 2)
    if not ok or accepted ~= true then return nil end
    local metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local flavorOK, flavor = ns.SafeCall(metadata, lib.addonName or "QuestieDB", "X-Flavor")
    if not flavorOK or flavor ~= "Forever" then return nil end
    return lib
end

-- Public Support.Get publishes this legacy-named structure explicitly. Parse
-- numeric literal entries only: never evaluate dependency-provided Lua strings.
local function numericMap(source)
    if type(source) == "table" then return source end
    if type(source) ~= "string" or #source > 500000 then return nil end
    local entries = {}
    source = source:gsub("%-%-[^\r\n]*", "")
    local body = source:match("^%s*return%s*{(.*)}%s*$")
    if not body then return nil end
    for area, map in body:gmatch("%[(%d+)%]%s*=%s*(%d+)") do
        entries[tonumber(area)] = tonumber(map)
    end
    -- Reject expressions/code rather than extracting partial plausible mappings.
    local residue = body:gsub("%[%d+%]%s*=%s*%d+", ""):gsub("[%s,;]", "")
    if residue ~= "" then return nil end
    return entries
end

function ns.DBMapID(areaID)
    local lib = foreverDB()
    if not lib or type(lib.Support) ~= "table" then return nil end
    local ok, zones = ns.SafeCall(lib.Support.Get, "ZoneDB")
    local source = ok and type(zones) == "table" and type(zones.private) == "table" and zones.private.areaIdToUiMapId or nil
    if cachedLib ~= lib or cachedSource ~= source then
        cachedLib, cachedSource, mapping = lib, source, numericMap(source)
    end
    local map = mapping and mapping[areaID]
    if type(map) ~= "number" or map <= 0 then return nil end
    local infoOK, info = ns.SafeCall(C_Map and C_Map.GetMapInfo, map)
    local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone
    if not infoOK or type(info) ~= "table" or info.mapID ~= map or not zoneType or info.mapType ~= zoneType then return nil end
    return map
end

function ns.DBEntityPoints(entity, id)
    local data = ns.DBRead(entity, id, { "name", "spawns" })
    local points = {}
    if not data or type(data[2]) ~= "table" then return points end
    for area, rows in pairs(data[2]) do
        local map = ns.DBMapID(area)
        if map and type(rows) == "table" then
            for _, row in ipairs(rows) do
                local x, y = row[1], row[2]
                if type(x) == "number" and type(y) == "number" and x >= 0 and x <= 100 and y >= 0 and y <= 100
                    and (row[3] == nil or row[3] == 0) then
                    points[#points + 1] = { map = map, x = x / 100, y = y / 100, entityID = id,
                        name = data[1], source = "QuestieDB Forever: public Support map + spawn" }
                end
            end
        end
    end
    table.sort(points, function(a, b)
        if a.map ~= b.map then return a.map < b.map end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    return points
end

function ns.DBQuestGiverPoints(questID, turnin)
    local data = ns.DBRead("Quest", questID, { turnin and "finishedBy" or "startedBy" })
    local points = {}
    if not data or type(data[1]) ~= "table" then return points end
    for index, entity in ipairs({ "Npc", "Object" }) do
        for _, id in ipairs(data[1][index] or {}) do
            for _, point in ipairs(ns.DBEntityPoints(entity, id)) do points[#points + 1] = point end
        end
    end
    return points
end
