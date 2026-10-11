@echo off
setlocal
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
    echo Godot 4.7.2 nao encontrado em .tools\godot-4.7.2.
    pause
    exit /b 1
)
echo Regressoes T09: probes headless e graficos em processos separados.
echo Janelas do Godot vao abrir e fechar sozinhas. Logs em .local\tests.
"%GODOT_EXE%" --headless --path "%~dp0." --script res://tests/run_all.gd -- %*
set "RESULT=%errorlevel%"
echo.
if "%RESULT%"=="0" (echo Todas as regressoes passaram.) else (echo Houve falhas: veja .local\tests\summary.txt)
pause
exit /b %RESULT%
