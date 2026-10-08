local _, ns = ...
local cache = {}
local shoppingCache

function ns.InvalidateHints() cache = {}; shoppingCache = nil end

function ns.DBRead(entity, id, fields)
    local lib = _G.LibQuestieDB
    if type(lib) ~= "table" then return nil end
    local contractOK, accepted = ns.SafeCall(lib.RequireContract, 2)
    if not contractOK or accepted ~= true then return nil end
    local reader = lib[entity]
    if type(reader) ~= "table" then return nil end
    local ok, data = ns.SafeCall(reader.GetAll, id, fields)
    return ok and type(data) == "table" and data or nil
end

local function includes(ids, id)
    if type(ids) ~= "table" then return false end
    for _, value in ipairs(ids) do if value == id then return true end end
    return false
end

function ns.NPCHints(npcID)
    if not npcID then return {} end
    if cache[npcID] then return cache[npcID].lines, cache[npcID].quests end
    local hints, related = {}, {}
    for _, q in ipairs(ns.guideState.quests) do
        local data = ns.DBRead("Quest", q.id, { "finishedBy", "objectives" })
        if data then
            local finish, objectives = data[1], data[2]
            local role
            if q.complete and type(finish) == "table" and includes(finish[1], npcID) then
                role = "Abgeben"
            elseif not q.complete and type(objectives) == "table" then
                for _, row in ipairs(objectives[1] or {}) do
                    if row[1] == npcID then role = "Questziel" end
                end
                for _, row in ipairs(objectives[5] or {}) do
                    if row[2] == npcID or includes(row[1], npcID) then role = "Questziel" end
                end
                for _, row in ipairs(objectives[3] or {}) do
                    local item = ns.DBRead("Item", row[1], { "npcDrops", "name" })
                    if item and includes(item[1], npcID) then
                        role = "Möglicher Questitem-Drop: " .. (item[2] or ("Item " .. row[1]))
                    end
                end
            end
            if role then
                hints[#hints + 1] = role .. " — " .. (q.name or tostring(q.id))
                related[q.id] = q.complete and "turnin" or "objective"
            end
        end
    end
    for _, step in ipairs(ns.routeSteps or {}) do
        if step.status == "candidate" then
            local q = ns.DBRead("Quest", step.questID, { "startedBy" })
            if q and type(q[1]) == "table" and includes(q[1][1], npcID) then
                hints[#hints + 1] = "Routenkandidat: " .. step.name .. " — Angebot hier prüfen"
                related[step.questID] = "pickup"
            end
        end
    end
    cache[npcID] = { lines = hints, quests = related }
    return hints, related
end

function ns.ShoppingHints()
    if shoppingCache then return shoppingCache end
    local hints, seen, active = {}, {}, {}
    for _, quest in ipairs(ns.guideState.quests) do active[quest.id] = true end
    local function inspect(questID, future, activeQuest)
        local q = ns.DBRead("Quest", questID, { "name", "objectives" })
        if not q or type(q[2]) ~= "table" then return end
        for _, row in ipairs(q[2][3] or {}) do
            local itemID = row[1]
            local item = ns.DBRead("Item", itemID, { "name", "vendors" })
            if item and type(item[2]) == "table" and #item[2] > 0 then
                local countOK, count = ns.SafeCall(GetItemCount, itemID)
                -- DB objective tuple slot 3 is an icon hint, NOT an item count.
                -- Associate a quantity only with an unambiguous localized client
                -- objective containing exactly one of this quest's item names.
                local required
                for _, objective in ipairs(activeQuest and activeQuest.objectives or {}) do
                    if objective.type == "item" and type(objective.text) == "string" and type(item[1]) == "string"
                        and objective.text:find(item[1], 1, true) then
                        local matches = 0
                        for _, other in ipairs(q[2][3] or {}) do
                            local name = ns.DBRead("Item", other[1], { "name" })
                            if name and type(name[1]) == "string" and objective.text:find(name[1], 1, true) then matches = matches + 1 end
                        end
                        if matches == 1 and type(objective.numRequired) == "number" then required = objective.numRequired end
                    end
                end
                local missing = required and countOK and type(count) == "number" and math.max(0, required - count) or nil
                if missing ~= 0 and not seen[itemID] then
                    seen[itemID] = true
                    local vendor = ns.DBRead("Npc", item[2][1], { "name" })
                    hints[#hints + 1] = (future and "Für möglichen Folgeschritt (Angebot prüfen): " or "Benötigt: ")
                        .. (missing and (missing .. "x ") or "Menge im Questlog/Angebot prüfen: ") .. (item[1] or ("Item " .. itemID))
                        .. (countOK and type(count) == "number" and (" [Bestand " .. count .. "]") or " [Bestand unbekannt]")
                        .. " — Händler: " .. (vendor and vendor[1] or ("NPC " .. item[2][1]))
                        .. " (Bestand/Erreichbarkeit ungeprüft), für " .. (q[1] or tostring(questID))
                end
            end
        end
    end
    for _, quest in ipairs(ns.guideState.quests) do
        if not quest.complete then inspect(quest.id, false, quest) end
    end
    local upcoming = 0
    for _, step in ipairs(ns.routeSteps or {}) do
        if step.status == "candidate" and upcoming < 3 then
            inspect(step.questID, true)
            upcoming = upcoming + 1
        end
    end
    for _, quest in ipairs(ns.guideState.quests) do
        local data = ns.DBRead("Quest", quest.id, { "nextQuestInChain" })
        local nextID = data and tonumber(data[1])
        if nextID and not active[nextID] and ns.guideState.ready and not ns.guideState.completed[nextID] then
            inspect(nextID, true)
        end
    end
    shoppingCache = hints
    return hints
end

function ns.InstallTooltipHints()
    if ns.tooltipInstalled or not GameTooltip or type(GameTooltip.HookScript) ~= "function" then return end
    local ok = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", function(tooltip)
        if tooltip.wflgAnnotated then return end
        local unitOK, _, unit = ns.SafeCall(tooltip.GetUnit, tooltip)
        if not unitOK or not unit then return end
        local hints = ns.NPCHints(ns.UnitInfo(unit).npcID)
        if #hints == 0 then return end
        tooltip.wflgAnnotated = true
        tooltip:AddLine("WFLG — Quest- und Routenhinweise", 0.2, 0.8, 1)
        for _, hint in ipairs(hints) do tooltip:AddLine(hint, 1, 0.85, 0.2, true) end
        tooltip:Show()
    end)
    if ok then
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip) tooltip.wflgAnnotated = nil end)
        ns.tooltipInstalled = true
    end
end
