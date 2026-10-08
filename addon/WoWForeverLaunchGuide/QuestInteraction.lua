local _, ns = ...
local attempted = {}

function ns.AutoTurnInEnabled()
    return WoWForeverLaunchGuideCharDB and WoWForeverLaunchGuideCharDB.autoTurnIn == true
end

function ns.ToggleAutoTurnIn()
    WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    WoWForeverLaunchGuideCharDB.autoTurnIn = not ns.AutoTurnInEnabled()
    ns.Chat("Abgabehilfe " .. (ns.AutoTurnInEnabled() and "AN; Shift pausiert. Belohnungsauswahl bleibt manuell." or "AUS"))
    ns.RefreshUI()
end

function ns.HandleQuestDialog(event)
    if event == "QUEST_FINISHED" then attempted = {}; return end
    if not ns.AutoTurnInEnabled() then return end
    if type(IsShiftKeyDown) == "function" and IsShiftKeyDown() then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
    if not QuestFrame or not QuestFrame:IsShown() then return end
    local panel = event == "QUEST_PROGRESS" and QuestFrameProgressPanel or QuestFrameRewardPanel
    if not panel or not panel:IsShown() then return end
    local idOK, questID = ns.SafeCall(GetQuestID)
    if not idOK or type(questID) ~= "number" or questID <= 0 then return end
    local activeComplete = false
    -- Read fresh state: a QUEST_LOG_UPDATE may still be queued.
    for _, quest in ipairs(ns.ReadQuestState().quests) do
        if quest.id == questID and quest.complete then activeComplete = true end
    end
    if not activeComplete or attempted[event .. questID] then return end
    local moneyOK, money = ns.SafeCall(GetQuestMoneyToGet)
    if not moneyOK or money ~= 0 then return end
    local fn, choice
    if event == "QUEST_PROGRESS" then
        local ok, complete = ns.SafeCall(IsQuestCompletable)
        if not ok or complete ~= true then return end
        fn = CompleteQuest
    elseif event == "QUEST_COMPLETE" then
        local ok, choices = ns.SafeCall(GetNumQuestChoices)
        if not ok or choices ~= 0 then
            ns.Chat("Belohnung bitte selbst auswählen; keine automatische Abgabe.")
            return
        end
        fn, choice = GetQuestReward, 0
    else
        return
    end
    if type(fn) ~= "function" then return end
    attempted[event .. questID] = true
    local ok = ns.SafeCall(fn, choice)
    ns.Record(ok and "TURNIN_REQUEST" or "TURNIN_ERROR", questID .. " " .. event)
    if not ok then ns.Chat("Automatische Abgabe nicht verfügbar; bitte manuell abgeben.") end
end
