local _, ns = ...
local tokens = {}

function ns.ObserveUnit(unit, remove)
    if type(unit) ~= "string" then return end
    if remove then tokens[unit] = nil; return end
    local info = ns.UnitInfo(unit)
    if not info.guid or not info.npcID then tokens[unit] = nil; return end
    tokens[unit] = { guid = info.guid, npcID = info.npcID }
end

function ns.ObservedQuestUnits(questID)
    local alive, unknown, seen = 0, 0, {}
    for unit, observation in pairs(tokens) do
        local info = ns.UnitInfo(unit)
        if info.guid ~= observation.guid then
            tokens[unit] = nil
        elseif not seen[info.guid] then
            seen[info.guid] = true
            local _, related = ns.NPCHints(observation.npcID)
            if related and related[questID] == "objective" then
                local deadOK, dead = ns.SafeCall(UnitIsDead, unit)
                local attackOK, attackable = ns.SafeCall(UnitCanAttack, "player", unit)
                if deadOK and dead == false and attackOK and attackable == true then alive = alive + 1
                elseif not deadOK or not attackOK then unknown = unknown + 1 end
            end
        end
    end
    return alive, unknown
end

function ns.UnitObservationSummary()
    local target = ns.GetTarget()
    if not target or target.kind ~= "objective" or not target.questID then return "Kein aktives Mobziel ausgewählt." end
    local alive, unknown = ns.ObservedQuestUnits(target.questID)
    return alive .. " beobachtbare mögliche Questgegner; " .. unknown .. " mit unbekanntem Status."
        .. " Kein Gebietsradar: 0 Sichtungen beweisen keinen leeren Spawn."
end
