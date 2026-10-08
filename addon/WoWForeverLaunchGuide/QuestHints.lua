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
    if cache[npcID] then return cache[npcID] end
    local hints = {}
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
            if role then hints[#hints + 1] = role .. " — " .. (q.name or tostring(q.id)) end
        end
    end
    cache[npcID] = hints
    return hints
end

function ns.ShoppingHints()
    if shoppingCache then return shoppingCache end
    local hints, seen, active = {}, {}, {}
    for _, quest in ipairs(ns.guideState.quests) do active[quest.id] = true end
    local function inspect(questID, future)
        local q = ns.DBRead("Quest", questID, { "name", "objectives" })
        if not q or type(q[2]) ~= "table" then return end
        for _, row in ipairs(q[2][3] or {}) do
            local itemID, required = row[1], tonumber(row[3])
            local item = ns.DBRead("Item", itemID, { "name", "vendors" })
            if item and type(item[2]) == "table" and #item[2] > 0 and required then
                local countOK, count = ns.SafeCall(GetItemCount, itemID)
                local missing = countOK and type(count) == "number" and math.max(0, required - count) or nil
                if missing ~= 0 and not seen[itemID] then
                    seen[itemID] = true
                    local vendor = ns.DBRead("Npc", item[2][1], { "name" })
                    hints[#hints + 1] = (future and "Später, falls Kette fortgesetzt: " or "Benötigt: ")
                        .. (missing and (missing .. "x ") or "Bestand unbekannt: ") .. (item[1] or ("Item " .. itemID))
                        .. " — Händler: " .. (vendor and vendor[1] or ("NPC " .. item[2][1]))
                        .. " (Bestand/Erreichbarkeit ungeprüft), für " .. (q[1] or tostring(questID))
                end
            end
        end
    end
    for _, quest in ipairs(ns.guideState.quests) do
        if not quest.complete then inspect(quest.id, false) end
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
        tooltip:AddLine("WFLG — relevant für aktive Quests", 0.2, 0.8, 1)
        for _, hint in ipairs(hints) do tooltip:AddLine(hint, 1, 0.85, 0.2, true) end
        tooltip:Show()
    end)
    if ok then
        GameTooltip:HookScript("OnTooltipCleared", function(tooltip) tooltip.wflgAnnotated = nil end)
        ns.tooltipInstalled = true
    end
end
