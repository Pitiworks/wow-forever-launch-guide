# M1 Navigation Foundation

`WoWForeverLaunchGuide` 0.3.0 is an experimental M1 quest assistant with executable editorial route packets for an Undead start. It does not replace the M0 diagnostic probe. It contains no copied quest catalogue, verified full 1–20 XP coverage, global optimizer, or bridge.

## Runtime behavior

- A player explicitly saves a next target with `/wflg target <map> <x> <y> [title]`.
- `/wflg next` evaluates active objectives, turn-ins and eligible route pickup candidates. It compares SPF travel estimates plus a heuristic 20 seconds per remaining objective unit (30 seconds for a pickup interaction). At >=50% progress, estimated work receives a 25% finishing bonus. These constants are not measured XP/h or drop-time predictions. If any travel estimate is missing, all candidates use work-only scoring and the UI explicitly labels travel comparison unknown. Cross-map pickups without a travel estimate are withheld. Ties use editorial packet order and then quest ID, never quest-log order.
- `/wflg go` requests manual navigation through the optional `ShortestPathForever.API.Navigate` public API. Starting Guide mode authorizes subsequent event-driven step updates through `NavigateRoute` with a single held stop. Only the public SPF API is used.
- `Scan area` (or `/wflg scan`) sends one player-triggered Who query for the current zone and a relevant level band, then records the result automatically when the server answers.
- Shortest Path Forever owns its arrow and map marker. This addon does not copy or reimplement them.
- The panel shows the saved target, an SPF travel-time estimate when available, and current target/mouseover NPC IDs.
- Guide mode starts only on the player's explicit button/command and is reset on login/reload. Once started, quest/zone/level/movement-stop events update steps automatically; combat delays starting a new arrow. Holding a stop retains guidance while the player interacts. A foreign SPF journey replacing ours pauses the guide rather than fighting that other addon.
- Quest updates reconcile active progress and the client's completed IDs; first installation at level 11 needs no old logs. Unknown completion history remains unknown. Pickup candidates require readable public fields, suitable level/race/class and conservative checks of prerequisites, exclusivity, parents and chain progression. Unhandled special requirements yield `unknown`. A candidate is never a confirmed server offer. Removed/invalid quest targets are cleared; manually placed targets remain intact.
- A valid selected step is retained unless all travel estimates are comparable and the alternative improves cost by more than both 30 seconds and 25% of the current estimated cost. Changed quest stages and invalid targets can advance immediately. `5 Min. zurückstellen` temporarily defers a step, including a distant turn-in, without abandoning it; expiry restores eligibility. No AFK/elapsed-time auto-block detector is implemented.
- With separately installed QuestieDB and accepted public contract 2, tooltips annotate NPC IDs related to active quest objectives, item drops and turn-ins. These are database relationships, not proof a particular unfinished sub-objective still needs that NPC. No raid icons, outline effects or copied Questie renderer are used. If the client lacks the legacy tooltip hook, recognition remains in the guide panel.
- Shopping preparation reads item relationships, inventory counts and vendor names from the public DB. It examines up to three upcoming candidates plus one chain successor where completion history is available. Quantities come only from an unambiguous localized client item-objective match; otherwise the UI says to check the quantity. Important 0.2 correction: DB objective tuple slot 3 may be an icon and must NEVER be used as a required count. There is no purchase, AH search, price comparison or vendor-stock verification.
- Optional turn-in assistance defaults OFF. Enable with the button or `/wflg autoturnin`. It operates only after the player opens the relevant quest progress/reward dialog, for an active complete quest, out of combat, without money costs and with zero reward choices. Holding Shift pauses it. It does not choose gossip entries, accept quests, abandon quests or move the character. A request is not considered a confirmed turn-in; `QUEST_TURNED_IN` is logged separately.
- A bounded per-character `report` (300 entries) records login, quest snapshots, selected targets and turn-in requests/errors/confirmations. WoW persists it in its normal SavedVariables file on reload/logout; the addon cannot write arbitrary report files while playing.
- `evaluation` automatically summarizes version/build, character/level/XP, completion-history readiness, dependency contract/flavor, route states, selected point/source, planner time when available, observed NPCs, confirmed turn-in count and compatibility issues. Own event/update/button/command errors are recorded and pause Guide mode; this is not a global error collector for other addons.
- Target, mouseover and nameplate events track observable related units. GUIDs deduplicate the same NPC; dead/nonattackable units are excluded and unavailable status is reported separately. These observations neither establish range/layer population nor trigger automatic rerouting. Zero observations are not evidence of zero mobs in the area.
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
| `/wflg guide` | Start/pause automatic step guidance for this session. Movement remains manual. |
| `/wflg skip` | Temporarily defer the current quest for five minutes; never abandon it. |
| `/wflg route` | Print route states and reasons, including blocked/unknown prerequisites. |
| `/wflg branch silverpine` / `branch barrens` | Choose future regional pickup candidates; already active quests remain eligible. No forced continent move or promise of less crowding. |
| `/wflg report` | Refresh the stored self-evaluation and print compatibility issues. |

## Deliberate limits

M1 supports manual targets and a small executable editorial route. Native POIs/waypoints remain preferred. For pickups and missing turn-in points, `DBCoordinates.lua` uses the published `LibQuestieDB.Support.Get("ZoneDB")` mapping and composed spawn reads. Forever metadata, the contract, numeric map structure and a client-reported Zone map are mandatory. Historical support field names contain `private`, but the entry point and that exact structure are explicitly documented by the provider; no private behavior/functions are invoked. Map literal strings are parsed as numeric pairs, never executed. Invalid coordinates, unknown mappings, phase-specific points and dungeon/non-zone maps are withheld. Already-Forever coordinates are normalized from percent, not projected again. The schema/mapping fixture passes; real-client spatial validation is still unknown.

The route profile currently covers Undead packets only; other profiles retain active-quest assistance. Race/class masks use public DB enums (including >32-bit race masks). Unknown professions, reputation, special flags and similar conditions are withheld rather than guessed. Simultaneous group/single prerequisites are conservatively required. Negative prerequisite IDs remain unknown. There is no full server-availability model, class-specific route, calibrated safe-mob/loot/crowd cost model or verified XP completeness. The next required evidence is an actual Forever session with this build, not further unverified API assumptions.

The crowd value is a player-triggered sample, not a radar. Forever restricts Who requests to a hardware event and the server can cap replies at 50 players. The addon's button satisfies the first restriction; a capped result is displayed as `at least 50` and `very high` rather than as an exact count.

## Verification and next normal-play check

`python3 tools/run_lua_tests.py` syntax-checks all addon Lua with LuaJIT/Lua 5.1 and runs seven isolated suites. Tests cover late-entry snapshots, unknown history, stale targets, progress-aware selection, missing estimates/dependencies, vendor/drop relationships, turn-in guards, Who timeout/missing totals, observations, error capture and full TOC/UI startup. A full simulated event flow covers pickup → objective → turn-in → next pickup → foreign journey replacement → reload. With `WFLG_QUESTIEDB_PATH=/path/to/QuestieDB`, an additional optional test reads the separately installed provider's public schema, base data and Forever mappings without copying them. This fixture ran against both local audit and M0 dependency checkouts. It is not a composed corrections/localization test or evidence of real-client runtime permissions/spatial accuracy.

Install the folder `WoWForeverLaunchGuide` under `Interface/AddOns`; keep Shortest Path Forever and QuestieDB enabled. Questie itself is optional and can retain map/nameplate rendering. LaunchProbe can be disabled for normal use. Open `/wflg`, click `Guide starten`, and play normally. Enable turn-in assistance only if desired. Finish with `/reload` to persist the self-evaluation and event report. The updated existing log-sync helper transfers `WoWForeverLaunchGuide.lua` alongside the probe file; it must be running on the game PC. No separate manual micro-test sequence is required. The first real report is required before declaring this version compatible or calibrating automatic crowd-based route switching.

API evidence: completion/objective calls were verified against `Core/State.lua` in the audited AGF checkout, DB fields against `src/types/{Quest,Item,Npc,General}.t.lua` in QuestieDB. Quest-dialog call semantics were cross-checked against [Classic FrameXML QuestFrame.lua](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_UIPanels_Game/Classic/QuestFrame.lua), especially `QuestProgressCompleteButton_OnClick` and `QuestRewardCompleteButton_OnClick`; that source is not proof of Forever runtime compatibility. No upstream code was copied.

Additional evidence: [QuestieDB support API](https://github.com/Questie/QuestieDB/blob/master/src/support/data.lua) explicitly documents `Support.Get("ZoneDB").private.areaIdToUiMapId`; `support/Forever/Zones/areaIdToUiMapId.lua` publishes the mapping, `src/types/Meta.t.lua` defines parent/chain semantics, and `src/meta/questMeta.lua` names supported keys. `Core/API.lua — API.NavigateRoute` in the audited SPF checkout documents held interactions and owner replacement. No QuestieLoader runtime modules, SPF internals, map overrides for dungeon entrances or evaluated data strings are used by the addon.
