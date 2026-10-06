local addonName, ns = ...

ns.addonName = addonName
ns.owner = "WoW Forever Launch Guide"

function ns.SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "unavailable"
    end
    return pcall(fn, ...)
end

function ns.Short(value, limit)
    if value == nil then
        return "unavailable"
    end
    local text = tostring(value)
    limit = limit or 72
    return #text > limit and text:sub(1, limit - 3) .. "..." or text
end

function ns.Chat(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffWFLG|r " .. message)
    end
end

function ns.UnitInfo(unit)
    local name = type(UnitName) == "function" and UnitName(unit) or nil
    local guid = type(UnitGUID) == "function" and UnitGUID(unit) or nil
    local kind, ignored1, ignored2, ignored3, ignored4, entry
    if type(strsplit) == "function" then
        kind, ignored1, ignored2, ignored3, ignored4, entry = strsplit("-", guid or "")
    end
    return {
        name = name,
        guid = guid,
        npcID = (kind == "Creature" or kind == "Vehicle") and tonumber(entry) or nil,
    }
end

function ns.RefreshUI()
    if ns.UI and ns.UI.Refresh then
        ns.UI.Refresh()
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_REGEN_ENABLED" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        WoWForeverLaunchGuideCharDB = WoWForeverLaunchGuideCharDB or {}
    end
    ns.RefreshUI()
end)

SLASH_WFLG1 = "/wflg"
SlashCmdList.WFLG = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$")
    local lower = command:lower()
    if lower == "" then
        ns.UI.Toggle()
    elseif lower == "next" then
        ns.UseSuggestedTarget()
    elseif lower == "go" then
        ns.StartNavigation()
    elseif lower == "clear" then
        ns.ClearTarget()
    elseif lower == "status" then
        ns.PrintStatus()
    else
        local map, x, y, title = command:match("^target%s+(%d+)%s+([%d%.]+)%s+([%d%.]+)%s*(.*)$")
        if map and x and y then
            ns.SetTarget(tonumber(map), tonumber(x), tonumber(y), title)
        else
            ns.Chat("commands: /wflg, next, target <map> <x> <y> [title], go, clear, status")
        end
    end
end
