extends RefCounted
## Presentation only: the terrain is decorative; all navigable geometry is AreaMap.
const Console := preload("res://ui/inventory_console.gd")
const INK := Color("b4bfd1")
const MUTED := Color("728899")
const GOLD := Color("ff9e28")
const TERRAIN_BOUNDS := Rect2(-43, -64, 86, 94)
static var _terrain: Texture2D
static var _font: Font

static func font() -> Font:
	if _font == null:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Consolas", "Liberation Mono", "monospace"])
		system.font_weight = 700
		var tracked := FontVariation.new()
		tracked.base_font = system
		tracked.spacing_glyph = 1
		_font = tracked
	return _font

static func text(target: CanvasItem, at: Vector2, value: String, points: int = 24, color: Color = INK, width: float = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	target.draw_string(font(), at + Vector2(1, 2), value, align, width, points, Color.BLACK)
	target.draw_string(font(), at, value, align, width, points, color)

static func panel(target: CanvasItem, box: Rect2) -> void:
	Console.panel(target, box, Color("030a0f"))
	target.draw_rect(box.grow(-5), Color("182c39"), false, 2)
	target.draw_line(box.position + Vector2(16, 4), Vector2(box.end.x - 16, box.position.y + 4), Color("839098"), 1)
	for corner: Vector2 in [box.position, Vector2(box.end.x - 18, box.position.y), box.end - Vector2(18, 18), Vector2(box.position.x, box.end.y - 18)]:
		target.draw_line(corner + Vector2(3, 14), corner + Vector2(14, 3), Color("0a141c"), 3)

static func heading(target: CanvasItem, box: Rect2, caption: String) -> void:
	text(target, box.position + Vector2(24, 38), caption, 23)
	var start := box.position + Vector2(20, 48)
	var end := Vector2(box.end.x - 20, start.y)
	target.draw_line(start, end, Color("3c525e"), 1)
	target.draw_circle(start, 2, MUTED)
	target.draw_circle(end, 2, MUTED)

static func terrain() -> Texture2D:
	if _terrain == null:
		_terrain = load("res://assets/ui/map/snow_forest_atlas_v02.png")
	return _terrain
