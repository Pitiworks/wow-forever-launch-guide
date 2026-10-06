local _, ns = ...

local function firstID(rows)
    return type(rows) == "table" and tonumber(rows[1]) or nil
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

local function read(entity, id, fields)
    if not (entity and type(entity.GetAll) == "function" and id) then
        return nil
    end
    local ok, values = ns.SafeCall(entity.GetAll, id, fields)
    return ok and values or nil
end

local function firstSpawn(spawns)
    if type(spawns) ~= "table" then
        return nil
    end
    for zoneID, points in pairs(spawns) do
        local point = type(points) == "table" and points[1] or nil
        if type(zoneID) == "number" and type(point) == "table" and type(point[1]) == "number" and type(point[2]) == "number" then
            if C_Map and type(C_Map.GetMapInfo) == "function" then
                local ok, info = ns.SafeCall(C_Map.GetMapInfo, zoneID)
                if ok and info then
                    return zoneID, point[1] / 100, point[2] / 100
                end
            end
        end
    end
    return nil
end

local function npcTarget(lib, npcID, title, kind, questID)
    local npc = read(lib.Npc, npcID, { "name", "spawns" })
    if not npc then
        return nil
    end
    local map, x, y = firstSpawn(npc[2])
    if not map then
        return nil
    end
    return {
        map = map,
        x = x,
        y = y,
        title = title .. " — " .. ns.Short(npc[1] or ("NPC " .. npcID)),
        kind = kind,
        questID = questID,
        npcID = npcID,
    }
end

function ns.ResolveSuggestedTarget()
    local lib = _G.LibQuestieDB
    if not (type(lib) == "table" and type(lib.Quest) == "table" and type(lib.Npc) == "table") then
        return nil, "QuestieDB unavailable"
    end
    if type(lib.RequireContract) == "function" then
        local ok, accepted = ns.SafeCall(lib.RequireContract, 2)
        if not ok or accepted ~= true then
            return nil, "QuestieDB contract unavailable"
        end
    end
    for _, quest in ipairs(activeQuests()) do
        local values = read(lib.Quest, quest.id, { "finishedBy", "objectives" })
        if values then
            local finishers, objectives = values[1], values[2]
            local npcID
            local kind
            if quest.complete then
                npcID, kind = firstID(finishers and finishers[1]), "turnin"
            else
                local creatures = objectives and objectives[1]
                local creature = type(creatures) == "table" and creatures[1] or nil
                npcID, kind = type(creature) == "table" and firstID(creature[1]) or nil, "objective"
            end
            local target = npcID and npcTarget(lib, npcID, quest.name or ("Quest " .. quest.id), kind, quest.id) or nil
            if target then
                return target
            end
        end
    end
    return nil, "no mappable active quest target"
end
