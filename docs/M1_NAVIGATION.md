# M1 Navigation Foundation

`WoWForeverLaunchGuide` is a separate M1 addon. It does not replace the M0 diagnostic probe and it does not contain a route, quest catalogue, optimizer, or bridge.

## Runtime behavior

- A player explicitly saves a next target with `/wflg target <map> <x> <y> [title]`.
- `/wflg next` resolves the first mappable active quest objective, or a completed quest's turn-in, through Forever's native quest POIs and next-waypoint API.
- `/wflg go` alone requests navigation from the optional `ShortestPathForever.API.Navigate` public API.
- Shortest Path Forever owns its arrow and map marker. This addon does not copy or reimplement them.
- The panel shows the saved target, an SPF travel-time estimate when available, and current target/mouseover NPC IDs.
- No navigation starts automatically on login, reload, target change, or quest update.
- If SPF is unavailable or the player is in combat, the target remains saved and the addon explains why navigation did not start.

## Commands

| Command | Result |
| --- | --- |
| `/wflg` | Open or close the navigation panel. |
| `/wflg next` | Select the first mappable objective or turn-in from the active quest log. |
| `/wflg target <map> <x> <y> [title]` | Save a normalized map target. Coordinates must be between `0` and `1`. |
| `/wflg go` | Explicitly start the SPF arrow and map marker for the saved target. |
| `/wflg clear` | Cancel this addon's SPF journey when owned and clear the saved target. |
| `/wflg status` | Write target and SPF status to chat. |

## Deliberate limits

M1 accepts a manually supplied target because guide selection belongs to later routing work. It never treats a QuestieDB zone ID as a Shortest Path Forever `uiMapID`: that relationship is not verified. QuestieDB is neither copied nor used for a route. The addon only calls Shortest Path Forever at runtime when the player requests it, and only through its documented public API.
