local ns = {
    SafeCall = function(fn, ...)
        if type(fn) ~= "function" then return false end
        return pcall(fn, ...)
    end,
    Chat = function() end, RefreshUI = function() end,
}
local function load(name) assert(loadfile("addon/WoWForeverLaunchGuide/" .. name .. ".lua"))("WFLG", ns) end
load("QuestHints")
load("RoutePlan")
load("DBCoordinates")
load("RouteState")
load("GuideState")
local questFields = { "name", "requiredLevel", "questLevel", "requiredRaces", "requiredClasses", "preQuestGroup", "preQuestSingle",
    "exclusiveTo", "nextQuestInChain", "parentQuest", "requiredSkill", "requiredMinRep", "requiredMaxRep", "requiredSpell",
    "requiredSpecialization", "requiredRanks", "availableStartingWith", "availableUntilCompleted", "disabledByQuest", "specialFlags",
    "requiredMaxLevel", "requiredSourceItems", "breadcrumbForQuestId" }
local data = { Quest = {}, Npc = {}, Object = {} }
local q = { name = "Route fixture", requiredLevel = 7, questLevel = 10, requiredRaces = 8589934770 }
data.Quest[375] = q
LibQuestieDB = { RequireContract = function() return true end, Enum = { questKeys = {}, raceMaskById = { [5] = 16 } } }
for i, field in ipairs(questFields) do LibQuestieDB.Enum.questKeys[field] = i end
for entity, rows in pairs(data) do
    LibQuestieDB[entity] = { GetAll = function(id, fields)
        if not rows[id] then return nil end
        local result = { n = #fields }
        for i, field in ipairs(fields) do result[i] = rows[id][field] end
        return result
    end }
end
UnitLevel = function() return 11 end
UnitRace = function() return "Untoter", "Scourge", 5 end
UnitClass = function() return "Krieger", "WARRIOR", 1 end
local player = ns.ReadRoutePlayer()
assert(player.level == 11 and player.raceMask == 16 and player.classMask == 1)
local state = { quests = {}, completed = {}, ready = true, logReady = true }
local function status() return ns.QuestEligibility(375, state, player) end
assert(status() == "candidate")
state.ready = false; assert(status() == "unknown"); state.ready = true
state.completed[375] = true; assert(status() == "done"); state.completed[375] = nil
state.quests = { { id = 375, complete = false } }; assert(status() == "active")
state.quests[1].complete = true; assert(status() == "turnin"); state.quests = {}
q.requiredLevel = 12; assert(status() == "blocked"); q.requiredLevel = 7
q.questLevel = 20; assert(status() == "blocked"); q.questLevel = 10
q.requiredRaces = 1; assert(status() == "blocked"); q.requiredRaces = 8589934770
player.raceMask = nil; assert(status() == "unknown"); player.raceMask = 16
q.requiredClasses = 2; assert(status() == "blocked"); q.requiredClasses = nil
q.preQuestGroup = { 363, 364 }
state.completed[363] = true; assert(status() == "blocked")
state.completed[364] = true; assert(status() == "candidate")
q.preQuestSingle = { 358, 404 }; assert(status() == "blocked")
state.completed[404] = true; assert(status() == "candidate")
q.preQuestSingle = { -358 }; assert(status() == "unknown"); q.preQuestSingle = nil
q.parentQuest = 358; assert(status() == "blocked")
state.quests = { { id = 358 } }; assert(status() == "candidate"); q.parentQuest = nil
q.disabledByQuest = 358; assert(status() == "blocked"); q.disabledByQuest = nil
q.exclusiveTo = { 404 }; assert(status() == "blocked"); q.exclusiveTo = nil
q.availableStartingWith = 426; assert(status() == "blocked")
state.completed[426] = true; assert(status() == "candidate"); q.availableStartingWith = nil
q.availableUntilCompleted = 426; assert(status() == "blocked"); q.availableUntilCompleted = nil
q.nextQuestInChain = 426; assert(status() == "blocked"); q.nextQuestInChain = nil
q.requiredMinRep = { 68, 3000 }; assert(status() == "unknown"); q.requiredMinRep = nil
q.requiredSourceItems = { 200 }; GetItemCount = nil; assert(status() == "unknown")
GetItemCount = function() return 0 end; assert(status() == "blocked")
GetItemCount = function() return 1 end; assert(status() == "candidate"); q.requiredSourceItems = nil
LibQuestieDB.Enum.questKeys.parentQuest = nil; assert(status() == "unknown")
LibQuestieDB.Enum.questKeys.parentQuest = 1

local source = "return { [85] = 1420, -- actual AreaID is not a UiMapID\n [130] = 1421, [209] = 310, [0] = 0 }"
LibQuestieDB.Support = { Get = function(module)
    assert(module == "ZoneDB")
    return { private = { areaIdToUiMapId = source } }
end }
local flavor = "Forever"
C_AddOns = { GetAddOnMetadata = function() return flavor end }
Enum = { UIMapType = { Zone = 3 } }
C_Map = { GetMapInfo = function(map) return { mapID = map, mapType = map == 310 and 4 or 3 } end }
assert(ns.DBMapID(85) == 1420 and ns.DBMapID(130) == 1421)
assert(ns.DBMapID(209) == nil and ns.DBMapID(0) == nil and ns.DBMapID(9999) == nil)
flavor = "Classic"; assert(ns.DBMapID(85) == nil); flavor = "Forever"
source = "return { [85] = (function() error('do not execute') end)() }"
assert(ns.DBMapID(85) == nil)
source = { [85] = 1420 }
data.Npc[900] = { name = "Fixture giver", spawns = { [85] = { { 25, 75 }, { -1, -1 }, { 101, 20 }, { 10, 10, 7 } } } }
q.startedBy = { { 900 } }
q.finishedBy = { { 900 } }
local points = ns.DBQuestGiverPoints(375, false)
assert(#points == 1 and points[1].map == 1420 and points[1].x == 0.25 and points[1].y == 0.75)
assert(source[85] == 1420) -- dependency data remains read-only

-- First install at 11: no forced Deathknell start, eligible route pickups included.
ns.guideState = state
state.quests = {}
local steps = ns.BuildRouteState()
local found
for _, step in ipairs(steps) do if step.questID == 375 then found = step end end
assert(found and found.status == "candidate")
WoWForeverLaunchGuideCharDB = { deferred = { [375] = 2000 } }
time = function() return 1000 end
steps = ns.BuildRouteState()
for _, step in ipairs(steps) do if step.questID == 375 then assert(step.status == "deferred") end end
WoWForeverLaunchGuideCharDB.deferred = nil
load("QuestResolver")
ns.EstimateTarget = function() return 10 end
C_Map.GetBestMapForUnit = function() return 1420 end
local target = ns.ResolveSuggestedTarget()
assert(target and target.questID == 375 and target.kind == "pickup" and target.map == 1420)
assert(target.title:find("Angebot prüfen", 1, true))

-- Session controller: idempotence, automatic stage change, combat postponement,
-- conservative switching and a genuine temporary defer (not AbandonQuest).
load("GuideController")
local navigationCalls, clearCalls, combat = 0, 0, false
local selected = { questID = 375, kind = "pickup", map = 1420, x = 0.25, y = 0.75, score = 40, comparableTravel = true }
ns.ResolveSuggestedTarget = function() return selected end
ns.GetTarget = function() return WoWForeverLaunchGuideCharDB.target end
ns.ClearTarget = function() clearCalls = clearCalls + 1; WoWForeverLaunchGuideCharDB.target = nil end
ns.StartNavigation = function() navigationCalls = navigationCalls + 1; return true end
ns.ReconcileGuide = function() end
ns.InvalidateSuggestion = function() end
InCombatLockdown = function() return combat end
ns.ToggleGuide()
assert(ns.guideRunning and navigationCalls == 1)
ns.UpdateGuide(); assert(navigationCalls == 1)
selected = { questID = 375, kind = "objective", map = 1420, x = 0.3, y = 0.8, score = 60, comparableTravel = true }
ns.guideCandidates = {}
combat = true; ns.UpdateGuide(); assert(navigationCalls == 1 and ns.GuideStatus():find("Kampfende"))
combat = false; ns.UpdateGuide(); assert(navigationCalls == 2)
local original = selected
selected = { questID = 358, kind = "objective", map = 1420, x = 0.4, y = 0.8, score = 50, comparableTravel = true }
ns.guideCandidates = { { target = original, score = 60 } }
ns.UpdateGuide(); assert(ns.GetTarget().questID == 375 and navigationCalls == 2)
selected.score = 5
ns.UpdateGuide(); assert(ns.GetTarget().questID == 358 and navigationCalls == 3)
ns.guideRunning = false
ns.DeferCurrentQuest()
assert(WoWForeverLaunchGuideCharDB.deferred[358] == 1300 and clearCalls == 1)
assert(ns.SelectBranch("invalid") == false)
print("m1_route_spec: ok")
