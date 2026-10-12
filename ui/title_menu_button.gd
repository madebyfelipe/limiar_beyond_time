extends Button
## Native focus/input semantics over a transparent, distressed red selection.
static var title_font: Font

static func font() -> Font:
	if title_font == null:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Consolas", "Liberation Mono", "monospace"])
		system.font_weight = 700
		system.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		var tracked := FontVariation.new()
		tracked.base_font = system
		tracked.spacing_glyph = 5
		title_font = tracked
	return title_font

func _ready() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", font())
	add_theme_font_size_override("font_size", 38)
	add_theme_color_override("font_color", Color("b7bcc4"))
	add_theme_color_override("font_hover_color", Color("f2e9dc"))
	add_theme_color_override("font_focus_color", Color("f2e9dc"))
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_color_override("font_disabled_color", Color("59616b"))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	add_theme_constant_override("shadow_offset_x", 3)
	add_theme_constant_override("shadow_offset_y", 3)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 48
	empty.content_margin_right = 16
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("disabled", empty)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, 0.6, 1])
	gradient.colors = PackedColorArray([Color(0.52, 0.025, 0.025, 0.86), Color(0.36, 0.018, 0.018, 0.66), Color(0.18, 0.008, 0.008, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 64
	var selected := StyleBoxTexture.new()
	selected.texture = texture
	selected.content_margin_left = 48
	selected.content_margin_right = 16
	for state: String in ["hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, selected)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(func() -> void:
		if not disabled:
			grab_focus())

func _draw() -> void:
	if not has_focus() or disabled:
		return
	# Sparse grain breaks up the bar without putting noise over the lettering.
	for i: int in range(90):
		var at := Vector2(posmod(i * 73, int(size.x)), posmod(i * 31, int(size.y)))
		draw_rect(Rect2(at, Vector2(3, 2)), Color(0.01, 0.01, 0.015, 0.10))
