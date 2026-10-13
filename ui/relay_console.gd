class_name RelayConsole
extends CanvasLayer
## The relay terminal waking up: firmware, an Arch Linux boot with its
## `[  OK  ]` lines, a login, the operator's journal read back, and the power
## dying under it. It only plays; there is no prompt to type into.
##
## Any interact, confirm or fire press finishes the block being written, so a
## second visit can be skipped through, but nothing is ever skipped unseen.

signal finished
## The journal has been read: the story beat is delivered even if the player
## skips the shutdown that follows.
signal log_read

const GREEN := Color("9cf2a2")
const DIM := Color("4f8f5a")
## Characters per second of a typed command and of journal lines scrolling in.
const TYPE_RATE := 26.0
const LOG_RATE := 95.0
## Lines kept on screen; the oldest scroll off the top, as on a real tty.
const MAX_LINES := 26

## Blocks of the sequence: text, how it appears and how long to wait after it.
## `type` writes character by character at `rate`; `line` appears at once.
const SCRIPT := [
	{"text": "LIMIAR RELAY R-2  //  BIOS 2.31  //  (C) LIMIAR FIELD SYSTEMS", "mode": "line", "pause": 0.35},
	{"text": "Memory test: 524288K OK", "mode": "line", "pause": 0.4},
	{"text": "Booting from disk 0 ...", "mode": "line", "pause": 0.6},
	{"text": ":: running early hook [udev]", "mode": "line", "pause": 0.12},
	{"text": "Starting systemd-udevd version 256.4-1-arch", "mode": "line", "pause": 0.12},
	{"text": ":: running hook [keymap]", "mode": "line", "pause": 0.1},
	{"text": "/dev/sda2: clean, 41822/1310720 files, 902114/5242880 blocks", "mode": "line", "pause": 0.3},
	{"text": "[  OK  ] Started Journal Service.", "mode": "line", "pause": 0.1},
	{"text": "[  OK  ] Reached target Local File Systems.", "mode": "line", "pause": 0.1},
	{"text": "[  OK  ] Started Network Time Synchronization.", "mode": "line", "pause": 0.15},
	{"text": "[FAILED] Failed to start Uplink to LIMIAR Station.", "mode": "line", "pause": 0.5},
	{"text": "See 'systemctl status relay-uplink.service' for details.", "mode": "line", "pause": 0.2},
	{"text": "[  OK  ] Started Relay Telemetry Logger.", "mode": "line", "pause": 0.1},
	{"text": "[  OK  ] Reached target Multi-User System.", "mode": "line", "pause": 0.5},
	{"text": "", "mode": "line", "pause": 0.05},
	{"text": "Arch Linux 6.9.7-arch1-1 (tty1)", "mode": "line", "pause": 0.3},
	{"text": "", "mode": "line", "pause": 0.05},
	{"text": "relay-r2 login: ", "mode": "line", "pause": 0.4, "join": true},
	{"text": "operator", "mode": "type", "pause": 0.3},
	{"text": "Password: ", "mode": "line", "pause": 0.9},
	{"text": "Last login: Tue Oct  6 03:12:44 on tty1", "mode": "line", "pause": 0.5},
	{"text": "[operator@relay-r2 ~]$ ", "mode": "line", "pause": 0.4, "join": true},
	{"text": "journalctl -u relay-log -n 5 --no-pager", "mode": "type", "pause": 0.5},
	{"text": "-- Journal begins at Mon 2026-09-28 06:00:00. --", "mode": "line", "pause": 0.4},
	{"text": "Oct 04 21:40 relay-r2 op[612]: Survey team AURORA overdue. Sector 4 radio silent since 17:05.", "mode": "log", "pause": 0.7},
	{"text": "Oct 05 02:13 relay-r2 op[612]: Pen camera 3 tripped. Something big moved along the fence. Footage corrupted.", "mode": "log", "pause": 0.7},
	{"text": "Oct 05 06:30 relay-r2 op[612]: Station ordered the outpost evacuated. I stay to keep the uplink alive.", "mode": "log", "pause": 0.7},
	{"text": "Oct 06 01:52 relay-r2 op[612]: Uplink down. Batteries at 18%. Scratching on the north wall again.", "mode": "log", "pause": 0.7},
	{"text": "Oct 06 03:12 relay-r2 op[612]: If anyone reads this: do not open the rear door after dark.", "mode": "log", "pause": 1.6, "read": true},
	{"text": "[operator@relay-r2 ~]$ ", "mode": "line", "pause": 1.2, "join": true},
	{"text": "", "mode": "line", "pause": 0.05},
	{"text": "kernel: ACPI: AC adapter [ADP0] offline", "mode": "line", "pause": 0.35},
	{"text": "relay-ups[221]: battery depleted - powering off", "mode": "line", "pause": 0.6},
]

## Speeds the whole sequence; probes raise it so the run stays short.
var speed: float = 1.0
var playing: bool = false
var screen: Control
var text: Label
var cursor_visible: bool = true

var _block: int = -1
var _shown: int = 0
var _wait: float = 0.0
var _carry: float = 0.0
var _lines: PackedStringArray = []
var _cursor_time: float = 0.0
var _powering_off: bool = false

func _ready() -> void:
	layer = 25
	var frame := AspectRatioContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.ratio = 16.0 / 9.0
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(frame)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	black.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(black)
	screen = Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.add_child(screen)
	var glow := ColorRect.new()
	glow.color = Color(0.03, 0.09, 0.05)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(glow)
	text = Label.new()
	text.name = "Text"
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 48
	text.offset_top = 36
	text.offset_right = -48
	text.offset_bottom = -36
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Liberation Mono", "monospace"])
	text.add_theme_font_override("font", font)
	text.add_theme_color_override("font_color", GREEN)
	text.add_theme_color_override("font_shadow_color", Color(0.2, 0.9, 0.35, 0.35))
	text.add_theme_constant_override("shadow_offset_x", 0)
	text.add_theme_constant_override("shadow_offset_y", 0)
	text.add_theme_constant_override("shadow_outline_size", 6)
	screen.add_child(text)
	black.resized.connect(func() -> void:
		text.add_theme_font_size_override("font_size", maxi(12, roundi(black.size.y / 1080.0 * 27.0))))
	hide()

func open() -> void:
	_lines = PackedStringArray([""])
	_block = -1
	_wait = 0.25
	_powering_off = false
	screen.scale = Vector2.ONE
	screen.modulate = Color.WHITE
	playing = true
	show()
	_render()

## How many blocks have been fully written; probes read progress from here.
func blocks_done() -> int:
	return maxi(0, _block)

func _process(delta: float) -> void:
	if not playing:
		return
	_cursor_time += delta
	cursor_visible = fmod(_cursor_time, 0.9) < 0.5
	if _powering_off:
		return
	if _wait > 0.0:
		_wait -= delta * speed
		_render()
		return
	if _block < 0 or _shown >= _length(_block):
		_next_block()
		return
	var rate: float = TYPE_RATE if SCRIPT[_block]["mode"] == "type" else LOG_RATE
	_carry += delta * speed * rate
	var count: int = int(_carry)
	if count > 0:
		_carry -= count
		_write(count)
	_render()

func _length(index: int) -> int:
	return String(SCRIPT[index]["text"]).length()

func _next_block() -> void:
	if _block >= 0:
		var done: Dictionary = SCRIPT[_block]
		if done.get("read", false):
			log_read.emit()
		_wait = float(done["pause"])
		if not done.get("join", false):
			_lines.append("")
	_block += 1
	_shown = 0
	_carry = 0.0
	if _block >= SCRIPT.size():
		_power_off()
		return
	if SCRIPT[_block]["mode"] == "line":
		_write(_length(_block))

func _write(count: int) -> void:
	var block: String = SCRIPT[_block]["text"]
	var piece: String = block.substr(_shown, count)
	_shown += piece.length()
	_lines[_lines.size() - 1] += piece
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)

func _render() -> void:
	var shown: PackedStringArray = _lines.duplicate()
	if cursor_visible and not _powering_off:
		shown[shown.size() - 1] += "_"
	text.text = "\n".join(shown)

## Finishes the block being written, so a press never skips text unseen.
func _unhandled_input(event: InputEvent) -> void:
	if not playing or _powering_off:
		return
	if event.is_echo() or not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("fire")):
		return
	get_viewport().set_input_as_handled()
	if _block >= 0 and _block < SCRIPT.size() and _shown < _length(_block):
		_write(_length(_block) - _shown)
	_wait = 0.0
	_render()

## The tube collapsing to a line and then to a dot, as the power dies.
func _power_off() -> void:
	_powering_off = true
	_render()
	var collapse := create_tween()
	screen.pivot_offset = screen.size * 0.5
	collapse.tween_property(screen, "modulate", Color(2.2, 2.2, 2.2), 0.08 / speed)
	collapse.tween_property(screen, "scale", Vector2(1.0, 0.004), 0.16 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse.tween_property(screen, "scale", Vector2(0.0, 0.004), 0.22 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse.tween_interval(0.35 / speed)
	await collapse.finished
	playing = false
	hide()
	finished.emit()
