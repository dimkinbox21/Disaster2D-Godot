# Save data

Profiles live in the Godot user data directory (`user://`), outside the source tree.
The port uses the original formats: `1.bson` for settings, `2.bson` for unlocks and
`3.bin` for statistics and achievements.

## First launch

When no port profile exists, the game asks **Import save data from the original game?**
Profile initialization waits for a choice:

- **Import save** checks `%LOCALAPPDATA%\Sonicexe_The_Disaster_2D_Remake`.
  If the folder is missing, a directory picker opens. Invalid files show an error
  and allow another folder to be selected.
- **Start fresh** creates a new profile after confirmation.

The original files are read only. Imported files are validated first, and existing
port files are backed up before replacement. `first-launch.json` remembers the
choice, so the prompt does not repeat. Existing port profiles load without a prompt.

For an explicit manual import, launch the client with
`-- --import-original-save="C:\path\to\original\save"`.

## Source files

- `src/autoload/save_store.gd`: format readers, import, backup and startup barrier.
- `src/menu/first_run_import.gd`: English first-launch choice and folder picker.
- `src/autoload/game_config.gd`: settings.
- `src/autoload/unlockables.gd`: skins, palettes and purchased emotions.
- `src/autoload/achievements.gd`: saved statistics and achievements.
- `src/game/achievement_rules.gd`: progress and reward conditions.

Solo test and practice rounds do not award profile progress.
