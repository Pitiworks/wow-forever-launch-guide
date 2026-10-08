local function reset()
    _G.C_FriendList = nil
    _G.GetRealZoneText = nil
    _G.GetZoneText = nil
    _G.UnitLevel = nil
    _G.time = nil
    _G.C_Timer = nil
    _G.WoWForeverLaunchGuideCharDB = {}
end

local function loadCrowd(env)
    for key, value in pairs(env) do
        _G[key] = value
    end
    local chunk = assert(loadfile("addon/WoWForeverLaunchGuide/CrowdScan.lua"))
    chunk("WoWForeverLaunchGuide", env.ns)
end

reset()
local sent
local env = {
    ns = {
        SafeCall = function(fn, ...) return pcall(fn, ...) end,
        Chat = function() end,
        RefreshUI = function() end,
    },
    GetRealZoneText = function() return "Tirisfal Glades" end,
    UnitLevel = function() return 9 end,
    time = function() return 123456 end,
    C_FriendList = {
        SendWho = function(filter) sent = filter end,
        GetNumWhoResults = function() return 3, 3 end,
        GetWhoInfo = function(index)
            return ({
                { area = "Tirisfal Glades", level = 8 },
                { area = "Tirisfal Glades", level = 12 },
                { area = "Tirisfal Glades", level = 20 },
            })[index]
        end,
    },
}
loadCrowd(env)
assert(env.ns.ScanCurrentArea())
assert(sent == 'z-"Tirisfal Glades" 7-12')
env.ns.OnWhoListUpdate()
local sample = WoWForeverLaunchGuideCharDB.crowd
assert(sample.count == 2 and sample.status == "low" and sample.scannedAt == 123456)

reset()
local capped = {
    ns = { SafeCall = function(fn, ...) return pcall(fn, ...) end, Chat = function() end, RefreshUI = function() end },
    GetRealZoneText = function() return "Durotar" end,
    UnitLevel = function() return 10 end,
    C_FriendList = {
        SendWho = function() end,
        GetNumWhoResults = function() return 50, 50 end,
        GetWhoInfo = function() return { area = "Durotar", level = 10 } end,
    },
}
loadCrowd(capped)
assert(capped.ns.ScanCurrentArea())
capped.ns.OnWhoListUpdate()
sample = WoWForeverLaunchGuideCharDB.crowd
assert(sample.count == 50 and sample.capped and sample.status == "very high (server result limit)")

reset()
local timeout
capped.C_FriendList.GetNumWhoResults = function() return 1 end -- some clients omit total
capped.C_Timer = { After = function(seconds, fn) assert(seconds == 30); timeout = fn end }
loadCrowd(capped)
assert(capped.ns.ScanCurrentArea())
capped.ns.OnWhoListUpdate()
assert(WoWForeverLaunchGuideCharDB.crowd.count == 1 and not WoWForeverLaunchGuideCharDB.crowd.capped)
assert(capped.ns.ScanCurrentArea())
timeout()
assert(not capped.ns.CrowdScanPending())
capped.C_FriendList.SendWho = function() error("restricted") end
assert(not capped.ns.ScanCurrentArea() and not capped.ns.CrowdScanPending())

print("m1_crowd_scan_spec: ok")
