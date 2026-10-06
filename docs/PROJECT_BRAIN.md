# Project Brain

## Produktziel

WoW Forever Launch Guide führt Spieler dynamisch von Level 1 bis 20. Es optimiert für minimale reale Spielzeit während eines Releases mit hohem Andrang, nicht für eine Labor-Metrik unter leeren Serverbedingungen.

## Nutzer-Setup

- WoW läuft auf dem Hauptmonitor.
- Ein HTML-/Web-Dashboard läuft auf einem zweiten Monitor.
- Der Zustand ist strikt pro Charakter und Realm getrennt.
- Ein Ingame-Addon liefert Navigation und beobachtbaren Live-Zustand.
- Eine externe lokale Komponente soll später Routing und Optimierung übernehmen.

## Beschlossene Prinzipien

- GitHub ist Projektgedächtnis und Code-Historie.
- Zustand wird pro Charakter gespeichert.
- Die Ingame-Navigation bleibt im Addon; komplexes Routing bleibt außerhalb von WoW.
- Die Live-Bridge wird erst nach Beta-Messungen entschieden.
- SavedVariables gelten nicht automatisch als Live-Lösung.
- QuestieDB Forever wird als bevorzugte Quest-/NPC-/Koordinaten-Datenbasis geprüft.
- Große strukturierte Quest- und Messdaten können später ergänzend in Tabellen liegen.

## Zielarchitektur (grob)

WoW-Forever-Addon → Live State / Bridge → lokaler Guide / Optimizer → HTML-Dashboard. Der Optimizer kombiniert Questdaten mit Crowd-Signalen und sendet das nächste Ziel zurück an die Addon-Navigation. Details stehen in [ARCHITECTURE.md](ARCHITECTURE.md).

## Aktueller Fokus: M0

M0 beantwortet durch reale Beta-Messungen, welche Charakter-, Quest-, NPC-, Koordinaten- und Fortschrittsinformationen der Forever-Client zuverlässig liefert. Keine Bridge-Technik wird vor diesen Ergebnissen festgelegt.

## Definition of Done: M0

- Charakter und Realm, Level/XP, Zone/Subzone sowie Koordinaten sind getestet und dokumentiert.
- Aktive Quest-ID, Name und Objectives sind getestet und dokumentiert.
- Target- und Mouseover-NPC-IDs sind getestet und dokumentiert.
- Fortschrittsupdates nach Kill und Questitem-Loot sowie Abschluss und Abgabe sind getestet und dokumentiert.
- QuestieDB Forever ist auf Verfügbarkeit, Flavor, öffentlichen Contract, benötigte Quest-/NPC-/Objekt-/Item-Daten, Login-/Reload-Verhalten und fehlende Dependency geprüft.
- Shortest Path Forever ist ausschließlich über seine öffentliche Navigation-API auf Verfügbarkeit, Kernaufrufe, Login-/Reload-, Combat- und fehlende-Dependency-Verhalten geprüft.
- Verwendete Client-/Interface-Version, APIs, Events, erwartete und tatsächliche Werte sowie Zuverlässigkeit sind für jeden Test erfasst.
- Die Ergebnisse reichen aus, um die Bridge-Entscheidung bewusst zu treffen oder offene Risiken klar zu benennen.

## Release-Ziel

Release-ready vor dem **05.11.2026**.

## Projektstatus

Initiale M0-Vorbereitung abgeschlossen: Dokumentationsstruktur und Arbeitsregeln sind angelegt. Es existiert noch kein Guide-Code und keine technische Bridge-Festlegung.
