local _, ns = ...

local function objectivesFor(questID)
    local objectives = {}
    if not (C_QuestLog and type(C_QuestLog.GetQuestObjectives) == "function") then
        return objectives
    end
    local ok, rows = ns.SafeCall(C_QuestLog.GetQuestObjectives, questID)
    if not ok or type(rows) ~= "table" then
        return objectives
    end
    for index, info in ipairs(rows) do
        objectives[#objectives + 1] = {
            type = info.type,
            text = info.text,
            done = info.finished == true,
            have = info.numFulfilled,
            need = info.numRequired,
        }
    end
    return objectives
end

local function modernQuestLog()
    local active = {}
    if not (C_QuestLog and type(C_QuestLog.GetNumQuestLogEntries) == "function" and type(C_QuestLog.GetInfo) == "function") then
        return active, false
    end
    local ok, count = ns.SafeCall(C_QuestLog.GetNumQuestLogEntries)
    if not ok or type(count) ~= "number" then
        return active, false
    end
    for index = 1, count do
        local infoOK, info = ns.SafeCall(C_QuestLog.GetInfo, index)
        if infoOK and info and not info.isHeader and info.questID then
            local complete = false
            if type(C_QuestLog.IsComplete) == "function" then
                local completeOK, value = ns.SafeCall(C_QuestLog.IsComplete, info.questID)
                complete = completeOK and value == true
            end
            active[#active + 1] = {
                id = info.questID,
                name = info.title,
                level = info.level,
                complete = complete,
                objectives = objectivesFor(info.questID),
            }
        end
    end
    return active, true
end

local function legacyQuestLog()
    local active = {}
    if type(GetNumQuestLogEntries) ~= "function" or type(GetQuestLogTitle) ~= "function" then
        return active
    end
    local count = GetNumQuestLogEntries()
    for index = 1, count do
        local title, level, _, isHeader, _, complete, _, questID = GetQuestLogTitle(index)
        if not isHeader and questID then
            active[#active + 1] = {
                id = questID,
                name = title,
                level = level,
                complete = complete == true or complete == 1,
                objectives = objectivesFor(questID),
            }
        end
    end
    return active
end

function ns.ReadQuestState()
    local active, modern = modernQuestLog()
    if not modern then
        active = legacyQuestLog()
    end
    return {
        active = active,
        source = modern and "C_QuestLog" or "legacy quest log fallback",
        observedCompletion = ns.observed.completion,
        observedTurnIn = ns.observed.turnIn,
    }
end
