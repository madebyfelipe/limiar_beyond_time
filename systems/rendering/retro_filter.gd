extends Control
## One shared presentation setting for gameplay and the isolated door cinematic.
## The effect samples the finished 2D + 3D composition, before the readable HUD.

enum Mode { ORIGINAL, PSX, CRT }
const MODE_NAMES: Array[String] = ["Original", "PSX", "PSX + CRT"]
static var selected_mode: int = Mode.PSX

@export var allow_mode_input: bool = true
@onready var effect: ColorRect = $Effect
@onready var back_buffer: BackBufferCopy = $BackBufferCopy
@onready var mode_notice: Label = $ModeNotice
var notice_seconds: float = 0.0
var last_span: Vector2 = Vector2.ZERO
var last_origin: Vector2 = Vector2.INF

func _ready() -> void:
	add_to_group(&"retro_filters")
	_apply_mode()
	_update_span()

func set_mode(value: int, show_notice: bool = false) -> void:
	selected_mode = clampi(value, Mode.ORIGINAL, Mode.CRT)
	get_tree().call_group(&"retro_filters", &"_apply_mode")
	if show_notice:
		mode_notice.text = "F4  ·  " + MODE_NAMES[selected_mode]
		notice_seconds = 2.5
		mode_notice.show()

func _apply_mode() -> void:
	effect.visible = selected_mode != Mode.ORIGINAL
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if effect.visible else BackBufferCopy.COPY_MODE_DISABLED
	(effect.material as ShaderMaterial).set_shader_parameter("crt_enabled", selected_mode == Mode.CRT)

func _unhandled_key_input(event: InputEvent) -> void:
	if allow_mode_input and event.is_action_pressed(&"cycle_retro_filter") and not event.is_echo():
		set_mode((selected_mode + 1) % MODE_NAMES.size(), true)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_update_span()
	if notice_seconds > 0.0:
		notice_seconds -= delta
		mode_notice.visible = notice_seconds > 0.0

func _update_span() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var span := size / viewport_size
	var origin := global_position / viewport_size
	if span != last_span or origin != last_origin:
		last_span = span
		last_origin = origin
		(effect.material as ShaderMaterial).set_shader_parameter("screen_span", span)
		(effect.material as ShaderMaterial).set_shader_parameter("screen_origin", origin)
