# Foundation decision and integration

The goal is to evaluate established systems before expanding custom mechanics. The attached handoff is a product reference; its contents are not permission to publish, contact anyone, or perform unrelated actions.

## Pinned source

COGITO v1.1.6, commit `8b38b0bb21fa432155e04655f6e6bcbb13c55d1c`, from https://codeberg.org/Phazorknight/Cogito.git. This version targets Godot 4.5.1 upstream; this fork is tested with Godot 4.6.3. We inspected 1.2.0's changes but did not runtime-qualify that release. Pinning 1.1.6 avoids combining a template migration with this first integration.

Integrated COGITO was selected over stitching together an independent controller, GLoot inventory and FPS template: interaction, item ownership, weapon equipment and UI already share interfaces. This does not imply that multiplayer is provided. Networking requires a deliberate authority layer around those interfaces.

## Ownership

- `addons/`: vendored COGITO and its bundled input-helper/quick-audio dependencies.
- `fieldlab/`: camp, Kenney environment assets, backpack wear adapter, resource-based supplies, stove and UI.
- `legacy/`: complete earlier project, isolated by `.gdignore`; open its own project.godot to run.
- Supply identity and amounts live on FieldSupply resources used by native InventorySlotPD slots. The stove transfers the actual slot, rather than copying quantities into a second inventory implementation. Failed returns retain the socket item.

## Local vendor changes

- Scene/resource dependencies use explicit paths instead of stale upstream import UIDs. The global project theme is omitted to avoid loading fonts before the first import; native UI scenes retain their own themes.
- Quest audio loads at runtime, settings omit the unused demo start scene (the root project launches the camp directly), and editor plugins are disabled by default (required runtime autoloads remain configured explicitly).
- PlayerInteractionComponent permits basic interaction with a carried CogitoContainer; existing pickup behavior retained.
- WieldableItemPD logging accepts carried containers as well as CogitoObject parents.
- Mouse inversion defaults to off in the player/options fallback.
- DynamicInputIcon silently handles Compatibility/headless rendering without a RenderingDevice.
- Toy pistol frees unparented pooled projectiles on exit and before rebuilding its pool.
- Language selector uses text instead of unverified Freepik sample flag icons.
- Restricted/sample audio references replaced with Kenney handling audio; see THIRD_PARTY.md.

Root project changes select Jolt, Compatibility rendering, the camp entry scene, and familiar E/Q/left/right mouse bindings. The camp disables save/load/back-to-demo buttons because procedural camp persistence is not yet implemented. Other upstream sample scenes remain for reference, not as supported game levels.

## Evaluation boundaries

Automated checks exercise real native inventory transfers, controller movement and collision, backpack wearing, stove conservation and failure paths, native weapon fire/reload, and container UI opening. Rendered screenshots inspect camp and inventory layout. These checks do not substitute for a human movement-feel/gamepad/playthrough review.

The next milestone should qualify feel and item handling with the user before adding network synchronization. The original co-op implementation remains a behavioral reference, not a drop-in replacement for COGITO's local systems.
