@echo off
rem Open the project in the Godot editor.
rem Same data redirect as Play.bat, so games run from the editor stay off C: too.
set "APPDATA=%~dp0appdata"
set "LOCALAPPDATA=%~dp0appdata\local"
start "" "%~dp0tools\godot\Godot_v4.7.1-stable_win64.exe" --path "%~dp0FindingNaresh" --editor
