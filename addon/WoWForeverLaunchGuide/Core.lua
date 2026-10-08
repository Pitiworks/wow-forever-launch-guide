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
    "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA", "BAG_UPDATE_DELAYED", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED" }) do
    pcall(events.RegisterEvent, events, event)
end
local queued = false
local function update()
    queued = false
    ns.ReconcileGuide()
    ns.RefreshUI()
end
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
        ns.InstallTooltipHints()
        ns.Record("LOGIN", "Guide 0.2.0")
        ns.Chat("Guide bereit: /wflg. Abgabehilfe zunächst AUS; im Fenster einschalten. Shift pausiert sie.")
    elseif event == "WHO_LIST_UPDATE" and ns.OnWhoListUpdate then
        ns.OnWhoListUpdate()
    end
    if event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
        -- Let Blizzard populate/show the dialog first, then verify its current quest.
        if C_Timer and type(C_Timer.After) == "function" then
            local ok, id = ns.SafeCall(GetQuestID)
            if ok and id then
                C_Timer.After(0, function()
                    local currentOK, currentID = ns.SafeCall(GetQuestID)
                    if currentOK and currentID == id then ns.HandleQuestDialog(event) end
                end)
            end
        end
    elseif event == "QUEST_FINISHED" then
        ns.HandleQuestDialog(event)
    end
    if event == "QUEST_TURNED_IN" then ns.Record("QUEST_TURNED_IN", select(1, ...)) end
    if event ~= "PLAYER_TARGET_CHANGED" and event ~= "UPDATE_MOUSEOVER_UNIT" then
        if not queued then
            queued = true
            if C_Timer and type(C_Timer.After) == "function" then C_Timer.After(0, update) else update() end
        end
    end
    ns.RefreshUI()
end)

SLASH_WFLG1 = "/wflg"
SlashCmdList.WFLG = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$")
    local lower = command:lower()
    if lower == "" then
        ns.UI.Toggle()
    elseif lower == "next" then
        ns.UseSuggestedTarget()
    elseif lower == "go" then
        ns.StartNavigation()
    elseif lower == "clear" then
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
    else
        local map, x, y, title = command:match("^target%s+(%d+)%s+([%d%.]+)%s+([%d%.]+)%s*(.*)$")
        if map and x and y then
            ns.SetTarget(tonumber(map), tonumber(x), tonumber(y), title)
        else
            ns.Chat("commands: /wflg, next, target <map> <x> <y> [title], go, clear, status, scan, autoturnin")
        end
    end
end
