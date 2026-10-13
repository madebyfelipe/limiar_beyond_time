extends SceneTree
## Builds the relay room's spatial source: the boxes that own collision and,
## until plates are painted, also the look of the room.
##   godot --headless --path . --script res://tools/build_relay_room_source.gd
## Writes res://environments/relay_room_source.tscn. Rerunning replaces it, so
## edit the layout here rather than in the editor.
##
## Unlike the guardhouse room (a single 6 × 5 box seen from one corner), this is
## an equipment room inside the relay shed's 6,6 × 5 m footprint: relay racks
## line the north wall, a battery bank on the west and a conduit column in the
## middle turn the floor into an L, the terminal sits on the east wall, a high
## window looks out to the north, and there are two doors, front and rear.
##
## Local axes as in the levels: +X east, -Z north, floor top at y = 0.

const OUTPUT := "res://environments/relay_room_source.tscn"
## Interior half extents; walls are 0,2 m thick outside these.
const HALF_X := 3.0
const HALF_Z := 2.2
const HEIGHT := 2.8
const WALL := 0.2
## North wall openings, east to west: rear door and window.
const REAR_DOOR := Vector2(1.85, 2.75)
const DOOR_HEIGHT := 2.05
const WINDOW := Vector2(0.2, 1.1)
const WINDOW_SILL := 1.45
const WINDOW_HEAD := 2.05
## South wall opening: the front door, in from the trail.
const FRONT_DOOR := Vector2(1.35, 2.25)

var source: Node3D
var materials: Dictionary = {}

func _initialize() -> void:
	source = Node3D.new()
	source.name = "RelayRoomSource"
	_build()
	var packed := PackedScene.new()
	var error: Error = packed.pack(source)
	if error == OK:
		error = ResourceSaver.save(packed, OUTPUT)
	print("RELAY_ROOM_SOURCE nodes=%d colliders=%d %s" % [source.get_child_count(), _collider_count(), error_string(error)])
	source.free()
	quit(0 if error == OK else 1)

func _collider_count() -> int:
	var count := 0
	for child: Node in source.get_children():
		if child.has_meta("collision_size"):
			count += 1
	return count

func _material(key: String, color: Color, emission: float = 0.0, texture: Texture2D = null) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if texture != null:
		material.albedo_texture = texture
		material.uv1_triplanar = true
		material.uv1_scale = Vector3.ONE * 0.7
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	materials[key] = material
	return material

## A box by its centre and size. With `solid`, the room builds a collider of
## the same size from it; without, it is only seen.
func box(name: String, centre: Vector3, size: Vector3, material: Material, solid: bool = true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = centre
	if solid:
		mesh.set_meta("collision_size", size)
	source.add_child(mesh)
	mesh.owner = source
	return mesh

## A wall segment between two x (or z) values and two heights.
func wall_x(name: String, x0: float, x1: float, z: float, y0: float, y1: float, material: Material) -> void:
	box(name, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z), Vector3(x1 - x0, y1 - y0, WALL), material)

func _build() -> void:
	var concrete := _material("concrete", Color("55595a"))
	var paint := _material("paint", Color("7a877f"))
	var trim := _material("trim", Color("3e4744"))
	var rack := _material("rack", Color("262c31"))
	var battery := _material("battery", Color("4b5241"))
	var desk := _material("desk", Color("4c4842"))
	var steel := _material("steel", Color("5d6a6c"), 0.0, load("res://assets/textures/doors/painted_steel_v01.png"))
	var screen := _material("screen", Color("74f08a"), 1.6)
	var led := _material("led", Color("ffb347"), 2.5)
	# Dim enough that the fitting, in frame at the top, does not wash out the
	# objective line drawn over it; the light itself comes from the OmniLight.
	var lamp := _material("lamp", Color("b9b29f"), 0.7)
	var emergency := _material("emergency", Color("ff2a1c"), 0.6)
	var night := _material("night", Color("0b1420"))
	var snow := _material("snow", Color("9aa7b4"))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.7, 0.8, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1

	var outer_x: float = HALF_X + WALL
	var outer_z: float = HALF_Z + WALL
	box("Floor", Vector3(0, -0.1, 0), Vector3(outer_x * 2, 0.2, outer_z * 2), concrete)
	box("Ceiling", Vector3(0, HEIGHT + 0.1, 0), Vector3(outer_x * 2, 0.2, outer_z * 2), trim, false)
	box("WallWest", Vector3(-HALF_X - WALL * 0.5, HEIGHT * 0.5, 0), Vector3(WALL, HEIGHT, outer_z * 2), paint)
	box("WallEast", Vector3(HALF_X + WALL * 0.5, HEIGHT * 0.5, 0), Vector3(WALL, HEIGHT, outer_z * 2), paint)
	# North wall, cut for the window and the rear door.
	var north: float = -HALF_Z - WALL * 0.5
	wall_x("WallNorthWest", -outer_x, WINDOW.x, north, 0, HEIGHT, paint)
	wall_x("WindowSill", WINDOW.x, WINDOW.y, north, 0, WINDOW_SILL, paint)
	wall_x("WindowHead", WINDOW.x, WINDOW.y, north, WINDOW_HEAD, HEIGHT, paint)
	wall_x("WallNorthMiddle", WINDOW.y, REAR_DOOR.x, north, 0, HEIGHT, paint)
	wall_x("RearDoorHead", REAR_DOOR.x, REAR_DOOR.y, north, DOOR_HEIGHT, HEIGHT, paint)
	wall_x("WallNorthEast", REAR_DOOR.y, outer_x, north, 0, HEIGHT, paint)
	# The leaf closes the opening, so the wall stays solid where the door is.
	box("RearDoor", Vector3((REAR_DOOR.x + REAR_DOOR.y) * 0.5, DOOR_HEIGHT * 0.5, north), Vector3(REAR_DOOR.y - REAR_DOOR.x, DOOR_HEIGHT, WALL), steel)
	box("RearDoorHandle", Vector3(REAR_DOOR.x + 0.12, 1.02, north + WALL * 0.5 + 0.03), Vector3(0.05, 0.18, 0.05), trim, false)
	box("WindowGlass", Vector3((WINDOW.x + WINDOW.y) * 0.5, (WINDOW_SILL + WINDOW_HEAD) * 0.5, north), Vector3(WINDOW.y - WINDOW.x, WINDOW_HEAD - WINDOW_SILL, 0.02), glass, false)
	# South wall, cut for the front door.
	var south: float = HALF_Z + WALL * 0.5
	wall_x("WallSouthWest", -outer_x, FRONT_DOOR.x, south, 0, HEIGHT, paint)
	wall_x("FrontDoorHead", FRONT_DOOR.x, FRONT_DOOR.y, south, DOOR_HEIGHT, HEIGHT, paint)
	wall_x("WallSouthEast", FRONT_DOOR.y, outer_x, south, 0, HEIGHT, paint)
	box("FrontDoor", Vector3((FRONT_DOOR.x + FRONT_DOOR.y) * 0.5, DOOR_HEIGHT * 0.5, south), Vector3(FRONT_DOOR.y - FRONT_DOOR.x, DOOR_HEIGHT, WALL), steel)
	# Relay racks along the west half of the north wall, lights facing south.
	for index: int in range(3):
		var x: float = -2.5 + 0.85 * index
		box("Rack%s" % ["A", "B", "C"][index], Vector3(x, 1.1, -1.88), Vector3(0.8, 2.2, 0.6), rack)
		for row: int in range(4):
			box("RackLed%d%d" % [index, row], Vector3(x - 0.22 + 0.15 * (row % 3), 1.75 - 0.32 * row, -1.57), Vector3(0.05, 0.03, 0.02), led, false)
	# Battery bank on the west side: the floor becomes an L around it.
	box("BatteryBank", Vector3(-2.35, 0.5, 0.75), Vector3(1.1, 1.0, 1.7), battery)
	for cell: int in range(3):
		box("BatteryCap%d" % cell, Vector3(-2.35, 1.03, 0.2 + 0.55 * cell), Vector3(0.9, 0.06, 0.35), trim, false)
	# A low transformer in front of the racks closes the gap along them, so the
	# west half is walked round its south side. Kept under the camera's sight
	# lines to the window, the terminal and the rear door: a full-height column
	# here hid the rear door and the walk to it.
	box("Transformer", Vector3(-0.3, 0.55, -0.9), Vector3(0.9, 1.1, 0.8), battery)
	box("TransformerFins", Vector3(-0.3, 0.6, -0.48), Vector3(0.8, 0.9, 0.04), trim, false)
	# Conduit runs overhead instead, along the ceiling to the racks.
	box("ConduitTray", Vector3(-0.6, HEIGHT - 0.25, -1.3), Vector3(4.6, 0.08, 0.3), trim, false)
	# Cable trench from the racks to the desk, flush with the floor.
	box("CableTrench", Vector3(0.0, 0.004, -1.35), Vector3(5.0, 0.01, 0.35), trim, false)
	# Terminal on the east wall.
	box("Desk", Vector3(2.65, 0.38, -0.35), Vector3(0.7, 0.76, 1.5), desk)
	box("Monitor", Vector3(2.78, 1.0, -0.35), Vector3(0.42, 0.44, 0.5), rack, false)
	box("TerminalScreen", Vector3(2.565, 1.0, -0.35), Vector3(0.02, 0.32, 0.4), screen, false)
	box("Keyboard", Vector3(2.45, 0.775, -0.35), Vector3(0.2, 0.03, 0.46), trim, false)
	# Lamps: the ceiling fitting and the red emergency lamp over the rear door.
	# Toward the camera's corner, above its frame: at the ceiling's centre the
	# fitting sat right behind the objective line.
	box("CeilingLamp", Vector3(-0.6, HEIGHT - 0.06, 1.0), Vector3(1.2, 0.08, 0.25), lamp, false)
	box("EmergencyLamp", Vector3((REAR_DOOR.x + REAR_DOOR.y) * 0.5, 2.45, -HALF_Z + 0.08), Vector3(0.25, 0.12, 0.12), emergency, false)
	# What the window shows: snow and the night behind the shed.
	box("OutsideGround", Vector3(0.6, -0.05, -6.0), Vector3(10, 0.1, 7), snow, false)
	box("OutsideNight", Vector3(0.6, 3.0, -9.5), Vector3(14, 8, 0.2), night, false)
