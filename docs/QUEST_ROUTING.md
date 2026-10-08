# Quest Routing – Grundlogik

Dieses Dokument hält die Bewertungsdimensionen fest, ohne bereits eine finale Formel festzulegen.

Die konkrete Grundroute, Questprioritäten, Quellen-/Kommentarbewertung und erste Wechselregeln stehen in [LAUNCH_ROUTE.md](LAUNCH_ROUTE.md). v0.1 gilt für einen Untoten-Start; sie ist redaktionell festgelegt, aber noch nicht als vollständiger 1–20-Guide validiert oder im Addon implementiert.

## Später Einstieg und Wiederaufnahme

Der Guide muss ohne frühere Aufzeichnungen funktionieren, etwa bei erstmaliger Aktivierung auf Level 11. Er startet nicht pauschal bei Schritt U01 und ordnet auch nicht allein anhand des Levels einen Schritt zu. Die folgenden Anforderungen sind festgelegt, aber noch nicht implementiert.

Beim ersten Start, Login/Reload, Charakterwechsel und Wiederanschließen einer späteren externen Komponente wird der aktuelle Stand abgeglichen:

- Charakter/Realm, Rasse/Klasse, Level/XP und aktuelle Position, soweit verfügbar.
- Aktive Quest-IDs und deren aktuelle Objective-Fortschritte; vollständig erfüllte aktive Quests sind abgabebereit, nicht bereits abgegeben.
- Vom Client nachweisbare abgegebene Quests sowie verifizierte Voraussetzungen der Routenquests. Fehlende lokale Logs bedeuten keine fehlenden Abschlüsse.
- Aktuelle Laufzeitdaten haben Vorrang vor einem alten gespeicherten Routenschritt. Unvollständige Daten während des Ladens dürfen keine neue Route erzwingen.

Schritte unterscheiden mindestens: **aktiv**, **abgabebereit**, **abgegeben**, **verfügbar**, **gesperrt**, **zurückgestellt** und **unknown**. Nicht im Questlog bedeutet weder automatisch verfügbar noch abgegeben. Bei unbekannten Voraussetzungen keinen Folgeauftrag als erreichbar behaupten; nach einem gesicherten Questangebot beziehungsweise vollständigen Daten erneut bewerten. Konkrete APIs und Ladebereitschaft müssen vor Umsetzung im Forever-Client verifiziert werden.

Aus den gültigen Paketen einen Einstieg wählen, der aktive Quests, nahe Abgaben, sichere Gegnerlevel und Reisekosten berücksichtigt. Niedrigstufige Vorgänger nur dann nachholen, wenn sie eine lohnende Kette freischalten; nicht die gesamte Startroute nachspielen lassen. Existiert kein nachweisbar gültiger Ast, den Grund anzeigen statt einen beliebigen Schritt zu erfinden. Aufgeschobene Quests dürfen später wieder relevant werden; Charakterwechsel dürfen keine Zustände vermischen.

**Beispiel Level 11:** Ein Charakter in Brill mit fertigen Nordquests erhält passende Abgaben und anschließend einen freigeschalteten Silverpine-Ast. Ein gleichstufiger Charakter mit offener Plague-Kette oder bereits erledigtem Silverpine-Einstieg kann ein anderes Paket erhalten. Level 11 allein beweist keinen dieser Zustände.

Abnahmefälle für die spätere Implementierung:

1. Erstinstallation auf Level 11 ohne lokale Historie: keine bereits nachweisbar abgegebenen Startquests empfehlen.
2. Teilweise erledigte aktive Quest übernehmen, ohne Fortschritt zurückzusetzen; abgabebereite Quest korrekt behandeln.
3. Fehlender Kettenvorgänger sperrt den Nachfolger, auch wenn das Level ausreicht.
4. Außerhalb des Guides weiterspielen und anschließend neu laden: veralteten Routenschritt korrigieren.
5. Noch nicht geladene Abschlussdaten oder fehlende Dependency: Unsicherheit sichtbar, keine falsche Erledigt-/Verfügbar-Markierung.
6. Zwischen zwei Charakteren wechseln: getrennte Zustände und passender Einstieg je Charakter.

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
