local _, ns = ...

function ns.WriteEvaluation()
    ns.ResolveSuggestedTarget()
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    local lib = _G.LibQuestieDB
    local contractOK, accepted = ns.SafeCall(lib and lib.RequireContract, 2)
    local metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local _, flavor = ns.SafeCall(metadata, lib and lib.addonName or "QuestieDB", "X-Flavor")
    local _, build, buildNumber, buildDate, interface = ns.SafeCall(GetBuildInfo)
    local _, name = ns.SafeCall(UnitName, "player")
    local _, realm = ns.SafeCall(GetRealmName)
    local _, xp = ns.SafeCall(UnitXP, "player")
    local _, xpMax = ns.SafeCall(UnitXPMax, "player")
    local target = ns.GetTarget()
    local report = { version = "0.3.0", recordedAt = type(time) == "function" and time() or 0,
        client = { version = build, build = buildNumber, date = buildDate, interface = interface },
        player = ns.ReadRoutePlayer(), character = name, realm = realm,
        xp = type(xp) == "number" and xp or nil, xpMax = type(xpMax) == "number" and xpMax or nil,
        completionHistoryReady = ns.guideState.ready, questLogReady = ns.guideState.logReady == true,
        activeQuests = #ns.guideState.quests, guideRunning = ns.guideRunning == true,
        contractAccepted = contractOK and accepted == true, flavor = flavor,
        tooltipHook = ns.tooltipInstalled == true, routeCounts = {}, route = {}, issues = {},
        turnInEnabled = ns.AutoTurnInEnabled(), confirmedTurnIns = WoWForeverLaunchGuideCharDB.confirmedTurnIns or 0,
        selectedQuest = target and target.questID, selectedKind = target and target.kind,
        selectedMap = target and target.map, selectedSource = target and target.source,
        routeReason = ns.routeReason, observation = ns.UnitObservationSummary(),
        lastAddonError = ns.lastAddonError,
        crowd = WoWForeverLaunchGuideCharDB.crowd,
        spatialValidation = "unknown: requires real-client verification",
        plannerMilliseconds = ns.plannerMilliseconds,
        efficiencyValidation = "unknown: heuristic, not measured optimal XP/h" }
    for _, step in ipairs(ns.routeSteps or {}) do
        report.routeCounts[step.status] = (report.routeCounts[step.status] or 0) + 1
        report.route[#report.route + 1] = { questID = step.questID, packet = step.packet.id, status = step.status, reason = step.reason }
    end
    if not report.questLogReady then report.issues[#report.issues + 1] = "Questlog noch nicht lesbar" end
    if not report.completionHistoryReady then report.issues[#report.issues + 1] = "Abschlusshistorie fehlt; keine unbekannten Quests freigeben" end
    if not report.contractAccepted then report.issues[#report.issues + 1] = "QuestieDB fehlt oder Contract abgelehnt" end
    if flavor ~= "Forever" then report.issues[#report.issues + 1] = "QuestieDB-Forever-Flavor nicht bestätigt" end
    if not report.tooltipHook then report.issues[#report.issues + 1] = "Tooltip-Hook nicht verfügbar; Panel-Fallback nutzen" end
    if ns.guideRunning and not target then report.issues[#report.issues + 1] = "Guide wartet: kein belegter Zielpunkt" end
    if ns.lastAddonError then report.issues[#report.issues + 1] = "Addon-Fehler: " .. ns.lastAddonError end
    WoWForeverLaunchGuideCharDB.evaluation = report
end
