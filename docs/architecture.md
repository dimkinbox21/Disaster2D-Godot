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
