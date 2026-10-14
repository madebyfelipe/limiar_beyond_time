class_name MapPage
extends Control
## The MAP tab of the inventory console: the room list on the left, the site
## plan in the middle, legend and objective on the right. Everything shown is
## read from AreaMap and MissionState. The full-screen atlas shares the
## inventory's navigation and leaves gameplay and discovery untouched.

const Console := preload("res://ui/inventory_console.gd")
const Atlas := preload("res://ui/map_atlas.gd")
const INK := Color("abc2d5")
const MUTED := Color("688393")
const ACCENT := Color("ffb84f")
const OPEN_DOOR := Color("39ed96")
const SEALED_DOOR := Color("f0836d")
const SAVE_POINT := Color("4d9df0")
const OBJECTIVE := Color("ee3b34")
const LIST_AT := Vector2(46, 532)
const LIST_ROW := Vector2(382, 43)
const LIST_STEP := 46.0
const PLAN_RECT := Rect2(470, 132, 1052, 790)
const HEADER_TABS := ["MAP", "ITEMS", "WEAPONS", "AMMO", "RECOVERY", "EXIT"]
const HEADER_TARGETS := [InventoryMenu.MAP_TAB, 0, 1, 2, 3, -1]
const REGION_RECT := Rect2(1562, 750, 310, 169)
## Pixels per plan metre: the cap while few rooms are known, and the zoom.
const MAX_SCALE := 16.0
const ZOOM := 2.0
## Right stick, in design pixels per second at full tilt.
const PAN_SPEED := 900.0
## How far past the known rooms the view may be carried, in plan metres.
const PAN_MARGIN := 8.0

var menu: InventoryMenu
## The room picked in the list, empty while nothing is known.
var selected: StringName = &""
var zoomed: bool = false
## The view carried off its centre by the mouse or the right stick, in plan
## metres. Picking a room in the list, zooming or confirming brings it back.
var pan: Vector2 = Vector2.ZERO
var _dragging: bool = false
var plan: Control
## Where the player stands on the plan (`AreaMap.locate`), empty off the plan.
var here: Dictionary = {}
var _pad: bool = false
var _previews: Dictionary = {}

func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	plan = Control.new()
	plan.name = "Plan"
	plan.position = PLAN_RECT.position
	plan.size = PLAN_RECT.size
	plan.clip_contents = true
	plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plan.draw.connect(_draw_plan)
	add_child(plan)

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _pad != GamepadControls.shared.gamepad_active:
		refresh()
	# The aim stick looks around the plan; the pad and the move stick pick rooms.
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down", float(GeneralSettings.get_value("stick_deadzone")))
	if not stick.is_zero_approx():
		move_view(stick * PAN_SPEED * delta)

## Dragging with the left button held carries the plan along. The menu takes
## the press itself, to pick the room under it, and never sees motion.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or menu == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed and PLAN_RECT.has_point(menu.canvas.get_global_transform().affine_inverse() * event.position)
	elif event is InputEventMouseMotion and _dragging:
		move_view(-event.relative / menu.canvas.scale.x)

## Slides the view by this many design pixels, no further than the edge of
## what is known.
func move_view(pixels: Vector2) -> void:
	var lens: Dictionary = plan_view()
	var centre: Vector2 = lens["centre"]
	var limits: Rect2 = AreaMap.bounds(AreaMap.known_rooms()).grow(PAN_MARGIN)
	pan += (centre + pixels / float(lens["scale"])).clamp(limits.position, limits.end) - centre
	refresh()

## The tab was selected: start on the room the player is in.
func enter() -> void:
	here = {}
	var scene := get_tree().current_scene
	if scene != null and menu != null and is_instance_valid(menu.player):
		here = AreaMap.locate(scene.scene_file_path, menu.player.global_position)
	var rooms: Array[StringName] = AreaMap.known_rooms()
	selected = here.get("room", rooms[0] if not rooms.is_empty() else &"")
	zoomed = false
	pan = Vector2.ZERO
	_dragging = false
	refresh()

func refresh() -> void:
	_pad = GamepadControls.shared.gamepad_active
	queue_redraw()
	plan.queue_redraw()

## Pressed events the menu did not use for its tabs or for closing.
func handle(event: InputEvent) -> void:
	var step := 0
	if event.is_action_pressed(&"ui_up", true): step = -1
	elif event.is_action_pressed(&"ui_down", true): step = 1
	if step != 0:
		var rooms: Array[StringName] = AreaMap.known_rooms()
		if not rooms.is_empty():
			selected = rooms[posmod(rooms.find(selected) + step, rooms.size())]
			pan = Vector2.ZERO
			refresh()
		return
	if event.is_echo():
		return
	if event.is_action_pressed(&"reload"):
		zoomed = not zoomed
		pan = Vector2.ZERO
		refresh()
	elif (event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact")) and not here.is_empty():
		selected = here["room"]
		pan = Vector2.ZERO
		refresh()

## A click in design coordinates: a row of the list or a room on the plan.
func click(point: Vector2) -> void:
	for index: int in range(HEADER_TABS.size()):
		if _tab_rect(index).has_point(point):
			if HEADER_TARGETS[index] < 0:
				menu.close()
			elif HEADER_TARGETS[index] != InventoryMenu.MAP_TAB:
				menu._select_tab(HEADER_TARGETS[index])
			return
	for index: int in range(AreaMap.ROOMS.size()):
		if Rect2(LIST_AT + Vector2(0, index * LIST_STEP), LIST_ROW).has_point(point):
			_select(AreaMap.ROOMS[index]["id"])
			return
	if REGION_RECT.has_point(point):
		zoomed = false
		pan = Vector2.ZERO
		refresh()
		return
	if not PLAN_RECT.has_point(point):
		return
	var lens: Dictionary = plan_view()
	for layer: int in [1, 0]:
		for entry: Dictionary in AreaMap.ROOMS:
			if entry["layer"] != layer:
				continue
			for shape: Rect2 in entry["shapes"]:
				if _pixels(shape, lens).has_point(point - PLAN_RECT.position):
					_select(entry["id"], true)
					return

## A room picked in the list brings the view back to it. One picked on the
## plan is selected where it is: the press may be the start of a drag.
func _select(id: StringName, in_place: bool = false) -> void:
	if not AreaMap.known(id):
		return
	var before: Vector2 = plan_view()["centre"]
	selected = id
	pan = Vector2.ZERO
	if in_place:
		pan = before - (plan_view()["centre"] as Vector2)
	refresh()

## Scale and centre of the plan: every known room fits, and zooming doubles
## that around the selected one.
func plan_view() -> Dictionary:
	var frame: Rect2 = AreaMap.bounds(AreaMap.known_rooms())
	var room_for: Vector2 = PLAN_RECT.size - Vector2(180, 150)
	var scale_px := MAX_SCALE
	if frame.size.x > 0.0 and frame.size.y > 0.0:
		scale_px = minf(minf(room_for.x / frame.size.x, room_for.y / frame.size.y), MAX_SCALE)
	var centre: Vector2 = frame.get_center()
	if zoomed and AreaMap.known(selected):
		scale_px *= ZOOM
		centre = AreaMap.bounds([selected]).get_center()
	return {"scale": scale_px, "centre": centre + pan}

func _point(at: Vector2, lens: Dictionary) -> Vector2:
	return PLAN_RECT.size * 0.5 + (at - lens["centre"]) * float(lens["scale"])

func _pixels(shape: Rect2, lens: Dictionary) -> Rect2:
	return Rect2(_point(shape.position, lens), shape.size * float(lens["scale"]))

func _preview(id: StringName) -> Texture2D:
	var path: String = AreaMap.room(id).get("preview", "")
	if path.is_empty() or not AreaMap.visited.has(id):
		return null
	if not _previews.has(path):
		_previews[path] = load(path) if ResourceLoader.exists(path) else null
	return _previews[path]

func _tab_rect(index: int) -> Rect2:
	return Rect2(72 + index * 258, 38, 250, 60)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("03080c"))
	draw_texture_rect(Console.metal(), Rect2(16, 16, 1888, 1048), true)
	Atlas.panel(self, Rect2(20, 22, 1880, 86))
	for index: int in range(HEADER_TABS.size()):
		var box := _tab_rect(index)
		Console.button(self, box, "", index == 0)
		Atlas.text(self, box.position + Vector2(0, 40), HEADER_TABS[index], 29, Atlas.GOLD if index == 0 else INK, box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	Atlas.text(self, Vector2(1652, 59), "FACILITY MODULE", 19, MUTED)
	Atlas.text(self, Vector2(1652, 85), "VER.2.01", 20, MUTED)
	for line: int in range(4):
		draw_rect(Rect2(1850, 45 + line * 12, 30, 5), Color("3c4d58"))
	_draw_areas()
	Atlas.panel(self, Rect2(456, 116, 1080, 822))
	_draw_legend()
	_draw_objective()
	_draw_region()
	Atlas.panel(self, Rect2(24, 952, 1872, 96))
	Atlas.text(self, Vector2(62, 1010), "View area map." if not zoomed else "Area detail.  Zoom x2", 26)
	var playstation := GamepadControls.shared.playstation
	var family := InputBindings.GAMEPAD if _pad else InputBindings.KEYBOARD
	var zoom_key := InputBindings.binding_label("reload", family, 0, playstation)
	var area_key := ("D-PAD" if _pad else "UP/DOWN")
	var tabs_key := (("L1 R1" if playstation else "LB RB") if _pad else "TAB")
	var move_key := "R-STICK" if _pad else "DRAG"
	Atlas.text(self, Vector2(640, 1010), "%s  AREA    %s  MOVE    %s  ZOOM    %s  TABS    %s  EXIT" % [area_key, move_key, zoom_key, tabs_key, ("O" if playstation else "B") if _pad else "ESC"], 20, INK)
	# Glass scanlines are beneath the clipped chart and remain faint over labels.
	for y: int in range(120, 930, 4):
		draw_line(Vector2(38, y), Vector2(1882, y), Color(0, 0, 0, 0.10))

func _draw_areas() -> void:
	Atlas.panel(self, Rect2(28, 116, 416, 822))
	Atlas.heading(self, Rect2(28, 116, 416, 822), "[ AREA")
	Atlas.text(self, Vector2(62, 204), "Limiar Outpost", 30)
	draw_line(Vector2(52, 217), Vector2(424, 217), Color("3b4e5a"))
	var box := Rect2(54, 230, 370, 274)
	draw_rect(box, Color("07121a"))
	var texture := _preview(selected)
	if texture != null:
		# Cover crop, never stretch the level's camera plate.
		var source := Rect2(Vector2.ZERO, texture.get_size())
		var aspect := box.size.x / box.size.y
		if source.size.x / source.size.y > aspect:
			var width := source.size.y * aspect
			source.position.x = (source.size.x - width) * 0.5
			source.size.x = width
		else:
			var height := source.size.x / aspect
			source.position.y = (source.size.y - height) * 0.5
			source.size.y = height
		draw_texture_rect_region(texture, box, source, Color("b5bfca"))
	else:
		for x: int in range(54, 424, 26):
			draw_line(Vector2(x, 230), Vector2(x, 504), Color("10202a"))
		for y: int in range(230, 504, 26):
			draw_line(Vector2(54, y), Vector2(424, y), Color("10202a"))
		Atlas.text(self, Vector2(54, 365), "NO VISUAL DATA", 21, MUTED, 370, HORIZONTAL_ALIGNMENT_CENTER)
		Atlas.text(self, Vector2(54, 395), "UNEXPLORED SECTOR", 16, MUTED, 370, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(box, Color("758897"), false, 2)
	for index: int in range(AreaMap.ROOMS.size()):
		var entry: Dictionary = AreaMap.ROOMS[index]
		var id: StringName = entry["id"]
		var row := Rect2(LIST_AT + Vector2(0, index * LIST_STEP), LIST_ROW)
		var caption := "- - - - - -"
		var color := Color(MUTED, 0.55)
		if AreaMap.visited.has(id):
			caption = entry["name"].capitalize()
			color = INK
		elif AreaMap.known(id):
			caption = "Unexplored"
			color = MUTED
		if id == selected:
			draw_rect(row, Color("32200d"))
			draw_rect(row, Color("bf6817"), false, 2)
			draw_rect(Rect2(row.position, Vector2(4, row.size.y)), Atlas.GOLD)
			for line: int in range(5):
				draw_line(row.position + Vector2(4, line * 8 + 3), Vector2(row.end.x, row.position.y + line * 8 + 3), Color(0.6, 0.28, 0.04, 0.08))
			color = Atlas.GOLD
		else:
			draw_line(Vector2(row.position.x + 6, row.end.y + 3), Vector2(row.end.x, row.end.y + 3), Color("293f4b"))
		Atlas.text(self, row.position + Vector2(16, 29), "%d. %s" % [index + 1, caption], 25, color)
	Atlas.text(self, Vector2(62, 918), "EXPLORED %02d / %02d" % [AreaMap.visited.size(), AreaMap.ROOMS.size()], 20, MUTED)

func _draw_legend() -> void:
	var box := Rect2(1548, 116, 344, 358)
	Atlas.panel(self, box)
	Atlas.heading(self, box, "LEGEND")
	var captions := ["Current position", "Objective", "Door", "Sealed door", "Save point", "Area boundary", "Unexplored"]
	for index: int in range(captions.size()):
		var at := Vector2(1588, 194 + index * 39)
		match index:
			0: _position_glyph(self, at, Vector2.RIGHT, 12)
			1: _objective_glyph(self, at, 25)
			2: draw_rect(Rect2(at - Vector2(14, 3), Vector2(28, 6)), OPEN_DOOR)
			3: draw_rect(Rect2(at - Vector2(14, 3), Vector2(28, 6)), SEALED_DOOR)
			4: _save_glyph(self, at, 25)
			5: draw_rect(Rect2(at - Vector2(16, 10), Vector2(32, 20)), Color("b2bcc5"), false, 3)
			6: draw_rect(Rect2(at - Vector2(16, 10), Vector2(32, 20)), MUTED, false, 3)
		Atlas.text(self, at + Vector2(38, 8), captions[index], 24)

func _draw_objective() -> void:
	var box := Rect2(1548, 486, 344, 206)
	Atlas.panel(self, box)
	Atlas.heading(self, box, "OBJECTIVE")
	_objective_glyph(self, Vector2(1588, 563), 25)
	var paragraph := TextParagraph.new()
	paragraph.width = 250
	var points := 24
	paragraph.add_string(MissionState.objective(), Atlas.font(), points)
	while paragraph.get_size().y > 126 and points > 18:
		points -= 1
		paragraph.clear()
		paragraph.add_string(MissionState.objective(), Atlas.font(), points)
	paragraph.draw(get_canvas_item(), Vector2(1618, 546), INK)

func _draw_region() -> void:
	var box := Rect2(1548, 704, 344, 234)
	Atlas.panel(self, box)
	Atlas.heading(self, box, "REGION MAP")
	var view := REGION_RECT
	draw_texture_rect(Atlas.terrain(), view, false, Color("94a6b0"))
	for x: int in range(1562, 1872, 26):
		draw_line(Vector2(x, view.position.y), Vector2(x, view.end.y), Color(0.1, 0.25, 0.3, 0.3))
	var bounds := Atlas.TERRAIN_BOUNDS
	var ratio := view.size / bounds.size
	for entry: Dictionary in AreaMap.ROOMS:
		if not AreaMap.known(entry["id"]):
			continue
		for shape: Rect2 in entry["shapes"]:
			var room_box := Rect2(view.position + (shape.position - bounds.position) * ratio, shape.size * ratio)
			draw_rect(room_box, Color("384953"))
			draw_rect(room_box, MUTED, false, 1)
	var lens := plan_view()
	var extent := PLAN_RECT.size / float(lens["scale"])
	var frame := Rect2(view.position + (lens["centre"] - extent * 0.5 - bounds.position) * ratio, extent * ratio).intersection(view.grow(-3))
	if frame.has_area():
		draw_rect(frame, Color("ff472b"), false, 3)
	if not here.is_empty():
		_position_glyph(self, view.position + (here["point"] - bounds.position) * ratio, Vector2.UP, 5)

## All geometry remains in plan metres, including the decorative atlas and grid.
func _draw_plan() -> void:
	plan.draw_rect(Rect2(Vector2.ZERO, plan.size), Color("030b11"))
	var lens := plan_view()
	plan.draw_texture_rect(Atlas.terrain(), _pixels(Atlas.TERRAIN_BOUNDS, lens), false)
	var pitch: float = float(lens["scale"]) * 2.5
	var origin := _point(Vector2.ZERO, lens)
	for x: int in range(int(fposmod(origin.x, pitch)), int(plan.size.x), maxi(1, int(pitch))):
		plan.draw_line(Vector2(x, 0), Vector2(x, plan.size.y), Color(0.13, 0.26, 0.33, 0.32))
	for y: int in range(int(fposmod(origin.y, pitch)), int(plan.size.y), maxi(1, int(pitch))):
		plan.draw_line(Vector2(0, y), Vector2(plan.size.x, y), Color(0.13, 0.26, 0.33, 0.32))
	if AreaMap.known_rooms().is_empty():
		Atlas.text(plan, Vector2(0, plan.size.y * 0.5), "NO SITE DATA", 24, MUTED, plan.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	for layer: int in [0, 1]:
		for entry: Dictionary in AreaMap.ROOMS:
			var id: StringName = entry["id"]
			if entry["layer"] != layer or not AreaMap.known(id):
				continue
			var seen := AreaMap.visited.has(id)
			for shape: Rect2 in entry["shapes"]:
				var box := _pixels(shape, lens)
				plan.draw_rect(box.grow(3), Color("050a0e"))
				plan.draw_rect(box, Color("414e57") if seen else Color("0c191f"))
				if seen:
					plan.draw_texture_rect(Console.metal(), box.grow(-3), true, Color(0.8, 0.86, 0.92, 0.32))
					plan.draw_rect(box.grow(-8), Color("67737b"), false, 1)
					# Floor seams are decorative, not walls or connections.
					for y: int in range(int(box.position.y + 20), int(box.end.y - 6), 23):
						plan.draw_line(Vector2(box.position.x + 7, y), Vector2(box.end.x - 7, y), Color(0.54, 0.62, 0.67, 0.12))
				plan.draw_rect(box, Color("b0b9bf") if seen else Color("607482"), false, 3)
				if id == selected:
					# Small corner brackets keep the grey blueprint visible.
					for corner: Vector2 in [box.position, box.end]:
						var direction := 1.0 if corner == box.position else -1.0
						plan.draw_line(corner, corner + Vector2(12 * direction, 0), ACCENT, 3)
						plan.draw_line(corner, corner + Vector2(0, 12 * direction), ACCENT, 3)
			if not seen:
				var centre := _point((entry["shapes"][0] as Rect2).get_center(), lens)
				Atlas.text(plan, centre + Vector2(-20, 8), "?", 24, MUTED, 40, HORIZONTAL_ALIGNMENT_CENTER)
			elif entry.has("exit"):
				var way := _point(entry["exit"]["at"], lens)
				plan.draw_colored_polygon(PackedVector2Array([way + Vector2(-10, 5), way + Vector2(10, 5), way + Vector2(0, 24)]), Color("ff4b22"))
				Atlas.text(plan, way + Vector2(-140, 48), entry["exit"]["label"], 22, INK, 280, HORIZONTAL_ALIGNMENT_CENTER)
	for door: Dictionary in AreaMap.DOORS:
		if not AreaMap.door_seen(door):
			continue
		var length := maxf(1.6 * float(lens["scale"]), 16.0)
		var bar := Vector2(length, 6.0) if door["wide"] else Vector2(6.0, length)
		var box := Rect2(_point(door["at"], lens) - bar * 0.5, bar)
		plan.draw_rect(box.grow(2), Color("040c09"))
		plan.draw_rect(box, OPEN_DOOR if AreaMap.door_open(door) else SEALED_DOOR)
	for entry: Dictionary in AreaMap.ROOMS:
		if entry.has("save") and AreaMap.visited.has(entry["id"]):
			_save_glyph(plan, _point(entry["save"], lens), 24)
	var target := AreaMap.objective_room()
	if AreaMap.known(target):
		_objective_glyph(plan, _point(AreaMap.mark(target), lens), 25)
	if not here.is_empty() and menu != null and is_instance_valid(menu.player):
		_position_glyph(plan, _point(here["point"], lens), AreaMap.heading(menu.player.facing(), here["quarter"]), 15)
	# Compass, scale and zoom badge stay fixed when the map changes scale.
	Atlas.text(plan, Vector2(44, 38), "N", 26, INK)
	plan.draw_colored_polygon(PackedVector2Array([Vector2(55, 47), Vector2(40, 79), Vector2(70, 79)]), Color("8195af"))
	plan.draw_colored_polygon(PackedVector2Array([Vector2(55, 47), Vector2(55, 73), Vector2(70, 79)]), Color("52647f"))
	var metres := 10.0 if float(lens["scale"]) < 15 else 5.0
	var length: float = metres * float(lens["scale"])
	var baseline := Vector2(32, plan.size.y - 24)
	plan.draw_rect(Rect2(baseline - Vector2(8, 32), Vector2(length + 72, 46)), Color(0.01, 0.03, 0.05, 0.84))
	Atlas.text(plan, baseline - Vector2(0, 12), "0", 21, INK)
	Atlas.text(plan, baseline + Vector2(length - 10, -12), "%d m" % int(metres), 21, INK)
	for index: int in range(10):
		plan.draw_rect(Rect2(baseline + Vector2(index * length / 10, 0), Vector2(length / 10, 6)), INK if index % 2 == 0 else Color("172735"))
	plan.draw_rect(Rect2(baseline, Vector2(length, 6)), MUTED, false, 1)
	if zoomed:
		Atlas.text(plan, Vector2(plan.size.x - 160, 40), "ZOOM x2", 21, ACCENT)
	for y: int in range(0, int(plan.size.y), 4):
		plan.draw_line(Vector2(0, y), Vector2(plan.size.x, y), Color(0, 0, 0, 0.08))

func _position_glyph(target: CanvasItem, at: Vector2, direction: Vector2, reach: float) -> void:
	if direction.is_zero_approx():
		direction = Vector2.UP
	var side := Vector2(-direction.y, direction.x)
	var shape := PackedVector2Array([at + direction * reach, at - direction * reach * 0.7 + side * reach * 0.75, at - direction * reach * 0.7 - side * reach * 0.75])
	target.draw_colored_polygon(shape, ACCENT)
	shape.append(shape[0])
	target.draw_polyline(shape, Color("2a1a00"), 1.5, true)

func _objective_glyph(target: CanvasItem, at: Vector2, side: float) -> void:
	var box := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	target.draw_rect(box, Color("1a0605"))
	target.draw_rect(box, OBJECTIVE, false, 2.0)
	target.draw_line(box.position + Vector2(5, 5), box.end - Vector2(5, 5), OBJECTIVE, 2.5)
	target.draw_line(Vector2(box.end.x - 5, box.position.y + 5), Vector2(box.position.x + 5, box.end.y - 5), OBJECTIVE, 2.5)

func _save_glyph(target: CanvasItem, at: Vector2, side: float) -> void:
	var box := Rect2(at - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	target.draw_rect(box, Color("06121f"))
	target.draw_rect(box, SAVE_POINT, false, 2.0)
	Atlas.text(target, Vector2(box.position.x, box.end.y - 4), "S", 22, SAVE_POINT, side, HORIZONTAL_ALIGNMENT_CENTER)
