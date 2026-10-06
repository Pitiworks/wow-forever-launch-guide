local _, ns = ...

local pending

local function currentZone()
    if type(GetRealZoneText) == "function" then
        local zone = GetRealZoneText()
        if type(zone) == "string" and zone ~= "" then
            return zone
        end
    end
    return type(GetZoneText) == "function" and GetZoneText() or nil
end

local function playerLevel()
    local level = type(UnitLevel) == "function" and UnitLevel("player") or nil
    return type(level) == "number" and level > 0 and level or nil
end

local function whoAPI()
    local friendList = _G.C_FriendList
    if type(friendList) == "table"
        and type(friendList.SendWho) == "function"
        and type(friendList.GetNumWhoResults) == "function"
        and type(friendList.GetWhoInfo) == "function" then
        return friendList
    end
    return nil
end

local function crowdStatus(count, capped)
    if capped then
        return "very high (server result limit)"
    elseif count <= 5 then
        return "low"
    elseif count <= 15 then
        return "medium"
    elseif count <= 30 then
        return "high"
    end
    return "very high"
end

function ns.CrowdSummary()
    local scan = WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.crowd
    if not scan then
        return "No area scan yet. Click Scan area."
    end
    local count = scan.capped and ("at least " .. scan.count) or tostring(scan.count)
    return scan.zone .. " · levels " .. scan.minimum .. "-" .. scan.maximum .. ": " .. count .. " players · " .. scan.status
end

-- This is called only from the addon's visible button or its slash command. Forever marks
-- SendWho as hardware-event restricted, so this function must never run from an event or timer.
function ns.ScanCurrentArea()
    if pending then
        ns.Chat("area scan is already waiting for the server")
        return false
    end
    local api = whoAPI()
    local zone, level = currentZone(), playerLevel()
    if not api then
        ns.Chat("Who API is unavailable on this client")
        return false
    elseif not zone or not level then
        ns.Chat("area scan needs a zone and character level")
        return false
    end
    local minimum, maximum = math.max(1, level - 2), level + 3
    local queryZone = zone:gsub('"', "")
    local filter = 'z-"' .. queryZone .. '" ' .. minimum .. "-" .. maximum
    pending = { zone = zone, minimum = minimum, maximum = maximum, filter = filter }
    api.SendWho(filter)
    ns.Chat("area scan requested for " .. zone .. " (levels " .. minimum .. "-" .. maximum .. ")")
    ns.RefreshUI()
    return true
end

function ns.OnWhoListUpdate()
    if not pending then
        return
    end
    local api = whoAPI()
    if not api then
        pending = nil
        return
    end
    local countOK, returned, total = ns.SafeCall(api.GetNumWhoResults)
    if not countOK or type(returned) ~= "number" then
        pending = nil
        ns.Chat("area scan returned no readable results")
        ns.RefreshUI()
        return
    end
    local matching = 0
    for index = 1, returned do
        local infoOK, info = ns.SafeCall(api.GetWhoInfo, index)
        if infoOK and type(info) == "table" and info.area == pending.zone
            and type(info.level) == "number" and info.level >= pending.minimum and info.level <= pending.maximum then
            matching = matching + 1
        end
    end
    local capped = returned >= 50 or total >= 50
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    WoWForeverLaunchGuideCharDB.crowd = {
        zone = pending.zone,
        minimum = pending.minimum,
        maximum = pending.maximum,
        filter = pending.filter,
        count = matching,
        returned = returned,
        total = total,
        capped = capped,
        status = crowdStatus(matching, capped),
        scannedAt = type(time) == "function" and time() or nil,
    }
    pending = nil
    ns.Chat("area crowd: " .. ns.CrowdSummary())
    ns.RefreshUI()
end

function ns.CrowdScanPending()
    return pending ~= nil
end
