local addonName, ns = ...

ns.addonName = addonName
ns.owner = "WoWForeverLaunchProbe"
ns.eventCounts = {}
ns.eventHistory = {}
ns.maxEvents = 100
ns.maxActivityLogEntries = 2000
ns.snapshot = {}
ns.observed = {}

local function now()
    return date and date("%H:%M:%S") or "unknown"
end

function ns.SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "unavailable"
    end
    return pcall(fn, ...)
end

function ns.Short(value, limit)
    if value == nil then
        return "unavailable"
    end
    local text = tostring(value)
    limit = limit or 80
    if #text > limit then
        return text:sub(1, limit - 3) .. "..."
    end
    return text
end

function ns.ValueSummary(value)
    if value == nil then
        return nil
    end
    if type(value) ~= "table" then
        return ns.Short(value)
    end
    local count = 0
    for _ in pairs(value) do
        count = count + 1
    end
    return "table (" .. count .. ")"
end

function ns.RecordEvent(event, ...)
    ns.eventCounts[event] = (ns.eventCounts[event] or 0) + 1
    local parts = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if value ~= nil then
            parts[#parts + 1] = ns.Short(value, 48)
        end
    end
    local entry = {
        event = event,
        time = now(),
        args = table.concat(parts, ", "),
    }
    ns.eventHistory[#ns.eventHistory + 1] = entry
    if #ns.eventHistory > ns.maxEvents then
        table.remove(ns.eventHistory, 1)
    end
    ns.lastEvent = entry
end

function ns.ActivityDetail(event, ...)
    local character = ns.snapshot.character or {}
    local location = ns.snapshot.location or {}
    local unit
    if event == "PLAYER_TARGET_CHANGED" then
        unit = ns.snapshot.target
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        unit = ns.snapshot.mouseover
    end

    if unit and unit.available then
        return "unit=" .. ns.Short(unit.name, 40) .. " npc=" .. ns.Short(unit.npcID, 24) .. " guid=" .. ns.Short(unit.guid, 64)
    elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_UP" then
        return "level=" .. ns.Short(character.level) .. " xp=" .. ns.Short(character.xp) .. "/" .. ns.Short(character.xpMax)
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        return "zone=" .. ns.Short(location.zone, 40) .. " map=" .. ns.Short(location.mapID) .. " x=" .. ns.Short(location.x) .. " y=" .. ns.Short(location.y)
    end

    local parts = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if value ~= nil then
            parts[#parts + 1] = ns.Short(value, 48)
        end
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end

function ns.AppendActivity(event, detail)
    local db = WoWForeverLaunchProbeCharDB
    if type(db) ~= "table" then
        return
    end
    db.activityLog = db.activityLog or {}
    db.activityLog[#db.activityLog + 1] = {
        time = now(),
        event = event,
        detail = detail,
    }
    if #db.activityLog > ns.maxActivityLogEntries then
        table.remove(db.activityLog, 1)
    end
end

function ns.RecordActivityEvent(event, ...)
    ns.AppendActivity(event, ns.ActivityDetail(event, ...))
end

function ns.ResetTemporaryValues()
    ns.eventCounts = {}
    ns.eventHistory = {}
    ns.lastEvent = nil
    ns.observed = {}
    ns.RefreshSnapshot()
end

function ns.EventCountsSummary()
    local rows = {}
    for event, count in pairs(ns.eventCounts) do
        rows[#rows + 1] = event .. "=" .. count
    end
    table.sort(rows)
    return #rows > 0 and table.concat(rows, ", ") or "none"
end

function ns.Chat(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99WFLP|r " .. message)
    end
end

local function register(frame, event)
    pcall(frame.RegisterEvent, frame, event)
end

local events = CreateFrame("Frame")
for _, event in ipairs({
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEVEL_UP",
    "PLAYER_XP_UPDATE",
    "ZONE_CHANGED",
    "ZONE_CHANGED_NEW_AREA",
    "QUEST_LOG_UPDATE",
    "QUEST_WATCH_UPDATE",
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN",
    "QUEST_AUTOCOMPLETE",
    "QUEST_REMOVED",
    "PLAYER_TARGET_CHANGED",
    "UPDATE_MOUSEOVER_UNIT",
}) do
    register(events, event)
end

events:SetScript("OnEvent", function(_, event, ...)
    ns.RecordEvent(event, ...)
    if ns.HandleEvent then
        ns.HandleEvent(event, ...)
    end
    ns.RecordActivityEvent(event, ...)
    if ns.UI and ns.UI.Refresh then
        ns.UI.Refresh()
    end
end)

SLASH_WFLP1 = "/wflp"
SlashCmdList.WFLP = function(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command ~= "clearlog" then
        ns.AppendActivity("COMMAND", command == "" and "/wflp" or "/wflp " .. command)
    end
    if command == "" then
        ns.UI.Toggle()
    elseif command == "dump" then
        ns.DumpSnapshot()
    elseif command == "questie" then
        ns.RunQuestieDBProbe()
        ns.UI.Refresh()
    elseif command == "path" then
        ns.RunShortestPathProbe()
        ns.UI.Refresh()
    elseif command == "events" then
        ns.DumpEvents()
    elseif command == "log" then
        ns.DumpActivityLog()
    elseif command == "clearlog" then
        ns.ClearActivityLog()
        ns.AppendActivity("LOG_CLEARED", "by player command")
        ns.Chat("persistent M0 test log cleared")
    elseif command == "reset" then
        ns.ResetTemporaryValues()
        ns.Chat("temporary diagnostic values reset")
    else
        ns.Chat("commands: /wflp, dump, questie, path, events, log, clearlog, reset")
    end
end
