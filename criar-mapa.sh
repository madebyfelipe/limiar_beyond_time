#!/usr/bin/env bash
source "$(dirname "$0")/tools/linux_godot.sh"
# Cria maps/<nome>.tscn a partir do modelo: ./criar-mapa.sh meu_mapa
if [ -z "$1" ]; then echo "Uso: ./criar-mapa.sh nome_do_mapa" >&2; exit 1; fi
"$GODOT_EXE" --headless --path "$ROOT" --script res://tools/new_map.gd -- "$1" || exit $?
echo "Abra no editor: ./editar-mapas.sh $1   Jogue: ./executar-mapa.sh $1"
