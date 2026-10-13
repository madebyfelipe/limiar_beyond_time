class_name MessageBox
extends CanvasLayer
## The bottom text strip of Resident Evil 4 and Dino Crisis: a dark band over
## the lower picture, monospaced lines typed out, item names picked out in
## green and, when there is a question, a No / Yes choice under it.
##
## The game holds still while it reads. Confirm (interact / ui_accept) shows
## the whole page at once and then turns it; left/right pick an answer and
## cancel picks the first one, which is always the safe "No".
##
## Deliberately plain: the visual pass belongs to the UI owner.
##   await MessageBox.say(self, ["You obtained %s." % MessageBox.item("PISTOL")])
##   var yes: bool = await MessageBox.say(self, ["Open it?"], ["No", "Yes"]) == 1

signal _advanced

const HIGHLIGHT := "8ef58a"
## Characters revealed per second; confirm skips the rest of the page.
const TYPE_SPEED := 60.0

var pages: Array = []
var options: PackedStringArray = []
var page: int = 0
var choice: int = 0
var band: ColorRect
var text: RichTextLabel
var answers: RichTextLabel
var _typed: float = 0.0
var _was_paused: bool = false

## Item names, places and other words the player must notice.
static func item(name: String) -> String:
	return "[color=#%s]%s[/color]" % [HIGHLIGHT, name]

## Shows `pages` one after another and returns the chosen option's index on
## the last page, or -1 when there were no options.
static func say(host: Node, lines: Array, choices: Array = []) -> int:
	var box := MessageBox.new()
	box.pages = lines
	box.options = PackedStringArray(choices)
	host.get_tree().root.add_child(box)
	await box._advanced
	var picked: int = box.choice if not box.options.is_empty() else -1
	box.queue_free()
	return picked

## Whether any message is on screen, so other input can stay out of its way.
static func is_open(tree: SceneTree) -> bool:
	return not tree.get_nodes_in_group(&"message_boxes").is_empty()

func _ready() -> void:
	add_to_group(&"message_boxes")
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	band = ColorRect.new()
	band.color = Color(0.0, 0.0, 0.0, 0.72)
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -190.0
	band.offset_bottom = -24.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	text = _rich(Rect2(48, 18, 0, 100))
	answers = _rich(Rect2(48, 122, 0, 40))
	answers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_show_page()

func _rich(box: Rect2) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_left = box.position.x
	label.offset_right = -box.position.x
	label.offset_top = box.position.y
	label.offset_bottom = box.position.y + box.size.y
	label.add_theme_font_override("normal_font", RetroScreen.font())
	label.add_theme_font_size_override("normal_font_size", 30)
	label.add_theme_color_override("default_color", Color.WHITE)
	band.add_child(label)
	return label

func _show_page() -> void:
	text.text = str(pages[page]) if page < pages.size() else ""
	_typed = 0.0
	text.visible_characters = 0
	_refresh_answers()

func _last_page() -> bool:
	return page >= pages.size() - 1

func _refresh_answers() -> void:
	answers.visible = _last_page() and not options.is_empty() and _page_done()
	var parts: PackedStringArray = []
	for index: int in range(options.size()):
		parts.append(item(options[index]) if index == choice else options[index])
	answers.text = "      ".join(parts)

func _page_done() -> bool:
	return text.visible_characters < 0 or text.visible_characters >= text.get_total_character_count()

func _process(delta: float) -> void:
	if _page_done():
		return
	_typed += delta * TYPE_SPEED
	text.visible_characters = int(_typed)
	if _page_done():
		text.visible_characters = -1
		_refresh_answers()

func _input(event: InputEvent) -> void:
	# Everything stops here while the box is up: the game must not react to
	# the key that closes it.
	get_viewport().set_input_as_handled()
	if event.is_echo() or not event.is_pressed():
		return
	var asking: bool = _last_page() and not options.is_empty()
	if asking and _page_done() and (event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_right")):
		choice = posmod(choice + (-1 if event.is_action_pressed(&"ui_left") else 1), options.size())
		_refresh_answers()
		return
	var cancel: bool = event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")
	if not (cancel or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"interact")):
		return
	if not _page_done():
		text.visible_characters = -1
		_refresh_answers()
		return
	if asking and cancel:
		choice = 0
	if _last_page():
		_close()
	else:
		page += 1
		_show_page()

func _close() -> void:
	set_process_input(false)
	hide()
	get_tree().paused = _was_paused
	_advanced.emit()
