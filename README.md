# WoW Forever Launch Guide

Ein dynamischer Leveling- und Navigationsguide für **WoW Forever**, der für den Release-Zeitraum mit hohem Spielerandrang entwickelt wird.

Das Ziel ist nicht die theoretisch höchste XP pro Stunde unter Idealbedingungen, sondern die kürzeste reale Zeit bis Level 20, wenn Startgebiete überfüllt sind, Named Mobs umkämpft sind und Quests blockieren.

## Hauptkomponenten

- Ein schlankes WoW-Forever-Addon für Ingame-Navigation und Zustandsaufnahme
- Eine noch festzulegende Live-State-/Bridge-Schicht
- Ein lokaler Guide und Optimizer für Routing-Entscheidungen
- Ein HTML-Dashboard auf einem zweiten Monitor
- Quest- und NPC-Daten, vorrangig geprüft gegen QuestieDB Forever

Der Zustand wird immer getrennt pro Charakter geführt. Crowd-Signale wie **Area überfüllt** und **Quest blockiert** sollen alternative Routen ermöglichen.

## Aktueller Stand

**M0 – Beta Probe:** Das Projekt bereitet Messungen vor. Es gibt noch keine Implementierung und bewusst keine technische Festlegung für die Live-Bridge.

Die vollständige Projektreferenz befindet sich in [docs/PROJECT_BRAIN.md](docs/PROJECT_BRAIN.md).
