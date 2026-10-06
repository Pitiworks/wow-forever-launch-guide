# Zielarchitektur

Dieses Dokument beschreibt das Zielbild, keine vorgezogene technische Umsetzung oder Bridge-Entscheidung.

```text
WoW Forever Addon
        ↓
Live State / Bridge
        ↓
lokaler Guide / Optimizer
        ↓
HTML Dashboard

Optimizer / Questdaten
        ↓
Next Target
        ↓
WoW Addon Navigation
```

## Verantwortungen

### WoW Forever Addon

Bleibt klein. Es ist für Ingame-Navigation zuständig und beobachtet Daten, die der Client in M0 als zuverlässig bestätigt. Es zeigt später Richtung, Entfernung und relevante Hinweise im Spiel an.

### Live State / Bridge

Überträgt den beobachteten Zustand zwischen Addon und lokaler Komponente. Ihre technische Form wird ausdrücklich erst nach M0 festgelegt; SavedVariables sind keine vorab angenommene Live-Lösung.

### Lokaler Guide / Optimizer

Verwaltet den Zustand pro Charakter, verbindet Questdaten mit beobachteten Spielsignalen und bewertet mögliche nächste Schritte inklusive Crowd-bedingter Alternativen.

### HTML Dashboard

Zeigt auf dem zweiten Monitor den aktuellen Schritt, Folgeschritte, Questfortschritt, Alternativen und Crowd-Signale an.

### Optimizer / Questdaten

Nutzen vorrangig zu prüfende QuestieDB-Forever-Daten für Quests, NPCs und Koordinaten. Sie berechnen daraus ein nächstes Ziel unter Berücksichtigung von Voraussetzungen, Folgequests, Questitems und Crowd-Risiken.
