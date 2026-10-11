@tool
extends Node2D

@export var study: Control

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var definition: CalibrationDefinition = study.definition
	if definition == null or study.background == null or not study.show_markers:
		return
	var font: Font = ThemeDB.fallback_font
	for index: int in range(definition.reference_pixels.size()):
		var expected: Vector2 = study.source_to_frame(definition.reference_pixels[index])
		draw_line(expected - Vector2(9,0), expected + Vector2(9,0), Color.MAGENTA, 2)
		draw_line(expected - Vector2(0,9), expected + Vector2(0,9), Color.MAGENTA, 2)
		var label := ("A" if definition.is_anchor(index) else "") + str(index+1)
		draw_string(font, expected + Vector2(12,-8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.MAGENTA)
		if index < definition.reference_world.size() and not study.camera.is_position_behind(definition.reference_world[index]):
			var actual: Vector2 = study.camera.unproject_position(definition.reference_world[index])
			actual *= study.background.size / Vector2(study.viewport.size)
			draw_circle(actual, 5, Color.LIME_GREEN)
			draw_line(expected, actual, Color.YELLOW, 1)
