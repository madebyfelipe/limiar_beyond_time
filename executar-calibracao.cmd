@echo off
setlocal
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
    echo Godot 4.7.2 nao encontrado em .tools\godot-4.7.2.
    pause
    exit /b 1
)
echo Previa T06: calibracao estatica, ainda nao aprovada.
"%GODOT_EXE%" --path "%~dp0." --scene res://environments/calibration_env1.tscn %*
exit /b %errorlevel%
