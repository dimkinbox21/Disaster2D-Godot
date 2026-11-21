# Disaster 2D — Godot Client

A Godot port of **Sonic.exe The Disaster 2D Remake**, maintained by
[dimkinbox21](https://github.com/dimkinbox21).

![Godot](https://img.shields.io/badge/Godot-4.7.2-478cbf)
![Platform](https://img.shields.io/badge/Windows-x86__64-blue)
![Build](https://img.shields.io/badge/build-1130-green)

## Download and play

1. Download the Windows client ZIP from [Releases](https://github.com/dimkinbox21/Disaster2D-Godot/releases/latest).
2. Extract the complete archive and run **Disaster2D.exe**. Keep its `.pck` file beside it.
3. Join a server from the game menu. The default local address is `127.0.0.1`, port `8606`.

To host a game, download the matching [DisasterServer](https://github.com/dimkinbox21/DisasterServer-Godot/releases/latest)
release and run **DisasterServer.exe**. Client and server must use the same build.
Godot does not need to be installed to play a release build. No BAT launchers are required.

## Features

- Twenty maps in the regular map pool, plus **Fart Zone** practice.
- Six survivors and four hunter variants, with separate ability modules.
- Multiplayer lobby, map voting, character selection, rounds and results.
- Skins, palettes, emotions, 50 achievements and original save support.
- Server-controlled damage, rings, cooldowns and profile events.
- A dedicated module for every map on both client and server.

This port uses its own network protocol. It does not connect to the original GameMaker server.

## First launch and saves

With a new profile, the game asks **“Import save data from the original game?”**
Choose **Import save** to transfer settings, unlocks and progress, or **Start fresh**.
The game checks the original Windows save directory and offers a folder picker when needed.
Original files remain untouched; existing port files are backed up before an import.
The choice is remembered. Existing port profiles continue to load normally.

See [Save data](docs/profiles.md) for file formats and manual import options.

## Solo testing

Connect one client to your server, open the lobby chat and enter:

- `.test k` — vote for a map and play as a hunter.
- `.test s` — vote for a map and play as a survivor.

Test rounds do not award achievements, currency, wins, map completion or other profile progress.
Hunter selection chance and pending priority stay unchanged. `.help` lists other commands.

## Source layout

| Path | Purpose |
| --- | --- |
| `src/game/maps/<map>/` | One map's client mechanics and overlays |
| `src/game/maps/shared/` | Shared map API |
| `src/game/survivors/`, `src/game/hunters/` | Character abilities |
| `src/net/`, `src/autoload/net.gd` | Connection, lobby and network protocol |
| `src/menu/` | Menus and first-launch import UI |
| `src/autoload/` | Settings, profiles, audio and rendering services |
| `assets/maps/catalog.json` | Stable map IDs, paths and round durations |
| `scenes/`, `assets/` | Scenes, textures, audio and map data |

More: [Architecture](docs/architecture.md) · [Maps](docs/maps.md) · [Commands](docs/commands.md).

## Build from source

Use **Godot 4.7.2** and install its matching export templates. Open `project.godot`,
or use the following PowerShell commands with Godot available as `godot`:

```powershell
New-Item -ItemType Directory -Force build
godot --headless --editor --path . --import --quit
godot --headless --path . --export-release "Windows Desktop" build/Disaster2D.exe
```

The Windows export preset includes JSON metadata used by dynamic resource loading.
Distribute the exported EXE and PCK together. Engine binaries, caches and exported packages
are excluded from Git.

## Credits and license

Original game and GameMaker source: **Team Exe Empire**.
The original MIT notice is retained in [LICENSE.md](LICENSE.md).
Godot: [Godot Engine](https://godotengine.org/), distributed under the MIT license.
