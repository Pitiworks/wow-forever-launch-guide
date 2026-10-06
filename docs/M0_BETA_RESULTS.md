# M0 Beta Results

## Scope and evidence

This document records the first real Forever Beta run of `WoW Forever Launch Probe`. The evidence is a per-character SavedVariables export supplied after a `/reload`; it is local test evidence and is deliberately not committed to this repository.

- Character observed in the diagnostic window: `Semli`
- Realm observed in the diagnostic window: `Classic Beta PvE`
- Persisted run: `14:52:49` to `15:41:56`
- Persisted entries after the operator cleared the log: `459`
- Reload counter after the run: `2`

The activity log is a reproducible event trail, not a copy of QuestieDB data and not a product telemetry channel.

## Confirmed Blizzard-state behavior

| M0 concern | Result | Evidence |
| --- | --- | --- |
| Character, realm, level and XP | confirmed in the live diagnostic window | the run recorded XP updates; a level transition from level 9 to 10 resulted in `510/7600` XP |
| Location / map position | confirmed in the live diagnostic window and event log | nine `ZONE_CHANGED` events with Tirisfal, map `1420`, and X/Y values |
| Active quest updates | confirmed | 46 `QUEST_LOG_UPDATE` and eight `QUEST_WATCH_UPDATE` events |
| Objective progress event | confirmed | quest `86784` emitted `QUEST_WATCH_UPDATE` repeatedly before its turn-in |
| Quest acceptance | confirmed | seven `QUEST_ACCEPTED` events, including quest IDs `426`, `99142`, `91282`, `359`, `405`, `96895`, and `375` |
| Quest turn-in | confirmed | six `QUEST_TURNED_IN` events: `86784`, `404`, `5482`, `398`, `99134`, and `358` |
| Target / mouseover GUID and NPC ID | confirmed | 38 target changes and 328 mouseover changes; creature GUIDs yielded NPC IDs while player and pet GUIDs correctly yielded `unavailable` |
| Reload persistence | confirmed | per-character database reload counter reached `2`; event history and activity log are separate by design |

## Representative unit observations

The following identifiers were extracted from live `Creature-...` GUIDs during the run. They prove the observed GUID-to-NPC-ID path without requiring Questie or QuestieDB.

| Unit | NPC ID |
| --- | ---: |
| Altersschwacher Schattenhund | 1547 |
| Großer Nachtsauger | 1553 |
| Eleanor Shackleton | 265812 |
| Todeswache Dillinger | 1496 |
| Todeswache Bartholomew | 1742 |
| Ratslin Maime | 6785 |
| Coleman Farthing | 1500 |
| Yvette Farthing | 1560 |

Player and pet GUIDs were not misrepresented as NPCs; their NPC-ID result was `unavailable`, as intended.

## Event distribution

| Event | Count |
| --- | ---: |
| `UPDATE_MOUSEOVER_UNIT` | 328 |
| `QUEST_LOG_UPDATE` | 46 |
| `PLAYER_TARGET_CHANGED` | 38 |
| `ZONE_CHANGED` | 9 |
| `QUEST_WATCH_UPDATE` | 8 |
| `QUEST_ACCEPTED` | 7 |
| `PLAYER_XP_UPDATE` | 7 |
| `QUEST_TURNED_IN` | 6 |
| `QUEST_REMOVED` | 6 |
| `PLAYER_LEVEL_UP` | 1 |

## Remaining M0 work

The normal Blizzard-state core is now evidenced well enough to continue collecting data passively during ordinary play. The QuestieDB and Shortest Path **present** cases are documented below; the missing-QuestieDB case was already observed as `LibQuestieDB unavailable`. The only remaining passive evidence is the corrected Combat-path record and the exact client/build version. No `Navigate` or `NavigateRoute` call may be made automatically.

No bridge, route optimizer, navigation user interface, or production guide decision follows from this evidence. Those remain gated by the documented M0 completion criteria.

## Dependency run: QuestieDB and Shortest Path Forever

A later normal play session loaded both optional addons and persisted their automatic probe results. No navigation call was made by the probe.

| Dependency / check | Observed result |
| --- | --- |
| QuestieDB loaded | `present=true`, `addonLoaded=true` |
| QuestieDB public contract | required contract was accepted; installed contract version was `3` |
| QuestieDB active quest data | records for active quests `374` and `95314` were available; the no-active-quest case was handled without failure |
| QuestieDB flavor metadata | `unavailable` from the installed addon's metadata; Forever compatibility must therefore be inferred from the successful contract/data run, not metadata alone |
| Shortest Path loaded | `present=true`, `addonLoaded=true`, public API version `1` |
| Shortest Path public members | `Navigate`, `NavigateRoute`, `Estimate`, `CurrentStop`, and `Ended` were present |
| Shortest Path estimate | same-point estimate returned `0`; no navigation was started |
| Reload behavior | automatic probe entries were recorded after reload/login |

The session produced 13 QuestieDB probe entries and 83 Shortest Path probe entries. It also produced 70 `PLAYER_REGEN_DISABLED` events. In the already captured build, the immediate Shortest Path sample after that event reported `combat=not in combat`; therefore that value is **not** accepted as a valid Combat result. The probe now carries the combat-event context directly so later ordinary play will log the correct safe “in combat” path without a manual command. This remaining observation can be collected passively and does not require a dedicated gameplay session.
