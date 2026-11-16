# FIELD LAB — Cooperative Backpacking

A playable Godot mechanics sandbox: first-person traversal, physical equipment, shared backpacks, finite camping supplies and persistent magazine/chamber state. Solo and 1–4-player ENet listen-server sessions use the same authoritative rules. No external assets, accounts, plugins or backend are required.

**Tested engine:** Godot **4.6.3 stable official (`7d41c59c4`)**, Compatibility renderer, Linux. Windows is the intended desktop target but a Windows runtime/export has not been tested. This is a prototype, not completion of every handoff requirement; see [status](docs/STATUS.md).

## Launch

1. Install Godot 4.6.3 from the official Godot distribution.
2. Import `project.godot` in Godot's Project Manager, open it, and press **F5**.
3. Choose **Solo session**, **Host LAN**, or enter a host address and choose **Join**.

Alternatively, with `godot` on PATH:

```sh
godot --path .
godot --path . -- --solo
godot --path . -- --host --port=24567
```

`tools/run-sandbox.sh` and `tools/run-sandbox.bat` are convenience launchers. The editable project is the deliverable; export templates and an executable are not bundled.

### Two local windows

Run these in two terminals, from this directory:

```sh
godot --path . -- --host --port=24567
godot --path . -- --join --port=24567
```

CLI join connects to `127.0.0.1`. Use the menu to enter a different LAN address. The port is UDP **24567** by default. Allow that UDP port through the host firewall for LAN play. Four players total; additional clients get a connection failure/timeout. Internet port forwarding, matchmaking, relay and host migration are outside this prototype.

**Escape** releases the cursor and opens the menu. The shared simulation keeps running. Choose Return to field to recapture the mouse; this makes switching between windows possible. Host departure ends the client session.

## Controls

| Input | Action |
|---|---|
| WASD / mouse | Move / look |
| Shift / Ctrl / Space | Sprint / crouch / jump |
| E | Focused item actions or station; rotates placement clockwise |
| Tab | Equipment panel, including reachable world items |
| LMB / RMB | Primary action / aim; placement confirm / cancel |
| G / F | Drop / placement preview |
| Q / E during placement | Rotate preview |
| 1–9, 0 / wheel | Equip from current quick-slot page / navigate all slots |
| R / V / B | Timed reload / cycle action / rifle semi-auto toggle |
| F3 | Debug display and recent events |
| Escape | Cancel placement, close panel, or open menu |
| T | Explicit “Voice unavailable — hooks only” notice |

Keyboard and mouse actions, sensitivity and invert-Y can be changed under Controls & settings. Duplicate bindings are rejected. Settings persist in Godot's `user://controls.cfg`. Prompts reflect bindings. No head bob or camera shake is added.

## Reproducible tour

Start Solo. Walk toward the amber **Camp & Supplies** station on the left. An initial camp kit lies beside it; the equipment panel includes only nearby, unobstructed world items and accessible carried equipment.

1. **Backpack:** press Tab; select Expedition pack → Take / equip → Wear pack. Belt has four medium slots; pockets have four small slots. Select supplies and use Transfer to to put them in compatible slots. Pack Internal 1–12 slots are accessible only while held or placed. The four External slots accept bag, bottle, stove and rifle respectively. A pack in hands needs both hands.
2. **Set down:** take the worn pack, close the panel, press F, look down at nearby clear level ground, and confirm the green preview with LMB. Cancel with RMB. Its contents retain their IDs. Nearby teammates may now use it.
3. **Camp:** select a stove → Take / equip, then place it. Select a fuel canister and transfer to the stove’s **Fuel socket**. Select a bottle → Stow accessibly. Select a dry meal → Hydrate (removes 250 mL from an accessible bottle). Transfer it into the stove’s **Cook socket**.
4. **Cook:** select the placed stove → Ignite. After ten seconds of heat the meal becomes cooked. Select the meal → Eat; hunger rises and the consumed instance disappears. Extinguish before packing the stove. Fuel lasts 120 seconds and remains attached when packed. Removing food or turning off heat pauses progress.
5. **Rest / water:** place a sleeping bag → Roll / unroll → Enter / exit rest. Occupancy is exclusive. At the Water Source station, refill a carried bottle; Drink removes 100 mL and raises thirst.
6. **Firearms:** approach Equipment Range on the right. Take a pistol or rifle, stow the matching magazine in belt/pocket, and press R. The initial kit magazines contain 8 pistol or 20 rifle rounds. Reload takes 1.2 seconds and feeds the chamber only if empty. Aim at orange targets; LMB fires and successful hits flash. The display separates magazine rounds and chamber (`7 + 1`). V ejects a recoverable round and feeds the next. The panel offers explicit magazine insertion, removal and drop. Detached magazines use Load one / Unload one with real accessible loose-ammo stacks.
7. **Repack / trade:** transfer supplies into a placed or held pack, take it, wear it, remove it and pass it to a teammate by placing/dropping. Burning stoves and occupied bags refuse movement. Disconnecting players leave one recovery crate with their equipment and nested contents.
8. **Terrain:** explore the labeled brush, rough ground, water, stairs, crouch clearance and slopes. Deep water is blocked; the open south edge tests fall recovery. Escape → Sandbox tools offers host recovery, cleanup and a confirmed reset.

A transfer refusal appears at the bottom of the screen. Occupied/incompatible slots never silently drop possessions. If hands cannot be stowed automatically, explicitly stow/drop an item first. Item IDs, resource state and location are visible in the panel.

## Testing

```sh
./tools/test.sh
```

Requires Godot on PATH and Python 3 for the subprocess harness. The runner isolates local settings under `/tmp/fieldlab-*`. It imports the project, runs state/physics/settings tests, then starts a host, three clients and one rejected fifth process. See [testing evidence](docs/TESTING.md), [architecture](docs/ARCHITECTURE.md), and [implementation limits](docs/STATUS.md).
