#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
"$GODOT_EXE" --headless --path "$ROOT" --script res://tests/run_all.gd -- "$@"
RESULT=$?
if [ "$RESULT" -eq 0 ]; then echo "Todas as regressoes passaram."; else echo "Houve falhas: veja .local/tests/summary.txt"; fi
exit $RESULT
