# Decision Log

Dieses ADR-artige Log dokumentiert Architektur- und Projektentscheidungen. Neue Entscheidungen erhalten eine fortlaufende Kennung, Kontext, Entscheidung und Auswirkungen.

## D-001 – GitHub als Projektgedächtnis

**Entscheidung:** GitHub ist die primäre Historie für Code, Dokumentation, Issues und Projektwissen.

## D-002 – Zustand pro Charakter

**Entscheidung:** Jeder gespeicherte Zustand ist eindeutig einem Charakter und Realm zugeordnet.

## D-003 – Zweiter Monitor mit HTML-Dashboard

**Entscheidung:** Ein HTML-/Web-Dashboard unterstützt den Guide auf einem separaten Monitor.

## D-004 – Ingame-Navigation bleibt im Addon

**Entscheidung:** Richtungsanzeige, Entfernung und unmittelbare Ingame-Navigation verbleiben im WoW-Addon.

## D-005 – Crowd-Signale

**Entscheidung:** Die Signale `AREA_CROWDED` und `QUEST_BLOCKED` werden als Eingaben für spätere Routenalternativen vorgesehen.

## D-006 – Erst M0 messen, dann Bridge festlegen

**Entscheidung:** Die technische Live-Bridge wird erst nach dokumentierten M0-Messungen gewählt.

## D-007 – QuestieDB Forever bevorzugt prüfen

**Entscheidung:** QuestieDB Forever ist die bevorzugt zu prüfende Datenbasis für Quest-, NPC- und Koordinatendaten.
