@echo off
rem Launch the Finding Naresh prototype.
rem Godot keeps user data (settings, logs, shader cache) under %APPDATA%, which
rem is on C:. Point it at this folder instead, for this process only.
set "APPDATA=%~dp0appdata"
set "LOCALAPPDATA=%~dp0appdata\local"
start "" "%~dp0tools\godot\Godot_v4.7.1-stable_win64.exe" --path "%~dp0FindingNaresh"
