# Quest Routing – Grundlogik

Dieses Dokument hält die Bewertungsdimensionen fest, ohne bereits eine finale Formel festzulegen.

Die konkrete Grundroute, Questprioritäten, Quellen-/Kommentarbewertung und erste Wechselregeln stehen in [LAUNCH_ROUTE.md](LAUNCH_ROUTE.md). v0.1 gilt für einen Untoten-Start; sie ist redaktionell festgelegt, aber noch nicht als vollständiger 1–20-Guide validiert oder im Addon implementiert.

## Normale Questbewertung

- XP
- Laufzeit
- Killzeit
- Dropchance
- Benötigte Mobs
- Questitem
- Voraussetzungen
- Folgequests

## Zusätzliche Launch-Bewertung

- Named Mob
- Kleiner Spawn-Bereich
- Lange Respawns
- Viele benötigte Mobs
- Sammelobjekte
- Escort
- Konkurrenzwahrscheinlichkeit

## Crowd-Modi

| Modus | Bedeutung |
| --- | --- |
| `NORMAL` | Keine erkannte besondere Engpasslage |
| `AREA_CROWDED` | Gebiet ist überfüllt; Alternativen sollen bewertbar sein |
| `QUEST_BLOCKED` | Aktuelle Quest ist praktisch blockiert; eine alternative Route soll priorisiert werden |

Die spätere Optimierung kombiniert reguläre Questkosten, Abhängigkeiten und Launch-Risiken. Eine finale Scoring- oder Routing-Formel wird erst nach M0-Messungen und mit realen Daten festgelegt.
