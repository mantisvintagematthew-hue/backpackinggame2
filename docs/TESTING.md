# Testing and evidence

## Environment and commands

Tested with **Godot 4.6.3.stable.official.7d41c59c4**, Linux; headless physics plus a visible desktop run using Compatibility/OpenGL and software Mesa rendering. Windows, different GPUs, LAN devices and simulated network delay/loss were not tested.

From the project root, with Godot and Python 3 on PATH:

```sh
./tools/test.sh
```

Individual commands:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/domain.gd
godot --headless --path . --script tests/physics.gd
godot --headless --path . --script tests/settings.gd
python3 tests/multiplayer.py
```

The shell runner supplies writable XDG directories in `/tmp/fieldlab-*`, avoiding restricted-home errors in managed sandboxes. Desktop users ordinarily need no overrides. The multiplayer harness uses UDP 24679 and writes per-process logs to `/tmp/fieldlab-network/`. CLI `--smoke` enables explicit test fixtures, not normal loadouts. Do not use it for ordinary play.

## Actual results

Final complete runner: **passed**, exit 0; no `SCRIPT ERROR` or `ERROR:` entries. See [captured output](test-results.txt).

| Suite | Result | What it establishes |
|---|---|---|
| Import / launch | Passed | Scripts load, scene instantiates, no missing resources. |
| Domain | **53 checks passed, 0 failed** | Backpack persistence/access, slot capacities, competing/stale/repeated requests, cooking/fuel/water/consumption, sleeping occupancy, magazine identity, timed reload, chamber accounting, ejection, drop interruption, ammunition conservation, recovery/reconnect and reset invariants. |
| Physics / scene | **16 checks passed, 0 failed** | Actual CharacterBody3D walking/sprint speed, normalized diagonals, water/brush/rough penalties, ceiling uncrouch rejection, jump, recovery with carried pack, placement/obstruction and inventory/settings scene integration. |
| Settings | Passed | Duplicate rejection, keyboard binding for mouse actions, sensitivity/invert persistence through fresh ConfigFile load and prompt labels. Tests restore prior settings. |
| Real multiplayer | Passed | One host plus three clients concurrently; fifth process rejected. One client joins later. All four observe a single contested pack, nested 650 mL bottle, hot meal and chambered pistol. One client takes pack, other claims fail; client reset is denied. Disconnect creates one recovery crate. All report empty invariant errors and ammunition total 156 (including fixture ammo). |
| Desktop smoke | Passed, limited | Actual project import, menu rendering, solo launch, keyboard movement to supplies, Tab panel, selecting/taking/wearing pack. Same ID `2-1` progresses world → hand → worn, revisions 0→1→2. Lighting and label clutter found and reduced. |

The initial network harness asserted the *final* player count, which raced with another client exiting. It now checks the peak simultaneous count and required replicated fixture state. This was a harness correction, not a claim that each client remains connected after its test has finished.

The state suite's quantity checks include fired rounds in ammunition totals. Spawner/reset operations are excluded from that controlled conservation sequence. It verifies consumption removes the instance and does not leave a second location. Geometry and networking checks complement those tests; screenshots alone do not prove consistency.

## Not run / manual follow-up checks

These are validation gaps, not a request to implement a future milestone:

1. **Full desktop camp-and-shoot tour:** follow README from a fresh Solo session. Record IDs before/after every pack transition, remaining water/fuel, and `magazine + chamber`. The underlying loops are automated; this complete UI tour has not been performed.
2. **Slope and jump feel:** approach each labeled slope walking/sprinting, then test coyote/buffer timing and crouch exit at the low ceiling. The 60° ramp should not act as walkable floor; inspect edge behavior separately.
3. **Placement extremes:** place rolled/unrolled bags near walls, platforms and other items; rotate at every angle; cancel and verify the original instance stays held. Drop tests need side-contact/ledge inspection because collision is simplified.
4. **Host/client moving trade:** open two windows using README commands, walk to the same station, pass a pack back and forth and observe held/worn geometry and remote interpolation. The automated multiplayer test transfers the pack from stationary fixtures.
5. **Latency/loss:** repeat movement and automatic fire under a controlled delayed/lossy UDP link; no smoothness claim is made beyond localhost.
6. **Reload interruption permutations:** start reload, then stow, disconnect or reset before 1.2 s. Sum loose rounds, magazines, chamber and fired rounds; the drop variant is already automated.
7. **Reset/cleanup UI:** reset during burning/cooking/reload while another client's inventory is open; verify old IDs reject. Cleanup should retain occupied bags, burning stoves, carried equipment and all nonempty containers.
8. **Host departure:** close host first; remaining clients should return to menu with “Host left the session.” Rejoin a new host and verify an empty player loadout.
9. **Windows/LAN:** import under the same stable Windows engine, run two PCs on the same LAN with UDP 24567 allowed, then exercise all four player slots. No Windows export or physical LAN test has been performed.
10. **Remapping restart:** change bindings in the UI, restart the application and use the new keys/mouse actions. ConfigFile reload is automated; a full desktop restart with altered keys was not manually exercised.
