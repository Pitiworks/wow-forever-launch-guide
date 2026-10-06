local _, ns = ...

local function addonMetadata(name, key)
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        local ok, value = ns.SafeCall(C_AddOns.GetAddOnMetadata, name, key)
        if ok then
            return value
        end
    end
    if type(GetAddOnMetadata) == "function" then
        local ok, value = ns.SafeCall(GetAddOnMetadata, name, key)
        if ok then
            return value
        end
    end
    return nil
end

function ns.IsAddonLoaded(name)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        local ok, loaded = ns.SafeCall(C_AddOns.IsAddOnLoaded, name)
        return ok and loaded == true
    end
    if type(IsAddOnLoaded) == "function" then
        local ok, loaded = ns.SafeCall(IsAddOnLoaded, name)
        return ok and loaded == true
    end
    return false
end

function ns.GetAddonMetadata(name, key)
    return addonMetadata(name, key)
end

local function playerState()
    local name = type(UnitName) == "function" and UnitName("player") or nil
    local realm = type(GetRealmName) == "function" and GetRealmName() or nil
    local level = type(UnitLevel) == "function" and UnitLevel("player") or nil
    local xp = type(UnitXP) == "function" and UnitXP("player") or nil
    local xpMax = type(UnitXPMax) == "function" and UnitXPMax("player") or nil
    return {
        name = name,
        realm = realm,
        level = level,
        xp = xp,
        xpMax = xpMax,
    }
end

local function locationState()
    local location = {
        zone = type(GetZoneText) == "function" and GetZoneText() or nil,
        subzone = type(GetSubZoneText) == "function" and GetSubZoneText() or nil,
    }
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, mapID = ns.SafeCall(C_Map.GetBestMapForUnit, "player")
        if ok then
            location.mapID = mapID
        end
        if mapID and type(C_Map.GetPlayerMapPosition) == "function" then
            local positionOK, position = ns.SafeCall(C_Map.GetPlayerMapPosition, mapID, "player")
            if positionOK and position and type(position.GetXY) == "function" then
                local xyOK, x, y = ns.SafeCall(position.GetXY, position)
                if xyOK then
                    location.x, location.y = x, y
                end
            end
        end
    end
    return location
end

function ns.RefreshSnapshot()
    ns.snapshot.character = playerState()
    ns.snapshot.location = locationState()
    ns.snapshot.quest = ns.ReadQuestState and ns.ReadQuestState() or { active = {} }
    ns.snapshot.target = ns.ReadUnit and ns.ReadUnit("target") or {}
    ns.snapshot.mouseover = ns.ReadUnit and ns.ReadUnit("mouseover") or {}
    if WoWForeverLaunchProbeCharDB then
        ns.snapshot.reloads = WoWForeverLaunchProbeCharDB.reloads
    end
    return ns.snapshot
end

function ns.HandleEvent(event, ...)
    if event == "QUEST_TURNED_IN" then
        ns.observed.turnIn = { id = select(1, ...), time = ns.lastEvent and ns.lastEvent.time }
    elseif event == "QUEST_AUTOCOMPLETE" then
        ns.observed.completion = { id = select(1, ...), time = ns.lastEvent and ns.lastEvent.time }
    elseif event == "QUEST_WATCH_UPDATE" then
        local questID = select(1, ...)
        if C_QuestLog and type(C_QuestLog.IsComplete) == "function" then
            local ok, complete = ns.SafeCall(C_QuestLog.IsComplete, questID)
            if ok and complete then
                ns.observed.completion = { id = questID, time = ns.lastEvent and ns.lastEvent.time }
            end
        end
    elseif event == "PLAYER_LOGIN" then
        WoWForeverLaunchProbeCharDB = WoWForeverLaunchProbeCharDB or {}
        WoWForeverLaunchProbeCharDB.reloads = (WoWForeverLaunchProbeCharDB.reloads or 0) + 1
        WoWForeverLaunchProbeCharDB.lastLogin = ns.lastEvent and ns.lastEvent.time
        WoWForeverLaunchProbeCharDB.activityLog = WoWForeverLaunchProbeCharDB.activityLog or {}
    end

    ns.RefreshSnapshot()
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ns.RunQuestieDBProbe()
        ns.RunShortestPathProbe()
    end
end

function ns.DumpSnapshot()
    ns.RefreshSnapshot()
    local character, location, quest = ns.snapshot.character, ns.snapshot.location, ns.snapshot.quest
    ns.Chat(string.format(
        "character=%s realm=%s level=%s xp=%s/%s zone=%s map=%s x=%s y=%s quests=%d",
        ns.Short(character.name), ns.Short(character.realm), ns.Short(character.level), ns.Short(character.xp),
        ns.Short(character.xpMax), ns.Short(location.zone), ns.Short(location.mapID), ns.Short(location.x),
        ns.Short(location.y), #(quest.active or {})
    ))
end

function ns.DumpEvents()
    ns.Chat("event history: " .. #ns.eventHistory .. " entries; counters: " .. ns.EventCountsSummary())
    local start = math.max(1, #ns.eventHistory - 9)
    for index = start, #ns.eventHistory do
        local entry = ns.eventHistory[index]
        ns.Chat(entry.time .. " " .. entry.event .. (entry.args ~= "" and " (" .. entry.args .. ")" or ""))
    end
end

function ns.DumpActivityLog()
    local db = WoWForeverLaunchProbeCharDB or {}
    local log = db.activityLog or {}
    ns.Chat("persistent M0 test log: " .. #log .. " entries (last 20 follow)")
    local start = math.max(1, #log - 19)
    for index = start, #log do
        local entry = log[index]
        ns.Chat(entry.time .. " " .. entry.event .. (entry.detail and " (" .. entry.detail .. ")" or ""))
    end
end

function ns.ClearActivityLog()
    if WoWForeverLaunchProbeCharDB then
        WoWForeverLaunchProbeCharDB.activityLog = {}
    end
end
