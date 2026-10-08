# Milestones

## M0 – Beta Probe

- Charakter/Realm
- Level/XP
- Quest-ID
- Questname
- Objectives
- Spielerkoordinaten
- Target/Mouseover NPC-ID
- Kill-Update
- Questitem-Update
- Questabschluss
- Questabgabe
- QuestieDB Forever compatibility probe
  - LibQuestieDB, Flavor und öffentlicher Contract
  - Quest-Voraussetzungen, Chains sowie Start-/End-NPCs
  - NPC-/Objekt-/Item-Koordinaten und Item-Drops
  - Verhalten bei Login, Reload und fehlendem QuestieDB
- Shortest Path Forever compatibility probe
  - ausschließlich öffentliche API: Navigate, NavigateRoute, Estimate, CurrentStop, Ended
  - Verhalten bei fehlender Dependency, Reload und Combat

## M1 – Ingame Navigation

- Nächstes Ziel
- Zustandsabgleich als Grundlage der Zielwahl bei späterem Einstieg, Login/Reload und Charakterwechsel; kein vorausgesetzter Start auf Level 1
- Pfeil
- Entfernung
- Questgeber-Erkennung
- Mob-Erkennung
- Mouseover-Hinweis
- Karten-/Waypoint-Unterstützung
- manueller Area-Crowd-Scan: aktuelle Zone und spielrelevanter Levelbereich über eine klickgebundene Who-Abfrage, automatische Auswertung und Speicherung pro Charakter

## M2 – Bridge

- Nahezu Live-Übertragung
- Pro Charakter
- Lokale Verbindung
- Robuste Aktualisierung
- Wiederanlauf nach Login/Reload

## M3 – Web Dashboard

- Aktueller Schritt
- Nächste Schritte
- Questfortschritt
- Area überfüllt
- Quest blockiert
- Alternative Route

## M4 – Crowd Optimizer

Redaktionelle Grundlage: [Launch Route v0.1](LAUNCH_ROUTE.md). Questabhängigkeiten, Paketwechsel und Rückkehrpunkte werden vor dynamischer Optimierung festgelegt.

- QuestieDB Forever
- Questabhängigkeiten
- Folgequests
- Questitems
- Crowd-Risk
- Named-Mob-Risk
- Escort-Risk
- Sammelquest-Risk
- Alternative Gebiete
- Rerouting
- Einstiegspunkt aus Level, Position, aktiven Objectives, abgegebenen Quests und verifizierten Voraussetzungen bestimmen; unbekannte Historie nicht als unerledigt behandeln

## M5 – Release 1–20

- Beta-Daten integriert
- Horde-Route
- Crowd-Routen
- Finale Release-Tests
- Release-ready vor 05.11.2026
