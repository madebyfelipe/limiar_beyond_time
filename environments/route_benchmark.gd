class_name RouteBenchmark
extends Node
## Opt-in autopilot (`-- --benchmark`): drives the real controller around the
## route through Input actions, restarting after each completed lap, and
## records wall-clock frame times after a warm-up. Works in exported release
## builds, which accept neither --script nor --scene. Writes
## user://benchmark.txt and user://benchmark-frametimes.csv, then quits:
## exit 0 only if p95 ≤ budget, no engine errors and at least one lap. Under
## --headless nothing renders, so only the functional part is judged.
## Options: --warmup=S (30) --duration=S (120) --budget-ms=X (16.7).

class ErrorCapture extends Logger:
	var errors: PackedStringArray = []
	var mutex := Mutex.new()
	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		errors.append("%s:%d %s %s" % [file, line, code, rationale])
		mutex.unlock()
	func _log_message(_message: String, _error: bool) -> void:
		pass

const OUTWARD: Array[Vector3] = [Vector3(-2.5,0,9),Vector3(-2.5,0,2),Vector3(0,0,2),Vector3(0,0,-4),Vector3(0,0.6,-8),Vector3(0,1.2,-11),Vector3(0,1.2,-15),Vector3(3.8,1.2,-15),Vector3(3.8,1.2,-20),Vector3(0,1.2,-23)]
const RETURN: Array[Vector3] = [Vector3(3.8,1.2,-20),Vector3(3.8,1.2,-15),Vector3(0,1.2,-15),Vector3(0,1.2,-11),Vector3(0,0,-4),Vector3(0,0,2),Vector3(2.5,0,2),Vector3(2.5,0,9),Vector3(0,0,9)]

var route: Control
var player: PlayerController
var warmup: float = 30.0
var duration: float = 120.0
var budget_ms: float = 16.7
var waypoints: Array[Vector3] = []
var waypoint: int = 0
var lap: int = 0
var completions: int = 0
var started_usec: int = 0
var last_usec: int = 0
var samples: PackedFloat64Array = []
var capture := ErrorCapture.new()
var done: bool = false
var window_checked: bool = false

func _ready() -> void:
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--warmup="):
			warmup = option.trim_prefix("--warmup=").to_float()
		elif option.begins_with("--duration="):
			duration = option.trim_prefix("--duration=").to_float()
		elif option.begins_with("--budget-ms="):
			budget_ms = option.trim_prefix("--budget-ms=").to_float()
	# Keeps sampling frames if someone pauses; gameplay itself stays paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = route.player
	route.progress.route_completed.connect(func(_elapsed: float) -> void: completions += 1)
	OS.add_logger(capture)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_begin_lap()
	started_usec = Time.get_ticks_usec()

func _begin_lap() -> void:
	waypoints = OUTWARD.duplicate()
	waypoints.append_array(RETURN)
	waypoint = 0

func _process(_delta: float) -> void:
	if done:
		return
	var now: int = Time.get_ticks_usec()
	var elapsed: float = (now-started_usec)/1000000.0
	if elapsed >= warmup and last_usec > 0:
		samples.append((now-last_usec)/1000.0)
	last_usec = now
	if not window_checked and elapsed > 1.0:
		# Fullscreen can be refused (e.g. no window manager): fall back to a 1080p window.
		window_checked = true
		if DisplayServer.get_name() != "headless" and DisplayServer.window_get_size() != Vector2i(1920,1080):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1920,1080))
	if elapsed >= warmup+duration:
		_finish()
		return
	_steer()

func _steer() -> void:
	if waypoint >= waypoints.size():
		_release()
		lap += 1
		route.restart()
		_begin_lap()
		return
	var delta: Vector3 = waypoints[waypoint]-player.global_position
	delta.y = 0
	if delta.length() < 0.15:
		waypoint += 1
		return
	var direction: Vector3 = delta.normalized()
	var right: Vector3 = player.movement_reference.right
	var back: Vector3 = player.movement_reference.back
	if not player.movement_reference.locked:
		right = Vector3(player.camera.global_basis.x.x,0,player.camera.global_basis.x.z).normalized()
		back = Vector3(player.camera.global_basis.z.x,0,player.camera.global_basis.z.z).normalized()
	var input := Vector2(direction.dot(right),direction.dot(back))
	for pair: Array in [["move_right",input.x],["move_left",-input.x],["move_down",input.y],["move_up",-input.y]]:
		if pair[1] > 0.001:
			Input.action_press(pair[0],pair[1])
		else:
			Input.action_release(pair[0])
	# Outward walking on even laps, running otherwise; slow down near targets.
	if (waypoint >= OUTWARD.size() or lap % 2 == 1) and delta.length() > 1.0:
		Input.action_press("run")
	else:
		Input.action_release("run")

func _release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func _percentile(sorted: PackedFloat64Array, fraction: float) -> float:
	return sorted[clampi(int(ceil(fraction*sorted.size()))-1,0,sorted.size()-1)]

func _finish() -> void:
	done = true
	_release()
	OS.remove_logger(capture)
	var report: PackedStringArray = []
	report.append("LIMIAR benchmark %s · Godot %s · %s" % [ProjectSettings.get_setting("application/config/version"),Engine.get_version_info().string,"exportado" if OS.has_feature("template") else "editor/fonte"])
	report.append("adaptador=\"%s\" driver=%s janela=%s vsync=%d 3D=1920x1080" % [RenderingServer.get_video_adapter_name(),RenderingServer.get_current_rendering_driver_name(),DisplayServer.window_get_size(),DisplayServer.window_get_vsync_mode()])
	var passed: bool = false
	if samples.is_empty():
		report.append("nenhum quadro amostrado")
	else:
		var sorted: PackedFloat64Array = samples.duplicate()
		sorted.sort()
		var total: float = 0.0
		var over: int = 0
		for value: float in samples:
			total += value
			if value > budget_ms:
				over += 1
		var count: int = samples.size()
		var p95: float = _percentile(sorted,0.95)
		report.append("aquecimento_s=%.0f medido_s=%.1f quadros=%d voltas=%d conclusoes=%d erros=%d" % [warmup,total/1000.0,count,lap,completions,capture.errors.size()])
		report.append("media_ms=%.2f p50_ms=%.2f p95_ms=%.2f p99_ms=%.2f max_ms=%.2f fps_medio=%.1f acima_do_orcamento=%.1f%%" % [total/count,_percentile(sorted,0.5),p95,_percentile(sorted,0.99),sorted[count-1],1000.0*count/total,100.0*over/count])
		var functional: bool = capture.errors.is_empty() and completions >= 1
		if DisplayServer.get_name() == "headless":
			# Nothing is rendered: only the functional run (laps, errors) counts.
			passed = functional
			report.append("gate=NÃO MEDIDO (headless não renderiza) · execução funcional %s (erros %d; conclusões %d)" % ["OK" if functional else "FALHOU",capture.errors.size(),completions])
		else:
			passed = p95 <= budget_ms and functional
			report.append("gate=%s (p95 %.2f ms; orçamento %.1f ms; erros %d; conclusões %d)" % ["APROVADO" if passed else "REPROVADO",p95,budget_ms,capture.errors.size(),completions])
		var csv := FileAccess.open("user://benchmark-frametimes.csv",FileAccess.WRITE)
		if csv:
			csv.store_line("frame,ms")
			for index: int in range(count):
				csv.store_line("%d,%.4f" % [index,samples[index]])
	for error: String in capture.errors.slice(0,10):
		report.append("erro: " + error)
	var text: String = "\n".join(report)
	var file := FileAccess.open("user://benchmark.txt",FileAccess.WRITE)
	if file:
		file.store_string(text + "\n")
	print(text)
	print("Relatório: ", ProjectSettings.globalize_path("user://benchmark.txt"))
	get_tree().quit(0 if passed else 1)
