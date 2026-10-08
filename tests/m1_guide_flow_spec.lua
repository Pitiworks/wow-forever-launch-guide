-- End-to-end simulated client events through the complete addon, not isolated calls.
local frames, timers, ns = {}, {}, {}
local function object()
    local f = { scripts = {}, shown = false }
    setmetatable(f, { __index = function(_, key)
        if key == "GetStringHeight" then return function() return 500 end end
        return function() end
    end })
    function f:SetScript(key, fn) self.scripts[key] = fn end
    function f:HookScript(key, fn) self.scripts[key] = fn end
    function f:CreateTexture() return object() end
    function f:CreateFontString() return object() end
    function f:IsShown() return self.shown end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    return f
end
CreateFrame = function() local f = object(); frames[#frames + 1] = f; return f end
UIParent, GameTooltip, SlashCmdList = object(), object(), {}
C_Timer = { After = function(delay, fn) if delay == 0 then timers[#timers + 1] = fn end end }
local function drain() while #timers > 0 do table.remove(timers, 1)() end end
UnitLevel = function() return 11 end
UnitRace = function() return "Untoter", "Scourge", 5 end
UnitClass = function() return "Krieger", "WARRIOR", 1 end
time = function() return 123456 end
local active, completed, complete = false, {}, false
local data = {
    Quest = {
        [375] = { name = "Felle", requiredLevel = 7, questLevel = 8, startedBy = { { 900 } }, finishedBy = { { 900 } } },
        [421] = { name = "Whitescalps", requiredLevel = 9, questLevel = 10, startedBy = { { 901 } } },
    },
    Npc = { [900] = { name = "Brill giver", spawns = { [85] = { { 20, 30 } } } },
        [901] = { name = "Sepulcher giver", spawns = { [130] = { { 40, 50 } } } } },
}
LibQuestieDB = { RequireContract = function() return true end, Enum = { questKeys = setmetatable({}, { __index = function() return 1 end }), raceMaskById = { [5] = 16 } },
    Support = { Get = function() return { private = { areaIdToUiMapId = { [85] = 1420, [130] = 1421 } } } end } }
for entity, rows in pairs(data) do
    LibQuestieDB[entity] = { GetAll = function(id, fields)
        if not rows[id] then return nil end
        local result = { n = #fields }
        for i, field in ipairs(fields) do result[i] = rows[id][field] end
        return result
    end }
end
Enum = { UIMapType = { Zone = 3 } }
C_AddOns = { GetAddOnMetadata = function() return "Forever" end }
C_Map = {
    GetMapInfo = function(id) return { mapID = id, mapType = 3 } end,
    GetBestMapForUnit = function() return 1420 end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.2, 0.3 end } end,
}
C_QuestLog = {
    GetNumQuestLogEntries = function() return active and 1 or 0 end,
    GetInfo = function() return { questID = 375, title = "Felle", level = 8 } end,
    GetAllCompletedQuestIDs = function() return completed end,
    IsComplete = function() return complete end,
    GetQuestObjectives = function() return { { type = "item", text = "Fell: 5/10", numRequired = 10, numFulfilled = complete and 10 or 5 } } end,
    GetQuestsOnMap = function() return active and { { questID = 375, x = complete and 0.2 or 0.4, y = 0.3 } } or {} end,
}
GetQuestUiMapID = function(id) return id == 375 and 1420 or 1421 end
local navigations, ended = {}, nil
ShortestPathForever = { API = {
    version = 1,
    Estimate = function(_, _, _, map) return map == 1420 and 10 or 600 end,
    Navigate = function() error("Guide must use held public route") end,
    NavigateRoute = function(owner, stops)
        assert(owner == ns.owner and #stops == 1 and stops[1].hold)
        ended = nil
        navigations[#navigations + 1] = stops[1]
        return true
    end,
    Cancel = function() ended = "cancelled"; return true end,
    Ended = function() return ended end,
    CurrentStop = function() return ended == nil and 1 or nil end,
} }
local toc = assert(io.open("addon/WoWForeverLaunchGuide/WoWForeverLaunchGuide.toc"))
for line in toc:lines() do
    if line:match("%.lua$") then assert(loadfile("addon/WoWForeverLaunchGuide/" .. line))("WFLG", ns) end
end
toc:close()
local function event(name, ...) frames[1].scripts.OnEvent(frames[1], name, ...); drain() end
event("PLAYER_LOGIN")
assert(#navigations == 0 and not ns.guideRunning)
SlashCmdList.WFLG("guide")
assert(ns.guideRunning and #navigations == 1 and navigations[1].questID == 375 and navigations[1].kind == "pickup")
active = true; event("QUEST_ACCEPTED", 1, 375)
assert(#navigations == 2 and navigations[2].kind == "objective")
complete = true; event("QUEST_LOG_UPDATE")
assert(#navigations == 3 and navigations[3].kind == "turnin")
active, completed = false, { 375 }
event("QUEST_TURNED_IN", 375, 100, 0)
assert(#navigations == 4 and navigations[4].questID == 421 and navigations[4].kind == "pickup")
assert(WoWForeverLaunchGuideCharDB.evaluation.confirmedTurnIns == 1)
assert(WoWForeverLaunchGuideCharDB.evaluation.selectedMap == 1421)
ended = "replaced"; event("QUEST_LOG_UPDATE")
assert(not ns.guideRunning and #navigations == 4) -- do not steal another addon's route
event("PLAYER_LOGIN")
assert(not ns.guideRunning and #navigations == 4) -- no unattended restart on reload
assert(ns.lastAddonError == nil)
print("m1_guide_flow_spec: pickup -> objective -> turn-in -> next pickup -> external replacement -> reload passed")
