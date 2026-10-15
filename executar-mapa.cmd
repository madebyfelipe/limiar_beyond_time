@echo off
setlocal
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
    echo Godot 4.7.2 nao encontrado em .tools\godot-4.7.2.
    pause
    exit /b 1
)
set "MAP=%~n1"
if "%MAP%"=="" set "MAP=exemplo"
"%GODOT_EXE%" --path "%~dp0." --scene res://environments/maps/map_runner.tscn -- "--map=res://maps/%MAP%.tscn"
exit /b %errorlevel%
