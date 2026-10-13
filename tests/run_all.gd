extends SceneTree
## T09 regression runner, no plugin. Each probe runs in a child process of the
## same Godot executable and passes only with exit code 0, its summary line
## and an output free of engine/script errors. Graphical probes need a display.
##   godot --headless --path . --script res://tests/run_all.gd
##   godot --headless --path . --script res://tests/run_all.gd -- --headless-only
##   godot --headless --path . --script res://tests/run_all.gd -- --only=operacao,unidades
## Logs: res://.local/tests/<probe>.log and summary.txt (ignored by Git).

const HEADLESS_FIXED: PackedStringArray = ["--headless", "--fixed-fps", "60"]
const GRAPHICAL_FIXED: PackedStringArray = ["--fixed-fps", "60"]
const PROBES: Array[Dictionary] = [
	{"name": "menu-inicial", "script": "res://tests/check_main_menu.gd", "args": HEADLESS_FIXED, "summary": "MAIN_MENU failures=0"},
	{"name": "menu-inicial-grafico", "script": "res://tests/check_main_menu.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "MAIN_MENU failures=0"},
	{"name": "unidades", "script": "res://tests/check_units.gd", "args": HEADLESS_FIXED, "summary": "units failures=0"},
	{"name": "cenas", "script": "res://tests/check_scenes.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "locomocao", "script": "res://tests/check_locomotion.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "cameras", "script": "res://tests/check_cameras.gd", "args": HEADLESS_FIXED, "summary": "per direction failures=0"},
	{"name": "referencia", "script": "res://tests/check_movement_reference.gd", "args": HEADLESS_FIXED, "summary": "T05 failures=0"},
	{"name": "calibracao-estudos", "script": "res://tests/check_calibration.gd", "args": HEADLESS_FIXED, "extra": ["--study", "--acceptance"], "summary": "mode=acceptance failures=0"},
	{"name": "calibracao-ferramentas", "script": "res://tests/check_calibration.gd", "args": HEADLESS_FIXED, "summary": "mode=tooling failures=0"},
	{"name": "percurso", "script": "res://tests/check_technical_route.gd", "args": HEADLESS_FIXED, "summary": "T07 failures=0"},
	{"name": "operacao", "script": "res://tests/check_operation.gd", "args": HEADLESS_FIXED, "summary": "T08 failures=0"},
	{"name": "env1-estrada", "script": "res://tests/check_env1_road_probe.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "env1-continuidade", "script": "res://tests/check_env1_continuity.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "sala-geometria", "script": "res://tests/check_save_room.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "exterior-geometria", "script": "res://tests/check_exterior.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "perimetro", "script": "res://tests/check_perimeter.gd", "args": HEADLESS_FIXED, "summary": "PERIMETER ticks="},
	{"name": "rele", "script": "res://tests/check_relay_room.gd", "args": HEADLESS_FIXED, "summary": "RELAY_ROOM ticks="},
	{"name": "dylan-portas", "script": "res://tests/check_dylan_doors.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "controles-tanque", "script": "res://tests/check_tank_controls.gd", "args": HEADLESS_FIXED, "summary": "TANK controls"},
	{"name": "gamepad", "script": "res://tests/check_gamepad.gd", "args": HEADLESS_FIXED, "summary": "GAMEPAD failures=0"},
	{"name": "gamepad-grafico", "script": "res://tests/check_gamepad.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "GAMEPAD failures=0"},
	{"name": "configuracoes", "script": "res://tests/check_settings.gd", "args": HEADLESS_FIXED, "summary": "SETTINGS failures=0"},
	{"name": "configuracoes-grafico", "script": "res://tests/check_settings.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "SETTINGS failures=0"},
	{"name": "contato-pes", "script": "res://tests/check_foot_contact.gd", "args": HEADLESS_FIXED, "summary": "FOOT contact"},
	{"name": "keleken-animacao", "script": "res://tests/check_keleken_animation.gd", "args": HEADLESS_FIXED, "summary": "KELEKEN animation bones=24 clips=9 failures=0"},
	{"name": "keleken-wander", "script": "res://tests/check_keleken_wander.gd", "args": HEADLESS_FIXED, "summary": "KELEKEN wander failures=0"},
	{"name": "salvamento", "script": "res://tests/check_save_persistence.gd", "args": HEADLESS_FIXED, "summary": "SAVE persistence"},
	{"name": "terminal-ui", "script": "res://tests/check_terminal_ui.gd", "args": HEADLESS_FIXED, "summary": "TERMINAL_UI failures=0"},
	{"name": "terminal-ui-grafico", "script": "res://tests/check_terminal_ui.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "TERMINAL_UI failures=0"},
	{"name": "operacao-cenarios", "script": "res://tests/check_level_operation.gd", "args": HEADLESS_FIXED, "summary": "OPERATION levels"},
	{"name": "combate", "script": "res://tests/check_combat.gd", "args": HEADLESS_FIXED, "summary": " failures=0"},
	{"name": "combate-inimigo", "script": "res://tests/check_enemy_combat.gd", "args": HEADLESS_FIXED, "summary": "ENEMY_COMBAT failures=0"},
	{"name": "esquiva", "script": "res://tests/check_dodge_presentation.gd", "args": HEADLESS_FIXED, "summary": "DODGE_PRESENTATION failures=0"},
	{"name": "transicoes", "script": "res://tests/check_dylan_transitions.gd", "args": HEADLESS_FIXED, "summary": "DYLAN_TRANSITIONS failures=0"},
	{"name": "rifle", "script": "res://tests/check_rifle.gd", "args": HEADLESS_FIXED, "summary": "RIFLE failures=0"},
	{"name": "cena-principal", "script": "", "args": ["--headless", "--quit-after", "30"], "summary": ""},
	{"name": "robustez-10min", "script": "res://tests/check_soak.gd", "args": HEADLESS_FIXED, "summary": "T10 soak minutes=10.0"},
	# One lap of the route takes most of 45 s; on a loaded machine physics falls
	# behind the wall clock and the only lap missed the window once. 75 s leaves room.
	{"name": "benchmark-funcional", "script": "", "args": ["--headless"], "extra": ["--benchmark", "--warmup=0", "--duration=75"], "summary": "execução funcional OK"},
	{"name": "composicao", "script": "res://tests/check_composition.gd", "args": [], "graphical": true, "summary": "T01 failures=0"},
	{"name": "oclusao", "script": "res://tests/check_occlusion.gd", "args": [], "graphical": true, "summary": "T02 failures=0"},
	{"name": "distancia-30", "script": "res://tests/check_distance.gd", "args": ["--disable-vsync", "--max-fps", "30"], "graphical": true, "summary": "ticks=120"},
	{"name": "distancia-60", "script": "res://tests/check_distance.gd", "args": ["--disable-vsync", "--max-fps", "60"], "graphical": true, "summary": "ticks=120"},
	{"name": "distancia-144", "script": "res://tests/check_distance.gd", "args": ["--disable-vsync", "--max-fps", "144"], "graphical": true, "summary": "ticks=120"},
	{"name": "renderizacao", "script": "res://tests/check_route_rendering.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "rendering failures=0"},
	{"name": "percurso-grafico", "script": "res://tests/check_technical_route.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "T07 failures=0"},
	{"name": "operacao-grafica", "script": "res://tests/check_operation.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "T08 failures=0"},
	{"name": "sala-grafica", "script": "res://tests/check_save_room.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": " failures=0"},
	{"name": "exterior-grafico", "script": "res://tests/check_exterior.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": " failures=0"},
	{"name": "perimetro-grafico", "script": "res://tests/check_perimeter.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "PERIMETER ticks="},
	{"name": "rele-grafico", "script": "res://tests/check_relay_room.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "RELAY_ROOM ticks="},
	{"name": "dylan-portas-grafico", "script": "res://tests/check_dylan_doors.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": " failures=0"},
	{"name": "filtro-retro", "script": "res://tests/check_retro_filter.gd", "args": GRAPHICAL_FIXED, "graphical": true, "summary": "RETRO failures=0"},
]
## Engine lines that mean failure, whatever the exit code says.
const ERROR_PREFIXES: PackedStringArray = ["ERROR:", "SCRIPT ERROR:", "USER ERROR:", "Parse Error"]
const TIMEOUT_MS: int = 1800000

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var options: PackedStringArray = OS.get_cmdline_user_args()
	var headless_only: bool = options.has("--headless-only")
	var only: PackedStringArray = []
	for option: String in options:
		if option.begins_with("--only="):
			only = option.trim_prefix("--only=").split(",", false)
	var log_dir: String = ProjectSettings.globalize_path("res://.local/tests")
	DirAccess.make_dir_recursive_absolute(log_dir)
	var results: PackedStringArray = []
	var failed: int = 0
	var executed: int = 0
	for probe: Dictionary in PROBES:
		if not only.is_empty() and not only.has(probe.name):
			continue
		if headless_only and probe.get("graphical", false):
			results.append("SKIP  %-24s gráfico (--headless-only)" % probe.name)
			continue
		executed += 1
		var outcome: Dictionary = await execute(probe, log_dir)
		var line: String = "%s  %-24s %6.1f s  %s" % ["OK  " if outcome.passed else "FALHA", probe.name, outcome.seconds, outcome.reason]
		results.append(line)
		print(line)
		if not outcome.passed:
			failed += 1
	var summary: String = "\n".join(results) + "\nT09 runner executed=%d failed=%d" % [executed, failed]
	var file := FileAccess.open(log_dir.path_join("summary.txt"), FileAccess.WRITE)
	if file:
		file.store_string(summary + "\n")
	print("\n", summary)
	quit(0 if failed == 0 and executed > 0 else 1)

func execute(probe: Dictionary, log_dir: String) -> Dictionary:
	var args: PackedStringArray = ["--path", ProjectSettings.globalize_path("res://"), "--audio-driver", "Dummy"]
	args.append_array(probe.args)
	if probe.script != "":
		args.append_array(["--script", probe.script])
	if probe.has("extra"):
		args.append("--")
		args.append_array(probe.extra)
	var started: int = Time.get_ticks_msec()
	var info: Dictionary = OS.execute_with_pipe(OS.get_executable_path(), args, false)
	if info.is_empty():
		return {"passed": false, "seconds": 0.0, "reason": "processo não iniciou"}
	var pid: int = info.pid
	var stdio: FileAccess = info.stdio
	var stderr: FileAccess = info.stderr
	var output: PackedByteArray = []
	var timed_out: bool = false
	while true:
		var chunk: PackedByteArray = stdio.get_buffer(65536)
		var chunk_err: PackedByteArray = stderr.get_buffer(65536)
		output.append_array(chunk)
		output.append_array(chunk_err)
		if chunk.is_empty() and chunk_err.is_empty():
			if not OS.is_process_running(pid):
				break
			if Time.get_ticks_msec() - started > TIMEOUT_MS:
				OS.kill(pid)
				timed_out = true
				break
			OS.delay_msec(20)
		await process_frame
	var code: int = OS.get_process_exit_code(pid)
	var text: String = output.get_string_from_utf8()
	var log := FileAccess.open(log_dir.path_join(probe.name + ".log"), FileAccess.WRITE)
	if log:
		log.store_string("$ godot %s\n\n%s" % [" ".join(args), text])
	var errors: PackedStringArray = []
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		for prefix: String in ERROR_PREFIXES:
			if line.begins_with(prefix):
				errors.append(line)
				break
	var reason: String = "saída %d" % code
	var passed: bool = code == 0 and errors.is_empty() and not timed_out
	if timed_out:
		reason = "tempo esgotado"
	elif not errors.is_empty():
		reason += " · %d erro(s): %s" % [errors.size(), errors[0]]
	if probe.summary != "":
		var summary_line: String = ""
		for line: String in text.split("\n"):
			if line.contains(probe.summary):
				summary_line = line.strip_edges()
		if summary_line == "":
			passed = false
			reason += " · resumo ausente ('%s')" % probe.summary
		else:
			reason += " · " + summary_line.left(150)
	return {"passed": passed, "seconds": (Time.get_ticks_msec() - started) / 1000.0, "reason": reason}
