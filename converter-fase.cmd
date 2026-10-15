@echo off
setlocal
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
    echo Godot 4.7.2 nao encontrado em .tools\godot-4.7.2.
    pause
    exit /b 1
)
if "%~1"=="" (
    echo Uso: converter-fase.cmd exterior^|sala^|perimetro^|rele^|patio-servico^|percurso [--force]
    exit /b 1
)
"%GODOT_EXE%" --headless --path "%~dp0." --script res://tools/map_from_level.gd -- %*
exit /b %errorlevel%
