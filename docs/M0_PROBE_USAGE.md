# M0 Probe Usage

## Installation

Kopiere den Ordner `addon/WoWForeverLaunchProbe` nach:

```text
<WoW Forever Beta>/Interface/AddOns/WoWForeverLaunchProbe/
```

Die Datei `WoWForeverLaunchProbe.toc` verwendet die aus den Forever-Projekten verifizierte Interface-Version `16001`.

Optionale Test-Addons werden **nicht** vom Probe eingebunden oder kopiert:

- QuestieDB Forever für Issue #10
- Shortest Path Forever für Issue #11

Das Probe funktioniert auch ohne diese Addons und zeigt deren Abwesenheit an.

## Slash Commands

| Command | Wirkung |
| --- | --- |
| `/wflp` | Diagnosefenster öffnen oder schließen |
| `/wflp dump` | Kompakten aktuellen Snapshot in den Chat schreiben |
| `/wflp questie` | QuestieDB-Kompatibilitätsprobe erneut ausführen |
| `/wflp path` | Shortest-Path-Kompatibilitätsprobe erneut ausführen |
| `/wflp events` | Die letzten bis zu zehn Event-History-Einträge in den Chat schreiben |
| `/wflp reset` | Nur temporäre Event- und Beobachtungswerte zurücksetzen |

`Navigate` und `NavigateRoute` werden niemals automatisch und auch nicht per Slash-Command ausgelöst.

## Testablauf für M0 Issues #1–#11

1. Einloggen, `/wflp` öffnen und Character, Location sowie Event-History für #1 und #2 notieren.
2. Questgeber und Questmob nacheinander targeten und per Mouseover prüfen; Target-/Mouseover-Name, GUID und NPC-ID für #4 notieren.
3. Eine Quest annehmen. Quest-ID, Name, Level, Objectives und Fortschritt für #3 erfassen.
4. Einen Questmob töten und nach jedem Update Objective-Fortschritt, letztes Event und Zeitpunkt für #5 notieren.
5. Ein Questitem looten und dieselben Werte für #6 notieren.
6. Quest abschließen und abgeben; beobachteten Completion-/Turn-in-Wert und Events für #7 notieren.
7. Zone wechseln und die Event-History für #2 und #8 erfassen.
8. Mit QuestieDB Forever `/wflp questie` ausführen: Presence, Flavor, Contract, Laufzeit, aktive Questfelder und Verhalten direkt nach Login bzw. nach `/reload` für #10 notieren. Danach ohne QuestieDB wiederholen.
9. Mit Shortest Path Forever `/wflp path` ausführen: API-Verfügbarkeit, Version, Funktionsverfügbarkeit, Estimate/CurrentStop/Ended und Reload-/Combat-Verhalten für #11 notieren. Danach ohne Shortest Path Forever wiederholen.
10. Für #9 die vollständige Sequenz wiederholen und für jeden Schritt Client-/Interface-Version, API/Funktion, Event, Erwartung, tatsächlichen Wert, Zuverlässigkeit und Bemerkungen festhalten.

## Pro Messung notieren

- Client- und Interface-Version
- Charakter und Realm
- Zeitpunkt und reproduzierbarer Testschritt
- API/Funktion und ausgelöstes Event
- erwarteter und tatsächlicher Wert
- Zuverlässigkeit / Wiederholbarkeit
- aktive optionale Addons und deren Abwesenheit oder Version
- Fehler oder `unavailable`-Werte

## Persistenz und Grenzen

Die Event-History verbleibt nur im Speicher und ist auf 100 relevante Events begrenzt. Die per-Character SavedVariable speichert nur Reload-Zähler, letzten Login-Zeitpunkt und die letzte Präsenz der optionalen Addons; sie speichert keine QuestieDB-Daten, Telemetrie oder Produktzustände.
