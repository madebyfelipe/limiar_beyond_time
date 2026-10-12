class_name TerminalMenu
extends RetroScreen

signal save_requested
signal closed
const SAVE_SKIN := preload("res://assets/ui/retro_terminal/save_terminal_skin_v02.png")
const SHOP_SKIN := preload("res://assets/ui/retro_terminal/shop_skin_v02.png")
var save_page: Control
var shop_page: Control
var save_button: Button
var shop_button: Button
var buy_button: Button
var back_button: Button
var record_label: Label
var message: Label
var credits_label: Label
var item_name: Label
var detail: Label
var stock_label: Label
var item_buttons: Array[Button] = []
var selected: int = 0
var in_shop: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"terminal_menus")
	build(SAVE_SKIN)
	save_page = Control.new()
	save_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(save_page)
	save_button = button_at("SAVE", Rect2(110, 310, 655, 150), func() -> void: save_requested.emit(), 58)
	shop_button = button_at("SHOP", Rect2(110, 495, 655, 150), show_shop, 58)
	var exit_button := button_at("EXIT", Rect2(110, 705, 287, 64), close, 30)
	record_label = label_at("", Rect2(1305, 405, 245, 172), 25)
	for control: Control in [save_button, shop_button, exit_button, record_label]:
		control.reparent(save_page)
	focus_ring([save_button, shop_button, exit_button])
	shop_page = Control.new()
	shop_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(shop_page)
	for index: int in range(SupplyStock.ITEMS.size()):
		var item: Dictionary = SupplyStock.ITEMS[index]
		var button := button_at("%s    %d" % [item["name"], item["price"]], Rect2(110, 307 + index * 141, 665, 125), func() -> void: select_item(index), 38)
		button.focus_entered.connect(select_item.bind(index))
		button.reparent(shop_page)
		item_buttons.append(button)
	buy_button = button_at("BUY", Rect2(454, 732, 416, 70), buy, 34)
	back_button = button_at("BACK", Rect2(913, 732, 289, 70), show_save, 32)
	credits_label = label_at("", Rect2(1265, 178, 305, 43), 25)
	item_name = label_at("", Rect2(895, 282, 650, 43), 32)
	detail = label_at("", Rect2(1300, 402, 260, 185), 23)
	stock_label = label_at("", Rect2(900, 402, 344, 170), 29)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var footer := label_at("SETAS SELECIONAR · ENTER CONFIRMAR · ESC BACK", Rect2(170, 817, 1332, 44), 25)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for control: Control in [buy_button, back_button, credits_label, item_name, detail, stock_label, footer]:
		control.reparent(shop_page)
	var all_buttons: Array[Button] = item_buttons.duplicate()
	all_buttons.append(buy_button)
	all_buttons.append(back_button)
	focus_ring(all_buttons)
	message = label_at("", Rect2(890, 659, 660, 62), 21)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_page.hide()
	hide()

func open() -> void:
	if visible or get_tree().paused:
		return
	SupplyStock.ensure_loaded()
	show()
	get_tree().paused = true
	show_save()
	message.text = ""

func show_save() -> void:
	in_shop = false
	backdrop.texture = SAVE_SKIN
	save_page.show()
	shop_page.hide()
	refresh_record()
	message.text = ""
	save_button.grab_focus()

func refresh_record() -> void:
	var record: Dictionary = SaveGame.read()
	record_label.text = "GUARITA\nSEM REGISTRO" if record.is_empty() else "GUARITA\nREGISTRO %02d\n%s" % [record["saves"], SaveGame.stamp(record).replace(" ", "\n")]

func show_shop() -> void:
	in_shop = true
	backdrop.texture = SHOP_SKIN
	save_page.hide()
	shop_page.show()
	message.text = "COMPRAS SÃO GUARDADAS AO USAR SAVE."
	select_item(selected)
	item_buttons[selected].grab_focus()

func select_item(index: int) -> void:
	selected = index
	var item: Dictionary = SupplyStock.ITEMS[index]
	credits_label.text = "CREDITS %d" % SupplyStock.credits
	item_name.text = item["name"]
	detail.text = "%s\nPREÇO %d" % [item["description"], item["price"]]
	stock_label.text = "ESTOQUE\n" + SupplyStock.quantity(index)
	buy_button.disabled = not SupplyStock.available(index)
	buy_button.text = "BUY" if not buy_button.disabled else ("ADQUIRIDA" if index == 2 and SupplyStock.weapon else "INDISPONÍVEL")

func buy() -> void:
	if SupplyStock.buy(selected):
		message.text = "%s COMPRADO · USE SAVE PARA GUARDAR." % SupplyStock.ITEMS[selected]["name"]
	else:
		message.text = "COMPRA INDISPONÍVEL · CONFIRA CRÉDITOS E ESTOQUE."
	select_item(selected)
	if buy_button.disabled:
		item_buttons[selected].grab_focus()

func close() -> void:
	if not visible:
		return
	hide()
	get_viewport().gui_release_focus()
	get_tree().paused = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause") and not event.is_echo():
		if in_shop:
			show_save()
		else:
			close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if visible:
		get_tree().paused = false
