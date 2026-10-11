extends SceneTree
## Run after the editor imports the three freshly authored PNG files.
func _initialize() -> void:
	for index: int in range(1,4):
		var path := "res://resources/route_study/shot_%d.tres" % index
		var sheet: CalibrationDefinition = load(path)
		sheet.background = load("res://assets/backgrounds/route_study/shot_%d.png" % index)
		assert(sheet.background != null)
		assert(ResourceSaver.save(sheet,path) == OK)
	quit()
