#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
echo "Medindo pelo projeto. Nao use o computador durante 2,5 minutos."
exec "$GODOT_EXE" --path "$ROOT" -- --benchmark "$@"
