@echo off
setlocal
"%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0." --scene res://environments/technical_route.tscn %*
endlocal
