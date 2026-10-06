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

The normal Blizzard-state core is now evidenced well enough to continue collecting data passively during ordinary play. M0 itself is not complete yet:

1. The QuestieDB **present** case still needs one bundled check: public contract, active-quest fields, data availability at login and after reload. The **missing dependency** case has already been observed as `LibQuestieDB unavailable`.
2. The Shortest Path Forever **present** case still needs one bundled public-API check. No `Navigate` or `NavigateRoute` call may be made automatically.
3. The exact client/build and interface version should be captured with the dependency run.

No bridge, route optimizer, navigation user interface, or production guide decision follows from this evidence. Those remain gated by the documented M0 completion criteria.
