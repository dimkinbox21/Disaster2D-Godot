@echo off
rem Launches the Disaster server (sibling folder on Desktop)
start "" "%~dp0..\DisasterServer-Godot\Godot\Godot.exe" --path "%~dp0..\DisasterServer-Godot"
