local addonName, ns = ...

ns.addonName = addonName
ns.owner = "WoW Forever Launch Guide"

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
    limit = limit or 72
    return #text > limit and text:sub(1, limit - 3) .. "..." or text
end

function ns.Chat(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffWFLG|r " .. message)
    end
end

function ns.Guard(context, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        ns.guideRunning = false
        local message = context .. ": " .. tostring(result)
        if message ~= ns.lastAddonError then
            ns.lastAddonError = message
            if ns.Record then pcall(ns.Record, "ADDON_ERROR", message) end
            pcall(ns.Chat, "Guide wegen eines Fehlers pausiert. Fehler ist im Bericht; mit /reload speichern.")
            local handler = type(geterrorhandler) == "function" and geterrorhandler() or nil
            if type(handler) == "function" then pcall(handler, message) end
        end
        local path = _G.ShortestPathForever and _G.ShortestPathForever.API
        if type(path) == "table" and type(path.Cancel) == "function" then pcall(path.Cancel, ns.owner) end
    end
    return ok, result
end

function ns.UnitInfo(unit)
    local name = type(UnitName) == "function" and UnitName(unit) or nil
    local guid = type(UnitGUID) == "function" and UnitGUID(unit) or nil
    local kind, ignored1, ignored2, ignored3, ignored4, entry
    if type(strsplit) == "function" then
        kind, ignored1, ignored2, ignored3, ignored4, entry = strsplit("-", guid or "")
    end
    return {
        name = name,
        guid = guid,
        npcID = (kind == "Creature" or kind == "Vehicle") and tonumber(entry) or nil,
    }
end

function ns.RefreshUI()
    if ns.UI and ns.UI.Refresh then
        ns.UI.Refresh()
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_REGEN_ENABLED", "WHO_LIST_UPDATE",
    "QUEST_LOG_UPDATE", "QUEST_POI_UPDATE", "QUEST_WATCH_UPDATE", "QUEST_ACCEPTED", "QUEST_TURNED_IN",
    "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA", "BAG_UPDATE_DELAYED", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED",
    "PLAYER_STOPPED_MOVING", "ADDON_LOADED" }) do
    pcall(events.RegisterEvent, events, event)
end
for _, event in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }) do pcall(events.RegisterEvent, events, event) end
local queued = false
local function update()
    queued = false
    ns.ReconcileGuide()
    ns.UpdateGuide()
    ns.RefreshUI()
    ns.WriteEvaluation()
end
local function guardedUpdate() ns.Guard("Queststand aktualisieren", update) end
local function onEvent(_, event, ...)
    if event == "PLAYER_LOGIN" then
        WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
        ns.InstallTooltipHints()
        ns.guideRunning = false
        ns.Record("LOGIN", "Guide 0.3.0")
        ns.Chat("Guide bereit: /wflg → Guide starten. Abgabehilfe " .. (ns.AutoTurnInEnabled() and "AN" or "AUS") .. "; Shift pausiert sie.")
    elseif event == "WHO_LIST_UPDATE" and ns.OnWhoListUpdate then
        ns.OnWhoListUpdate()
    end
    if event == "PLAYER_TARGET_CHANGED" then ns.ObserveUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then ns.ObserveUnit("mouseover")
    elseif event == "NAME_PLATE_UNIT_ADDED" then ns.ObserveUnit(select(1, ...))
    elseif event == "NAME_PLATE_UNIT_REMOVED" then ns.ObserveUnit(select(1, ...), true) end
    if event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
        -- Let Blizzard populate/show the dialog first, then verify its current quest.
        if C_Timer and type(C_Timer.After) == "function" then
            local ok, id = ns.SafeCall(GetQuestID)
            if ok and id then
                C_Timer.After(0, function()
                    local currentOK, currentID = ns.SafeCall(GetQuestID)
                    if currentOK and currentID == id then ns.Guard("Questdialog " .. event, ns.HandleQuestDialog, event) end
                end)
            end
        end
    elseif event == "QUEST_FINISHED" then
        ns.HandleQuestDialog(event)
    end
    if event == "QUEST_TURNED_IN" then
        ns.Record("QUEST_TURNED_IN", select(1, ...))
        WoWForeverLaunchGuideCharDB.confirmedTurnIns = (WoWForeverLaunchGuideCharDB.confirmedTurnIns or 0) + 1
    end
    if event ~= "PLAYER_TARGET_CHANGED" and event ~= "UPDATE_MOUSEOVER_UNIT" and event ~= "NAME_PLATE_UNIT_ADDED" and event ~= "NAME_PLATE_UNIT_REMOVED" then
        if not queued then
            queued = true
            if C_Timer and type(C_Timer.After) == "function" then C_Timer.After(0, guardedUpdate) else guardedUpdate() end
        end
    end
    ns.RefreshUI()
    if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" then ns.WriteEvaluation() end
end
events:SetScript("OnEvent", function(...) ns.Guard("Addon-Ereignis", onEvent, ...) end)

SLASH_WFLG1 = "/wflg"
local function slash(message)
    local command = (message or ""):match("^%s*(.-)%s*$")
    local lower = command:lower()
    if lower == "" then
        ns.UI.Toggle()
    elseif lower == "next" then
        ns.UseSuggestedTarget()
    elseif lower == "go" then
        ns.StartNavigation()
    elseif lower == "clear" then
        ns.guideRunning = false
        ns.ClearTarget()
    elseif lower == "status" then
        ns.PrintStatus()
    elseif lower == "scan" then
        ns.ScanCurrentArea()
    elseif lower == "autoturnin" then
        ns.ToggleAutoTurnIn()
    elseif lower == "shopping" then
        local hints = ns.ShoppingHints()
        for _, hint in ipairs(hints) do ns.Chat(hint) end
        if #hints == 0 then ns.Chat("Keine belegten Einkaufshinweise verfügbar.") end
    elseif lower == "guide" then
        ns.ToggleGuide()
    elseif lower == "skip" then
        ns.DeferCurrentQuest()
    elseif lower == "route" then
        ns.ResolveSuggestedTarget()
        for _, step in ipairs(ns.routeSteps or {}) do
            ns.Chat(step.packet.id .. " " .. step.questID .. " " .. step.name .. " — " .. step.status .. ": " .. step.reason)
        end
    elseif lower == "report" then
        ns.WriteEvaluation()
        local evaluation = WoWForeverLaunchGuideCharDB.evaluation
        ns.Chat("Bericht " .. evaluation.version .. ": " .. evaluation.activeQuests .. " aktive Quests, " .. #evaluation.issues .. " Hinweise. Speichern mit /reload.")
        for _, issue in ipairs(evaluation.issues) do ns.Chat(issue) end
    elseif lower == "branch barrens" then
        ns.SelectBranch("barrens")
    elseif lower == "branch silverpine" then
        ns.SelectBranch("silverpine")
    else
        local map, x, y, title = command:match("^target%s+(%d+)%s+([%d%.]+)%s+([%d%.]+)%s*(.*)$")
        if map and x and y then
            ns.SetTarget(tonumber(map), tonumber(x), tonumber(y), title)
        else
            ns.Chat("commands: /wflg, guide, next, go, skip, route, branch silverpine|barrens, shopping, report, clear, status, scan, autoturnin, target <map> <x> <y> [title]")
        end
    end
end
SlashCmdList.WFLG = function(message) ns.Guard("Slash-Befehl", slash, message) end
