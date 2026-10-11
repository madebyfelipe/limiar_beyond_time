extends SceneTree
## T09: every project scene loads, instantiates and runs a few frames without
## engine or script errors. Errors are captured in-process with a Logger, so
## the probe fails on its own even when its output is not inspected.

class ErrorCapture extends Logger:
	var errors: PackedStringArray = []
	var mutex := Mutex.new()
	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		errors.append("%s:%d %s %s" % [file, line, code, rationale])
		mutex.unlock()
	func _log_message(_message: String, _error: bool) -> void:
		pass

const ROOTS: PackedStringArray = ["res://environments", "res://actors", "res://ui"]
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func collect(path: String, found: PackedStringArray) -> void:
	for file: String in ResourceLoader.list_directory(path):
		if file.ends_with("/"):
			collect(path.path_join(file.trim_suffix("/")), found)
		elif file.ends_with(".tscn"):
			found.append(path.path_join(file))

func run() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	var scenes: PackedStringArray = []
	for path: String in ROOTS:
		collect(path, scenes)
	scenes.sort()
	check(scenes.size() >= 16,"Scene inventory unexpectedly small: %d" % scenes.size())
	check(scenes.has(ProjectSettings.get_setting("application/run/main_scene")),"Main scene missing from inventory")
	var capture := ErrorCapture.new()
	OS.add_logger(capture)
	for path: String in scenes:
		var before: int = capture.errors.size()
		var packed: PackedScene = load(path)
		check(packed != null,"Scene did not load: %s" % path)
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		check(instance != null,"Scene did not instantiate: %s" % path)
		if instance == null:
			continue
		root.add_child(instance)
		for frame: int in range(5):
			await physics_frame
			await process_frame
		paused = false
		instance.queue_free()
		await process_frame
		var new_errors: PackedStringArray = capture.errors.slice(before)
		check(new_errors.is_empty(),"%s produced errors: %s" % [path, "\n".join(new_errors)])
		print("T09 scene ", path, " errors=", new_errors.size())
	OS.remove_logger(capture)
	print("T09 scenes=", scenes.size(), " failures=", failures)
	quit(0 if failures == 0 else 1)
