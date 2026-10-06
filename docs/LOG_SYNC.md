# Automatic Beta Log Sync

WoW Addons may write only their SavedVariables file inside the WoW `WTF` directory. They cannot write directly to a network share. `Start-WoWForeverLogSync.cmd` is a Windows helper that watches that one SavedVariables file and copies it to `\\192.168.178.88\Daten\WoWForeverLaunchProbe.lua` whenever WoW saves it during reload or exit.

Run the helper once on the game PC, paste the full path to `WoWForeverLaunchProbe.lua` when asked, and leave the small console window open while playing. Afterwards, normal `/reload` or exiting WoW automatically makes the new report available on the Mini-PC; no manual copy is needed.
