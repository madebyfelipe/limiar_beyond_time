class_name InventoryMenu
extends RetroScreen
## The attaché case on screen, Resident Evil 4 style: the grid, a cursor, and
## items you pick up, turn and set down wherever they fit. Confirm on an item
## opens its actions (equip a gun, use a med kit, move); while moving, the
## reload button turns it and confirm drops it. The game is paused throughout.
##
## Three-column steel console based on the supplied visual reference, with
## category tabs, character condition, loadout and a contextual action rail.

signal closed

const Console := preload("res://ui/inventory_console.gd")
const CELL := Vector2(104, 86)
const GRID_AT := Vector2(542, 222)
const INK := Color("abc2d5")
const MUTED := Color("688393")
const ACCENT := Color("ffb84f")
const HEALTHY := Color("39ed96")
const DANGER := Color("f0836d")
const POWER_ON_DURATION := 0.52
var player: PlayerController
var cursor: Vector2i = Vector2i.ZERO
## The entry being moved, empty when nothing is in hand.
var held: Dictionary = {}
var held_rotated: bool = false
## Actions offered for the entry under the cursor; empty when the list is shut.
var actions: PackedStringArray = []
var action_index: int = 0
var grid: Control
var details: Label
var status: Label
var hint: Label
var category: Label
var description: Label
var metadata: Label
var capacity: Label
var action_panel: Control
var preview: Control
var scene_art: Control
var vitality: Label
var loadout: Label
var _vitality: float = -1.0
var _inspected: Dictionary = {}
var _pad_active: bool = false
var _drawn_revision: int = -1
var selected_tab: int = 0
var _heartbeat: float = 0.0
var _power_on: Control
var _power_on_elapsed: float = POWER_ON_DURATION
var location_texture: Texture2D
var location_name: String = "FIELD OPERATIONS"
const TAB_NAMES := ["ALL ITEMS", "WEAPONS", "AMMO", "RECOVERY"]
const TAB_KINDS := [&"", &"weapon", &"ammo", &"recovery"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"inventory_menus")
	design_size = Vector2(1920, 1080)
	build(null)
	(get_child(0) as ColorRect).color = Color("03070a")
	scene_art = Control.new()
	scene_art.size = design_size
	scene_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_art.draw.connect(_draw_case)
	canvas.add_child(scene_art)
	_caption("DYLAN", Rect2(48, 154, 320, 40), 30)
	_caption("CONDITION", Rect2(262, 212, 232, 32), 22)
	vitality = _caption("", Rect2(266, 350, 226, 36), 27)
	vitality.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption("EQUIPPED WEAPON", Rect2(48, 418, 440, 34), 22)
	loadout = _caption("", Rect2(48, 578, 330, 30), 19)
	_caption("AMMO", Rect2(392, 460, 102, 28), 20)
	_caption("STATS", Rect2(48, 630, 440, 32), 23)
	_caption("INVENTORY", Rect2(550, 154, 370, 38), 30)
	capacity = _caption("", Rect2(1330, 156, 250, 34), 22)
	capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_caption("ACTIONS", Rect2(1630, 154, 254, 38), 25)
	grid = Control.new()
	grid.name = "Grid"
	grid.position = GRID_AT
	grid.size = CELL * Vector2(Inventory.COLUMNS, Inventory.ROWS)
	grid.clip_contents = true
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.draw.connect(_draw_grid)
	canvas.add_child(grid)
	category = _caption("", Rect2(550, 748, 1032, 24), 17)
	status = _caption("", Rect2(550, 778, 1032, 26), 17)
	status.add_theme_color_override("font_color", ACCENT)
	preview = Control.new()
	preview.position = Vector2(552, 852)
	preview.size = Vector2(260, 156)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.draw.connect(_draw_preview)
	canvas.add_child(preview)
	details = _caption("", Rect2(838, 852, 1032, 36), 29)
	details.add_theme_color_override("font_color", ACCENT)
	metadata = _caption("", Rect2(838, 980, 1032, 28), 16)
	description = _caption("", Rect2(838, 910, 1032, 64), 21)
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_panel = Control.new()
	action_panel.position = Vector2(1628, 216)
	action_panel.size = Vector2(256, 520)
	action_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_panel.draw.connect(_draw_actions)
	canvas.add_child(action_panel)
	hint = _caption("", Rect2(36, 1032, 1848, 32), 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_power_on = Control.new()
	_power_on.name = "PowerOn"
	_power_on.size = design_size
	_power_on.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_on.draw.connect(_draw_power_on)
	canvas.add_child(_power_on)
	_power_on.hide()
	hide()

func _caption(text: String, box: Rect2, points: int) -> Label:
	var result := label_at(text, box, points)
	result.add_theme_font_override("font", Console.lettering())
	result.add_theme_color_override("font_color", INK)
	result.add_theme_color_override("font_shadow_color", Color.BLACK)
	result.add_theme_constant_override("shadow_offset_y", 2)
	return result
func open() -> void:
	if visible or get_tree().paused:
		return
	SupplyStock.ensure_loaded()
	var scene := get_tree().current_scene
	if scene != null:
		location_name = scene.scene_file_path.get_file().get_basename().replace("_", " ").to_upper()
		var background := scene.get_node_or_null("Frame/Composition/Background") as TextureRect
		location_texture = background.texture if background != null else null
	held = {}
	actions = []
	selected_tab = 0
	status.text = ""
	cursor = Vector2i(Inventory.entries[0]["cell"]) if not Inventory.entries.is_empty() else Vector2i.ZERO
	_power_on_elapsed = 0.0
	_power_on.show()
	_power_on.queue_redraw()
	show()
	get_tree().paused = true
	_refresh()

func close() -> void:
	if not visible:
		return
	# A move that was never set down leaves the item where it was.
	held = {}
	actions = []
	_power_on_elapsed = POWER_ON_DURATION
	_power_on.hide()
	hide()
	get_tree().paused = false
	closed.emit()

func _process(delta: float) -> void:
	if visible:
		if _power_on_elapsed < POWER_ON_DURATION:
			_power_on_elapsed = minf(_power_on_elapsed + delta, POWER_ON_DURATION)
			_power_on.queue_redraw()
			_power_on.visible = _power_on_elapsed < POWER_ON_DURATION
		_heartbeat = fmod(_heartbeat + delta, 2.0)
		scene_art.queue_redraw()
	var life := player.vitality if is_instance_valid(player) else -1.0
	if visible and (_drawn_revision != Inventory.revision or _pad_active != GamepadControls.shared.gamepad_active or not is_equal_approx(life, _vitality)):
		_refresh()

## A phosphor line grows sideways, then opens vertically over the live UI.
## Drawing in design coordinates keeps the reveal centered after a resize.
func _draw_power_on() -> void:
	var t := _power_on_elapsed
	var horizontal := ease(clampf(t / 0.14, 0.0, 1.0), 0.35)
	var vertical := smoothstep(0.12, 0.42, t)
	var aperture := Vector2(lerpf(8.0, design_size.x, horizontal), lerpf(2.0, design_size.y, vertical))
	var corner := (design_size - aperture) * 0.5
	var dark := Color("03070a")
	_power_on.draw_rect(Rect2(Vector2.ZERO, Vector2(design_size.x, corner.y)), dark)
	_power_on.draw_rect(Rect2(Vector2(0, design_size.y - corner.y), Vector2(design_size.x, corner.y)), dark)
	_power_on.draw_rect(Rect2(Vector2(0, corner.y), Vector2(corner.x, aperture.y)), dark)
	_power_on.draw_rect(Rect2(Vector2(design_size.x - corner.x, corner.y), Vector2(corner.x, aperture.y)), dark)
	var glow := 1.0 - smoothstep(0.14, 0.36, t)
	if glow > 0.0:
		var center := design_size * 0.5
		for band: int in range(4, 0, -1):
			var thickness := float(band * band) * 2.0
			_power_on.draw_rect(Rect2(Vector2(corner.x, center.y - thickness * 0.5), Vector2(aperture.x, thickness)), Color(0.55, 0.82, 1.0, glow * 0.09))
		_power_on.draw_line(Vector2(corner.x, center.y), Vector2(design_size.x - corner.x, center.y), Color(0.87, 0.96, 1.0, glow), 2.0)
	# A soft phosphor afterglow settles without a full-screen white flash.
	var afterglow := smoothstep(0.12, 0.24, t) * (1.0 - smoothstep(0.26, POWER_ON_DURATION, t))
	_power_on.draw_rect(Rect2(corner, aperture), Color(0.55, 0.78, 0.9, afterglow * 0.12))

func _input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_click(canvas.get_local_mouse_position(), event.double_click)
		return
	var tab_step := 0
	if event is InputEventKey and event.physical_keycode == KEY_TAB:
		tab_step = -1 if event.shift_pressed else 1
	elif event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER: tab_step = -1
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER: tab_step = 1
	if tab_step != 0 and not event.is_echo():
		_select_tab(posmod(selected_tab + tab_step, TAB_NAMES.size()))
		return
	var back: bool = event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause") or event.is_action_pressed(&"inventory")
	if back and not event.is_echo():
		if not actions.is_empty():
			actions = []
		elif not held.is_empty():
			held = {}
			status.text = ""
		else:
			close()
			return
		_refresh()
		return
	var step := Vector2i.ZERO
	if event.is_action_pressed(&"ui_left", true): step = Vector2i.LEFT
	elif event.is_action_pressed(&"ui_right", true): step = Vector2i.RIGHT
	elif event.is_action_pressed(&"ui_up", true): step = Vector2i.UP
	elif event.is_action_pressed(&"ui_down", true): step = Vector2i.DOWN
	if step != Vector2i.ZERO:
		if not actions.is_empty():
			if step.y != 0:
				action_index = posmod(action_index + step.y, actions.size())
		else:
			cursor = (cursor + step).clamp(Vector2i.ZERO, Vector2i(Inventory.COLUMNS - 1, Inventory.ROWS - 1))
		_refresh()
		return
	if event.is_echo():
		return
	if event.is_action_pressed(&"reload") and not held.is_empty():
		held_rotated = not held_rotated
		_refresh()
	elif event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact"):
		confirm()

## Confirm: run the chosen action, set down what is held, or open the actions
## of the item under the cursor.
func confirm() -> void:
	if not actions.is_empty():
		var entry: Dictionary = Inventory.entry_at(cursor)
		var chosen: String = actions[action_index]
		actions = []
		if not entry.is_empty():
			_run(chosen, entry)
	elif not held.is_empty():
		if Inventory.move(held, cursor, held_rotated):
			status.text = ""
			held = {}
		else:
			status.text = "It does not fit there."
	else:
		var entry: Dictionary = Inventory.entry_at(cursor)
		if not entry.is_empty() and _matches_tab(entry):
			actions = actions_for(entry)
			action_index = 0
	_refresh()

func actions_for(entry: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	match Inventory.kind(entry["id"]):
		&"weapon":
			if _weapon_definition(entry["id"]) != null and not _is_equipped(entry["id"]):
				result.append("EQUIP")
		&"recovery":
			result.append("USE")
	result.append_array(["MOVE", "CANCEL"])
	return result

func _run(chosen: String, entry: Dictionary) -> void:
	var item_label: String = Inventory.item_name(entry["id"])
	match chosen:
		"EQUIP":
			if is_instance_valid(player) and player.weapon != null:
				player.weapon.equip(_weapon_definition(entry["id"]))
				status.text = "%s equipped." % item_label
		"USE":
			if is_instance_valid(player) and player.use_med_kit(true):
				status.text = "%s used." % item_label
			else:
				status.text = "Vitality is already full."
		"MOVE":
			selected_tab = 0
			held = entry
			held_rotated = bool(entry["rotated"])
			cursor = entry["cell"]
			status.text = ""

func _weapon_definition(id: StringName) -> WeaponDefinition:
	for definition: WeaponDefinition in PlayerWeapon.ARSENAL:
		if definition.id == id:
			return definition
	return null

func _is_equipped(id: StringName) -> bool:
	return is_instance_valid(player) and player.weapon != null and player.weapon.definition.id == id

func _refresh() -> void:
	_drawn_revision = Inventory.revision
	_vitality = player.vitality if is_instance_valid(player) else -1.0
	var condition := "FINE" if _vitality > 50.0 else ("CAUTION" if _vitality > 25.0 else "DANGER")
	vitality.text = "%s  %03d" % [condition, int(_vitality)] if _vitality >= 0.0 else "OFFLINE"
	vitality.add_theme_color_override("font_color", _health_color())
	loadout.text = "MAIN / NONE"
	if is_instance_valid(player) and player.weapon != null and Inventory.has(player.weapon.definition.id):
		loadout.text = "MAIN / " + Inventory.item_name(player.weapon.definition.id)
	var entry: Dictionary = held if not held.is_empty() else Inventory.entry_at(cursor)
	_inspected = entry if _matches_tab(entry) else {}
	entry = _inspected
	var occupied := 0
	for stored: Dictionary in Inventory.entries:
		var footprint: Vector2i = Inventory.footprint(stored["id"], stored["rotated"])
		occupied += footprint.x * footprint.y
	capacity.text = "%02d / 60" % occupied
	if entry.is_empty():
		category.text = TAB_NAMES[selected_tab] + " / STORAGE"
		details.text = "EMPTY SLOT"
		metadata.text = "%02d FREE SLOTS" % (60 - occupied)
		description.text = "Select an item to inspect or arrange it.\nDimmed equipment belongs to another tab."
	else:
		var id: StringName = entry["id"]
		category.text = "INSPECT / " + str({&"weapon": "WEAPON", &"ammo": "AMMUNITION", &"recovery": "RECOVERY"}.get(Inventory.kind(id), "SUPPLY"))
		details.text = Inventory.item_name(id)
		var footprint: Vector2i = Inventory.footprint(id, held_rotated if not held.is_empty() else entry["rotated"])
		metadata.text = "%d × %d SLOTS" % [footprint.x, footprint.y]
		if Inventory.stack_limit(id) > 1:
			metadata.text += "   /   %02d ROUNDS" % entry["count"]
		elif _is_equipped(id):
			metadata.text += "   /   EQUIPPED"
		description.text = {&"pistol": "Semi-automatic sidearm.\nUses handgun ammunition.", &"shotgun": "Two-shell shotgun. Effective at close range.\nUses shotgun shells.", &"handgun_ammo": "Handgun ammunition.\nUp to 50 rounds in one stack.", &"shotgun_shells": "Shotgun ammunition.\nUp to 15 shells in one stack.", &"med_kit": "First-aid supplies.\nRestores up to 50 vitality."}.get(id, "")
	var pad: bool = GamepadControls.shared.gamepad_active
	_pad_active = pad
	var accept := "✕" if GamepadControls.shared.playstation else "A"
	var back := "○" if GamepadControls.shared.playstation else "B"
	var family := InputBindings.GAMEPAD if pad else InputBindings.KEYBOARD
	var turn := InputBindings.binding_label("reload", family, 0, GamepadControls.shared.playstation)
	var directions := "D-PAD" if pad else "ARROWS"
	if not held.is_empty():
		hint.text = "%s  Move     %s  Rotate     %s  Place     %s  Cancel" % [directions, turn, accept if pad else "ENTER", back if pad else "ESC"]
		var fits := Inventory.fits(held["id"], cursor, held_rotated, held)
		if status.text.is_empty() or status.text == "Ready to place." or status.text == "It does not fit there.":
			status.text = "Ready to place." if fits else "It does not fit there."
		status.add_theme_color_override("font_color", HEALTHY if fits else DANGER)
	elif not actions.is_empty():
		hint.text = "%s  Select action     %s  Confirm     %s  Back" % [directions, accept if pad else "ENTER", back if pad else "ESC"]
	else:
		hint.text = "%s  Select     %s  Actions     %s  Close" % [directions, accept if pad else "ENTER", back if pad else "ESC / " + InputBindings.binding_label("inventory", family)]
		hint.text += "     " + ("L1 / R1" if pad and GamepadControls.shared.playstation else ("LB / RB" if pad else "TAB")) + "  Tabs"
		status.add_theme_color_override("font_color", ACCENT)
	grid.queue_redraw()
	preview.queue_redraw()
	action_panel.queue_redraw()
	scene_art.queue_redraw()

func _draw_grid() -> void:
	for y: int in range(Inventory.ROWS):
		for x: int in range(Inventory.COLUMNS):
			var cell := Rect2(Vector2(x, y) * CELL, Vector2.ONE * CELL)
			var slot := cell.grow(-3)
			grid.draw_rect(slot, Color("070f15"))
			grid.draw_rect(slot, Color("3c5665"), false, 1.5)
			grid.draw_line(slot.position + Vector2(4, 4), slot.end - Vector2(4, 4), Color("16232c"))
			grid.draw_line(Vector2(slot.end.x - 4, slot.position.y + 4), Vector2(slot.position.x + 4, slot.end.y - 4), Color("16232c"))
	for entry: Dictionary in Inventory.entries:
		_draw_entry(entry, Inventory.rect(entry), 0.18 if not _matches_tab(entry) else (0.35 if is_same(entry, held) else 1.0))
	if not held.is_empty():
		var area := Rect2i(cursor, Inventory.footprint(held["id"], held_rotated))
		_draw_entry(held, area, 0.9)
		var fits: bool = Inventory.fits(held["id"], cursor, held_rotated, held)
		_focus(_pixels(area), HEALTHY if fits else DANGER)
	else:
		var under: Dictionary = Inventory.entry_at(cursor)
		var focus: Rect2i = Inventory.rect(under) if not under.is_empty() else Rect2i(cursor, Vector2i.ONE)
		_focus(_pixels(focus), ACCENT)

func _draw_entry(entry: Dictionary, area: Rect2i, alpha: float) -> void:
	var box: Rect2 = _pixels(area).grow(-3.0)
	var fill := Color("13232e")
	grid.draw_rect(box, Color(fill, 0.94 * alpha))
	grid.draw_rect(box, Color(Color("707c77"), 0.6 * alpha), false, 1.0)
	grid.draw_line(box.position + Vector2(1, 1), Vector2(box.end.x - 1, box.position.y + 1), Color(Color("9ba39a"), 0.35 * alpha))
	InventoryArt.draw_item(grid, entry["id"], box.grow(-5), alpha, held_rotated if is_same(entry, held) and area.position == cursor else entry["rotated"])
	var font: Font = Console.lettering()
	if _is_equipped(entry["id"]):
		grid.draw_rect(Rect2(box.position + Vector2(4, 4), Vector2(48, 19)), Color(HEALTHY, alpha))
		grid.draw_string(font, box.position + Vector2(8, 18), "MAIN", HORIZONTAL_ALIGNMENT_LEFT, 42, 11, Color(Color("18211a"), alpha))
	if Inventory.stack_limit(entry["id"]) > 1:
		grid.draw_rect(Rect2(box.end - Vector2(44, 30), Vector2(41, 27)), Color(0.04, 0.06, 0.04, 0.92 * alpha))
		grid.draw_string(font, box.end - Vector2(41, 7), str(entry["count"]), HORIZONTAL_ALIGNMENT_RIGHT, 34, 22, Color(INK, alpha))

func _focus(box: Rect2, color: Color) -> void:
	box = box.grow(-2)
	grid.draw_rect(box, Color(color, 0.11))
	grid.draw_rect(box, Color(color, 0.9), false, 2.0)
	for point: Vector2 in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
		var direction := Vector2(1 if point.x == box.position.x else -1, 1 if point.y == box.position.y else -1)
		grid.draw_line(point, point + Vector2(13 * direction.x, 0), color, 3.0)
		grid.draw_line(point, point + Vector2(0, 13 * direction.y), color, 3.0)

func _draw_preview() -> void:
	Console.panel(preview, Rect2(Vector2.ZERO, preview.size), Color("050c11"), false)
	if not _inspected.is_empty():
		InventoryArt.draw_item(preview, _inspected["id"], Rect2(Vector2(12, 12), preview.size - Vector2(24, 26)))

func _draw_actions() -> void:
	Console.actions(self)

func _draw_case() -> void:
	Console.draw(self)
func _health_color() -> Color:
	if _vitality < 0.0:
		return MUTED
	return HEALTHY if _vitality > 50.0 else (ACCENT if _vitality > 25.0 else DANGER)

func _pixels(area: Rect2i) -> Rect2:
	return Rect2(Vector2(area.position) * CELL, Vector2(area.size) * CELL)

func _matches_tab(entry: Dictionary) -> bool:
	return entry.is_empty() or selected_tab == 0 or Inventory.kind(entry["id"]) == TAB_KINDS[selected_tab]

func _select_tab(index: int) -> void:
	if not held.is_empty():
		return
	selected_tab = index
	actions = []
	status.text = ""
	cursor = Vector2i.ZERO
	for entry: Dictionary in Inventory.entries:
		if _matches_tab(entry):
			cursor = entry["cell"]
			break
	_refresh()

func _click(point: Vector2, double_click: bool) -> void:
	for index: int in range(TAB_NAMES.size()):
		if Console.tab_rect(index, TAB_NAMES.size()).has_point(point):
			_select_tab(index)
			return
	if Rect2(46, 64, 66, 52).has_point(point):
		_select_tab(posmod(selected_tab - 1, TAB_NAMES.size()))
		return
	if Rect2(1810, 64, 66, 52).has_point(point):
		_select_tab(posmod(selected_tab + 1, TAB_NAMES.size()))
		return
	if Rect2(GRID_AT, grid.size).has_point(point):
		cursor = Vector2i((point - GRID_AT) / CELL)
		actions = []
		if not held.is_empty() or double_click:
			confirm()
		else:
			_refresh()
		return
	if Console.EXIT_RECT.has_point(point):
		close()
		return
	if held.is_empty() and not _inspected.is_empty():
		var offered := actions_for(_inspected)
		for index: int in range(offered.size()):
			if Rect2(action_panel.position + Vector2(0, index * 66), Vector2(action_panel.size.x, 58)).has_point(point):
				actions = offered
				action_index = index
				confirm()
				return
