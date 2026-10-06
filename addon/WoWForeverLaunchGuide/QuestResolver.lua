local _, ns = ...

local function validPoint(map, x, y)
    return type(map) == "number" and map > 0
        and type(x) == "number" and x >= 0 and x <= 1
        and type(y) == "number" and y >= 0 and y <= 1
end

local function activeQuests()
    local quests = {}
    if not (C_QuestLog and type(C_QuestLog.GetNumQuestLogEntries) == "function" and type(C_QuestLog.GetInfo) == "function") then
        return quests
    end
    local ok, count = ns.SafeCall(C_QuestLog.GetNumQuestLogEntries)
    if not ok or type(count) ~= "number" then
        return quests
    end
    for index = 1, count do
        local infoOK, info = ns.SafeCall(C_QuestLog.GetInfo, index)
        if infoOK and info and not info.isHeader and info.questID then
            local complete = false
            if type(C_QuestLog.IsComplete) == "function" then
                local completeOK, value = ns.SafeCall(C_QuestLog.IsComplete, info.questID)
                complete = completeOK and value == true
            end
            quests[#quests + 1] = { id = info.questID, name = info.title, complete = complete }
        end
    end
    return quests
end

-- Forever exposes active quest destinations as native POIs and next waypoints. Their uiMapID
-- and normalized coordinates are already in the exact form required by Shortest Path Forever.
local function nativePoint(quest)
    if type(GetQuestUiMapID) ~= "function" then
        return nil
    end
    local mapOK, map = ns.SafeCall(GetQuestUiMapID, quest.id, true)
    if not mapOK or type(map) ~= "number" or map <= 0 then
        return nil
    end

    if C_QuestLog and type(C_QuestLog.GetQuestsOnMap) == "function" then
        local poisOK, pois = ns.SafeCall(C_QuestLog.GetQuestsOnMap, map)
        if poisOK and type(pois) == "table" then
            for _, poi in ipairs(pois) do
                if type(poi) == "table" and poi.questID == quest.id and not poi.isQuestStart and validPoint(map, poi.x, poi.y) then
                    return map, poi.x, poi.y, "native quest POI"
                end
            end
        end
    end

    if C_QuestLog and type(C_QuestLog.GetNextWaypoint) == "function" then
        local waypointOK, waypointMap, x, y = ns.SafeCall(C_QuestLog.GetNextWaypoint, quest.id)
        if waypointOK and validPoint(waypointMap, x, y) then
            return waypointMap, x, y, "native quest waypoint"
        end
    end
    return nil
end

local function questieDBAvailable()
    local lib = _G.LibQuestieDB
    if not (type(lib) == "table" and type(lib.Quest) == "table" and type(lib.Npc) == "table") then
        return false
    end
    if type(lib.RequireContract) == "function" then
        local ok, accepted = ns.SafeCall(lib.RequireContract, 2)
        return ok and accepted == true
    end
    return true
end

function ns.ResolveSuggestedTarget()
    local sawQuest = false
    for _, quest in ipairs(activeQuests()) do
        sawQuest = true
        local map, x, y, source = nativePoint(quest)
        if map then
            return {
                map = map,
                x = x,
                y = y,
                title = (quest.name or ("Quest " .. quest.id)) .. (quest.complete and " — turn in" or ""),
                kind = quest.complete and "turnin" or "objective",
                questID = quest.id,
                source = source,
            }
        end
    end
    if not sawQuest then
        return nil, "no active quests"
    end
    if questieDBAvailable() then
        return nil, "QuestieDB is available, but no verified native map target exists"
    end
    return nil, "no native quest POI or waypoint available"
end
