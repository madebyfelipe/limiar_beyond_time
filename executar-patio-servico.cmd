@echo off
setlocal
rem Pass --dinos to put an animal on every home: executar-patio-servico.cmd --dinos
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" exit /b 1
"%GODOT_EXE%" --path "%~dp0." --scene res://environments/service_yard.tscn -- %*
