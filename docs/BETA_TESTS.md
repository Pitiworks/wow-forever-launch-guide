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
