# Architecture

## Item truth

`Catalog.DEFS` contains immutable definition data: display name, size, hands, tags, ammunition compatibility, capacity and colors. `ItemRegistry.items` is the sole mutable inventory source. Each instance has `id`, `def`, `loc`, `pos`, `rev`, `state` and optionally world `yaw`. IDs combine an arena epoch with a monotonically increasing serial, so reset invalidates old references.

Locations are exactly one of:

- `world`: host-owned world position;
- `p:<peer>:<slot>`: two hands, four belt slots, four pockets, or the pack mount;
- `i:<instance>:<slot>`: pack internals/external slots, stove fuel/cooking socket, gun magazine socket, or recovery crate.

World meshes and UI never own items. A transfer changes the one registry location. Compatibility and capacity checks precede mutation. Equip stages displaced hands with rollback on failure; no implicit drops. Two-handed objects reserve both hands through validation rather than a second item reference. Parent traversal rejects cycles; backpacks cannot nest.

Pack internals are accessible when held or when their world root is nearby and unobstructed. Worn packs expose external slots only. No teammate access to held/worn packs. The equipment panel refreshes access every 200 ms and removes invalid selections. Destination occupancy is checked at commit, not trusted from the UI. Quick slots are stable location strings, not persistent array indices.

## Commands and authority

`main.gd` handles ENet lifecycle, peer identity, scene reach/line-of-sight checks, placement geometry, request throttling and routing. Remote sender IDs come from Godot, never from client payloads. Item commands pass through `ItemRegistry.command`, which validates epoch, per-peer request sequence, source revision and accessibility before executing the domain action. Rejected actions return a visible reason. Sandbox reset/recover/cleanup require host peer 1. Spawners require station reach and a one-second cooldown.

Solo uses OfflineMultiplayerPeer and the same registry/scene handlers. Clients send intentions and never authoritative transforms or hit claims. The host simulates every CharacterBody3D at 60 Hz, validates direction inputs, rate-limits gun fire, changes resources and advances reload/cooking timers. Camera look updates locally. There is **no movement prediction/reconciliation**, so a client feels transport latency in movement; this is a LAN prototype.

Full item/player/reload snapshots are sent on reliable ordered channel 0 at approximately 20 Hz. They include the epoch/revision baseline, nested relationships, resource quantities, occupancy and chamber/magazine state. This small lab deliberately uses full snapshots rather than deltas. Godot's ordered RPC channel prevents older snapshots overwriting newer item state. A late join first restores the complete registry, then creates dependent views. Commands wait until the peer has an avatar and registry player. Input intentions and cosmetic target flashes use unreliable channel 1. Remote transforms interpolate; world equipment positions currently update directly from snapshots.

The host uses current validated player head position, aim orientation, small spread and geometry raycast for hits. Teammates block rays but take no damage. Local aiming narrows FOV; recoil is a small local pitch impulse. There is no lag compensation. Reload state holds the target magazine ID, original slot/revision, peer and completion time; completion revalidates references and commits old-mag return, new-mag insertion and optional feed together. Stow, drop, changed access and disconnect cancel it.

## Scene and presentation

- `arena.gd`: primitive 100 × 100 m laboratory, collision geometry, semantic terrain regions and stations.
- `player.gd`: movement, collision/crouch clearance, recovery, camera and equipment views.
- `registry.gd`: inventory/camping/ammunition rules, timers, snapshot schema and invariant checks.
- `world_motion.gd`: host-only swept-ray drop motion and fall recovery; placed objects remain stable.
- `ui.gd`: local session/settings/inventory/context panels, prompts and hotbar.
- `bindings.gd`: named actions, duplicate-binding rejection and ConfigFile persistence.
- `voice.gd`: optional service boundary, peer head positions, mute/capture/PTT fields and 2–20 m attenuation. No capture or transport.

Gameplay definitions and registry rules have no arena-node dependency. `near_check` is injected; future authored levels can provide their own reach policy, terrain volumes and stations. The current arena's terrain regions use position bounds, not a reusable arbitrary-volume authoring tool. Main scene orchestration is still relatively large and is a sensible future extraction point for transport and world presentation.

## Recovery and persistence

On disconnect, the host cancels reloads, releases rest occupancy and moves all top-level carried items into one world recovery crate at the last grounded position. Nested contents and attachments retain their IDs. Rejoining creates an empty player. Host departure ends the session; no migration exists.

Reset increments the epoch, clears items/reloads, releases occupants and creates fresh kits. Old panels refresh/close and old commands fail. Cleanup deletes only empty movable world roots, preserving carried items and containers with descendants. Persistence is **within the current session only**; no disk save format exists.

## Limits of the authority boundary

This implements gameplay authority for trusted LAN sandbox use, not a hardened hostile Internet server. Full snapshots expose the entire lab's inventory to all connected peers. Server rate limits are modest; there is no packet fuzzing, authentication, encryption layer, bandwidth backpressure design or replay journal across sessions. The test fixture is activated only by the explicit `--smoke` CLI flag and must not be used for normal sessions.
