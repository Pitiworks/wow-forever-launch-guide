local _, ns = ...

ns.UI = {}

local function status(value)
    if value == nil or value == false or value == "unavailable" then
        return "|cffff5555" .. ns.Short(value) .. "|r"
    end
    if value == "unknown" or value == "present" or value == "not called: position unavailable" then
        return "|cffffff55" .. ns.Short(value) .. "|r"
    end
    return "|cff55ff55" .. ns.Short(value) .. "|r"
end

local function line(label, value)
    return "|cffffffff" .. label .. ":|r " .. status(value)
end

local function questSummary(quest)
    local active = quest and quest.active
    if not active or #active == 0 then
        return "no active quest"
    end
    local rows = {}
    for index = 1, math.min(3, #active) do
        local entry = active[index]
        local objective = entry.objectives and entry.objectives[1]
        local objectiveText = objective and string.format("%s %s/%s", ns.Short(objective.text), ns.Short(objective.have), ns.Short(objective.need)) or "no objectives"
        rows[#rows + 1] = string.format(
            "#%s %s (level %s, %s)\n  %s",
            ns.Short(entry.id), ns.Short(entry.name), ns.Short(entry.level),
            entry.complete and "complete" or "incomplete", objectiveText
        )
    end
    if #active > 3 then
        rows[#rows + 1] = "... and " .. (#active - 3) .. " more active quests"
    end
    return table.concat(rows, "\n")
end

local function unitSummary(unit)
    if not unit or not unit.available then
        return "unavailable"
    end
    return string.format("%s\nGUID: %s\nNPC ID: %s", ns.Short(unit.name), ns.Short(unit.guid), ns.Short(unit.npcID))
end

local function dbSummary(probe)
    if not probe then
        return "not probed yet"
    end
    local quest = probe.quest or {}
    return table.concat({
        line("LibQuestieDB", probe.present and "yes" or "no"),
        line("Flavor", probe.flavor),
        line("Forever compatible", probe.foreverCompatibility),
        line("Contract", probe.contract),
        line("Contract version", probe.contractVersion),
        line("Load", probe.elapsedMs and (probe.elapsedMs .. " ms") or probe.reason),
        line("Quest", probe.activeQuestID),
        "  prereq: " .. ns.Short(quest.prerequisites),
        "  chain: " .. ns.Short(quest.chain),
        "  start/end: " .. ns.Short(quest.start) .. " / " .. ns.Short(quest.finish),
        "  objectives: " .. ns.Short(quest.objectives),
        "  NPC/object/item data: " .. ns.Short(quest.objectiveNPCsObjectsItems),
        "  NPC sample: " .. ns.Short(quest.npc),
        "  object sample: " .. ns.Short(quest.object),
        "  item sample: " .. ns.Short(quest.item),
        "  NPC coordinates: " .. ns.Short(probe.npcCoordinates),
        "  object coordinates: " .. ns.Short(probe.objectCoordinates),
        "  item drops: " .. ns.Short(probe.itemDrops),
    }, "\n")
end

local function pathSummary(probe)
    if not probe then
        return "not probed yet"
    end
    return table.concat({
        line("API", probe.present and "yes" or "no"),
        line("Version", probe.version),
        "  Navigate: " .. ns.Short(probe.Navigate),
        "  NavigateRoute: " .. ns.Short(probe.NavigateRoute),
        "  Estimate: " .. ns.Short(probe.Estimate) .. " (" .. ns.Short(probe.estimate) .. ")",
        "  CurrentStop: " .. ns.Short(probe.CurrentStop) .. " (" .. ns.Short(probe.currentStop) .. ")",
        "  Ended: " .. ns.Short(probe.Ended) .. " (" .. ns.Short(probe.ended) .. ")",
    }, "\n")
end

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(650, 610)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()
local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(frame)
if background.SetColorTexture then
    background:SetColorTexture(0, 0, 0, 0.88)
end

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 14, -12)
title:SetText("WoW Forever Launch Probe — M0 diagnostics")

local close = CreateFrame("Button", nil, frame)
close:SetSize(24, 24)
close:SetPoint("TOPRIGHT", -8, -8)
local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeText:SetAllPoints(close)
closeText:SetText("X")
close:SetScript("OnClick", function()
    frame:Hide()
end)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("TOPLEFT", 14, -42)
text:SetPoint("BOTTOMRIGHT", -14, 14)
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")

function ns.UI.Refresh()
    ns.RefreshSnapshot()
    local s = ns.snapshot
    local character, location = s.character or {}, s.location or {}
    local last = ns.lastEvent
    text:SetText(table.concat({
        "|cffffd100[Character]|r",
        line("Name", character.name), line("Realm", character.realm), line("Level", character.level), line("XP", ns.Short(character.xp) .. " / " .. ns.Short(character.xpMax)), line("Reload count", s.reloads),
        "", "|cffffd100[Location]|r",
        line("Zone", location.zone), line("Subzone", location.subzone), line("Map", location.mapID), line("X/Y", ns.Short(location.x) .. " / " .. ns.Short(location.y)),
        "", "|cffffd100[Quest]|r", questSummary(s.quest),
        "Observed complete: " .. ns.Short(s.quest and s.quest.observedCompletion and s.quest.observedCompletion.id),
        "Observed turn-in: " .. ns.Short(s.quest and s.quest.observedTurnIn and s.quest.observedTurnIn.id),
        "", "|cffffd100[Target]|r", unitSummary(s.target),
        "", "|cffffd100[Mouseover]|r", unitSummary(s.mouseover),
        "", "|cffffd100[Events]|r", "Last: " .. ns.Short(last and (last.time .. " " .. last.event)), "History: " .. #ns.eventHistory,
        "Counters: " .. ns.EventCountsSummary(),
        "", "|cffffd100[QuestieDB]|r", dbSummary(s.questieDB),
        "", "|cffffd100[Shortest Path]|r", pathSummary(s.shortestPath),
    }, "\n"))
end

function ns.UI.Toggle()
    if frame:IsShown() then
        frame:Hide()
    else
        ns.UI.Refresh()
        frame:Show()
    end
end
