#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
# Abre o editor do Godot no projeto; o mapa pedido (nome em maps/) já vem aberto.
if [ -n "$1" ]; then exec "$GODOT_EXE" --path "$ROOT" --editor "res://maps/${1%.tscn}.tscn"; fi
exec "$GODOT_EXE" --path "$ROOT" --editor
