-- Optional schema/base-data integration against a separately checked-out QuestieDB.
-- Never ships these files or data in our addon; no client/correction/locale claim.
local root = assert(os.getenv("WFLG_QUESTIEDB_PATH"), "Set WFLG_QUESTIEDB_PATH")
local modules = { QuestieDB = {}, ZoneDB = { private = {} } }
QuestieLoader = { ImportModule = function(_, name) return assert(modules[name], name) end }
local lib = { RequireContract = function() return true end, Enum = { questKeys = {}, raceMaskById = { [5] = 16 } } }
for _, entity in ipairs({ "Quest", "Npc", "Object", "Item" }) do
    local lower = entity:lower()
    local meta = assert(loadfile(root .. "/src/meta/" .. lower .. "Meta.lua"))("QuestieDB", lib)
    assert(loadfile(root .. "/data/Forever/forever" .. entity .. "DB.lua"))()
    -- The full data literal exceeds LuaJIT's constant limit. Decode only the
    -- requested independent generated rows in this trusted upstream fixture.
    local rows, decoded = {}, {}
    for line in assert(modules.QuestieDB[lower .. "Data"]):gmatch("[^\r\n]+") do
        local id, row = line:match("^%[(%d+)%]%s*=%s*({.*}),?%s*$")
        if id then rows[tonumber(id)] = row end
    end
    if entity == "Quest" then lib.Enum.questKeys = meta.keys end
    lib[entity] = { GetAll = function(id, fields)
        if not rows[id] then return nil end
        if not decoded[id] then decoded[id] = assert(loadstring("return " .. rows[id]))() end
        local result = { n = #fields }
        for i, field in ipairs(fields) do result[i] = decoded[id][assert(meta.keys[field], field)] end
        return result
    end }
end
assert(loadfile(root .. "/support/Forever/Zones/areaIdToUiMapId.lua"))()
lib.Support = { Get = function(name) return modules[name] end }
LibQuestieDB = lib
C_AddOns = { GetAddOnMetadata = function() return "Forever" end }
Enum = { UIMapType = { Zone = 3 } }
C_Map = { GetMapInfo = function(id) return { mapID = id, mapType = 3 } end }
local ns = { SafeCall = function(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end }
for _, name in ipairs({ "QuestHints", "RoutePlan", "DBCoordinates", "RouteState" }) do
    assert(loadfile("addon/WoWForeverLaunchGuide/" .. name .. ".lua"))("WFLG", ns)
end
local state = { quests = {}, completed = { [363] = true }, ready = true, logReady = true }
local player = { level = 11, race = "Scourge", raceMask = 16, classMask = 1 }
assert(ns.DBMapID(85) == 1420 and ns.DBMapID(130) == 1421)
assert(ns.QuestEligibility(363, state, player) == "done")
assert(ns.QuestEligibility(375, state, player) == "candidate")
assert(ns.QuestEligibility(421, state, player) == "candidate")
assert(ns.QuestEligibility(438, state, player) == "blocked")
assert(ns.QuestEligibility(480, state, player) == "blocked")
local points = ns.DBQuestGiverPoints(375, false)
assert(#points > 0 and points[1].map == 1420)
for _, point in ipairs(points) do assert(point.x >= 0 and point.x <= 1 and point.y >= 0 and point.y <= 1) end
local q = lib.Quest.GetAll(375, { "objectives" })
assert(q[1][3][2][1] == 2320 and q[1][3][2][3] == nil) -- Thread, no quantity in slot 3
print("integration_questiedb: public schema/base-data and Forever mapping fixture passed (no client validation)")
