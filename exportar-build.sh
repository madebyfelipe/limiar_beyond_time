#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
mkdir -p "$ROOT/builds/windows-t10"
"$GODOT_EXE" --headless --path "$ROOT" --export-release "Windows Desktop" "$ROOT/builds/windows-t10/LIMIAR-Recon.exe"
RESULT=$?
if [ "$RESULT" -eq 0 ]; then echo "Pronto: builds/windows-t10/LIMIAR-Recon.exe"; else echo "A exportacao falhou com codigo $RESULT."; fi
exit $RESULT
