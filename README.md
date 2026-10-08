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

**M1 – experimenteller Questassistent 0.3.0:** Erste ausführbare Untoten-Routenpakete mit Annahme-/Objective-/Abgabeschritten und automatischer SPF-Schrittfolge nach Klick auf „Guide starten“. Dazu später Einstieg, Voraussetzungssperren, Abschlussbonus ab 50 %, vorsichtige Zielwechsel, Mouseover-/Händlerhinweise, beobachtbare Questgegner, optionale Abgabehilfe und automatisch gespeicherte Selbstauswertung. 21 Lua-5.1-Syntaxprüfungen, sieben Testsuiten und ein optionaler QuestieDB-Basisdaten-/Mapping-Abgleich bestehen. Die neuen Funktionen und Koordinaten sind im Forever-Client noch zu bestätigen. Vollständige 1–20-XP-Abdeckung, globaler Crowd-Optimizer und Live-Bridge fehlen weiterhin. [Bedienung und Grenzen](docs/M1_NAVIGATION.md).

Die vollständige Projektreferenz befindet sich in [docs/PROJECT_BRAIN.md](docs/PROJECT_BRAIN.md).
