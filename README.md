# Disaster 2D Remake — Godot port (клиент)

Порт **Sonic.exe The Disaster 2D Remake** (GameMaker, оригинал под MIT — Team Exe Empire)
на **Godot 4.7**. Это клиент; сервер — отдельный репозиторий [DisasterServer-Godot](https://github.com/dimkinbox21/DisasterServer-Godot).

## Запуск
1. Положи Godot 4.7 в папку `Godot\` (`Godot\Godot.exe`) — движок не хранится в репо.
2. `ИГРАТЬ.bat` — за EXE на карту «...», `КАРТА - ....bat` — выбор карты/персонажа.
3. Для сетевой игры: `ЗАПУСТИ СЕРВЕР.bat` из репо сервера (или из папки клиента, если она рядом).

Подробнее — `ИНСТРУКЦИЯ.txt`.

## Структура
- `assets/` — спрайты, звуки и данные конвертации из оригинала (`assets/gm/sprites.json`)
- `src/` — исходники: `src/game/` — игровые объекты (порты obj_*), `src/menu/` — база GMNode/меню
- `scenes/` — сцены карт, конвертируемые из комнат оригинала

Портируемые механики: движение/коллизии оригинала (scr_move_basic / scr_collision_basic),
Tails (полёт, зарядовая атака, HP/кольца/лечение, смерть → возрождение → демонизация),
лобби/нетплей, HUD раунда.
