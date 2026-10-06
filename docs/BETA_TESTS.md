# M0 Beta Probe – Testplan

## Testsequenz

1. Charakter einloggen
2. Charakter und Realm erkennen
3. Level und XP erkennen
4. Zone und Subzone erkennen
5. Spielerkoordinaten erkennen
6. Questgeber per Target prüfen
7. Questgeber per Mouseover prüfen
8. Quest annehmen
9. Quest-ID und Name erkennen
10. Objectives auslesen
11. Relevanten Mob targeten
12. Relevanten Mob per Mouseover prüfen
13. Einen Questmob töten
14. Prüfen, ob das Objective sofort aktualisiert
15. Questitem looten
16. Prüfen, ob das Objective aktualisiert
17. Quest fertigstellen
18. Quest abgeben
19. Zone wechseln
20. Relevante Events protokollieren

## QuestieDB Forever compatibility probe

Diese Probe prüft ausschließlich eine vorhandene Installation über deren öffentliche Schnittstelle. Sie baut keine Produktintegration ein, kopiert keine Daten und trifft keine endgültige Dependency-Entscheidung.

1. Prüfen, ob `LibQuestieDB` vorhanden ist.
2. Erkannten Flavor und Forever-Kompatibilität dokumentieren.
3. Öffentlichen Contract/API-Aufruf prüfen.
4. Benötigte Quest-Felder lesen: Name, Objectives, Prerequisites, Quest Chains sowie Start-/End-NPCs.
5. NPC-, Objekt- und Item-Koordinaten prüfen.
6. Item-Drops prüfen.
7. Ladezeit und Verfügbarkeit direkt nach Login erfassen.
8. Verhalten nach `/reload` erfassen.
9. Verhalten mit fehlendem/deaktiviertem QuestieDB erfassen.

## Shortest Path Forever compatibility probe

Diese Probe verwendet ausschließlich die dokumentierte öffentliche API. Sie baut keine Produktintegration ein und verwendet keine internen oder privaten APIs.

1. Prüfen, ob Addon und öffentliche API vorhanden sind.
2. `Navigate` mit einem sicheren Testziel prüfen.
3. `NavigateRoute` mit einer kurzen Teststrecke prüfen.
4. `Estimate` prüfen.
5. `CurrentStop` prüfen.
6. `Ended` nach Abschluss oder Abbruch prüfen.
7. Verhalten bei fehlender/deaktivierter Dependency erfassen.
8. Verhalten nach `/reload` erfassen.
9. Verhalten im Combat prüfen, soweit die API dafür relevant ist.

## Pro Test erfassen

| Feld | Zu dokumentieren |
| --- | --- |
| Client-/Interface-Version | Exakte getestete Version |
| API/Funktion | Verwendeter Zugriff oder beobachtete Funktion |
| Event | Auslösendes Client-Event, falls vorhanden |
| Erwarteter Wert | Erwartetes Ergebnis vor der Messung |
| Tatsächlicher Wert | Tatsächlich beobachtetes Ergebnis |
| Zuverlässig | Ja/nein, einschließlich Wiederholbarkeit |
| Bemerkung | Einschränkungen, Timing und offene Fragen |

## Ergebnisregel

Ein Messpunkt gilt erst als Grundlage für Architekturentscheidungen, wenn sein Verhalten und seine Zuverlässigkeit nachvollziehbar dokumentiert sind.

Die beiden Dependency-Proben gelten erst dann als erfolgreich, wenn die öffentliche Schnittstelle, fehlende Dependency sowie Login-/Reload-Verhalten dokumentiert sind. Sie ersetzen keine Client-State-Proben und legen keine Produkt-Dependency fest.
