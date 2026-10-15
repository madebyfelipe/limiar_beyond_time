#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
exec "$GODOT_EXE" --path "$ROOT" --scene res://environments/save_room.tscn "$@"
