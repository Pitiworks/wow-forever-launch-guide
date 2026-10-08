local _, ns = ...

local function api()
    local root = _G.ShortestPathForever
    return type(root) == "table" and type(root.API) == "table" and root.API or nil
end

local function validTarget(map, x, y)
    return type(map) == "number" and map > 0 and type(x) == "number" and x >= 0 and x <= 1 and type(y) == "number" and y >= 0 and y <= 1
end

function ns.SetTarget(map, x, y, title)
    if not validTarget(map, x, y) then
        ns.Chat("target rejected: map must be positive and coordinates must be between 0 and 1")
        return false
    end
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    WoWForeverLaunchGuideCharDB.target = {
        map = map,
        x = x,
        y = y,
        title = title ~= "" and title or "Next target",
    }
    ns.Chat("next target saved; use /wflg go to start navigation")
    ns.RefreshUI()
    return true
end

function ns.GetTarget()
    return WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.target or nil
end

function ns.UseSuggestedTarget()
    if ns.InvalidateSuggestion then ns.InvalidateSuggestion() end
    local target, reason = ns.ResolveSuggestedTarget()
    if not target then
        ns.Chat("no suggested target: " .. ns.Short(reason))
        return false
    end
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    WoWForeverLaunchGuideCharDB.target = target
    if ns.Record then ns.Record("TARGET_SELECTED", target.questID .. " " .. (target.reason or "")) end
    ns.Chat("next quest target selected; use /wflg go to start navigation")
    ns.RefreshUI()
    return true
end

function ns.ClearTarget()
    local target = ns.GetTarget()
    local path = api()
    if path and type(path.Cancel) == "function" then
        ns.SafeCall(path.Cancel, ns.owner)
    end
    if WoWForeverLaunchGuideCharDB then
        WoWForeverLaunchGuideCharDB.target = nil
    end
    ns.Chat(target and "target cleared" or "no target to clear")
    ns.RefreshUI()
end

function ns.EstimateTarget(target)
    local path = api()
    if not (path and type(path.Estimate) == "function" and target and C_Map and type(C_Map.GetBestMapForUnit) == "function" and type(C_Map.GetPlayerMapPosition) == "function") then
        return nil, "unavailable"
    end
    local okMap, map = ns.SafeCall(C_Map.GetBestMapForUnit, "player")
    local okPosition, position
    if okMap then
        okPosition, position = ns.SafeCall(C_Map.GetPlayerMapPosition, map, "player")
    end
    if not (okPosition and position and type(position.GetXY) == "function") then
        return nil, "position unavailable"
    end
    local okXY, x, y = ns.SafeCall(position.GetXY, position)
    if not okXY then
        return nil, "position unavailable"
    end
    local ok, seconds, reason = ns.SafeCall(path.Estimate, map, x, y, target.map, target.x, target.y)
    return ok and seconds or nil, ok and reason or "estimate error"
end

function ns.StartNavigation()
    local target = ns.GetTarget()
    if not target then
        ns.Chat("set a target first: /wflg target <map> <x> <y> [title]")
        return false
    end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        ns.Chat("navigation is not started during combat")
        return false
    end
    local path = api()
    if not (path and type(path.Navigate) == "function") then
        ns.Chat("Shortest Path Forever is unavailable; target remains saved")
        return false
    end
    local ok, started = ns.SafeCall(path.Navigate, ns.owner, target.map, target.x, target.y, target.title, target.kind or "objective")
    ns.Chat(ok and started and "navigation started" or "Shortest Path Forever rejected the target")
    ns.RefreshUI()
    return ok and started == true
end

function ns.NavigationStatus()
    local path = api()
    if not path then
        return "Shortest Path Forever unavailable"
    end
    local stop = type(path.CurrentStop) == "function" and select(2, ns.SafeCall(path.CurrentStop, ns.owner)) or nil
    local ended = type(path.Ended) == "function" and select(2, ns.SafeCall(path.Ended, ns.owner)) or nil
    return "SPF v" .. ns.Short(path.version) .. "; current stop=" .. ns.Short(stop) .. "; ended=" .. ns.Short(ended)
end

function ns.PrintStatus()
    local target = ns.GetTarget()
    ns.Chat(target and ("target=" .. target.title .. " map=" .. target.map .. " x=" .. target.x .. " y=" .. target.y) or "no next target")
    ns.Chat(ns.NavigationStatus())
end
