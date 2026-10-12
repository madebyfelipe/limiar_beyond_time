extends Control
## Selection belongs to the enemy; the existing 3D ring shows the actual shot.

var weapon: PlayerWeapon
var marker_position: Vector2
var marker_offscreen: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		hide()

func _process(_delta: float) -> void:
	visible = weapon != null and weapon.aiming and weapon.uses_locked_aim() and weapon._locked_valid()
	if visible:
		queue_redraw()

func _draw() -> void:
	if weapon == null or not weapon._locked_valid():
		return
	var camera: Camera3D = weapon.player.camera
	if camera == null or size.x < 1.0 or size.y < 1.0:
		return
	var point: Vector3 = weapon.target.aim_point()
	var behind: bool = camera.is_position_behind(point)
	var at: Vector2 = camera.unproject_position(point) / Vector2(camera.get_viewport().get_visible_rect().size) * size
	var margin: float = minf(size.x, size.y) * 0.07
	var bounds := Rect2(Vector2.ONE * margin, size - Vector2.ONE * margin * 2.0)
	marker_offscreen = behind or not bounds.has_point(at)
	var direction: Vector2 = at - size * 0.5
	if behind:
		var local: Vector3 = camera.to_local(point)
		direction = Vector2(local.x, -local.y)
	if marker_offscreen:
		if direction.is_zero_approx():
			direction = Vector2.DOWN
		var half: Vector2 = bounds.size * 0.5
		var ratio: float = maxf(absf(direction.x) / half.x, absf(direction.y) / half.y)
		at = size * 0.5 + direction / ratio
	marker_position = at
	var color := Color("ffad66") if weapon.lock_blocked() else Color("64d6e0")
	var radius: float = maxf(12.0, size.y * 0.016)
	if marker_offscreen:
		var forward: Vector2 = direction.normalized()
		var side := Vector2(-forward.y, forward.x)
		draw_colored_polygon(PackedVector2Array([at + forward * radius, at - forward * radius + side * radius * 0.6, at - forward * radius - side * radius * 0.6]), color)
	else:
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var start: Vector2 = at + corner * radius
			draw_line(start, start - Vector2(corner.x * radius * 0.6, 0), color, 2.0)
			draw_line(start, start - Vector2(0, corner.y * radius * 0.6), color, 2.0)
	var caption: String = "BLOCKED" if weapon.lock_blocked() else "TARGET"
	var font: Font = ThemeDB.fallback_font
	var font_size: int = maxi(20, int(size.y * 0.024))
	var text_width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var label_at := Vector2(clampf(at.x - text_width * 0.5, 8.0, size.x - text_width - 8.0), maxf(font_size + 8.0, at.y - radius - 8.0))
	draw_string(font, label_at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
