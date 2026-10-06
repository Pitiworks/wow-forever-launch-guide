# Reuse Audit

Audit-Stichtag: 06.10.2026. Dieser Bericht basiert ausschließlich auf den öffentlichen Upstream-Quellen an den unten genannten Commits. **`unknown` bedeutet: nicht aus einer geprüften Quelle ableitbar; keine Annahme.** Es wurden weder Fremdcode kopiert noch Dependencies eingebunden.

## Executive Summary

Die sinnvollste Wiederverwendung ist **nicht** das Kopieren von Addon-Code:

- **QuestieDB Forever** ist der stärkste Kandidat als installierte, zur Laufzeit abgefragte Quest-, NPC-, Objekt- und Item-Datenquelle. Seine öffentliche, dokumentierte Contract-API deckt Questreihen, Voraussetzungen, Start-/Endgeber, Spawn- und Item-Drop-Beziehungen ab.
- **Shortest Path Forever (SPF)** ist der stärkste Kandidat für Ingame-Navigation als optionale Addon-Dependency. Es bietet eine eigene, kleine Public API für Einzelziele, Multi-Stop-Journeys und Reisezeit-Schätzungen.
- **Adventure Guide Forever (AGF)** ist eine hochwertige Referenz für State-Snapshot, Routenrebuild, per-character Speicherung und die Integration beider Kandidaten. Wegen GPL-3.0 soll sein Code nicht direkt in ein anders lizenziertes Projekt übernommen werden.
- **Questie Forever** enthält eine reife Questlog-/Event-/Tooltip-Implementierung. Da zum geprüften Commit keine erkennbare Repository-Lizenz vorlag, ist direkte Codeübernahme **not suitable**; die darin verwendeten Blizzard-APIs bleiben hingegen als zu messende M0-Kandidaten relevant.

Der Audit macht M0 nicht überflüssig: Er reduziert M0 von „alles selbst bauen“ auf eine **Kompatibilitäts- und Contract-Probe**. Insbesondere müssen Forever-Client-Verhalten, QuestieDB-Ladezustand und SPF-API im tatsächlichen Zielclient gemessen werden.

## Candidate Projects

| Projekt | Geprüfter Stand | Lizenz | Forever-Kompatibilität und Pflegezustand |
| --- | --- | --- | --- |
| [Adventure Guide Forever](https://github.com/cjber/adventure-guide-forever) | `947fcab` (2026-10-05), „Prepare v0.9.0 release“ | GPL-3.0-or-later: `LICENSE`; TOC `X-License: GPL-3.0-or-later` | `AdventureGuideForever.toc` setzt `Interface: 16001`, speichert `AdventureGuideForeverCharDB` pro Charakter und führt SPF, Questie und QuestieDB als OptionalDeps. Aktiv gepflegt. |
| [Questie Forever](https://github.com/tysongoulding/Questie-Forever) | `46c8dc7` (2026-10-02), „chore(sync): merge upstream forever-303-patch fixes“ | `unknown`: GitHub-License-Metadaten und geprüfter Dateibaum liefern keine Repository-Lizenz. | Aktiver Forever-Fork nach Commit-Text; die Root-`Questie.toc` ist bewusst nur ein Fallback für nicht unterstützte Clients (`Interface: 00000`). Die flavor-spezifische Forever-TOC wurde in diesem Audit nicht verifiziert: genaue Interface-Version `unknown`. |
| [QuestieDB](https://github.com/Questie/QuestieDB) | `e0a6eaa` (2026-10-05), „Bumb QuestieDB version to v1.0.5“ | `unknown`: GitHub-License-Metadaten und geprüfter Dateibaum liefern keine Repository-Lizenz. | `QuestieDB.toc` enthält `Interface: ... 16001`; `src/flavors/Forever.lua` wählt Flavor `Forever`; die TOC lädt eigene `data/Forever/*`- und `support/Forever/*`-Daten. Aktiv gepflegt. |
| [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) | `e748ff4` (2026-10-05), „Prepare v1.10.0 release“ | GPL-3.0-or-later: `LICENSE`. | `ShortestPathForever.toc` und Public API sind Forever-spezifisch; AGF führt es als OptionalDep. Aktiv gepflegt. |

### Lizenzfolgen

GPL-3.0 erlaubt das Kopieren, Ändern und Verteilen von Code, verlangt bei Weitergabe eines abgeleiteten Gesamtwerks aber GPL-3.0, Quellenbereitstellung, Lizenz-/Copyright-Hinweise und Änderungsmarkierungen. Deshalb: AGF- und SPF-Code **nicht kopieren**; als getrennte optionale Addon-Dependency kann er später erst nach einer gesonderten Lizenz-/Packaging-Prüfung verwendet werden. Bei Questie Forever und QuestieDB ist direkte Wiederverwendung bis zu einer geklärten Lizenz **not suitable**. API-Aufrufe gegen separat installierte Addons sind keine Codeübernahme; die genaue Vertriebs- und Kopplungsbewertung bleibt vor Release offen.

## Existing Solutions We Should Reuse

### QuestieDB Forever: strukturierte Questdaten als Runtime-Datenquelle

**Empfehlung: call as dependency, nicht Daten kopieren.**

`QuestieDB.toc` wählt für Forever die vier Datenquellen `data/Forever/foreverQuestDB.lua`, `foreverNpcDB.lua`, `foreverItemDB.lua`, `foreverObjectDB.lua` sowie Forever-spezifische Zone-, Faction-, Drop- und XP-Unterstützung. Damit unterscheidet sich Forever bewusst von Classic: Es ist kein bloßes Classic-Dataset mit unveränderten Koordinaten, sondern hat eigenständige Inputs und „coordinate-adjusted inputs“ (siehe `README.md`, Abschnitt „Era-to-Forever coordinate conversion“).

Öffentliche Schnittstelle: `src/api.lua — LibQuestieDB.RequireContract(required)`, `InvalidateCache`, `GetProvenance`. Die Entity-Reader bieten laut `src/types/*.t.lua` jeweils `Get`, `GetAll`, `GetAllIds`, `GetRaw`, `Exists`, `IdsByName` und Cache-/Index-Operationen.

| Datenart | Belegte Felder / API | Quelle |
| --- | --- | --- |
| Quest | `name`, `startedBy`, `finishedBy`, `objectivesText`, `objectives`, `triggerEnd`, `preQuestGroup`, `preQuestSingle`, `childQuests`, `exclusiveTo`, `nextQuestInChain`, `breadcrumbForQuestId`, `availableStartingWith`, `availableUntilCompleted` | `src/types/Quest.t.lua — QuestDB`; Feldzuordnung: `src/meta/questMeta.lua` |
| NPC | `name`, `spawns`, `waypoints`, `zoneID`, `questStarts`, `questEnds`, `friendlyToFaction`, `npcFlags` | `src/types/Npc.t.lua — NpcDB`; `src/meta/npcMeta.lua` |
| Objekt | `name`, `questStarts`, `questEnds`, `spawns`, `zoneID`, `waypoints` | `src/types/Object.t.lua — ObjectDB`; `src/meta/objectMeta.lua` |
| Item | `npcDrops`, `objectDrops`, `itemDrops`, `startQuest`, `questRewards`, `vendors`, `relatedQuests` | `src/types/Item.t.lua — ItemDB`; `src/meta/itemMeta.lua` |

### Shortest Path Forever: Navigation als optionale Dependency

**Empfehlung: call as dependency.** Nicht den Pathfinder, die Kartenpins oder den Arrow kopieren.

Die Public API liegt in `Core/API.lua — ShortestPathForever.API`:

- `Estimate(fromMap, fromX, fromY, toMap, toX, toY)` und `EstimateDetail(...)` für Kosten-/Reisezeit-Schätzungen;
- `Navigate(owner, map, x, y, title, kind)` für ein Ziel;
- `NavigateRoute(owner, stops)` für 1–64 Stops;
- `CurrentStop(owner)`, `Cancel(owner)`, `Ended(owner)`, `Active()` für Kontrolle des eigenen Journeys.

Die tatsächliche Routing-/Navigationseinheit ist vorhanden: `Routing/Path.lua — Path.FindSync`, `Path.FindManySync`; `Routing/Planner.lua — Planner.QuestDestination`, `Planner.WalkPoints`; `Journey/Journey.lua — ns.JourneyPosition`, `ns.StartJourney`; `UI/Arrow.lua — Bearing`, `Update`, `ns.PointGuideArrow`. Richtungs- und Restdistanzanzeige sind damit vorhanden. Die UI zeichnet Karten-/Transportpins in `UI/Map.lua — ns.RefreshMap` und die eigene Pfeil-UI in `UI/Arrow.lua`; für unser eigenes Addon nur nutzen, nicht nachbauen.

### Adventure Guide Forever: referenzierbares Integrationsmuster

AGF ist keine zu kopierende Bibliothek, aber seine Architektur beantwortet mehrere Designfragen direkt:

- **State-Snapshot:** `Core/State.lua — State.Player`, `State.Where`, `State.Log`, `State.Completed`.
- **Questlog:** `State.Log` iteriert `C_QuestLog.GetNumQuestLogEntries`, liest `C_QuestLog.GetInfo`, `C_QuestLog.GetNextWaypoint`, `C_QuestLog.IsComplete`; `Objectives` liest `C_QuestLog.GetQuestObjectives` inklusive `type`, `text`, `finished`, `numFulfilled`, `numRequired`.
- **Events:** `Core/State.lua — events:SetScript("OnEvent", ...)` registriert `PLAYER_ENTERING_WORLD`, `QUEST_LOG_UPDATE`, `QUEST_TURNED_IN`, `PLAYER_LEVEL_UP`, `ZONE_CHANGED_NEW_AREA`, `SKILL_LINES_CHANGED`, `UPDATE_FACTION`; optional per `pcall`: `PLAYER_UPDATE_RESTING`, `UPDATE_EXHAUSTION`, `PLAYER_XP_UPDATE`, `QUEST_POI_UPDATE`, `QUEST_WATCH_UPDATE`. `Coalesce` bündelt QUEST_LOG_UPDATE pro Frame.
- **Per-character und Reload:** `AdventureGuideForever.toc` deklariert `SavedVariablesPerCharacter: AdventureGuideForeverCharDB`; `Core/Guidance.lua — ns.Guidance.Restore` beschreibt Wiederherstellung nach Login/Reload, ohne vor dem QuestieDB-Ready-Zustand die Auswahl zu verlieren.
- **„Do this next“ / Reihenfolge:** `Core/API.lua — API.CurrentStop`, `API.NextStops`; `Planning/Steps.lua`, `Planning/Order.lua`, `Planning/Routing.lua` erzeugen/gewinnen Schritte; die konkrete Reihenfolge ist keine allgemein dokumentierte Public API und daher für externe Nutzung **unknown**.
- **QuestieDB/Questie:** `Integrations/QuestieSource.lua — Fit`, `MissingField` prüft Contract, `X-Flavor == "Forever"` und benötigte Felder. `Integrations/QuestieObjectives.lua — ns.QuestieObjectives` löst NPC-/Objekt-/Item-Drops in Spawnflächen auf. `Core/State.lua — PolicyModule`, `Available`, `QuestUpdateChanged` nutzt, wenn verfügbar, Questies `QuestieLoader.ImportModule("QuestieDB")` und `IsDoable`.
- **SPF:** `Core/Guidance.lua — Navigate`, `StartRoute`, `Restore` übergibt Multi-Stop-Strecken oder fällt auf einen nativen Waypoint zurück; die gespiegelt verwendete SPF-Schnittstelle ist in `types/Namespace.lua — AGFSPFAPI` dokumentiert.

## Existing Solutions We Should NOT Reimplement

1. **Quest-, NPC-, Objekt- und Item-Katalog samt Relationship-Graph:** QuestieDB Forever liefert Start-/Endgeber, Prerequisites, Ketten, Spawns und Drops. Eigene manuelle Duplikation würde genau die in `AGENTS.md` untersagte Drift erzeugen.
2. **Multimodales Ingame-Pathfinding:** SPF hat Wege, Flugrouten, Boote, Zeppeline, Lifte, Tram und Portale sowie Replanning. Keine eigene Nachimplementierung in M1.
3. **Questlog-Cache und Event-Debouncing als ungetestete Kopie:** Questie Forever (`Modules/Quest/QuestLogCache.lua — CheckForChanges`, `GetQuestObjectives`; `Modules/EventHandler/QuestEventHandler.lua — QuestLogUpdate`, `QuestAccepted`, `QuestTurnedIn`) hat dafür Lösungen, aber Lizenz und konkretes Forever-Interface müssen geklärt werden. Wir sollen das Muster messen/klein nachbauen, nicht den Code kopieren.
4. **Questie-Karten-/Nameplate-Renderer:** Questie Forever verfügt über Map- und Nameplate-Systeme (`Modules/Map/QuestieMap.lua — ShowNPC`, `ShowObject`, `DrawWaypoints`; `Modules/QuestieNameplate.lua — NameplateCreated`, `DrawTargetFrame`). Eine parallele vollständige Darstellung wäre Doppelarbeit und nicht M0/M1-Umfang.

## Missing Pieces

- Ein crowd-aware Optimizer mit `AREA_CROWDED` und `QUEST_BLOCKED`: in keinem geprüften Projekt als unser Produktziel gefunden.
- Ein charaktergetrennter externer lokaler State/Guide/Dashboard-Teil: AGF speichert zwar pro Charakter im Addon, aber kein externes Web-Dashboard oder eine festgelegte Live-Bridge.
- Verlässliche Live-Übertragungsart zwischen Addon und lokalem Prozess: weiterhin **unknown**, M0 entscheidet sie nicht vorweg.
- Ein gesicherter Vertrag für Target-/Mouseover-NPC-ID im konkreten Forever-Client: Questie Forever nutzt `UnitGUID("target")` (`Modules/QuestieNameplate.lua — DrawTargetFrame`) und Tooltip-Fallback `UnitGUID("mouseover")` (`Modules/Tooltips/TooltipHandler.lua — AddUnitDataToTooltip`), aber eine Forever-Client-Probe ist weiterhin nötig.
- Character name, Realm und aktuelles XP sind in den geprüften AGF- und SPF-Quellen nicht als benötigte Reuse-API gefunden: **unknown** als wiederverwendbare Quelle. Questie Forever liest in `Database/QuestieDB.lua` `GetRealmName()`; eine vollständige identity-/XP-Quelle für unser Produktziel ist damit nicht belegt.

## Recommended Architecture After Audit

Das Zielbild bleibt gültig, mit folgenden **Vorschlägen, nicht beschlossenen Entscheidungen**:

```text
kleines eigenes Forever-Addon
  ├─ Blizzard-Quest-/Player-Snapshot (nur getestete M0-APIs)
  ├─ optionale Laufzeitabfrage: LibQuestieDB (Contract + Flavor prüfen)
  └─ optionale Navigation: ShortestPathForever.API
                 ↓
        Bridge: erst nach M0 festlegen
                 ↓
charaktergetrennter lokaler Optimizer + HTML-Dashboard
  ├─ eigener Crowd-/Blockierungszustand
  └─ Route über QuestieDB-Beziehungen, nicht über kopierte Tabellen
```

AGF zeigt, dass ein Snapshot mit `C_QuestLog.GetQuestObjectives`, Waypoints, Completed IDs und koaleszierten Quest-Events tragfähig sein kann. Unser Addon soll jedoch nur seine minimale Mess- und Integrationsschicht besitzen; der Optimizer und die Crowd-Entscheidung verbleiben außerhalb von WoW.

## Recommended Dependencies

| Dependency | Empfehlung | Bedingung |
| --- | --- | --- |
| QuestieDB Forever | **call as dependency** | Zur Laufzeit `LibQuestieDB.RequireContract(...)`, `X-Flavor == "Forever"` und benötigte Felder prüfen; Lizenz/Distribution vor Release klären. |
| Shortest Path Forever | **call as dependency** | OptionalDep und ausschließlich dessen Public API verwenden; GPL-/Packaging-Auswirkung vor Release klären. Fallback auf einen nativen Waypoint bleibt nötig. |
| Questie Forever | **unknown / optional integration only** | Keine Codeübernahme. Erst Contract, Lizenz, stabile API und konkrete Forever-TOC prüfen. |
| Adventure Guide Forever | **not suitable als Dependency** | Referenzarchitektur; keine direkte Abhängigkeit für unser Produktziel. |

## License Considerations

- **AGF und SPF:** GPL-3.0-or-later. Direkte Übernahme, modifizierte Kopie oder eng abgeleitetes Addon zieht bei Distribution GPL-3.0-Pflichten nach sich. Deshalb keine Quellcode-Kopie in dieses Repository.
- **Questie Forever und QuestieDB:** In der geprüften Revision fehlt eine erkennbare Lizenzmetadatei. Bis der Rechteinhaber eine Lizenz bestätigt, keine Code- oder Datenkopie. Eine installierte Runtime-Dependency ist erst nach eigener Packaging-/Lizenzprüfung zu entscheiden.
- **Blizzard APIs:** Die Nennung von API-Namen ist keine Codeübernahme; ihre tatsächliche Verfügbarkeit und Semantik wird in M0 gemessen.

## M0 Impact

M0 bleibt erforderlich, aber der Umfang kann nach diesem Audit **vorgeschlagen** angepasst werden:

1. Bestehende Character-/Realm-, Level/XP-, Questlog-, Objective-, Completed-, Target-/Mouseover- und Event-Proben beibehalten.
2. Ergänze eine **QuestieDB-Contract-Probe**: Addon geladen, `X-Flavor`, `RequireContract`, `Quest/Npc/Object/Item.GetAllIds`, die für die Route benötigten `GetAll`-Felder, sowie Ladezeit/Reload-Verhalten erfassen.
3. Ergänze eine **SPF-Public-API-Probe**: `Navigate`, `NavigateRoute`, `Estimate`, `CurrentStop`, `Ended`; kein SPF-Source-Code kopieren.
4. Behalte den eigenen minimalen Snapshot bei. AGF belegt die APIs, ersetzt aber nicht die Messung auf unserem exakten Client.

Diese Änderung ist nur eine Empfehlung. `docs/MILESTONES.md`, `docs/BETA_TESTS.md` und GitHub-Issues wurden **nicht** geändert.

## M1 Impact

M1 sollte nicht mit einem eigenen Arrow-/Pathfinder beginnen. Zuerst SPF als optionale Navigation evaluieren und bei Nichtverfügbarkeit nur den nativen Waypoint nutzen. Eigene M1-Arbeit bleibt: semantisches nächstes Ziel, SPF-Stop-Übersetzung, sicherer Fallback und später die UI-/Dashboard-Anzeige.

## Open Questions For Beta Testing

- Ist `C_QuestLog.GetQuestObjectives` im Forever-Client nach Kill und Item-Loot sofort bzw. zuverlässig aktualisiert?
- Welche Events feuern tatsächlich und in welcher Reihenfolge für Pickup, Kill, Loot, Complete und Turn-in?
- Liefert `UnitGUID("target")` und der Tooltip-/`mouseover`-Pfad auf Forever stabil die Creature-ID, auch für Questgeber und Phasing?
- Welche Client-TOC und welcher `X-Flavor` gelten in der installierten QuestieDB-Forever-Version?
- Welche Contract-Version akzeptiert die installierte QuestieDB, und stehen die benötigten `startedBy`, `finishedBy`, `objectives`, `spawns` und Drop-Felder bereit?
- Funktioniert SPF `NavigateRoute` außerhalb von Combat, über Reload/Login und bei einem bereits aktiven Journey wie dokumentiert?
- Ist die optionale Addon-Kopplung mit QuestieDB/SPF lizenz- und distributionstechnisch für das gewünschte Release-Modell zulässig?

## Decision Matrix

Legende: **reuse directly**, **call as dependency**, **adapt**, **not suitable**, **unknown**.

| Funktion | Adventure Guide | Questie | QuestieDB | Shortest Path | selbst bauen |
| --- | --- | --- | --- | --- | --- |
| Charakter/Realm | unknown | adapt (`GetRealmName` belegt, vollständige Identity nicht) | not suitable | not suitable | adapt, nach M0 |
| Level/XP | adapt (`State.Player` nutzt `UnitLevel`; XP nur Rest-/Max-XP) | adapt (`QuestiePlayer.GetPlayerLevel`) | not suitable | not suitable | adapt, nach M0 |
| Aktive Quests, IDs, Namen | adapt (`State.Log`) | adapt (`QuestLogCache.CheckForChanges`) | not suitable | not suitable | adapt, minimal |
| Objectives/Fortschritt | adapt (`Objectives`) | adapt (`QuestLogCache.GetQuestObjectives`) | not suitable als Live-State | not suitable | adapt, minimal |
| Completed quests | adapt (`State.Completed`) | adapt (`QuestieDB.IsComplete` im Addon) | not suitable als Live-State | not suitable | adapt, nach M0 |
| Pickup/Turn-in/Events | adapt (`Core/State.lua` Event-Frame) | adapt (`QuestEventHandler.QuestAccepted/QuestTurnedIn`) | not suitable | not suitable | adapt, minimal |
| Questgraph, Prerequisites, Chains | not suitable | unknown | call as dependency | not suitable | not suitable |
| NPC/Object/Item Spawns und Drops | adapt (`QuestieObjectives`) | adapt (interne DB) | call as dependency | not suitable | not suitable |
| Spieler-/Kartenkoordinaten | adapt (`State.Where`) | adapt (`QuestieCoords.GetPlayerMapPosition`) | not suitable | adapt (`JourneyPosition`) | adapt, minimal |
| Questziel-/POI-Koordinaten | adapt (`LoadPoints`) | adapt (`QuestieMap`) | call as dependency für Spawns | adapt (`Planner.QuestDestination`) | adapt, nur Übersetzung |
| Pfeil, Distanz, Wegpunkte | not suitable | not suitable | not suitable | call as dependency | not suitable |
| Kartenmarker, Questgeber-/Mobmarker | adapt (Pins) | adapt (Map/Nameplates) | call as dependency für Daten | adapt (Transportpins) | unknown; nur falls UX es verlangt |
| Target-/Mouseover-NPC-ID | unknown | adapt (`QuestieNameplate`, `TooltipHandler`) | not suitable | not suitable | adapt, nach M0 |
| „Do this next“ / Schrittordnung | adapt (`API.CurrentStop`, `NextStops`) | not suitable | call as dependency für Graph | call as dependency für Kosten | **selbst bauen**: Crowd-Optimierung |
| Zustand pro Charakter / Reload | adapt (TOC + `Guidance.Restore`) | unknown | not suitable | adapt (Journey nur Session) | **selbst bauen**: eigener Produktzustand |
| Crowd-Signale und Rerouting | not suitable | not suitable | not suitable | adapt für Travel-Kosten | **selbst bauen** |
