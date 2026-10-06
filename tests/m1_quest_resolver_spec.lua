local function loadResolver(env)
    for key, value in pairs(env) do
        _G[key] = value
    end
    local chunk = assert(loadfile("addon/WoWForeverLaunchGuide/QuestResolver.lua"))
    chunk("WoWForeverLaunchGuide", env.ns)
end

local function reset()
    _G.C_QuestLog = nil
    _G.GetQuestUiMapID = nil
    _G.LibQuestieDB = nil
end

local function environment(complete)
    local ns = { SafeCall = function(fn, ...) return pcall(fn, ...) end }
    return {
        ns = ns,
        C_QuestLog = {
            GetNumQuestLogEntries = function() return 1 end,
            GetInfo = function() return { questID = 101, title = "A real target" } end,
            IsComplete = function() return complete end,
        },
    }
end

reset()
local poi = environment(false)
poi.GetQuestUiMapID = function() return 1420 end
poi.C_QuestLog.GetQuestsOnMap = function(map)
    assert(map == 1420)
    return { { questID = 101, x = 0.31, y = 0.72, isQuestStart = false } }
end
loadResolver(poi)
local target = poi.ns.ResolveSuggestedTarget()
assert(target.map == 1420 and target.x == 0.31 and target.y == 0.72)
assert(target.source == "native quest POI" and target.kind == "objective")

reset()
local waypoint = environment(false)
waypoint.GetQuestUiMapID = function() return 1420 end
waypoint.C_QuestLog.GetQuestsOnMap = function() return {} end
waypoint.C_QuestLog.GetNextWaypoint = function() return 1411, 0.4, 0.5 end
loadResolver(waypoint)
target = waypoint.ns.ResolveSuggestedTarget()
assert(target.map == 1411 and target.source == "native quest waypoint")

reset()
local completed = environment(true)
completed.GetQuestUiMapID = function() return 1420 end
completed.C_QuestLog.GetQuestsOnMap = function() return { { questID = 101, x = 0.2, y = 0.3, isQuestStart = false } } end
completed.C_QuestLog.GetNextWaypoint = function() return 1411, 0.4, 0.5 end
loadResolver(completed)
target = completed.ns.ResolveSuggestedTarget()
assert(target.kind == "turnin" and target.map == 1420)

reset()
local unavailable = environment(false)
unavailable.GetQuestUiMapID = function() return 1420 end
unavailable.C_QuestLog.GetQuestsOnMap = function() return {} end
unavailable.LibQuestieDB = { Quest = {}, Npc = {}, RequireContract = function() return true end }
loadResolver(unavailable)
local missing, reason = unavailable.ns.ResolveSuggestedTarget()
assert(missing == nil and reason == "QuestieDB is available, but no verified native map target exists")

print("m1_quest_resolver_spec: ok")
