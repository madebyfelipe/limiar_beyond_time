class_name VitalityGauge
extends Control
## The two-level green silhouette in the gameplay reference; no enclosing HUD.
var ratio: float = 1.0:
	set(value):
		if is_equal_approx(ratio, clampf(value, 0.0, 1.0)):
			return
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	var outer := PackedVector2Array([Vector2(0, 34), Vector2(130, 34), Vector2(185, 0), Vector2(455, 0), Vector2(455, 32), Vector2(193, 32), Vector2(139, 65), Vector2(0, 65)])
	var inner := PackedVector2Array([Vector2(5, 39), Vector2(134, 39), Vector2(189, 5), Vector2(450, 5), Vector2(450, 27), Vector2(189, 27), Vector2(135, 60), Vector2(5, 60)])
	draw_colored_polygon(outer, Color("03230c"))
	var border := outer.duplicate()
	border.append(outer[0])
	draw_polyline(border, Color("001205"), 9)
	draw_polyline(border, Color("a9ffad"), 3)
	# Clip the shaped interior rather than drawing a rectangular bar over scenery.
	var filled := PackedVector2Array()
	var cutoff: float = 5.0 + 445.0 * ratio
	var previous: Vector2 = inner[inner.size() - 1]
	for point: Vector2 in inner:
		var inside: bool = point.x <= cutoff
		var was_inside: bool = previous.x <= cutoff
		if inside != was_inside:
			var blend: float = (cutoff - previous.x) / (point.x - previous.x)
			filled.append(previous.lerp(point, blend))
		if inside:
			filled.append(point)
		previous = point
	if filled.size() >= 3 and ratio > 0.0:
		var colours := PackedColorArray()
		for point: Vector2 in filled:
			colours.append(Color("2aff16").lerp(Color("008708"), fmod(point.y, 34.0) / 34.0))
		draw_polygon(filled, colours)
