@echo off
setlocal
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT_EXE%" (
    echo Godot 4.7.2 nao encontrado em .tools\godot-4.7.2.
    pause
    exit /b 1
)
if not exist "%~dp0builds\windows-t10" mkdir "%~dp0builds\windows-t10"
echo Exportando build release Windows x64 para builds\windows-t10 ...
"%GODOT_EXE%" --headless --path "%~dp0." --export-release "Windows Desktop" "%~dp0builds\windows-t10\LIMIAR-Recon.exe"
set "RESULT=%errorlevel%"
if "%RESULT%"=="0" (echo Pronto: builds\windows-t10\LIMIAR-Recon.exe) else (echo A exportacao falhou com codigo %RESULT%.)
pause
exit /b %RESULT%
