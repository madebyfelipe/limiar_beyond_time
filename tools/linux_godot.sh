# Sourced by the executar-*.sh launchers: the Linux side of the .cmd shortcuts.
# Finds Godot 4.7.2 in .tools/godot-4.7.2/, or takes $GODOT_EXE when it is set.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_EXE="${GODOT_EXE:-$ROOT/.tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}"
if [ ! -x "$GODOT_EXE" ]; then
	echo "Godot 4.7.2 nao encontrado em .tools/godot-4.7.2 (ou defina GODOT_EXE)." >&2
	exit 1
fi
