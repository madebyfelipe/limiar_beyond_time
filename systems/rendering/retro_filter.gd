class_name RetroFilter
extends Control
## One shared presentation setting for gameplay and the isolated door cinematic.
## The effect samples the finished composition from a layer above the interface,
## so the HUD and the menus get the same treatment as the scene.
##
## There is no fixed list of looks: the pixelation is a step and every effect is
## its own switch, so a player assembles the screen they want. Adding an effect
## is a uniform in the shader plus a row in EFFECTS below.

## Virtual framebuffer steps. Every width divides 1280 and 1920 exactly, which
## is what keeps one virtual pixel a whole number of screen pixels at the window
## sizes the project tests; a step that did not divide them would show seams.
const PIXEL_STEPS: Array[Dictionary] = [
	{"name": "desligado", "size": Vector2.ZERO},
	{"name": "leve", "size": Vector2(1280.0, 720.0)},
	{"name": "médio", "size": Vector2(640.0, 360.0)},
	{"name": "PSX", "size": Vector2(320.0, 180.0)},
]

## How a virtual pixel reaches the window: hard blocks or blended neighbours.
const SCALING: Array[String] = ["mais próximo", "bilinear"]

enum Effect { COLOR, SCANLINES, GRILLE, CURVE, VIGNETTE }

## Each switch: the label a menu shows, the shader uniform it drives, the
## strength it applies, and how much light it takes away.
const EFFECTS: Array[Dictionary] = [
	{"id": Effect.COLOR, "name": "Cor reduzida", "dial": "quantize", "strength": 1.0, "gain": 1.0},
	{"id": Effect.SCANLINES, "name": "Linhas de varredura", "dial": "scanline", "strength": 0.55, "gain": 1.38},
	{"id": Effect.GRILLE, "name": "Grade de abertura", "dial": "grille", "strength": 0.32, "gain": 1.07},
	{"id": Effect.CURVE, "name": "Tela de tubo", "dial": "curve", "strength": 0.55, "gain": 1.0},
	{"id": Effect.VIGNETTE, "name": "Cantos escuros", "dial": "vignette", "strength": 0.26, "gain": 1.07},
]

## Scanlines any finer than this stop reading as lines: at 360 bands a 720-row
## window gives each one a single pixel, and resampling averages them back into
## flat grey. Measured, not guessed -- see RETRO_PRESETS.md.
const MAX_SCANLINE_ROWS := 240.0

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "video"

## Master switch, on F4. Off is the untouched composition, for calibration work.
static var enabled: bool = true
## Index into PIXEL_STEPS. "médio" by default: the filter now also covers the
## interface, and 320x180 chews menu text past reading.
static var pixel_step: int = 2
## Index into SCALING. Nearest by default, the look the project was tuned on.
static var scaling: int = 0
static var effects: Dictionary = {}
static var _loaded: bool = false

@export var allow_mode_input: bool = true
## The 16:9 composition this filter covers. The filter sits in a layer above the
## interface, so the effect reaches the HUD and the menus too; it therefore
## cannot be laid out by the composition and copies that rect each frame
## instead. Left empty, the filter keeps whatever rect its parent gives it,
## which is what the door cinematic needs.
@export var follow: Control
@onready var effect: ColorRect = $Effect
@onready var back_buffer: BackBufferCopy = $BackBufferCopy
@onready var mode_notice: Label = $ModeNotice
var notice_seconds: float = 0.0
var last_span: Vector2 = Vector2.ZERO
var last_origin: Vector2 = Vector2.INF

## Reduced colour alone is the look the project ships with; the screen effects
## are opt-in, because they are a matter of taste.
static func _defaults() -> Dictionary:
	return {Effect.COLOR: true, Effect.SCANLINES: false, Effect.GRILLE: false,
		Effect.CURVE: false, Effect.VIGNETTE: false}

## Reads the stored choice once per process. Probes run through --script and
## keep the documented defaults instead of inheriting what a player picked.
static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	effects = _defaults()
	if OS.get_cmdline_args().has("--script"):
		return
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	enabled = bool(file.get_value(SECTION, "enabled", true))
	pixel_step = clampi(int(file.get_value(SECTION, "pixels", pixel_step)), 0, PIXEL_STEPS.size() - 1)
	scaling = clampi(int(file.get_value(SECTION, "scaling", scaling)), 0, SCALING.size() - 1)
	for row: Dictionary in EFFECTS:
		effects[row["id"]] = bool(file.get_value(SECTION, "effect_%d" % int(row["id"]), effects[row["id"]]))

## A probe ignores the stored choice and must not write one either, or running
## the suite would change the settings of whoever plays on this machine.
static func _store() -> void:
	if OS.get_cmdline_args().has("--script"):
		return
	var file := ConfigFile.new()
	file.load(SETTINGS_PATH)
	file.set_value(SECTION, "enabled", enabled)
	file.set_value(SECTION, "pixels", pixel_step)
	file.set_value(SECTION, "scaling", scaling)
	for row: Dictionary in EFFECTS:
		file.set_value(SECTION, "effect_%d" % int(row["id"]), bool(effects[row["id"]]))
	file.save(SETTINGS_PATH)

## Pushes the current settings to every live filter. Takes a node because the
## settings are static while reaching the filters needs a tree.
static func refresh(from: Node, show_notice: bool = false) -> void:
	ensure_loaded()
	_store()
	from.get_tree().call_group(&"retro_filters", &"_apply_settings", show_notice)

static func set_enabled(from: Node, value: bool, show_notice: bool = false) -> void:
	ensure_loaded()
	enabled = value
	refresh(from, show_notice)

static func set_pixel_step(from: Node, value: int) -> void:
	ensure_loaded()
	pixel_step = clampi(value, 0, PIXEL_STEPS.size() - 1)
	refresh(from)

static func set_scaling(from: Node, value: int) -> void:
	ensure_loaded()
	scaling = clampi(value, 0, SCALING.size() - 1)
	refresh(from)

static func scaling_name() -> String:
	ensure_loaded()
	return SCALING[scaling]

static func set_effect(from: Node, id: int, value: bool) -> void:
	ensure_loaded()
	effects[id] = value
	refresh(from)

static func is_effect_on(id: int) -> bool:
	ensure_loaded()
	return bool(effects.get(id, false))

static func pixel_name() -> String:
	ensure_loaded()
	return String(PIXEL_STEPS[pixel_step]["name"])

## Short summary for the on-screen notice and for a menu row.
static func describe() -> String:
	ensure_loaded()
	if not enabled:
		return "Desligado"
	var parts: PackedStringArray = ["Pixels: " + pixel_name()]
	# Blending only means something while there are virtual pixels to blend.
	if PIXEL_STEPS[pixel_step]["size"] != Vector2.ZERO and scaling != 0:
		parts[0] += " " + scaling_name()
	for row: Dictionary in EFFECTS:
		if effects[row["id"]]:
			parts.append(String(row["name"]))
	return " · ".join(parts)

func _ready() -> void:
	add_to_group(&"retro_filters")
	ensure_loaded()
	if follow:
		# Full-rect anchors would re-stretch this to the window every layout pass
		# and swallow the letterbox bars; following means owning the rect.
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		_follow_composition()
	_apply_settings()
	_update_span()

func _apply_settings(show_notice: bool = false) -> void:
	var material: ShaderMaterial = effect.material as ShaderMaterial
	var gain: float = 1.0
	var any_effect: bool = false
	for row: Dictionary in EFFECTS:
		var on: bool = enabled and bool(effects[row["id"]])
		material.set_shader_parameter(String(row["dial"]), float(row["strength"]) if on else 0.0)
		if on:
			gain *= float(row["gain"])
			any_effect = true
	material.set_shader_parameter("gain", gain)
	var step: Vector2 = PIXEL_STEPS[pixel_step]["size"]
	var pixelated: bool = enabled and step != Vector2.ZERO
	material.set_shader_parameter("virtual_resolution", step if pixelated else size.max(Vector2.ONE))
	material.set_shader_parameter("scanline_rows", minf(step.y if pixelated else size.y, MAX_SCANLINE_ROWS))
	material.set_shader_parameter("smoothing", 1.0 if pixelated and scaling == 1 else 0.0)
	# With nothing switched on there is nothing to sample for, so the pass and
	# its copy of the screen are skipped outright.
	effect.visible = pixelated or any_effect
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if effect.visible else BackBufferCopy.COPY_MODE_DISABLED
	if show_notice:
		mode_notice.text = "F4  ·  " + describe()
		notice_seconds = 2.5
		mode_notice.show()

func _unhandled_key_input(event: InputEvent) -> void:
	if allow_mode_input and event.is_action_pressed(&"cycle_retro_filter") and not event.is_echo():
		set_enabled(self, not enabled, true)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if follow:
		_follow_composition()
	_update_span()
	if notice_seconds > 0.0:
		notice_seconds -= delta
		mode_notice.visible = notice_seconds > 0.0

func _follow_composition() -> void:
	global_position = follow.global_position
	size = follow.size

func _update_span() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var span := size / viewport_size
	var origin := global_position / viewport_size
	if span == last_span and origin == last_origin:
		return
	last_span = span
	last_origin = origin
	var material: ShaderMaterial = effect.material as ShaderMaterial
	material.set_shader_parameter("screen_span", span)
	material.set_shader_parameter("screen_origin", origin)
	# With pixelation off the framebuffer is the composition itself, so the
	# resolution has to follow the rect rather than a fixed step.
	if PIXEL_STEPS[pixel_step]["size"] == Vector2.ZERO:
		material.set_shader_parameter("virtual_resolution", size.max(Vector2.ONE))
		material.set_shader_parameter("scanline_rows", minf(size.y, MAX_SCANLINE_ROWS))
