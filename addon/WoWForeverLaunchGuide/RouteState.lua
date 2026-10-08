local _, ns = ...

local fields = { "name", "requiredLevel", "questLevel", "requiredRaces", "requiredClasses", "preQuestGroup", "preQuestSingle",
    "exclusiveTo", "nextQuestInChain", "parentQuest", "requiredSkill", "requiredMinRep", "requiredMaxRep", "requiredSpell",
    "requiredSpecialization", "requiredRanks", "availableStartingWith", "availableUntilCompleted", "disabledByQuest", "specialFlags",
    "requiredMaxLevel", "requiredSourceItems", "breadcrumbForQuestId" }

function ns.RouteQuestData(id)
    local lib = _G.LibQuestieDB
    local keys = lib and lib.Enum and lib.Enum.questKeys
    if type(keys) ~= "table" then return nil end
    for _, field in ipairs(fields) do if not keys[field] then return nil end end
    local data = ns.DBRead("Quest", id, fields)
    if not data then return nil end
    local q = {}
    for index, field in ipairs(fields) do q[field] = data[index] end
    return q
end

local function present(value)
    return value ~= nil and value ~= 0 and (type(value) ~= "table" or next(value) ~= nil)
end

local function maskAllows(mask, playerMask)
    if mask == nil or mask == 0 then return true end
    if type(mask) ~= "number" or type(playerMask) ~= "number" or playerMask <= 0 then return nil end
    -- Division avoids truncating Forever's >32-bit race masks through bit.band.
    return math.floor(mask / playerMask) % 2 == 1
end

function ns.QuestEligibility(id, state, player)
    if state.completed[id] then return "done", "bereits abgegeben" end
    for _, active in ipairs(state.quests) do
        if active.id == id then return active.complete and "turnin" or "active", "im Questlog" end
    end
    if not state.ready or not state.logReady then return "unknown", "Queststand noch unvollständig" end
    local q = ns.RouteQuestData(id)
    if not q or not q.name then return "unknown", "QuestieDB-Contract/Felder oder Quest fehlen" end
    if not player.level or type(q.requiredLevel) ~= "number" then return "unknown", "Levelvoraussetzung unbekannt" end
    if player.level < q.requiredLevel then return "blocked", "Mindestlevel " .. q.requiredLevel end
    if type(q.requiredMaxLevel) == "number" and q.requiredMaxLevel > 0 and player.level > q.requiredMaxLevel then
        return "blocked", "Maximallevel überschritten"
    end
    if type(q.questLevel) == "number" and q.questLevel > player.level + 2 then return "blocked", "Questlevel noch zu hoch" end
    for _, check in ipairs({ { q.requiredRaces, player.raceMask }, { q.requiredClasses, player.classMask } }) do
        local allowed = maskAllows(check[1], check[2])
        if allowed == nil then return "unknown", "Charaktermaske unbekannt" end
        if not allowed then return "blocked", "Rasse/Klasse nicht passend" end
    end
    local active = {}
    for _, quest in ipairs(state.quests) do active[quest.id] = true end
    local function done(prerequisite)
        if type(prerequisite) ~= "number" or prerequisite <= 0 then return nil end
        return state.completed[prerequisite] == true
    end
    if present(q.preQuestGroup) then
        if type(q.preQuestGroup) ~= "table" then return "unknown", "Gruppenvoraussetzung unbekannt" end
        for _, prerequisite in ipairs(q.preQuestGroup) do
            local satisfied = done(prerequisite)
            if satisfied == nil then return "unknown", "signierte Voraussetzung ungeprüft" end
            if not satisfied then return "blocked", "Vorgänger fehlt: " .. prerequisite end
        end
    end
    if present(q.preQuestSingle) then
        if type(q.preQuestSingle) ~= "table" then return "unknown", "Alternativvoraussetzung unbekannt" end
        local satisfied, uncertain = false, false
        for _, prerequisite in ipairs(q.preQuestSingle) do
            local result = done(prerequisite)
            satisfied = satisfied or result == true
            uncertain = uncertain or result == nil
        end
        if not satisfied then return uncertain and "unknown" or "blocked", "Alternativer Vorgänger fehlt/ungeprüft" end
    end
    if present(q.parentQuest) and not active[q.parentQuest] then return "blocked", "Elternquest muss aktiv sein" end
    if present(q.availableStartingWith) and not active[q.availableStartingWith] and not state.completed[q.availableStartingWith] then
        return "blocked", "Freischaltung fehlt"
    end
    if present(q.availableUntilCompleted) and state.completed[q.availableUntilCompleted] then return "blocked", "Verfügbarkeit beendet" end
    if present(q.disabledByQuest) and active[q.disabledByQuest] then return "blocked", "Durch aktive Quest gesperrt" end
    for _, other in ipairs(q.exclusiveTo or {}) do
        if active[other] or state.completed[other] then return "blocked", "Exklusiver Ast bereits gewählt" end
    end
    for _, successor in ipairs({ q.nextQuestInChain or 0, q.breadcrumbForQuestId or 0 }) do
        if successor > 0 and (active[successor] or state.completed[successor]) then return "blocked", "Folgeschritt bereits erreicht" end
    end
    for _, field in ipairs({ "requiredSkill", "requiredMinRep", "requiredMaxRep", "requiredSpell", "requiredSpecialization", "requiredRanks", "specialFlags" }) do
        if present(q[field]) then return "unknown", "Sonderbedingung ungeprüft: " .. field end
    end
    for _, item in ipairs(q.requiredSourceItems or {}) do
        local ok, count = ns.SafeCall(GetItemCount, item)
        if not ok or type(count) ~= "number" then return "unknown", "Voraussetzungsitem unbekannt" end
        if count <= 0 then return "blocked", "Voraussetzungsitem fehlt: " .. item end
    end
    return "candidate", "Datenvoraussetzungen erfüllt; Angebot vor Ort prüfen"
end

function ns.ReadRoutePlayer()
    local _, level = ns.SafeCall(UnitLevel, "player")
    local raceOK, _, race, raceID = ns.SafeCall(UnitRace, "player")
    local classOK, _, _, classID = ns.SafeCall(UnitClass, "player")
    local lib = _G.LibQuestieDB
    local masks = lib and lib.Enum and lib.Enum.raceMaskById
    return { level = type(level) == "number" and level > 0 and level or nil,
        race = raceOK and race or nil, raceMask = raceOK and masks and masks[raceID] or nil,
        classMask = classOK and type(classID) == "number" and classID > 0 and classID <= 64 and 2 ^ (classID - 1) or nil }
end

function ns.BuildRouteState()
    local player, steps = ns.ReadRoutePlayer(), {}
    if player.race ~= "Scourge" then return steps, "Routenprofil nur für Untote; aktive Quests bleiben nutzbar" end
    local branch = WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.branch or "silverpine"
    for _, packet in ipairs(ns.routePlan) do
        if not packet.branch or packet.branch == branch then
            for _, id in ipairs(packet.quests) do
                local status, reason = ns.QuestEligibility(id, ns.guideState, player)
                if status == "candidate" and (player.level < packet.minimum or player.level > packet.maximum) then
                    status, reason = "deferred", "Außerhalb des geplanten Einstiegsfensters"
                end
                local deferred = WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.deferred
                local untilTime = deferred and deferred[id]
                local now = type(time) == "function" and time() or 0
                if (status == "candidate" or status == "active" or status == "turnin") and type(untilTime) == "number" and untilTime > now then
                    status, reason = "deferred", "Vorübergehend zurückgestellt; kein Questabbruch"
                end
                local data = ns.DBRead("Quest", id, { "name" })
                steps[#steps + 1] = { questID = id, name = data and data[1] or ("Quest " .. id),
                    packet = packet, status = status, reason = reason }
            end
        end
    end
    return steps
end
