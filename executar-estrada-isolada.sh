#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
exec "$GODOT_EXE" --path "$ROOT" --scene res://environments/env1_road_probe.tscn "$@"
