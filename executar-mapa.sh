#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
# Joga um mapa de maps/: ./executar-mapa.sh exterior  (sem nome: exemplo)
MAP="${1:-exemplo}"; shift || true
exec "$GODOT_EXE" --path "$ROOT" --scene res://environments/maps/map_runner.tscn -- "--map=res://maps/${MAP%.tscn}.tscn" "$@"
