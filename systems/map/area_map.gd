class_name AreaMap
extends RefCounted
## The Episode 1 site plan and what Dylan has seen of it. Static, like
## MissionState and SupplyStock, so it survives the door transitions without an
## autoload; SAVE records the visited rooms next to the objective.
##
## Plan coordinates are schematic metres with north up: x runs east and y runs
## south, as x and z do in the levels. A room carries the rectangles drawn on
## the map and, once it has a scene, the pieces of that scene's floor they stand
## for, which is what turns a position in a level into a point on the plan.
##
## Eight rooms are declared, four of them without a scene yet: the plan is the
## whole episode, and a room that is not built is a sealed door on the map.

## A door no objective opens: the room behind it is not built yet.
const SEALED := -1

## List order is the order of the MAP tab. `layer` 1 is drawn over layer 0: the
## guardhouse stands inside its yard.
const ROOMS: Array[Dictionary] = [
	{
		"id": &"exterior", "name": "GUARDHOUSE YARD", "layer": 0,
		"scene": "res://environments/exterior.tscn",
		"preview": "res://assets/backgrounds/dc2_psx/exterior_cam02.png",
		"shapes": [Rect2(-11, -7, 17, 17), Rect2(-2.5, 10, 5, 6)],
		# The 19 m of road are drawn as a 6 m stub with an arrow past it.
		"parts": [
			{"world": Rect2(-11, -7, 17, 17), "plan": Rect2(-11, -7, 17, 17)},
			{"world": Rect2(-2.5, 10, 5, 19), "plan": Rect2(-2.5, 10, 5, 6)},
		],
		"exit": {"at": Vector2(0, 16), "label": "TO ACCESS ROAD"},
		# The barrier gate the first objective sends Dylan to.
		"mark": Vector2(1.7, 8.4),
	},
	{
		"id": &"guardhouse", "name": "GUARDHOUSE", "layer": 1,
		"scene": "res://environments/save_room.tscn",
		"preview": "res://assets/backgrounds/dc2_psx/guardhouse_cam01.png",
		"shapes": [Rect2(-7.7, -3.2, 5.4, 6.4)],
		# The room's door is on its west wall and the building's is on the south
		# face, so the floor goes on the plan a quarter turn round.
		"parts": [{"world": Rect2(-3, -2.5, 6, 5), "plan": Rect2(-7.7, -3.2, 5.4, 6.4), "quarter": 1}],
		"save": Vector2(-6.35, 0.05),
		"mark": Vector2(-4.2, 1.5),
	},
	{
		"id": &"trail", "name": "PERIMETER TRAIL", "layer": 0,
		"scene": "res://environments/perimeter.tscn",
		"preview": "res://assets/backgrounds/dc2_psx/perimeter_cam02.png",
		"shapes": [Rect2(-3.2, -25, 6.4, 18)],
		# 27 m of trail on 18 m of plan.
		"parts": [{"world": Rect2(-3.2, -26.9, 6.4, 27.4), "plan": Rect2(-3.2, -25, 6.4, 18)}],
	},
	{
		"id": &"relay", "name": "RELAY ROOM", "layer": 1,
		"scene": "res://environments/relay_room.tscn",
		"preview": "res://assets/backgrounds/dc2_psx/relay_powered.png",
		"shapes": [Rect2(-3.3, -30, 6.6, 5)],
		"parts": [{"world": Rect2(-3, -2.2, 6, 4.4), "plan": Rect2(-3.3, -30, 6.6, 5)}],
	},
	{
		"id": &"service_yard", "name": "SERVICE YARD", "layer": 0,
		# The level is the plan at 4/3 of its metres, in the trail's coordinates.
		# Until it has a plate, its preview is the geometry of its first view.
		"scene": "res://environments/service_yard.tscn",
		"preview": "res://assets/backgrounds/service_yard/geometry_cam01.png",
		"shapes": [Rect2(-9, -44, 18, 14), Rect2(-9, -52, 5, 8)],
		"parts": [
			{"world": Rect2(-12, -50.5, 24, 18.5), "plan": Rect2(-9, -44, 18, 14)},
			{"world": Rect2(-12, -61, 6.5, 10.5), "plan": Rect2(-9, -52, 5, 8)},
		],
		"mark": Vector2(0, -38),
	},
	{
		"id": &"quarters", "name": "CREW QUARTERS", "layer": 1,
		"scene": "", "preview": "",
		"shapes": [Rect2(9, -40, 6, 5)],
		"parts": [],
		"save": Vector2(12, -37.5),
	},
	{
		"id": &"kennel", "name": "KENNEL BLOCK", "layer": 1,
		"scene": "", "preview": "",
		"shapes": [Rect2(-11, -30, 6.5, 23)],
		"parts": [],
	},
	{
		"id": &"generator", "name": "GENERATOR HOUSE", "layer": 1,
		"scene": "", "preview": "",
		"shapes": [Rect2(-4, -52, 9, 8)],
		"parts": [],
	},
]

## `wide` doors sit in a wall that runs east-west. A door opens at the stage
## that releases it in the levels.
const DOORS: Array[Dictionary] = [
	{"id": &"guardhouse_door", "at": Vector2(-4.45, 3.2), "wide": true, "rooms": [&"exterior", &"guardhouse"], "opens_at": MissionState.Stage.ROAD},
	{"id": &"north_gate", "at": Vector2(0, -7), "wide": true, "rooms": [&"exterior", &"trail"], "opens_at": MissionState.Stage.DONE},
	{"id": &"relay_front", "at": Vector2(0, -25), "wide": true, "rooms": [&"trail", &"relay"], "opens_at": MissionState.Stage.RELAY},
	{"id": &"relay_rear", "at": Vector2(2.4, -30), "wide": true, "rooms": [&"relay", &"service_yard"], "opens_at": MissionState.Stage.OUTAGE},
	{"id": &"quarters_door", "at": Vector2(9, -37.5), "wide": false, "rooms": [&"service_yard", &"quarters"], "opens_at": SEALED},
	{"id": &"generator_front", "at": Vector2(1, -44), "wide": true, "rooms": [&"service_yard", &"generator"], "opens_at": SEALED},
	{"id": &"generator_side", "at": Vector2(-4, -48), "wide": false, "rooms": [&"service_yard", &"generator"], "opens_at": SEALED},
	{"id": &"kennel_north", "at": Vector2(-7, -30), "wide": true, "rooms": [&"service_yard", &"kennel"], "opens_at": SEALED},
	{"id": &"kennel_south", "at": Vector2(-8, -7), "wide": true, "rooms": [&"exterior", &"kennel"], "opens_at": SEALED},
]

## Where each objective points. The last stage is the end of the content.
const OBJECTIVE_ROOM := {
	MissionState.Stage.ROAD: &"exterior",
	MissionState.Stage.YARD: &"guardhouse",
	MissionState.Stage.TERMINAL: &"guardhouse",
	MissionState.Stage.DONE: &"trail",
	MissionState.Stage.PERIMETER: &"relay",
	MissionState.Stage.RELAY: &"relay",
	MissionState.Stage.RELAY_ROOM: &"relay",
	MissionState.Stage.OUTAGE: &"service_yard",
}

## Rooms the objective cannot have reached without passing through them. A save
## from before the map existed gets its rooms from here.
const REACHED_BY := [
	[MissionState.Stage.ROAD, &"exterior"],
	[MissionState.Stage.TERMINAL, &"guardhouse"],
	[MissionState.Stage.PERIMETER, &"trail"],
	[MissionState.Stage.RELAY_ROOM, &"relay"],
	[MissionState.Stage.REAR_YARD, &"service_yard"],
]

## Room ids Dylan has stood in, used as a set.
static var visited: Dictionary = {}
## Bumped whenever a room is added, so a screen knows to draw again.
static var revision: int = 0

static func room(id: StringName) -> Dictionary:
	for entry: Dictionary in ROOMS:
		if entry["id"] == id:
			return entry
	return {}

## Where a position in a level falls on the plan: `room`, `point` and the
## `quarter` turns that `heading` needs. Empty for a scene the plan does not
## cover. A position off every piece of floor counts as the nearest one.
static func locate(scene: String, at: Vector3) -> Dictionary:
	var point := Vector2(at.x, at.z)
	var best: Dictionary = {}
	var nearest := INF
	for entry: Dictionary in ROOMS:
		if scene.is_empty() or entry["scene"] != scene:
			continue
		for part: Dictionary in entry["parts"]:
			var world: Rect2 = part["world"]
			var gap := Vector2(maxf(maxf(world.position.x - point.x, point.x - world.end.x), 0.0), maxf(maxf(world.position.y - point.y, point.y - world.end.y), 0.0)).length()
			if gap >= nearest:
				continue
			nearest = gap
			var plan: Rect2 = part["plan"]
			var quarter: int = part.get("quarter", 0)
			var inside: Vector2 = (point.clamp(world.position, world.end) - world.position) / world.size
			for turn: int in range(quarter):
				inside = Vector2(inside.y, 1.0 - inside.x)
			best = {"room": entry["id"], "point": plan.position + inside * plan.size, "quarter": quarter}
	return best

## A facing in a level as a direction on the plan.
static func heading(facing: Vector3, quarter: int = 0) -> Vector2:
	var direction := Vector2(facing.x, facing.z)
	for turn: int in range(quarter):
		direction = Vector2(direction.y, -direction.x)
	return direction.normalized()

## Called while the level runs: marks the room under the player as visited and
## returns its id, empty outside the plan.
static func track(scene: String, at: Vector3) -> StringName:
	var here: Dictionary = locate(scene, at)
	if here.is_empty():
		return &""
	visit(here["room"])
	return here["room"]

static func visit(id: StringName) -> bool:
	if visited.has(id) or room(id).is_empty():
		return false
	visited[id] = true
	revision += 1
	return true

## Visited, or seen through a door of a visited room: such a room is drawn as an
## unexplored outline before Dylan gets in.
static func known(id: StringName) -> bool:
	if visited.has(id):
		return true
	for door: Dictionary in DOORS:
		var rooms: Array = door["rooms"]
		if rooms.has(id) and (visited.has(rooms[0]) or visited.has(rooms[1])):
			return true
	return false

static func known_rooms() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Dictionary in ROOMS:
		if known(entry["id"]):
			result.append(entry["id"])
	return result

## A door is on the map once Dylan has been on either side of it.
static func door_seen(door: Dictionary) -> bool:
	return visited.has(door["rooms"][0]) or visited.has(door["rooms"][1])

static func door_open(door: Dictionary) -> bool:
	var opens_at: int = door["opens_at"]
	return opens_at != SEALED and MissionState.stage >= opens_at

## The room the current objective points at, empty when it points nowhere.
static func objective_room() -> StringName:
	return OBJECTIVE_ROOM.get(MissionState.stage, &"")

## Where a marker for the room goes: its own mark, or the middle of its floor.
static func mark(id: StringName) -> Vector2:
	var entry: Dictionary = room(id)
	if entry.is_empty():
		return Vector2.ZERO
	return entry.get("mark", (entry["shapes"][0] as Rect2).get_center())

## The rectangle on the plan that holds every shape of these rooms.
static func bounds(ids: Array) -> Rect2:
	var result := Rect2()
	var first := true
	for id: StringName in ids:
		for shape: Rect2 in room(id).get("shapes", []):
			result = shape if first else result.merge(shape)
			first = false
	return result

static func snapshot() -> Array:
	var result: Array = []
	for entry: Dictionary in ROOMS:
		if visited.has(entry["id"]):
			result.append(String(entry["id"]))
	return result

## Takes a stored list and trusts none of it: unknown ids are dropped, and the
## rooms the stored objective implies are added whether or not they were listed.
static func restore(value: Variant) -> void:
	visited = {}
	if value is Array:
		for id: Variant in value:
			if (id is String or id is StringName) and not room(StringName(id)).is_empty():
				visited[StringName(id)] = true
	for pair: Array in REACHED_BY:
		if MissionState.stage >= pair[0]:
			visited[pair[1]] = true
	revision += 1

## A new game: nothing has been seen.
static func reset() -> void:
	visited = {}
	revision += 1
