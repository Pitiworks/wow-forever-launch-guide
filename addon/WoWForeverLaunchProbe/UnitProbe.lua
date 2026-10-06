local _, ns = ...

local function npcIDFromGUID(guid)
    if type(guid) ~= "string" or type(strsplit) ~= "function" then
        return nil
    end
    local kind, _, _, _, _, entry = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then
        return tonumber(entry)
    end
    return nil
end

function ns.ReadUnit(unit)
    local name = type(UnitName) == "function" and UnitName(unit) or nil
    local guid = type(UnitGUID) == "function" and UnitGUID(unit) or nil
    return {
        name = name,
        guid = guid,
        npcID = npcIDFromGUID(guid),
        available = guid ~= nil or name ~= nil,
    }
end
