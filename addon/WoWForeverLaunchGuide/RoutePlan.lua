local _, ns = ...

-- Editorial route only. No names, NPCs, requirements or coordinates copied here.
ns.routePlan = {
    { id = "U01", label = "Deathknell: Einstieg", minimum = 1, maximum = 5, quests = { 363, 364, 376, 3901 } },
    { id = "U02", label = "Deathknell: Scarlet-Ast", minimum = 2, maximum = 6, quests = { 380, 381, 382, 383 }, optional = true },
    { id = "U03", label = "Brill: West und unterwegs", minimum = 4, maximum = 12, quests = { 404, 367, 375, 365 } },
    { id = "U04", label = "Brill: Nordschleife", minimum = 5, maximum = 12, quests = { 358, 5482, 398 } },
    { id = "U05", label = "Brill: Mühlen", minimum = 7, maximum = 13, quests = { 426 } },
    { id = "U06", label = "Tirisfal: Plague-Fortsetzung", minimum = 7, maximum = 14, quests = { 368, 369 } },
    { id = "U07", label = "Übergang nach Silverpine", minimum = 10, maximum = 15, quests = { 445 }, branch = "silverpine" },
    { id = "U08", label = "Sepulcher: Einstieg", minimum = 10, maximum = 16, quests = { 421, 447, 437, 438 }, branch = "silverpine" },
    { id = "U09", label = "Silverpine: Arugal-Ast", minimum = 12, maximum = 19, quests = { 422, 423, 424 }, optional = true, branch = "silverpine" },
    { id = "U10", label = "Silverpine: Süden", minimum = 16, maximum = 20, quests = { 477, 478, 481, 482, 479, 98299, 516, 480 }, branch = "silverpine" },
    { id = "B01", label = "Barrens: manuell gewählter Ausweichast", minimum = 10, maximum = 20, quests = { 844, 4921, 900, 5041 }, branch = "barrens" },
}

function ns.RouteStep(questID)
    for order, packet in ipairs(ns.routePlan) do
        for index, id in ipairs(packet.quests) do
            if questID == id then return packet, order * 100 + index end
        end
    end
end
