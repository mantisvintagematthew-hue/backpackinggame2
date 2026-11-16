# Verification

Tested with Godot 4.6.3 official on Linux.

- Removed the complete generated .godot directory, then ran tools/test.sh from fresh user-data/config/cache directories.
- Clean import and settled editor validation completed; integration run passed 31 checks with no script errors.
- Checks cover Jolt selection, native movement/ground collision, generated interaction prompts, native inventory transfers, hydration conservation, cooking/fuel consumption, burning/full-inventory rejection, backpack wear/drop/carry, opening a carried container, weapon equip/fire/reload, eating and inventory opening.
- Original project: 53 domain checks, 16 physics/integration checks, settings persistence checks, and five-process multiplayer test passed (four connect, fifth rejected).
- Rendered camp, native inventory and stove screenshots checked at 1280×720 using Compatibility rendering on a virtual display. This is automated rendering and visual inspection, not a human playtest.

Known upstream warnings: some binary animation resources fall back from stale UIDs to valid file paths; Jolt ignores a sample custom solver bias; Godot reports ObjectDB instances on shutdown. These did not produce script errors or failed checks. Human movement-feel, gamepad behavior, exports and networking of the new foundation are not qualified yet.

Run:
```sh
./tools/test.sh
(cd legacy && ./tools/test.sh)
godot --path . -- --capture
```
