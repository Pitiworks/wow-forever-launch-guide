local _, ns = ...
ns.guideRunning = false
local lastKey, pendingCombat, pendingNavigation, lastReason

local function key(target)
    return target and table.concat({ target.questID or "manual", target.kind or "", target.map, target.x, target.y }, ":") or nil
end

function ns.GuideStatus()
    if not ns.guideRunning then return "AUS — " .. (lastReason or "Guide starten aktiviert die Schrittfolge für diese Sitzung.") end
    if pendingCombat then return "AN — neuer Pfeil wartet auf Kampfende." end
    return "AN — " .. (lastReason or "Queststand wird abgeglichen.")
end

function ns.UpdateGuide(force)
    if not ns.guideRunning then return end
    if not ns.guideState.logReady then
        lastReason = "Questlog noch unvollständig; kein erzwungener Schrittwechsel."
        return
    end
    local path = _G.ShortestPathForever and _G.ShortestPathForever.API
    local ok, ended = ns.SafeCall(type(path) == "table" and path.Ended, ns.owner)
    if lastKey and ok and ended == "replaced" then
        ns.guideRunning = false
        lastReason = "Andere SPF-Navigation übernommen; Guide bei Bedarf neu starten."
        ns.Record("GUIDE_REPLACED", "paused; other owner's route is not overwritten")
        return
    end
    local suggested, reason = ns.ResolveSuggestedTarget()
    if not suggested then
        lastReason = reason or ns.routeReason or "Kein belegtes Ziel verfügbar."
        if lastKey then
            ns.ClearTarget()
            ns.Record("GUIDE_WAIT", lastReason)
        end
        lastKey, pendingCombat, pendingNavigation = nil, false, false
        return
    end
    local current = ns.GetTarget()
    -- A valid existing step needs a material, known cost improvement to switch.
    if current and not force and key(current) ~= key(suggested) then
        for _, candidate in ipairs(ns.guideCandidates or {}) do
            if key(candidate.target) == key(current) then
                if not suggested.comparableTravel or candidate.score <= suggested.score + math.max(30, candidate.score * 0.25) then
                    suggested = candidate.target
                    suggested.score = candidate.score
                    suggested.reason = "Aktuellen Schritt beibehalten: Wechselvorteil nicht belegt/groß genug"
                end
                break
            end
        end
    end
    local targetKey = key(suggested)
    if lastKey == targetKey and not pendingCombat and not pendingNavigation and current and key(current) == targetKey then return end
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    WoWForeverLaunchGuideCharDB.target = suggested
    if lastKey ~= targetKey then ns.Record("GUIDE_STEP", suggested.questID .. " " .. suggested.kind .. " " .. (suggested.packet or "Questlog")) end
    lastKey = targetKey
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        pendingCombat = true
        lastReason = "Navigation nach Kampfende"
        return
    end
    local started = ns.StartNavigation(true)
    pendingCombat = false
    lastReason = started and "Schritt gewählt; SPF führt. Bewegung bleibt manuell." or "Ziel gewählt; SPF-Navigation nicht verfügbar/abgelehnt."
    if not started and not pendingNavigation then ns.Record("GUIDE_NAV_UNAVAILABLE", suggested.questID) end
    pendingNavigation = not started
end

function ns.ToggleGuide()
    ns.guideRunning = not ns.guideRunning
    lastKey, pendingCombat, pendingNavigation = nil, false, false
    lastReason = nil
    ns.Record(ns.guideRunning and "GUIDE_START" or "GUIDE_STOP", "session")
    if ns.guideRunning then
        ns.ReconcileGuide()
        ns.UpdateGuide(true)
    else
        ns.ClearTarget()
    end
    ns.RefreshUI()
end

function ns.DeferCurrentQuest()
    local target = ns.GetTarget()
    if not target or not target.questID then ns.Chat("Kein Questschritt ausgewählt."); return end
    WoWForeverLaunchGuideCharDB.deferred = WoWForeverLaunchGuideCharDB.deferred or {}
    local now = type(time) == "function" and time() or 0
    WoWForeverLaunchGuideCharDB.deferred[target.questID] = now + 300
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(300, function()
            local deferred = WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.deferred
            if deferred and deferred[target.questID] == now + 300 then
                deferred[target.questID] = nil
                ns.InvalidateSuggestion()
                if ns.guideRunning then ns.UpdateGuide() end
                ns.RefreshUI()
            end
        end)
    end
    ns.Record("QUEST_DEFERRED", target.questID .. " 300s; kein Questabbruch")
    if ns.InvalidateSuggestion then ns.InvalidateSuggestion() end
    ns.ClearTarget()
    lastKey = nil
    if ns.guideRunning then ns.UpdateGuide(true) end
    ns.RefreshUI()
end

function ns.SelectBranch(branch)
    if branch ~= "silverpine" and branch ~= "barrens" then return false end
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    WoWForeverLaunchGuideCharDB.branch = branch
    ns.Record("BRANCH_SELECTED", branch)
    ns.ReconcileGuide()
    ns.UpdateGuide(true)
    ns.RefreshUI()
    return true
end
