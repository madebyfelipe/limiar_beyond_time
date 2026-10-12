class_name WeaponReadout
extends Label
## Rounds in the magazine over what is left in the stock, in the lower right of
## the frame, only once Dylan owns a gun.

var weapon: PlayerWeapon

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = -420.0
	offset_top = -86.0
	offset_right = -36.0
	offset_bottom = -30.0
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 26)
	add_theme_color_override("font_color", Color("f2e4b4"))
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	visible = weapon != null and weapon.is_armed()
	if not visible:
		return
	var stock: String = "TREINO" if weapon.practice else str(weapon.reserve())
	text = "%s  %d | %s" % [weapon.definition.display_name, PlayerWeapon.magazine, stock]
	if weapon.is_reloading():
		text = "RECARREGANDO  " + text
