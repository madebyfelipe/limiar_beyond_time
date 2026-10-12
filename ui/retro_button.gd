class_name RetroButton
extends Button
## Native Button semantics, with a drawn angular CRT outline and live cursor.
func _ready() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_override("font", RetroScreen.font())
	add_theme_color_override("font_color", Color("88c7c9"))
	add_theme_color_override("font_hover_color", Color("d2ffe0"))
	add_theme_color_override("font_focus_color", Color("d2ffe0"))
	add_theme_color_override("font_pressed_color", Color("d2ffe0"))
	add_theme_color_override("font_disabled_color", Color("49666c"))
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.018, 0.08, 0.10, 0.92) if state == "normal" else Color(0.04, 0.19, 0.17, 0.94)
		style.content_margin_left = 72
		style.content_margin_right = 22
		add_theme_stylebox_override(state, style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(func() -> void: grab_focus(); queue_redraw())
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	var active: bool = (has_focus() or is_hovered()) and not disabled
	var ink := Color("b4ffd2") if active else Color("46858b")
	if disabled:
		ink = Color("35545b")
	var w: float = size.x - 3
	var h: float = size.y - 3
	var cut: float = minf(18, h * 0.23)
	var outline := PackedVector2Array([Vector2(cut, 3), Vector2(w - cut, 3), Vector2(w, cut), Vector2(w, h - cut), Vector2(w - cut, h), Vector2(cut, h), Vector2(3, h - cut), Vector2(3, cut), Vector2(cut, 3)])
	draw_polyline(outline, ink, 3 if active else 2, true)
	if active:
		draw_colored_polygon(PackedVector2Array([Vector2(30, h * 0.3), Vector2(30, h * 0.7), Vector2(50, h * 0.5)]), ink)
