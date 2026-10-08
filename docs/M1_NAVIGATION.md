# M1 Navigation Foundation

`WoWForeverLaunchGuide` 0.2.0 is a separate M1 quest assistant. It does not replace the M0 diagnostic probe. It contains no copied quest catalogue, executable full 1–20 route, global optimizer, or bridge.

## Runtime behavior

- A player explicitly saves a next target with `/wflg target <map> <x> <y> [title]`.
- `/wflg next` evaluates mappable active objectives and turn-ins through native POIs/waypoints. It compares SPF travel estimates plus a heuristic 20 seconds per remaining objective unit. At >=50% progress, estimated work receives a 25% finishing bonus. These constants are not measured XP/h or drop-time predictions. If any travel estimate is missing, all candidates use work-only scoring and the UI explicitly labels travel comparison unknown. Ties use quest ID, not quest-log order.
- `/wflg go` alone requests navigation from the optional `ShortestPathForever.API.Navigate` public API.
- `Scan area` (or `/wflg scan`) sends one player-triggered Who query for the current zone and a relevant level band, then records the result automatically when the server answers.
- Shortest Path Forever owns its arrow and map marker. This addon does not copy or reimplement them.
- The panel shows the saved target, an SPF travel-time estimate when available, and current target/mouseover NPC IDs.
- No navigation starts automatically on login, reload, target change, or quest update.
- Quest updates reconcile active progress and the client's completed IDs; first installation at level 11 needs no old logs. Unknown completion history remains unknown. This version selects active quests only, not unaccepted steps of the planned route. Removed quests invalidate saved quest targets; manually placed targets remain intact.
- With separately installed QuestieDB and accepted public contract 2, tooltips annotate NPC IDs related to active quest objectives, item drops and turn-ins. These are database relationships, not proof a particular unfinished sub-objective still needs that NPC. No raid icons, outline effects or copied Questie renderer are used. If the client lacks the legacy tooltip hook, recognition remains in the guide panel.
- Shopping preparation reads item objectives, inventory counts and vendor names from the public DB. It also checks one `nextQuestInChain` successor when completion history is available, explicitly conditional on continuing that chain. It does not assert that successor is available; there is no inventory purchase, AH search, price comparison, vendor-stock verification or navigation to unverified DB coordinates.
- Optional turn-in assistance defaults OFF. Enable with the button or `/wflg autoturnin`. It operates only after the player opens the relevant quest progress/reward dialog, for an active complete quest, out of combat, without money costs and with zero reward choices. Holding Shift pauses it. It does not choose gossip entries, accept quests, abandon quests or move the character. A request is not considered a confirmed turn-in; `QUEST_TURNED_IN` is logged separately.
- A bounded per-character `report` (300 entries) records login, quest snapshots, selected targets and turn-in requests/errors/confirmations. WoW persists it in its normal SavedVariables file on reload/logout; the addon cannot write arbitrary report files while playing.
- If SPF is unavailable or the player is in combat, the target remains saved and the addon explains why navigation did not start.

## Commands

| Command | Result |
| --- | --- |
| `/wflg` | Open or close the navigation panel. |
| `/wflg next` | Recompute and select a mappable active objective/turn-in using the heuristic above. |
| `/wflg target <map> <x> <y> [title]` | Save a normalized map target. Coordinates must be between `0` and `1`. |
| `/wflg go` | Explicitly start the SPF arrow and map marker for the saved target. |
| `/wflg clear` | Cancel this addon's SPF journey when owned and clear the saved target. |
| `/wflg status` | Write target and SPF status to chat. |
| `/wflg scan` | Player-triggered crowd sample for the current zone and level minus two through plus three. |
| `/wflg autoturnin` | Toggle conservative quest-dialog turn-in assistance. |
| `/wflg shopping` | Print all available vendor-item preparation hints. |

## Deliberate limits

M1 supports manual targets and heuristic selection among active quests. It never treats a QuestieDB zone ID as a Shortest Path Forever `uiMapID`: that relationship is not verified. QuestieDB is read only for relationships and hints, never copied. SPF is called only through its public API; movement remains manual. The heuristic does not yet model safe mob levels, crowd-related waiting, objective-specific drop rates or prerequisites for unaccepted quests. Route packages and full prerequisite gating remain separate unfinished work.

The crowd value is a player-triggered sample, not a radar. Forever restricts Who requests to a hardware event and the server can cap replies at 50 players. The addon's button satisfies the first restriction; a capped result is displayed as `at least 50` and `very high` rather than as an exact count.

## Verification and next normal-play check

`python3 tools/run_lua_tests.py` syntax-checks all addon Lua with LuaJIT/Lua 5.1 and runs isolated mocked tests. Tests cover late-entry snapshots, unknown history, stale targets, progress-aware selection, missing estimates/dependencies, vendor/drop relationships, turn-in safety guards, duplicate event handling and full TOC/UI startup. They cannot establish Forever API runtime permissions or actual efficiency. The UI hooks and quest-dialog automation are experimental until checked in the real client.

Install the folder `WoWForeverLaunchGuide` under `Interface/AddOns`; keep Shortest Path Forever for its arrow and QuestieDB for hints. Questie itself is optional and can retain its own map/nameplate rendering. LaunchProbe can be disabled for normal use. Open `/wflg`, choose `Nächstes Ziel`, then `Pfeil starten`. Enable the turn-in button only if desired. During normal play inspect a quest mob with the mouse and open a completed quest at its NPC; no separate micro-test sequence is required. Finish with `/reload` to persist the report for the existing log-sync workflow.

API evidence: completion/objective calls were verified against `Core/State.lua` in the audited AGF checkout, DB fields against `src/types/{Quest,Item,Npc,General}.t.lua` in QuestieDB. Quest-dialog call semantics were cross-checked against [Classic FrameXML QuestFrame.lua](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/QuestFrame.lua), especially `QuestProgressCompleteButton_OnClick` and `QuestRewardCompleteButton_OnClick`; that source is not proof of Forever runtime compatibility. No upstream code was copied.
