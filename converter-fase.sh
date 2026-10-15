#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
# Copia uma fase pronta para um mapa editável em maps/:
#   ./converter-fase.sh exterior|sala|perimetro|rele|patio-servico|percurso [--force]
if [ -z "$1" ]; then echo "Uso: ./converter-fase.sh exterior|sala|perimetro|rele|patio-servico|percurso [--force]" >&2; exit 1; fi
exec "$GODOT_EXE" --headless --path "$ROOT" --script res://tools/map_from_level.gd -- "$@"
