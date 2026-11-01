@echo off
rem Starts Brandmauer from the project folder (no export needed).
rem Uses %GODOT% if set, otherwise the default download location.
if "%GODOT%"=="" set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot 4.7.2 nicht gefunden: %GODOT%
	echo Setze die Umgebungsvariable GODOT auf den Pfad zur Godot-Exe.
	pause
	exit /b 1
)
start "" "%GODOT%" --path "%~dp0.."
