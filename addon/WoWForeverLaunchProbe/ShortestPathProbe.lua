local _, ns = ...

function ns.RunShortestPathProbe()
    ns.RefreshSnapshot()
    local root = _G.ShortestPathForever
    local api = type(root) == "table" and root.API or nil
    local probe = {
        addonLoaded = ns.IsAddonLoaded("ShortestPathForever"),
        present = type(api) == "table",
        state = type(api) == "table" and "present" or "unavailable",
    }
    if not probe.present then
        probe.reason = "ShortestPathForever.API unavailable"
        ns.snapshot.shortestPath = probe
        return probe
    end

    probe.version = api.version
    for _, name in ipairs({ "Navigate", "NavigateRoute", "Estimate", "CurrentStop", "Ended" }) do
        probe[name] = type(api[name]) == "function" and "available" or "unavailable"
    end

    if type(api.CurrentStop) == "function" then
        local ok, value = ns.SafeCall(api.CurrentStop, ns.owner)
        probe.currentStop = ok and ns.ValueSummary(value) or "error"
    end
    if type(api.Ended) == "function" then
        local ok, value = ns.SafeCall(api.Ended, ns.owner)
        probe.ended = ok and ns.ValueSummary(value) or "error"
    end

    local location = ns.snapshot.location or {}
    local inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() == true
    if type(api.Estimate) == "function" and location.mapID and location.x and location.y and not inCombat then
        local ok, seconds, reason = ns.SafeCall(
            api.Estimate, location.mapID, location.x, location.y, location.mapID, location.x, location.y
        )
        probe.estimate = ok and (ns.ValueSummary(seconds) or ns.ValueSummary(reason) or "no result") or "error"
    else
        probe.estimate = inCombat and "not called during combat" or "not called: position unavailable"
    end
    probe.navigation = "Navigate and NavigateRoute are never called automatically"
    probe.combat = inCombat and "in combat" or "not in combat"
    ns.snapshot.shortestPath = probe
    if WoWForeverLaunchProbeCharDB then
        probe.previousPresent = WoWForeverLaunchProbeCharDB.shortestPathWasPresent
        WoWForeverLaunchProbeCharDB.shortestPathWasPresent = probe.present
    end
    return probe
end
