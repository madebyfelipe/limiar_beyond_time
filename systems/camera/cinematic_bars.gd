class_name CinematicBars
extends Control
## Letterbox for cutscenes: two black bars that slide in from the top and the
## bottom of the 16:9 composition. Lives inside the composition, under the HUD
## and the retro filter, so the bars are filtered like the picture they crop.

## Height of each bar as a share of the composition. 0,12 crops 16:9 to about
## 2,35:1, the scope ratio.
const COVER := 0.12
const COLOR := Color.BLACK

var top: ColorRect
var bottom: ColorRect
## 0 = gone, 1 = fully in. Probes read it; the tween drives it.
var amount: float = 0.0:
	set(value):
		amount = clampf(value, 0.0, 1.0)
		_layout()
var _tween: Tween

func _ready() -> void:
	name = "CinematicBars"
	# GameHud steps aside while the bars are in.
	add_to_group(&"cinematic_bars")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top = _bar("Top")
	bottom = _bar("Bottom")
	_layout()

func _bar(label: String) -> ColorRect:
	var bar := ColorRect.new()
	bar.name = label
	bar.color = COLOR
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	return bar

func _layout() -> void:
	if top == null:
		return
	var cover: float = COVER * amount
	top.anchor_left = 0.0
	top.anchor_right = 1.0
	top.anchor_top = 0.0
	top.anchor_bottom = cover
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0 - cover
	bottom.anchor_bottom = 1.0
	for bar: ColorRect in [top, bottom]:
		bar.offset_left = 0.0
		bar.offset_right = 0.0
		bar.offset_top = 0.0
		bar.offset_bottom = 0.0
	visible = amount > 0.0

## Slides the bars in (true) or out (false) over `seconds`.
func set_shown(shown: bool, seconds: float = 0.6) -> Tween:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "amount", 1.0 if shown else 0.0, maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _tween
