# Prototype status

Verified on Godot 4.6.3 (`7d41c59c4`), Linux Compatibility renderer. “Tested” below means the specific evidence named, not every possible input sequence. This project implements a coherent subset of the supplied handoff; it is not a claim of full acceptance.

| Area | Status | Evidence / concrete limits |
|---|---|---|
| Fresh launch | Implemented and tested | Clean headless import/run and actual desktop launch. No missing local assets. |
| Solo integrated rules | Implemented and tested | State tests exercise pack, cooking, consumption, magazines and shots; scene/UI tests cover access and movement. Complete human-driven tour was **not** performed. |
| Movement | Implemented and tested | Walk/sprint, diagonal normalization, crouch ceiling, jump, terrain penalties and fall recovery pass physics tests. Coyote time/buffering exist; slope traversal needs further manual tuning. Jump is roughly half a meter with current tuning. |
| Arena | Implemented, partially verified | 100 × 100 m floor, paths, stations, stairs, 20/40/60° slopes, low ceiling, targets, terrain patches and open fall edge. The deep-water barrier closes the approach from the shallow patch; it is not a sealed swimming-volume simulation. |
| Interaction | Implemented and tested | Ray focus, UI, distance/obstruction tests. E opens explicit actions even for simple objects rather than auto-taking. Server reach includes a 0.3 m tolerance. |
| Placement/drop | Partial | Level surface, shape overlap, reach, rotation, cancel, host-controlled drop motion. Clear/invalid surface tests pass. Drop collision uses swept rays, not full rigid-body collision; complex ledge/side contact needs testing. |
| Inventory and identity | Implemented and tested | Stable IDs, revisions, atomic equip/transfer, capacities, rollback, two-hand constraints, no nested packs. Competing claims and inaccessible storage tested. No grid or weight system. |
| Backpack cycle | Implemented and tested | Domain verifies wear→hold→place→hold→wear, contents and external slots. Desktop verifies take and wear with same ID. Simplified pack meshes; attachments aren't individually rendered on pack geometry. |
| Dynamic hotbar | Implemented, partially verified | Access expansion/removal tested in domain; wheel/pages and current-binding labels implemented. Number-key navigation across all loadout permutations not manually tested. Selection tracks a slot string. |
| Camping | Implemented and tested | Exclusive sleeping bag occupancy, finite fuel, real canister socket, exact 250 mL hydration, 10 s cooking, pause/resume, one-time consumption, measurable hunger/thirst and exhaustion shutdown. No survival decay. |
| Firearms | Implemented and tested | Distinct ammo, individual magazines, load/unload, tactical chamber preservation, single chambered shot, recoverable ejection, dry fire, drop interruption and cadence rejection pass state tests. |
| Weapon presentation | Implemented but partly unverified | Hitscan targets, recoil, FOV aim, spread and rifle auto mode implemented; shooting interaction/accuracy was not manually exercised on desktop. No firing sounds, muzzle effects, detailed animation or damage system. |
| Reload cancellation | Partially tested | Drop cancellation and unchanged ammo totals tested. Stow/disconnect paths cancel through shared logic, but interruption at every timer boundary was not independently exercised. |
| Host/client state | Implemented and tested | Four real ENet processes, late snapshots, one successful shared-pack claim, denied competing claims, client-reset refusal, crate recovery and matching ammo totals. Fifth process rejected. |
| Network movement | Partial | Host simulates intent; local look is immediate; remote positions interpolate. No prediction or lag compensation. Integration test covers host physics, not intentional latency/loss or a remote movement tour. |
| Late join | Implemented and tested | Client joining later observes active cooking, a 650 mL nested bottle, chambered pistol and magazine state. Reliable full-state snapshots; no interest management. |
| Disconnect / reconnect | Partially tested | Real processes trigger one recovery crate. Domain confirms occupied bag release and reconnect without duplication. Host-exit UI code exists but a host-exits-first multi-process run was not performed. |
| Sandbox controls | Partial | Spawn kits/items, host-only reset/recover/cleanup, destructive-reset confirmation, debug and event messages. Recover targets the host only. State reset tested; reset during all UI/timer combinations and cleanup edge cases need manual testing. |
| Settings | Implemented and tested | Keyboard/mouse actions, duplicate rejection, persisted sensitivity/invert, label updates tested with ConfigFile reload. Desktop settings panel renders. No gamepad support. |
| Voice | Hooks only | Explicit unavailable notice, capture off, peer/head-position fields, mute/PTT interface and 2–20 m attenuation. No microphone, codec, transport, speaking indicator or synthetic tone. |
| Save/load / Windows export | Absent / not run | Session persistence only. Source project and Windows launch script provided; Windows runtime and export not tested. |

## Deliberate simplifications

All equipment uses colored primitive geometry. Stable placed objects and shared slot panels replace complex physical manipulation. World item snapshots currently snap rather than interpolate. Full reliable snapshots prioritize coherence over bandwidth; congested/high-latency networks will need refinement. The host validates gameplay rules but this is not an adversarially hardened Internet service.

Remaining acceptance checks are listed in `TESTING.md` with reproducible steps. No story, quests, enemies, progression, procedural world generation, paid assets or backend service were added.
