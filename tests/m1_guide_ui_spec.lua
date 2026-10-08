-- Load the complete TOC order and render the UI without a WoW client.
local ns, frames, timers = {}, {}, {}
local function frame()
    local f = { scripts = {}, shown = false }
    setmetatable(f, { __index = function(_, key)
        if key == "GetStringHeight" then return function() return 600 end end
        return function() end
    end })
    function f:SetScript(key, fn) self.scripts[key] = fn end
    function f:HookScript(key, fn) self.scripts[key] = fn end
    function f:CreateTexture() return frame() end
    function f:CreateFontString() return frame() end
    function f:IsShown() return self.shown end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetText(value) self.text = value end
    return f
end
CreateFrame = function()
    local f = frame()
    frames[#frames + 1] = f
    return f
end
UIParent = frame()
GameTooltip = frame()
SlashCmdList = {}
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local function drain()
    while #timers > 0 do table.remove(timers, 1)() end
end
C_QuestLog = {
    GetNumQuestLogEntries = function() return 0 end,
    GetAllCompletedQuestIDs = function() return {} end,
}
local toc = assert(io.open("addon/WoWForeverLaunchGuide/WoWForeverLaunchGuide.toc"))
for line in toc:lines() do
    if line:match("%.lua$") then
        assert(loadfile("addon/WoWForeverLaunchGuide/" .. line))("WFLG", ns)
    end
end
toc:close()
local events = frames[1]
events.scripts.OnEvent(events, "PLAYER_LOGIN")
drain()
assert(ns.guideState.ready and #ns.guideState.quests == 0)
assert(GameTooltip.scripts.OnTooltipSetUnit)
SlashCmdList.WFLG("")
SlashCmdList.WFLG("next") -- no active quests, no crash
SlashCmdList.WFLG("shopping")
SlashCmdList.WFLG("autoturnin")
assert(ns.AutoTurnInEnabled())
events.scripts.OnEvent(events, "QUEST_COMPLETE") -- absent interaction APIs, no action
drain()
events.scripts.OnEvent(events, "UPDATE_MOUSEOVER_UNIT")
assert(#WoWForeverLaunchGuideCharDB.report >= 2)
assert(WoWForeverLaunchGuideCharDB.evaluation.version == "0.3.0")
ns.ReconcileGuide = function() error("intentional test failure") end
ns.guideRunning = true
events.scripts.OnEvent(events, "QUEST_LOG_UPDATE")
drain()
assert(not ns.guideRunning and ns.lastAddonError:find("intentional test failure", 1, true))
assert(WoWForeverLaunchGuideCharDB.report[#WoWForeverLaunchGuideCharDB.report].event == "ADDON_ERROR")
print("m1_guide_ui_spec: ok")
