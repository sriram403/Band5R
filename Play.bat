@echo off
rem Launch the Finding Naresh prototype.
rem Godot keeps user data (settings, logs, shader cache) under %APPDATA%, which
rem is on C:. Point it at this folder instead, for this process only.
set "APPDATA=%~dp0appdata"
set "LOCALAPPDATA=%~dp0appdata\local"
rem If any script is newer than Godot's list of script classes (after an
rem update), import first, or a new class is unknown and the game shows a
rem grey screen. Takes a few seconds, only then.
set "CACHE=%~dp0FindingNaresh\.godot\global_script_class_cache.cfg"
powershell -NoProfile -Command "$c='%CACHE%'; $n=(Get-ChildItem -Recurse -Filter *.gd '%~dp0FindingNaresh\scripts' | Sort-Object LastWriteTime | Select-Object -Last 1).LastWriteTime; if (-not (Test-Path $c) -or (Get-Item $c).LastWriteTime -lt $n) { exit 1 } else { exit 0 }"
if errorlevel 1 (
	echo Updating the game's script list, a few seconds...
	"%~dp0tools\godot\Godot_v4.7.1-stable_win64_console.exe" --headless --path "%~dp0FindingNaresh" --import >nul 2>&1
	if exist "%CACHE%" copy /b "%CACHE%" +,, "%CACHE%" >nul
)
start "" "%~dp0tools\godot\Godot_v4.7.1-stable_win64.exe" --path "%~dp0FindingNaresh"
