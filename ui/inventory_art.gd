class_name InventoryArt
extends RefCounted
## Textured inventory portraits in the supplied survival-horror art style.
## UI frames, focus and quantities are always drawn separately by the menu.
const PORTRAITS: Dictionary = {
	&"pistol": preload("res://assets/ui/inventory/pistol_v06.png"),
	&"shotgun": preload("res://assets/ui/inventory/shotgun_v06.png"),
	&"handgun_ammo": preload("res://assets/ui/inventory/handgun_ammo_v06.png"),
	&"shotgun_shells": preload("res://assets/ui/inventory/shotgun_shells_v06.png"),
	&"med_kit": preload("res://assets/ui/inventory/med_kit_v06.png"),
}
## Measured opaque bounds (alpha >= 0.25 plus eight pixels of padding).
## Faint generated halos must not shrink the actual objects inside the slots.
## Keep these regions paired with the versioned PNGs above.
const PORTRAIT_REGIONS: Dictionary = {
	&"pistol": Rect2(168, 86, 1237, 869),
	&"shotgun": Rect2(32, 210, 2099, 381),
	&"handgun_ammo": Rect2(170, 58, 1205, 855),
	&"shotgun_shells": Rect2(214, 36, 1133, 901),
	&"med_kit": Rect2(198, 102, 1087, 909),
}

static func draw_item(target: CanvasItem, id: StringName, box: Rect2, alpha: float = 1.0, rotated: bool = false) -> void:
	if not PORTRAITS.has(id):
		return
	var extent := Vector2(box.size.y, box.size.x) if rotated else box.size
	var texture: Texture2D = PORTRAITS[id]
	var region: Rect2 = PORTRAIT_REGIONS[id]
	var ratio := minf(extent.x / region.size.x, extent.y / region.size.y)
	var dimensions := region.size * ratio
	target.draw_set_transform(box.get_center(), PI / 2.0 if rotated else 0.0)
	target.draw_texture_rect_region(texture, Rect2(-dimensions * 0.5, dimensions), region, Color(1, 1, 1, alpha))
	target.draw_set_transform(Vector2.ZERO)
