@echo off
rem Играем за Тейлза (1=tails, 2=knux, 3=egg, 4=amy, 5=cream, 6=sally)
rem Дополнительно можно задать: set DISASTER_HP=40 / set DISASTER_RINGS=9
set DISASTER_CHAR=1
cd /d "%~dp0"
start "" "Godot\Godot.exe" --path . res://scenes/map_dotdotdot.tscn --resolution 960x540
