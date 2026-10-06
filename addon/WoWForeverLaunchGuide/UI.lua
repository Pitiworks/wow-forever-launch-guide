local _, ns = ...

ns.UI = {}

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(480, 250)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(frame)
if background.SetColorTexture then
    background:SetColorTexture(0, 0, 0, 0.88)
end

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 14, -12)
title:SetText("WoW Forever Launch Guide — M1 navigation")

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("TOPLEFT", 14, -42)
text:SetPoint("BOTTOMRIGHT", -14, 14)
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")

local function unitLine(label, unit)
    return label .. ": " .. ns.Short(unit.name) .. " | NPC ID: " .. ns.Short(unit.npcID)
end

function ns.UI.Refresh()
    local target = ns.GetTarget()
    local estimate, reason
    if target then
        estimate, reason = ns.EstimateTarget(target)
    end
    local rows = {
        "|cffffd100[Next target]|r",
        target and (target.title .. "\nMap " .. target.map .. "  X " .. target.x .. "  Y " .. target.y) or "No target set.",
        target and (estimate ~= nil and ("Estimated travel: " .. ns.Short(estimate) .. " seconds") or ("Estimated travel unavailable: " .. ns.Short(reason))) or "Use: /wflg target <map> <x> <y> [title]",
        "", "|cffffd100[Navigation]|r", ns.NavigationStatus(),
        "Use /wflg go only when you want SPF to start its arrow and map marker.",
        "", "|cffffd100[Recognition]|r",
        unitLine("Target", ns.UnitInfo("target")),
        unitLine("Mouseover", ns.UnitInfo("mouseover")),
    }
    text:SetText(table.concat(rows, "\n"))
end

function ns.UI.Toggle()
    if frame:IsShown() then
        frame:Hide()
    else
        ns.UI.Refresh()
        frame:Show()
    end
end
