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

## D-008 – M1 nutzt Shortest Path Forever nur optional und nur über die Public API

**Kontext:** Die M0-Beta-Ergebnisse belegen eine akzeptierte QuestieDB-Contract-Version und die verfügbare Shortest-Path-Forever-API-Version 1. Die API bietet `Navigate`, `NavigateRoute`, `Estimate`, `CurrentStop`, `Ended` und `Cancel`. Lizenz- und Packaging-Fragen bleiben vor einem Release offen.

**Entscheidung:** M1 beginnt mit einem eigenen kleinen Addon. Es bündelt weder Shortest-Path- noch QuestieDB-Code und kopiert keine Questdaten. Shortest Path Forever ist ausschließlich eine optionale Laufzeit-Dependency über dessen Public API. Eine Navigation wird nur nach einer ausdrücklichen Spieleraktion gestartet. QuestieDB bleibt bis zum Routing-/Optimizer-Milestone eine Datenquelle, nicht Teil dieses M1-Vertikalschnitts. Eine Bridge wird weiterhin nicht implementiert.

**Auswirkungen:** M1 kann einen manuell gesetzten nächsten Zielpunkt über den SPF-Pfeil und dessen Kartenmarker führen, ohne eine Route oder eigene Navigation zu behaupten. Fehlt SPF, zeigt das Addon einen klaren Status statt zu scheitern. Die spätere Distribution muss die GPL-/Packaging-Bewertung erneut prüfen.
