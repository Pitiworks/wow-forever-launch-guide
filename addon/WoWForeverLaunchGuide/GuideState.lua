local _, ns = ...

ns.guideState = { quests = {}, completed = {}, ready = false }

function ns.Record(event, detail)
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    local db = WoWForeverLaunchGuideCharDB
    db.report = db.report or {}
    db.report[#db.report + 1] = {
        time = type(time) == "function" and time() or 0,
        event = event, detail = tostring(detail or ""),
    }
    if #db.report > 300 then table.remove(db.report, 1) end
end

function ns.ReadQuestState()
    local state = { quests = {}, completed = {}, ready = false }
    if not C_QuestLog then return state end
    local ok, ids = ns.SafeCall(C_QuestLog.GetAllCompletedQuestIDs)
    if ok and type(ids) == "table" then
        state.ready = true
        for _, id in ipairs(ids) do state.completed[id] = true end
    end
    local countOK, count = ns.SafeCall(C_QuestLog.GetNumQuestLogEntries)
    if not countOK or type(count) ~= "number" then return state end
    state.logReady = true
    for index = 1, count do
        local infoOK, info = ns.SafeCall(C_QuestLog.GetInfo, index)
        if infoOK and type(info) == "table" and not info.isHeader and info.questID then
            local completeOK, complete = ns.SafeCall(C_QuestLog.IsComplete, info.questID)
            local objectivesOK, objectives = ns.SafeCall(C_QuestLog.GetQuestObjectives, info.questID)
            local q = { id = info.questID, name = info.title, level = info.level,
                complete = completeOK and complete == true, objectives = {}, remaining = 0 }
            local have, need = 0, 0
            if objectivesOK and type(objectives) == "table" then
                q.objectives = objectives
                for _, objective in ipairs(objectives) do
                    local required, fulfilled = tonumber(objective.numRequired), tonumber(objective.numFulfilled)
                    if required and required > 0 and fulfilled then
                        have = have + math.min(required, math.max(0, fulfilled))
                        need = need + required
                    elseif objective.finished ~= nil then
                        have = have + (objective.finished and 1 or 0)
                        need = need + 1
                    end
                end
            end
            q.progress = need > 0 and have / need or nil
            q.remaining = need > 0 and (need - have) or nil
            state.quests[#state.quests + 1] = q
        end
    end
    table.sort(state.quests, function(a, b) return a.id < b.id end)
    return state
end

function ns.ReconcileGuide()
    ns.guideState = ns.ReadQuestState()
    ns.InvalidateHints()
    if ns.InvalidateSuggestion then ns.InvalidateSuggestion() end
    if ns.guideState.logReady then
        local parts = { ns.guideState.ready and "history=ready" or "history=unknown" }
        for _, q in ipairs(ns.guideState.quests) do
            parts[#parts + 1] = q.id .. ":" .. (q.complete and "turnin" or tostring(q.remaining or "unknown"))
        end
        local signature = table.concat(parts, " ")
        if signature ~= ns.lastQuestSignature then
            ns.lastQuestSignature = signature
            ns.Record("QUEST_SNAPSHOT", signature)
        end
    end
    local target = ns.GetTarget()
    if target and target.questID then
        local found = false
        for _, q in ipairs(ns.guideState.quests) do
            if q.id == target.questID then found = true end
        end
        if ns.guideState.logReady and ns.guideState.ready and not found then
            -- Never leave the player following an abandoned or already turned-in quest.
            ns.ClearTarget()
            ns.Record("STALE_TARGET_CLEARED", target.questID)
        end
    end
end

-- Heuristic seconds, not measured kill time or XP/h. Never compare quests with
-- known travel costs against quests whose travel cost is unavailable.
function ns.ScoreQuest(quest, travel)
    local work = quest.complete and 0 or math.max(1, quest.remaining or 4) * 20
    if not quest.complete and quest.progress and quest.progress >= 0.5 then
        work = work * 0.75
    end
    return (travel or 0) + work
end
