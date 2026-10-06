local _, ns = ...

local CONTRACT = 2

local function read(entity, id, fields)
    if not (entity and type(entity.GetAll) == "function" and id) then
        return nil
    end
    local ok, values = ns.SafeCall(entity.GetAll, id, fields)
    return ok and values or nil
end

local function firstActiveQuestID()
    ns.RefreshSnapshot()
    local active = ns.snapshot.quest and ns.snapshot.quest.active
    return active and active[1] and active[1].id or nil
end

local function firstID(list)
    return type(list) == "table" and tonumber(list[1]) or nil
end

local function objectiveID(objectives, slot)
    local rows = type(objectives) == "table" and objectives[slot] or nil
    local row = type(rows) == "table" and rows[1] or nil
    return type(row) == "table" and tonumber(row[1]) or nil
end

local function killCreditID(objectives)
    local rows = type(objectives) == "table" and objectives[5] or nil
    local row = type(rows) == "table" and rows[1] or nil
    return type(row) == "table" and firstID(row[1]) or nil
end

local function entitySummary(entity, id, fields)
    if not id then
        return nil
    end
    local values = read(entity, id, fields)
    if not values then
        return "#" .. id .. " unavailable"
    end
    return "#" .. id .. " " .. (ns.ValueSummary(values[1]) or "unknown") .. " ("
        .. (ns.ValueSummary(values[2]) or "unknown") .. ")"
end

function ns.RunQuestieDBProbe()
    local started = type(GetTime) == "function" and GetTime() or 0
    local probe = {
        addonLoaded = ns.IsAddonLoaded("QuestieDB"),
        flavor = ns.GetAddonMetadata("QuestieDB", "X-Flavor"),
        state = "unavailable",
    }
    local lib = _G.LibQuestieDB
    probe.present = type(lib) == "table"
    if not probe.present then
        probe.reason = "LibQuestieDB unavailable"
        ns.snapshot.questieDB = probe
        return probe
    end

    probe.state = "present"
    probe.contractVersion = lib.contractVersion
    probe.minSupportedContract = lib.minSupportedContract
    probe.readMode = lib.readMode
    probe.foreverCompatibility = probe.flavor == "Forever" and "yes" or (probe.flavor and "no: " .. probe.flavor or "unknown")
    if type(lib.RequireContract) == "function" then
        local ok, accepted, message = ns.SafeCall(lib.RequireContract, CONTRACT)
        probe.contract = ok and accepted == true and "accepted" or ns.Short(message or "rejected")
    else
        probe.contract = "unavailable"
    end

    local questID = firstActiveQuestID()
    probe.activeQuestID = questID
    if questID and type(lib.Quest) == "table" then
        local values = read(lib.Quest, questID, {
            "name", "preQuestGroup", "preQuestSingle", "childQuests", "nextQuestInChain",
            "startedBy", "finishedBy", "objectives",
        })
        if values then
            local startedBy, finishedBy, objectives = values[6], values[7], values[8]
            local npcID = firstID(type(startedBy) == "table" and startedBy[1]) or objectiveID(objectives, 1) or killCreditID(objectives)
            local objectID = firstID(type(startedBy) == "table" and startedBy[2]) or objectiveID(objectives, 2)
            local itemID = firstID(type(startedBy) == "table" and startedBy[3]) or objectiveID(objectives, 3)
            probe.quest = {
                name = ns.ValueSummary(values[1]),
                prerequisites = ns.ValueSummary(values[2]) or ns.ValueSummary(values[3]),
                chain = ns.ValueSummary(values[4]) or ns.ValueSummary(values[5]),
                start = ns.ValueSummary(startedBy),
                finish = ns.ValueSummary(finishedBy),
                objectives = ns.ValueSummary(objectives),
                objectiveNPCsObjectsItems = ns.ValueSummary(objectives),
                npc = entitySummary(lib.Npc, npcID, { "name", "spawns" }),
                object = entitySummary(lib.Object, objectID, { "name", "spawns" }),
                item = entitySummary(lib.Item, itemID, { "name", "npcDrops", "objectDrops", "itemDrops" }),
            }
        else
            probe.quest = { error = "Quest.GetAll unavailable or quest unknown" }
        end
    else
        probe.quest = { error = questID and "Quest reader unavailable" or "no active quest" }
    end

    probe.npcCoordinates = type(lib.Npc) == "table" and type(lib.Npc.GetAll) == "function"
        and "Npc.GetAll(name, spawns) available" or "unavailable"
    probe.objectCoordinates = type(lib.Object) == "table" and type(lib.Object.GetAll) == "function"
        and "Object.GetAll(name, spawns) available" or "unavailable"
    probe.itemDrops = type(lib.Item) == "table" and type(lib.Item.GetAll) == "function"
        and "Item.GetAll(name, npcDrops, objectDrops, itemDrops) available" or "unavailable"
    local finished = type(GetTime) == "function" and GetTime() or started
    probe.elapsedMs = math.floor((finished - started) * 1000 + 0.5)
    ns.snapshot.questieDB = probe
    if WoWForeverLaunchProbeCharDB then
        probe.previousPresent = WoWForeverLaunchProbeCharDB.questieDBWasPresent
        WoWForeverLaunchProbeCharDB.questieDBWasPresent = probe.present
    end
    return probe
end
