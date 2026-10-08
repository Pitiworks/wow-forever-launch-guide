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
- Einstieg und Wiedereinstieg sind auf jedem Level innerhalb 1–20 möglich: Der Guide gleicht den aktuellen Charakter-/Queststand ab, statt einen Start auf Level 1 oder eine vollständig mitgeloggte Historie vorauszusetzen. Details: [QUEST_ROUTING.md](QUEST_ROUTING.md).
- Die Ingame-Navigation bleibt im Addon; komplexes Routing bleibt außerhalb von WoW.
- Die Live-Bridge wird erst nach Beta-Messungen entschieden.
- SavedVariables gelten nicht automatisch als Live-Lösung.
- QuestieDB Forever wird als bevorzugte Quest-/NPC-/Koordinaten-Datenbasis geprüft.
- Große strukturierte Quest- und Messdaten können später ergänzend in Tabellen liegen.

## Zielarchitektur (grob)

WoW-Forever-Addon → Live State / Bridge → lokaler Guide / Optimizer → HTML-Dashboard. Der Optimizer kombiniert Questdaten mit Crowd-Signalen und sendet das nächste Ziel zurück an die Addon-Navigation. Details stehen in [ARCHITECTURE.md](ARCHITECTURE.md).

## Aktueller Fokus: M1

Die redaktionelle Grundroute v0.1 ist in [LAUNCH_ROUTE.md](LAUNCH_ROUTE.md) festgelegt: Untoten-Profil über Deathknell → Brill/Tirisfal-Schleifen → Silverpine, mit Barrens als vorbereitetem Ausweichast. Sie beruht auf Wowhead-Recherche und unseren Beta-Beobachtungen; vollständige XP-Abdeckung, Voraussetzungen und ausführbarer Guide sind noch offen. Crowd-Signale sollen zwischen vorbereiteten gültigen Paketen wählen, nicht erst spontan eine Route erfinden.

M0 hat die Blizzard-State-APIs und die beiden optionalen Addon-Contracts im echten Forever-Client messbar gemacht. M1 baut darauf eine kleine Ingame-Navigation auf. Keine Bridge-Technik wird vor einer gesonderten, dokumentierten Entscheidung festgelegt.

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

Das M0-Diagnose-Addon und die Beta-Ergebnisse sind in [M0_BETA_RESULTS.md](M0_BETA_RESULTS.md) dokumentiert. M1 0.2.0 erweitert die optionale SPF-Navigation um aktuellen Queststand, eine lokale Restaufwand-/Reiseheuristik mit Abschlussbonus ab 50 %, QuestieDB-Mouseover-/Einkaufshinweise und abschaltbare Questdialog-Abgabehilfe. Automatisierte Lua-5.1-Tests bestehen; die neuen Funktionen sind noch nicht im Forever-Client bestätigt. Ein ausführbarer 1–20-Routenplan, globaler Crowd-Optimizer, AH-Abfragen und eine technische Bridge-Festlegung fehlen weiterhin. Bedienung und Grenzen: [M1_NAVIGATION.md](M1_NAVIGATION.md).
