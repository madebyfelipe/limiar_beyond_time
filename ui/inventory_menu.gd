class_name InventoryMenu
extends RetroScreen
## The attaché case on screen, Resident Evil 4 style: the grid, a cursor, and
## items you pick up, turn and set down wherever they fit. Confirm on an item
## opens its actions (equip a gun, use a med kit, move); while moving, the
## reload button turns it and confirm drops it. The game is paused throughout.
##
## Deliberately plain: drawn rectangles and labels. The visual pass belongs to
## the UI owner; the rules live in Inventory.

signal closed

const CELL := 58.0
const GRID_AT := Vector2(72, 132)
const KIND_COLORS: Dictionary = {
	&"weapon": Color("33475a"),
	&"ammo": Color("5a4a25"),
	&"recovery": Color("2b5634"),
}

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
var _drawn_revision: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"inventory_menus")
	design_size = Vector2(1280, 720)
	build(null)
	label_at("ATTACHÉ CASE", Rect2(GRID_AT.x, 60, 600, 50), 34)
	grid = Control.new()
	grid.name = "Grid"
	grid.position = GRID_AT
	grid.size = CELL * Vector2(Inventory.COLUMNS, Inventory.ROWS)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.draw.connect(_draw_grid)
	canvas.add_child(grid)
	details = label_at("", Rect2(720, 132, 500, 230), 24)
	details.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status = label_at("", Rect2(720, 380, 500, 110), 22)
	status.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color("8ef58a"))
	hint = label_at("", Rect2(GRID_AT.x, 520, 1140, 90), 20)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hide()

func open() -> void:
	if visible or get_tree().paused:
		return
	SupplyStock.ensure_loaded()
	held = {}
	actions = []
	status.text = ""
	cursor = Vector2i(Inventory.entries[0]["cell"]) if not Inventory.entries.is_empty() else Vector2i.ZERO
	show()
	get_tree().paused = true
	_refresh()

func close() -> void:
	if not visible:
		return
	# A move that was never set down leaves the item where it was.
	held = {}
	actions = []
	hide()
	get_tree().paused = false
	closed.emit()

func _process(_delta: float) -> void:
	if visible and _drawn_revision != Inventory.revision:
		_refresh()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed():
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
		if not entry.is_empty():
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
	var entry: Dictionary = held if not held.is_empty() else Inventory.entry_at(cursor)
	if entry.is_empty():
		details.text = "—"
	else:
		var lines := PackedStringArray([Inventory.item_name(entry["id"])])
		if Inventory.stack_limit(entry["id"]) > 1:
			lines.append("×%d" % entry["count"])
		if _is_equipped(entry["id"]):
			lines.append("EQUIPPED")
		for index: int in range(actions.size()):
			lines.append(("> " if index == action_index else "  ") + actions[index])
		details.text = "\n".join(lines)
	var pad: bool = GamepadControls.shared.gamepad_active
	if not held.is_empty():
		hint.text = "Arrows move · %s turn · %s set down · %s cancel" % ["□ / X" if pad else "R", "✕ / A" if pad else "Enter / E", "○ / B" if pad else "Esc"]
	else:
		hint.text = "Arrows select · %s actions · %s close" % ["✕ / A" if pad else "Enter / E", "○ / B" if pad else "Esc / I"]
	grid.queue_redraw()

func _draw_grid() -> void:
	var line := Color("2c4a50")
	for y: int in range(Inventory.ROWS):
		for x: int in range(Inventory.COLUMNS):
			grid.draw_rect(Rect2(Vector2(x, y) * CELL, Vector2.ONE * CELL), Color(0.03, 0.08, 0.1), true)
			grid.draw_rect(Rect2(Vector2(x, y) * CELL, Vector2.ONE * CELL), line, false, 1.0)
	for entry: Dictionary in Inventory.entries:
		_draw_entry(entry, Inventory.rect(entry), 0.35 if is_same(entry, held) else 1.0)
	if not held.is_empty():
		var area := Rect2i(cursor, Inventory.footprint(held["id"], held_rotated))
		_draw_entry(held, area, 0.9)
		var fits: bool = Inventory.fits(held["id"], cursor, held_rotated, held)
		grid.draw_rect(_pixels(area), Color("8ef58a") if fits else Color("f26a5a"), false, 3.0)
	else:
		var under: Dictionary = Inventory.entry_at(cursor)
		var focus: Rect2i = Inventory.rect(under) if not under.is_empty() else Rect2i(cursor, Vector2i.ONE)
		grid.draw_rect(_pixels(focus), Color("f2e4b4"), false, 3.0)

func _draw_entry(entry: Dictionary, area: Rect2i, alpha: float) -> void:
	var box: Rect2 = _pixels(area).grow(-3.0)
	var fill: Color = KIND_COLORS.get(Inventory.kind(entry["id"]), Color("444444"))
	grid.draw_rect(box, Color(fill, alpha), true)
	grid.draw_rect(box, Color(0.75, 0.85, 0.85, 0.6 * alpha), false, 1.0)
	var font: Font = RetroScreen.font()
	grid.draw_string(font, box.position + Vector2(6, 20), Inventory.item_name(entry["id"]), HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 10, 14, Color(1, 1, 1, alpha))
	if Inventory.stack_limit(entry["id"]) > 1:
		grid.draw_string(font, box.position + Vector2(0, box.size.y - 6), str(entry["count"]), HORIZONTAL_ALIGNMENT_RIGHT, box.size.x - 6, 18, Color(1, 1, 1, alpha))

func _pixels(area: Rect2i) -> Rect2:
	return Rect2(Vector2(area.position) * CELL, Vector2(area.size) * CELL)
