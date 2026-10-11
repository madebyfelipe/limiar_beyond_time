@echo off
setlocal
rem Gate T10: 30 s de aquecimento + 120 s de percurso automatico, VSync desligado.
rem Usa a build exportada se existir; caso contrario, o projeto pela engine local.
set "BUILD_EXE=%~dp0builds\windows-t10\LIMIAR-Recon.console.exe"
set "GODOT_EXE=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if exist "%BUILD_EXE%" (
    echo Medindo a build exportada. Nao use o computador durante 2,5 minutos.
    "%BUILD_EXE%" -- --benchmark %*
) else (
    if not exist "%GODOT_EXE%" (
        echo Nem a build nem o Godot 4.7.2 foram encontrados.
        pause
        exit /b 1
    )
    echo Build nao encontrada: medindo pelo projeto. Nao use o computador durante 2,5 minutos.
    "%GODOT_EXE%" --path "%~dp0." -- --benchmark %*
)
set "RESULT=%errorlevel%"
echo.
echo Relatorio completo: %APPDATA%\Godot\app_userdata\LIMIAR Recon\benchmark.txt
pause
exit /b %RESULT%
