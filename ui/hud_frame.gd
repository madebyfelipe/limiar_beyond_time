class_name HudFrame
extends MarginContainer
## Angular PSX-era panel in the Dino Crisis 2 idiom: a translucent dark field, a
## faint hairline box, bright bracket corners and an optional header rule. It is
## drawn rather than sliced from a bitmap, so it stays one pixel thin at any
## window size and needs no art pass.
##
## A MarginContainer, so the panel is measured by what it holds: adding a menu
## item grows the frame instead of spilling past its border.

@export var line: Color = Color("64d6e0")
@export var fill: Color = Color(0.016, 0.055, 0.078, 0.93)
## Length of the bracket arms at each corner, in pixels.
@export_range(0.0, 200.0) var bracket: float = 34.0
## Distance from the top to the header rule. Zero draws no rule.
@export_range(0.0, 400.0) var header: float = 0.0

func _ready() -> void:
	# Redraw on resize: the brackets are measured from the current corners.
	resized.connect(queue_redraw)

func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, fill)
	# The continuous outline stays faint; the corners carry the shape.
	draw_rect(box, Color(line, line.a * 0.3), false, 1.0)
	if header > 0.0 and header < size.y:
		draw_line(Vector2(0.0, header), Vector2(size.x, header), Color(line, line.a * 0.5), 1.0)
	var arm: float = minf(bracket, minf(size.x, size.y) * 0.5)
	for corner: Array in [[Vector2.ZERO, 1.0, 1.0], [Vector2(size.x, 0.0), -1.0, 1.0],
			[Vector2(0.0, size.y), 1.0, -1.0], [Vector2(size.x, size.y), -1.0, -1.0]]:
		var at: Vector2 = corner[0]
		# Pulled half a line inside, so the stroke lands on the panel, not astride it.
		at += Vector2(1.5 * float(corner[1]), 1.5 * float(corner[2]))
		draw_line(at, at + Vector2(arm * float(corner[1]), 0.0), line, 3.0)
		draw_line(at, at + Vector2(0.0, arm * float(corner[2])), line, 3.0)
