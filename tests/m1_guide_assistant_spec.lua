local ns = {
    SafeCall = function(fn, ...)
        if type(fn) ~= "function" then return false end
        return pcall(fn, ...)
    end,
    Chat = function() end, RefreshUI = function() end,
}
local function load(name) assert(loadfile("addon/WoWForeverLaunchGuide/" .. name .. ".lua"))("WFLG", ns) end
load("GuideState")
load("QuestHints")
load("QuestInteraction")

local infos = { { questID = 375, title = "Felle", level = 7 }, { questID = 358, title = "Gnolle", level = 8 } }
local completed = { 363, 364, 404 }
local readyQuest = false
C_QuestLog = {
    GetAllCompletedQuestIDs = function() return completed end,
    GetNumQuestLogEntries = function() return #infos end,
    GetInfo = function(i) return infos[i] end,
    IsComplete = function(id) return id == 375 and readyQuest end,
    GetQuestObjectives = function(id)
        return { { numRequired = 10, numFulfilled = id == 375 and 5 or 1, finished = false } }
    end,
}
local stale = { questID = 404 }
local cleared = 0
ns.GetTarget = function() return stale end
ns.ClearTarget = function() cleared = cleared + 1; stale = nil end
ns.ReconcileGuide()
assert(cleared == 1 and ns.guideState.completed[363])
assert(ns.guideState.quests[2].progress == 0.5)
assert(ns.ScoreQuest({ remaining = 5, progress = 0.5 }, 10) == 85)
assert(ns.ScoreQuest({ remaining = 5, progress = 0.49 }, 10) == 110)
assert(ns.ScoreQuest({ remaining = 0, complete = true }, 100) == 100)
completed = nil
ns.ReconcileGuide()
assert(not ns.guideState.ready and #ns.guideState.quests == 2)

local data = {
    Quest = {
        [375] = { name = "Felle", finishedBy = { { 900 } }, objectives = { [3] = { { 100, nil, 5 }, { 200, nil, 1 } } }, nextQuestInChain = 376 },
        [376] = { name = "Folge", objectives = { [3] = { { 300, nil, 2 } } } },
        [358] = { objectives = { [1] = { { 901, nil, 8 } } } },
    },
    Item = { [100] = { name = "Fell", npcDrops = { 902 } },
        [200] = { name = "Faden", vendors = { 903 } }, [300] = { name = "Öl", vendors = { 903 } } },
    Npc = { [903] = { name = "Händler" } },
}
local accept = true
LibQuestieDB = { RequireContract = function() return accept end }
for entity, rows in pairs(data) do
    LibQuestieDB[entity] = { GetAll = function(id, fields)
        if not rows[id] then return nil end
        local result = {}
        for i, field in ipairs(fields) do result[i] = rows[id][field] end
        return result
    end }
end
GetItemCount = function() return 0 end
ns.InvalidateHints()
assert(#ns.NPCHints(901) == 1 and #ns.NPCHints(902) == 1 and #ns.NPCHints(999) == 0)
assert(#ns.ShoppingHints() == 1) -- unknown history suppresses future look-ahead
completed = { 363 }
ns.ReconcileGuide()
assert(#ns.ShoppingHints() == 2)
GetItemCount = function() return 100 end
ns.InvalidateHints()
assert(#ns.ShoppingHints() == 0)
accept = false
ns.InvalidateHints()
assert(#ns.NPCHints(901) == 0 and #ns.ShoppingHints() == 0)
accept = true
GetItemCount = function() return 0 end

-- Turn-in protection: opt-in, Shift, money, choices, active completion and dialog.
local shown, shift, combat, money, choices, id = true, false, false, 0, 0, 375
local progressed, rewarded = 0, 0
QuestFrame = { IsShown = function() return shown end }
QuestFrameProgressPanel = { IsShown = function() return shown end }
QuestFrameRewardPanel = { IsShown = function() return shown end }
IsShiftKeyDown = function() return shift end
InCombatLockdown = function() return combat end
GetQuestID = function() return id end
GetQuestMoneyToGet = function() return money end
GetNumQuestChoices = function() return choices end
IsQuestCompletable = function() return true end
CompleteQuest = function() progressed = progressed + 1 end
GetQuestReward = function(choice) assert(choice == 0); rewarded = rewarded + 1 end
ns.HandleQuestDialog("QUEST_COMPLETE")
assert(rewarded == 0)
ns.ToggleAutoTurnIn()
ns.HandleQuestDialog("QUEST_COMPLETE")
assert(rewarded == 0) -- only half done
readyQuest = true
for _, block in ipairs({ "shift", "combat", "money", "choices", "hidden", "wrongQuest" }) do
    shift, combat, money, choices, shown, id = false, false, 0, 0, true, 375
    if block == "shift" then shift = true elseif block == "combat" then combat = true
    elseif block == "money" then money = 1 elseif block == "choices" then choices = 1
    elseif block == "hidden" then shown = false else id = 999 end
    ns.HandleQuestDialog("QUEST_COMPLETE")
    assert(rewarded == 0, block)
end
shift, combat, money, choices, shown, id = false, false, 0, 0, true, 375
ns.HandleQuestDialog("QUEST_PROGRESS")
ns.HandleQuestDialog("QUEST_PROGRESS")
assert(progressed == 1)
ns.HandleQuestDialog("QUEST_COMPLETE")
ns.HandleQuestDialog("QUEST_COMPLETE")
assert(rewarded == 1)
ns.HandleQuestDialog("QUEST_FINISHED")
GetQuestReward = nil
ns.HandleQuestDialog("QUEST_COMPLETE") -- missing API is safe
assert(rewarded == 1)

-- Choose by work + comparable travel, with a completion bonus, never log order.
load("QuestResolver")
readyQuest = false
ns.ReconcileGuide()
GetQuestUiMapID = function() return 1420 end
C_QuestLog.GetQuestsOnMap = function()
    return { { questID = 375, x = 0.2, y = 0.3 }, { questID = 358, x = 0.4, y = 0.5 } }
end
ns.EstimateTarget = function(target) return target.questID == 375 and 10 or 20 end
local selected = ns.ResolveSuggestedTarget()
assert(selected.questID == 375 and selected.reason:find("50%%"))
ns.EstimateTarget = function(target) return target.questID == 375 and 1000 or 20 end
ns.InvalidateSuggestion()
assert(ns.ResolveSuggestedTarget().questID == 358) -- progress is not an absolute lock
ns.EstimateTarget = function(target) return target.questID == 375 and 1000 or nil end
ns.InvalidateSuggestion()
selected = ns.ResolveSuggestedTarget()
assert(selected.questID == 375 and selected.reason:find("unbekannt"))

-- Real navigation adapter must preserve both pcall return values for position.
load("Navigation")
C_Map = {
    GetBestMapForUnit = function(unit) assert(unit == "player"); return 1420 end,
    GetPlayerMapPosition = function(map, unit)
        assert(map == 1420 and unit == "player")
        return { GetXY = function() return 0.1, 0.2 end }
    end,
}
ShortestPathForever = { API = { Estimate = function(map, x, y, targetMap, targetX, targetY)
    assert(map == 1420 and x == 0.1 and y == 0.2 and targetMap == 1420 and targetX == 0.3 and targetY == 0.4)
    return 42
end } }
assert(ns.EstimateTarget({ map = 1420, x = 0.3, y = 0.4 }) == 42)
ShortestPathForever = nil
assert(ns.EstimateTarget({ map = 1420, x = 0.3, y = 0.4 }) == nil)
print("m1_guide_assistant_spec: ok")
