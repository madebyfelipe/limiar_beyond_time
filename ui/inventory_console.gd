extends RefCounted
## Native industrial console skin. Text and state always come from gameplay.
const PORTRAIT_PATH := "res://assets/ui/inventory/dylan_portrait.png"
const INK := Color("abc2d5")
const MUTED := Color("688393")
const GOLD := Color("ffb84f")
const EXIT_RECT := Rect2(1628, 746, 256, 56)
static var _font: Font
static var _metal: Texture2D
static var _portrait: Texture2D

## The tabs share the 1656 px between the two shoulder buttons.
static func tab_rect(index: int, count: int = 4) -> Rect2:
	var step := 1656.0 / count
	return Rect2(132 + index * step, 62, step - 10, 58)

static func lettering() -> Font:
	if _font == null:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Bahnschrift", "DejaVu Sans", "Arial"])
		system.font_weight = 600
		var spaced := FontVariation.new()
		spaced.base_font = system
		spaced.spacing_glyph = 2
		_font = spaced
	return _font

static func metal() -> Texture2D:
	if _metal == null:
		var noise := FastNoiseLite.new()
		noise.seed = 7241
		noise.frequency = 0.18
		var surface := Image.create(128, 128, false, Image.FORMAT_RGB8)
		for y: int in range(128):
			for x: int in range(128):
				var value := clampf(0.5 + noise.get_noise_2d(x, y) * 0.9, 0, 1)
				var color := Color("0b1820").lerp(Color("394d59"), value)
				if (x * 7 + y * 29) % 97 < 2:
					color = color.lightened(0.15)
				surface.set_pixel(x, y, color)
		_metal = ImageTexture.create_from_image(surface)
	return _metal

static func text(target: CanvasItem, at: Vector2, value: String, points: int = 22, color: Color = INK, width: float = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	target.draw_string(lettering(), at + Vector2(1, 2), value, align, width, points, Color.BLACK)
	target.draw_string(lettering(), at, value, align, width, points, color)

static func panel(target: CanvasItem, box: Rect2, fill: Color = Color("060e14"), bolts: bool = true) -> void:
	target.draw_rect(box.grow(3), Color("020609"))
	target.draw_texture_rect(metal(), box, true)
	var edge := PackedVector2Array([
		box.position + Vector2(9, 0), Vector2(box.end.x - 9, box.position.y),
		Vector2(box.end.x, box.position.y + 9), box.end - Vector2(0, 9),
		box.end - Vector2(9, 0), Vector2(box.position.x + 9, box.end.y),
		Vector2(box.position.x, box.end.y - 9), box.position + Vector2(0, 9), box.position + Vector2(9, 0)])
	target.draw_polyline(edge, Color("748b94"), 1.5)
	target.draw_rect(box.grow(-11), fill)
	target.draw_rect(box.grow(-10), Color("101c24"), false, 3)
	target.draw_rect(box.grow(-12), Color("425c6c"), false)
	if bolts:
		for point: Vector2 in [box.position + Vector2(6, 6), Vector2(box.end.x - 6, box.position.y + 6), box.end - Vector2(6, 6), Vector2(box.position.x + 6, box.end.y - 6)]:
			target.draw_circle(point, 3.5, Color("030a10"))
			target.draw_circle(point - Vector2(0, 1), 2, Color("718a95"))
			target.draw_line(point - Vector2(1, 0), point + Vector2(1, 0), Color("10202c"))

static func button(target: CanvasItem, box: Rect2, caption: String, active: bool, points: int = 28) -> void:
	panel(target, box, Color("15120d") if active else Color("070e15"), false)
	if active:
		for inset: int in range(4):
			target.draw_rect(box.grow(-5 + inset), Color(GOLD, 0.18 - inset * 0.035), false, 2)
		target.draw_rect(box.grow(-5), GOLD, false, 2)
		target.draw_rect(box.grow(-9), Color(GOLD, 0.1))
	text(target, box.position + Vector2(8, box.size.y * 0.5 + points * 0.34), caption, points, GOLD if active else INK, box.size.x - 16, HORIZONTAL_ALIGNMENT_CENTER)

static func draw(menu: Control) -> void:
	var art: Control = menu.scene_art
	art.draw_texture_rect(metal(), Rect2(Vector2.ZERO, menu.design_size), true, Color("667984"))
	# Deep ventilation channels behind the modular panel frames.
	for x: int in [40, 342, 1394, 1824]:
		art.draw_rect(Rect2(x, 0, 58, 1080), Color("02080c"))
		for y: int in range(0, 1080, 8):
			art.draw_line(Vector2(x + 3, y), Vector2(x + 55, y), Color("152731"), 2)
	panel(art, Rect2(22, 48, 1876, 84))
	button(art, Rect2(46, 64, 66, 52), ("L1" if GamepadControls.shared.playstation else "LB") if menu._pad_active else "<", false, 24)
	button(art, Rect2(1810, 64, 66, 52), ("R1" if GamepadControls.shared.playstation else "RB") if menu._pad_active else ">", false, 24)
	for index: int in range(menu.TAB_NAMES.size()):
		button(art, tab_rect(index, menu.TAB_NAMES.size()), menu.TAB_NAMES[index], index == menu.selected_tab, 28)
	panel(art, Rect2(24, 146, 490, 264))
	panel(art, Rect2(24, 414, 490, 204))
	panel(art, Rect2(24, 622, 490, 196))
	panel(art, Rect2(528, 146, 1068, 672))
	panel(art, Rect2(1610, 146, 288, 672))
	for line: Rect2 in [Rect2(36, 196, 466, 2), Rect2(540, 202, 1044, 2), Rect2(1622, 202, 264, 2), Rect2(36, 454, 466, 2), Rect2(36, 668, 466, 2)]:
		art.draw_rect(line, Color("3f5665"))
	panel(art, Rect2(40, 208, 208, 190), Color("020709"), false)
	if _portrait == null and ResourceLoader.exists(PORTRAIT_PATH):
		_portrait = load(PORTRAIT_PATH)
	if _portrait != null:
		art.draw_texture_rect(_portrait, Rect2(50, 219, 188, 168), false)
	panel(art, Rect2(258, 250, 238, 146), Color("010c0b"), false)
	_draw_condition(menu)
	_draw_weapon(menu)
	_draw_location(menu)
	panel(art, Rect2(528, 838, 1370, 182))
	art.draw_line(Vector2(838, 898), Vector2(1870, 898), Color("3f5665"), 2)
	button(art, EXIT_RECT, "EXIT", false, 25)
	# Fine scanlines stay under native labels and keep their contrast intact.
	for y: int in range(148, 818, 4):
		art.draw_line(Vector2(38, y), Vector2(1886, y), Color(0, 0, 0, 0.12))

static func _draw_condition(menu: Control) -> void:
	var art: Control = menu.scene_art
	var color: Color = menu._health_color()
	var points := PackedVector2Array()
	var phase: float = menu._heartbeat * 110
	for x: int in range(216):
		var cycle := fposmod(float(x) - phase, 216.0)
		var wave := 0.0
		if menu._vitality > 0:
			# ECG waveform is a status ornament; health is the numeric readout.
			wave = -7 * exp(-pow((cycle - 60) / 5, 2)) + 12 * exp(-pow((cycle - 84) / 3, 2)) - 44 * exp(-pow((cycle - 92) / 3, 2)) + 23 * exp(-pow((cycle - 99) / 4, 2)) - 8 * exp(-pow((cycle - 123) / 8, 2))
		points.append(Vector2(270 + x, 310 + wave))
	art.draw_polyline(points, Color(color, 0.10), 8, true)
	art.draw_polyline(points, Color(color, 0.28), 4, true)
	art.draw_polyline(points, color, 1.6, true)

static func _draw_weapon(menu: Control) -> void:
	var art: Control = menu.scene_art
	var definition: WeaponDefinition
	if is_instance_valid(menu.player) and menu.player.weapon != null and Inventory.has(menu.player.weapon.definition.id):
		definition = menu.player.weapon.definition
	art.draw_line(Vector2(378, 462), Vector2(378, 604), Color("3f5665"))
	if definition != null:
		InventoryArt.draw_item(art, definition.id, Rect2(54, 464, 304, 110))
		text(art, Vector2(398, 538), "%02d" % maxi(0, PlayerWeapon.magazine), 42, GOLD, 86, HORIZONTAL_ALIGNMENT_CENTER)
		for index: int in range(mini(maxi(PlayerWeapon.magazine, 0), 5)):
			var box := Rect2(404 + index * 16, 560, 10, 26)
			art.draw_rect(box, Color("98701f"))
			art.draw_rect(box.grow(-2), Color("e5b553"))
		text(art, Vector2(394, 601), "/ %02d" % definition.magazine, 18, MUTED, 92, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		text(art, Vector2(60, 528), "NO WEAPON", 23, MUTED, 300, HORIZONTAL_ALIGNMENT_CENTER)
		text(art, Vector2(412, 540), "--", 36, MUTED)
	var values := [0.0, 0.0, 0.0, 0.0]
	var maxima := [150.0, 30.0, 5.0, 15.0]
	var captions := ["ATTACK", "RANGE", "RATE", "CAPACITY"]
	if definition != null:
		values = [definition.damage * definition.pellets, definition.reach, 1.0 / definition.fire_interval, float(definition.magazine)]
	for row: int in range(4):
		var y := 694 + row * 29
		text(art, Vector2(60, y), captions[row], 20)
		for index: int in range(10):
			var lit: bool = float(index) < values[row] / maxima[row] * 10.0
			art.draw_rect(Rect2(236 + index * 17, y - 17, 13, 17), Color("81a9c1") if lit else Color("142630"))
		var number := ("%.1f" % values[row]) if row == 2 else str(int(values[row]))
		text(art, Vector2(420, y), number if definition != null else "--", 18, MUTED, 60, HORIZONTAL_ALIGNMENT_RIGHT)

static func _draw_location(menu: Control) -> void:
	var art: Control = menu.scene_art
	panel(art, Rect2(24, 838, 490, 182))
	if menu.location_texture != null:
		art.draw_texture_rect(menu.location_texture, Rect2(38, 852, 462, 154), false, Color("80909c"))
	art.draw_rect(Rect2(38, 938, 462, 68), Color(0.01, 0.03, 0.05, 0.92))
	text(art, Vector2(52, 963), menu.location_name, 23)
	text(art, Vector2(52, 993), "CREDITS  %05d" % SupplyStock.credits, 18, GOLD)

static func actions(menu: Control) -> void:
	var target: Control = menu.action_panel
	if not menu.held.is_empty():
		text(target, Vector2(8, 34), "MOVING", 23, GOLD)
		text(target, Vector2(8, 78), "CHECK SPACE", 16, INK)
		text(target, Vector2(8, 112), "THEN PLACE", 16, MUTED)
		return
	var offered: PackedStringArray = menu.actions
	if offered.is_empty() and not menu._inspected.is_empty():
		offered = menu.actions_for(menu._inspected)
	for index: int in range(offered.size()):
		button(target, Rect2(0, index * 66, target.size.x, 58), offered[index], not menu.actions.is_empty() and index == menu.action_index, 25)
	if offered.is_empty():
		text(target, Vector2(14, 32), "SELECT", 22, MUTED)
		text(target, Vector2(14, 64), "AN ITEM", 22, MUTED)
