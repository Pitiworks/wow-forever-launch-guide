local ns = { SafeCall = function(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end }
local units = {
    target = { guid = "same", npcID = 100 }, nameplate1 = { guid = "same", npcID = 100 },
    nameplate2 = { guid = "other", npcID = 100 }, nameplate3 = { guid = "dead", npcID = 100 },
    mouseover = { guid = "unknown", npcID = 100 },
}
ns.UnitInfo = function(unit) return units[unit] or {} end
ns.NPCHints = function() return {}, { [375] = "objective", [358] = "turnin" } end
ns.GetTarget = function() return { kind = "objective", questID = 375 } end
UnitIsDead = function(unit) if unit == "mouseover" then error("unavailable") end; return unit == "nameplate3" end
UnitCanAttack = function() return true end
assert(loadfile("addon/WoWForeverLaunchGuide/UnitObservations.lua"))("WFLG", ns)
for unit in pairs(units) do ns.ObserveUnit(unit) end
local alive, unknown = ns.ObservedQuestUnits(375)
assert(alive == 2 and unknown == 1)
assert(ns.ObservedQuestUnits(358) == 0) -- quest givers are not quest mobs
ns.ObserveUnit("nameplate2", true)
assert(ns.ObservedQuestUnits(375) == 1)
units.target, units.nameplate1 = nil, nil
assert(ns.ObservedQuestUnits(375) == 0)
assert(ns.UnitObservationSummary():find("keinen leeren Spawn", 1, true))
print("m1_observations_spec: ok")
