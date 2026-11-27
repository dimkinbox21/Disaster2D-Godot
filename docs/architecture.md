# Architecture

The client renders the world and simulates movement. The server validates teams,
damage, rings, abilities, cooldowns, profile events and round outcomes.

## One module per map

Each map has a directory under `src/game/maps/<map>/`:

- `rules.gd`: client state, network updates and map-specific effects.
- `hud.gd`: screen-space effects.
- `overlay.gd`: an additional effect layer where needed.

`src/game/maps/shared/rules.gd` provides the common client API.
`imported_map.gd` loads entities and artwork from map manifests;
`map_controller.gd` creates the local player, camera, HUD and remote players.
Reusable doors, platforms, particles and sound emitters remain shared objects.
Original `obj_*` names are retained to make source comparisons straightforward.
Scene-configured script properties use `@export_storage` so their values survive
binary scene conversion in exported builds.

`assets/maps/catalog.json` maps stable numeric IDs to scenes, module directories
and round durations. `src/data/maps.gd` reads that catalog. Client world layout
lives in `scenes/map_*.tscn` and `assets/gm/maps/*.json`.

The matching server map uses `src/maps/<map>/rules.gd` and
`assets/maps/<map>/world.json`. The world file contains entities, collision geometry,
ring spawners, exits and springs. The server creates one `active_map` and delegates
map packets, snapshots and ticking to it. Update both projects when changing a map.
Map IDs are part of the protocol and saved progress; keep them stable.

## Other systems

- `src/game/player.gd`: shared player movement and collision.
- `src/game/survivors/`, `src/game/hunters/`: character abilities.
- `src/net/`, `src/autoload/net.gd`: connection, lobby and protocol.
- `src/menu/`: menus and the first-launch import screen.
- `src/autoload/visual_effects.gd`: shaders and layer materials.
- `src/autoload/save_store.gd`, `achievements.gd`, `unlockables.gd`: profile storage.

Local test launchers and server emulators are not shipped. Use the server's `.test`
command for solo gameplay checks. `tools/export_map_geometry.gd` is a maintenance
utility that exports actual client collision masks to a selected server map file.

## Scene properties in release exports

Every script property assigned by a `.tscn` scene must use `@export_storage` (or
an appropriate exported property). The editor can load unmarked assignments from
text scenes, but the release scene converter does not preserve them. This includes
menu button IDs, columns and submenu IDs, world-map regions, shop items, demo
sprites, layer colours and sound-emitter types. Runtime-only animation state stays
unexported. After changing storage annotations, make a clean export and compare
stored scene values with the source scenes before publishing a release.

## Game authority and synchronization

Build 1131 changes the protocol; update both client and server.

Clients send only the round ID, input sequence and held buttons for movement.
The server calculates position, velocity, collision, animation state and character
abilities. It owns HP, damage, healing, death, revival, pickups, ring destruction,
projectiles, map schedules and round outcomes. Client damage, death and character
ability reports cannot authorize these actions.

`src/net/player_health.gd` applies a separate revisioned health stream to owners,
puppets and cached players. `src/net/predicted_movement.gd` retains up to 256 local
input frames. An authoritative checkpoint restores the actor state, then replays
unacknowledged input without repeating sounds, particles or network commands.
Round IDs and warp epochs reject obsolete corrections. Rendering, camera, sound,
menus and local profile storage remain client responsibilities.

The server's `src/simulation/generated/` contains actor and character logic exported
from this client's source, with rendering replaced by small headless adapters.
Animation timing is retained because several abilities depend on animation frames.
`src/net/movement_state.gd` defines the matching checkpoint schema in both projects.
Generated controllers belong to individual files; do not edit their server copies.

After changing actor or character logic, synchronize the matching server:

```powershell
python tools/export_server_simulation.py C:/path/to/DisasterServer-Godot
godot --headless --path . --script res://tools/export_map_geometry.gd -- C:/path/to/DisasterServer-Godot
```

The map exporter writes static masks, hazard regions, spawn pools, ring positions
and gameplay objects for all 21 maps. Server map rules supply moving walls, doors,
ice, lifts and lava platforms. Artwork is not part of the server simulation.
The generated manifest records hashes of the client controller sources.

The server budgets input simulation using elapsed server ticks. It buffers brief
packet jitter, limits catch-up work, and releases controls after a stalled sender.
Sending extra packets cannot grant extra simulation time. The network event loop
also has a per-tick work limit.

Downed players have the original 31-second rescue window. The primary hunter
within 240 pixels pauses it; a nearby demon halves its speed. Below two minutes
of round time, downed players are resolved immediately. On expiry, the server
allows at most `floor(non-primary players / 2)` demons; other casualties remain
dead without a second countdown. Helping uses the actors' sprite bounds, costs
the helper's rings and restores two health sections. Progress is broadcast to
all clients and drawn above foreground scenery. The death camera holds for three
seconds, then follows living survivors until revival or demonization.
