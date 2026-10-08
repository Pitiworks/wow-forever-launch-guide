local _, ns = ...

ns.UI = {}

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(660, 600)
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
title:SetText("WoW Forever Launch Guide — Questassistent 0.3")

local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 14, -42)
scroll:SetPoint("BOTTOMRIGHT", -34, 82)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(610, 510)
scroll:SetScrollChild(content)
local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("TOPLEFT", 0, 0)
text:SetWidth(605)
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")

local function unitLine(label, unit)
    return label .. ": " .. ns.Short(unit.name) .. " | NPC ID: " .. ns.Short(unit.npcID)
end

local scanButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
scanButton:SetSize(132, 24)
scanButton:SetPoint("BOTTOMLEFT", 14, 14)
scanButton:SetText("Scan area")
scanButton:SetScript("OnClick", function()
    ns.Guard("Gebietsscan", ns.ScanCurrentArea)
end)

local function button(label, x, width, action)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("BOTTOMLEFT", x, 14)
    b:SetText(label)
    b:SetScript("OnClick", function() ns.Guard("Button " .. label, action) end)
    return b
end
button("Nächstes Ziel", 154, 120, function() ns.UseSuggestedTarget() end)
button("Pfeil starten", 282, 120, function() ns.StartNavigation() end)
local autoButton = button("Abgabehilfe AUS", 410, 150, function() ns.ToggleAutoTurnIn() end)
button("X", 570, 60, function() frame:Hide() end)
local guideButton = button("Guide starten", 14, 150, function() ns.ToggleGuide() end)
guideButton:ClearAllPoints()
guideButton:SetPoint("BOTTOMLEFT", 14, 46)
local deferButton = button("5 Min. zurückstellen", 174, 170, function() ns.DeferCurrentQuest() end)
deferButton:ClearAllPoints()
deferButton:SetPoint("BOTTOMLEFT", 174, 46)
local branchButton = button("Ast: Silverpine", 354, 200, function()
    local branch = WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.branch or "silverpine"
    ns.SelectBranch(branch == "silverpine" and "barrens" or "silverpine")
end)
branchButton:ClearAllPoints()
branchButton:SetPoint("BOTTOMLEFT", 354, 46)

function ns.UI.Refresh()
    if not frame:IsShown() then return end
    local target = ns.GetTarget()
    local estimate, reason
    local suggestion, suggestionReason = ns.ResolveSuggestedTarget()
    if target then
        estimate, reason = ns.EstimateTarget(target)
    end
    local rows = {
        "|cffffd100[Guide-Modus]|r " .. ns.GuideStatus(),
        "|cffffd100[Nächstes Ziel]|r",
        target and (target.title .. "\nMap " .. target.map .. "  X " .. target.x .. "  Y " .. target.y) or "No target set.",
        target and (estimate ~= nil and ("Estimated travel: " .. ns.Short(estimate) .. " seconds") or ("Estimated travel unavailable: " .. ns.Short(reason))) or "Use: /wflg target <map> <x> <y> [title]",
        suggestion and ("Suggested quest target: " .. suggestion.title .. " (quest " .. suggestion.questID .. "; " .. suggestion.source .. ")") or ("Suggested quest target: " .. ns.Short(suggestionReason)),
        suggestion and ("Auswahl: " .. (suggestion.reason or "Questziel")) or "",
        suggestion and ("Paket: " .. (suggestion.packet or "aktive Quest außerhalb der Grundroute")) or "",
        "", "|cffffd100[Navigation]|r", ns.NavigationStatus(),
        "Use /wflg go only when you want SPF to start its arrow and map marker.",
        "", "|cffffd100[Area crowd]|r",
        ns.CrowdSummary(),
        ns.CrowdScanPending() and "Waiting for the server's Who response..." or "Click Scan area to update this value.",
        ns.UnitObservationSummary(),
        "", "|cffffd100[Recognition]|r",
        unitLine("Target", ns.UnitInfo("target")),
        unitLine("Mouseover", ns.UnitInfo("mouseover")),
    }
    local hints = ns.NPCHints(ns.UnitInfo("mouseover").npcID)
    for index = 1, math.min(2, #hints) do rows[#rows + 1] = "|cffffd100" .. hints[index] .. "|r" end
    rows[#rows + 1] = ""
    rows[#rows + 1] = "|cffffd100[Queststand / Einstieg]|r " .. #ns.guideState.quests .. " aktive Quests; Abschlusshistorie "
        .. (ns.guideState.ready and "geladen" or "unbekannt")
    for index = 1, math.min(3, #ns.guideState.quests) do
        local q = ns.guideState.quests[index]
        rows[#rows + 1] = (q.name or tostring(q.id)) .. ": "
            .. (q.complete and "abgabebereit" or (q.progress and (math.floor(q.progress * 100) .. "%") or "Fortschritt unbekannt"))
    end
    if #ns.guideState.quests > 3 then rows[#rows + 1] = "Weitere Quests werden ebenfalls ausgewertet." end
    rows[#rows + 1] = ""
    rows[#rows + 1] = "|cffffd100[Einkaufsvorbereitung]|r"
    local shopping = ns.ShoppingHints()
    for index = 1, math.min(3, #shopping) do rows[#rows + 1] = shopping[index] end
    if #shopping == 0 then rows[#rows + 1] = "Keine belegten Einkaufshinweise (QuestieDB und Inventardaten nötig)." end
    if #shopping > 3 then rows[#rows + 1] = "Weitere Hinweise: /wflg shopping" end
    rows[#rows + 1] = "Keine automatischen Käufe. AH-Handelbarkeit, Angebote und Preise ungeprüft."
    rows[#rows + 1] = "Abgabehilfe: nur geöffneter Questdialog, ohne Geldkosten/Belohnungsauswahl. Shift pausiert."
    autoButton:SetText(ns.AutoTurnInEnabled() and "Abgabehilfe AN" or "Abgabehilfe AUS")
    guideButton:SetText(ns.guideRunning and "Guide pausieren" or "Guide starten")
    local branch = WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.branch or "silverpine"
    branchButton:SetText(branch == "barrens" and "Ast: Barrens" or "Ast: Silverpine")
    rows[#rows + 1] = ""
    rows[#rows + 1] = "|cffffd100[Routenstatus]|r " .. (ns.routeReason or "Untoten-Profil; Kandidaten sind keine bestätigten Questangebote.")
    local shown = 0
    for _, step in ipairs(ns.routeSteps or {}) do
        if step.status == "candidate" or step.status == "active" or step.status == "turnin" then
            shown = shown + 1
            if shown <= 4 then rows[#rows + 1] = step.packet.id .. " " .. step.name .. " — " .. step.status end
        end
    end
    rows[#rows + 1] = "Details/gesperrte Schritte: /wflg route. Zurückstellen bricht keine Quest ab."
    text:SetText(table.concat(rows, "\n"))
    content:SetHeight(math.max(510, text:GetStringHeight() + 16))
end

function ns.UI.Toggle()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        ns.UI.Refresh()
    end
end
