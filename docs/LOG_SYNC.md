# Automatic Beta Log Sync

WoW Addons may write only their SavedVariables file inside the WoW `WTF` directory. They cannot write directly to a network share. `Start-WoWForeverLogSync.cmd` is a Windows helper that watches that one SavedVariables file and copies it to `\\192.168.178.88\Daten\WoWForeverLaunchProbe.lua` whenever WoW saves it during reload or exit.

The updated helper also watches `WoWForeverLaunchGuide.lua` beside the selected probe file and copies it under its own name to the share. Alternatively, select the Guide SavedVariables file directly; its default destination is then corrected to `WoWForeverLaunchGuide.lua`, never the probe filename. Existing running helper processes must be restarted to use this change. This is a SavedVariables copy helper, not a live bridge. The PowerShell change is not runtime-verified on the game PC.

Run the helper once on the game PC, paste the full path to `WoWForeverLaunchProbe.lua` when asked, and leave the small console window open while playing. Afterwards, normal `/reload` or exiting WoW automatically makes the new report available on the Mini-PC; no manual copy is needed.
