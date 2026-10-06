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

**Entscheidung:** M1 beginnt mit einem eigenen kleinen Addon. Es bündelt weder Shortest-Path- noch QuestieDB-Code und kopiert keine Questdaten. Shortest Path Forever ist ausschließlich eine optionale Laufzeit-Dependency über dessen Public API. Eine Navigation wird nur nach einer ausdrücklichen Spieleraktion gestartet. QuestieDB darf als optionale Laufzeit-Datenquelle erkannt werden, ist aber noch nicht Teil eines Routen- oder Optimizer-Systems. Eine Bridge wird weiterhin nicht implementiert.

**Auswirkungen:** M1 kann einen manuell gesetzten nächsten Zielpunkt über den SPF-Pfeil und dessen Kartenmarker führen, ohne eine Route oder eigene Navigation zu behaupten. Fehlt SPF, zeigt das Addon einen klaren Status statt zu scheitern. Die spätere Distribution muss die GPL-/Packaging-Bewertung erneut prüfen.

## D-009 – Native Quest-POIs vor QuestieDB-Spawnkarten in M1

**Kontext:** QuestieDB-NPC-Spawns sind nach QuestieDB-Zonen-IDs organisiert. Diese IDs sind nicht nachweisbar identisch mit den `uiMapID`s, welche die Shortest-Path-Forever-Public-API akzeptiert. Eine direkte Verwendung würde Ziele auf einer falschen Karte riskieren. Der Forever-Client bietet dagegen für aktive Quests `GetQuestUiMapID`, `C_QuestLog.GetQuestsOnMap` und `C_QuestLog.GetNextWaypoint`; deren Ausgabe besteht bereits aus `uiMapID` und normalisierten Koordinaten.

**Entscheidung:** M1 löst das nächste Questziel ausschließlich aus nativen Quest-POIs oder dem nativen nächsten Quest-Waypoint auf. QuestieDB wird nur auf Verfügbarkeit seines öffentlichen Contracts geprüft und nicht als unbestätigter Kartenübersetzer verwendet. Gibt es keinen nativen Zielpunkt, speichert und startet das Addon keine Navigation.

**Auswirkungen:** Der M1-Vertikalschnitt führt nur zu kartengenauen, laufzeitverifizierten Zielen. Eine spätere Mapping-Schicht darf erst nach einer dokumentierten, getesteten Zuordnung zwischen QuestieDB-Zone und `uiMapID` ergänzt werden.
