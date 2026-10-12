class_name TerminalMenu
extends RetroScreen
## In-game command console. Dispatches game commands; no operating-system shell.
signal save_requested
signal closed

const COMMANDS := ["help", "save", "shop", "buy", "inventory", "status", "clear", "exit"]
const ALIASES := {"ajuda": "help", "salvar": "save", "loja": "shop", "comprar": "buy", "inventario": "inventory", "estado": "status", "limpar": "clear", "sair": "exit"}
const USAGE := {
	"help": "help [comando]", "save": "save", "shop": "shop",
	"buy": "buy ammo | medkit | weapon", "inventory": "inventory",
	"status": "status", "clear": "clear", "exit": "exit",
}
const HELP := {
	"help": "Lista comandos ou explica um comando.",
	"save": "Grava progresso e estoque no terminal.",
	"shop": "Lista produtos, preços e saldo.",
	"buy": "Compra um produto. Exemplo: buy ammo",
	"inventory": "Mostra os suprimentos disponíveis.",
	"status": "Mostra o objetivo e o último registro.",
	"clear": "Limpa a tela; mantém o histórico de comandos.",
	"exit": "Encerra a sessão e retorna ao jogo.",
}
const MAX_LINES := 300
const MAX_HISTORY := 100
var input_field: LineEdit
var output: RichTextLabel
var scroll: ScrollContainer
var lines: PackedStringArray = []
var history: PackedStringArray = []
var history_index: int = 0
var draft: String = ""
var booted: bool = false
var console_font: Font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"terminal_menus")
	design_size = Vector2(1280, 720)
	build(null)
	(get_child(0) as ColorRect).color = Color("020704")
	var system := SystemFont.new()
	system.font_names = PackedStringArray(["Consolas", "Liberation Mono", "monospace"])
	console_font = system
	var frame := PanelContainer.new()
	frame.position = Vector2(32, 32)
	frame.size = Vector2(1216, 656)
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("030b06")
	skin.set_border_width_all(1)
	skin.border_color = Color("25432c")
	skin.set_content_margin_all(24)
	frame.add_theme_stylebox_override("panel", skin)
	canvas.add_child(frame)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	frame.add_child(scroll)
	var text_area := VBoxContainer.new()
	text_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_area.add_theme_constant_override("separation", 4)
	scroll.add_child(text_area)
	output = RichTextLabel.new()
	output.name = "Transcript"
	output.fit_content = true
	output.scroll_active = false
	output.bbcode_enabled = false
	output.selection_enabled = true
	output.focus_mode = Control.FOCUS_NONE
	output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output.add_theme_font_override("normal_font", console_font)
	output.add_theme_font_size_override("normal_font_size", 26)
	output.add_theme_color_override("default_color", Color("9bda91"))
	text_area.add_child(output)
	var prompt_row := HBoxContainer.new()
	prompt_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_row.add_theme_constant_override("separation", 12)
	text_area.add_child(prompt_row)
	var prompt := Label.new()
	prompt.text = "GUARITA>"
	prompt.add_theme_font_override("font", console_font)
	prompt.add_theme_font_size_override("font_size", 26)
	prompt.add_theme_color_override("font_color", Color("b5f7a6"))
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_row.add_child(prompt)
	input_field = LineEdit.new()
	input_field.name = "CommandLine"
	input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_field.max_length = 160
	input_field.caret_blink = true
	input_field.keep_editing_on_text_submit = true
	input_field.add_theme_font_override("font", console_font)
	input_field.add_theme_font_size_override("font_size", 26)
	input_field.add_theme_color_override("font_color", Color("b5f7a6"))
	input_field.add_theme_color_override("caret_color", Color("b5f7a6"))
	input_field.add_theme_color_override("selection_color", Color("28442c"))
	for state: String in ["normal", "focus"]:
		input_field.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	prompt_row.add_child(input_field)
	input_field.text_submitted.connect(execute_command)
	input_field.text_changed.connect(func(_text: String) -> void: _queue_scroll())
	hide()

func open() -> void:
	if visible or get_tree().paused:
		return
	SupplyStock.ensure_loaded()
	show()
	get_tree().paused = true
	if not booted:
		booted = true
		write_line("LIMIAR // TERMINAL DA GUARITA\nConexão local estabelecida.\nDigite help para listar os comandos.\nTab completa · ↑↓ histórico · Esc sai.\n")
	else:
		write_line("\nSessão reaberta. Digite help para ajuda.")
	input_field.clear()
	history_index = history.size()
	draft = ""
	input_field.grab_focus()
	_queue_scroll()

func write_line(text: String) -> void:
	for line: String in text.split("\n"):
		lines.append(line)
	while lines.size() > MAX_LINES:
		lines.remove_at(0)
	output.text = "\n".join(lines)
	_queue_scroll()

func _queue_scroll() -> void:
	call_deferred("_scroll_bottom")

func _scroll_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func clear_screen() -> void:
	lines.clear()
	output.text = ""
	_queue_scroll()

func execute_command(raw: String) -> void:
	if not visible:
		return
	var command_line: String = raw.strip_edges()
	input_field.clear()
	if command_line.is_empty():
		return
	if command_line.length() > input_field.max_length:
		write_line("ERRO: comando longo demais.")
		return
	history.append(command_line)
	while history.size() > MAX_HISTORY:
		history.remove_at(0)
	history_index = history.size()
	draft = ""
	write_line("GUARITA> " + command_line)
	var words: PackedStringArray = command_line.to_lower().replace("\t", " ").split(" ", false)
	var verb: String = words[0]
	verb = String(ALIASES.get(verb, verb))
	var args: PackedStringArray = words.slice(1)
	if not COMMANDS.has(verb):
		write_line("Comando desconhecido. Digite help.")
	elif verb == "help":
		_help(args)
	elif verb == "buy":
		_buy(args)
	elif not args.is_empty():
		write_line("Uso: " + String(USAGE[verb]))
	else:
		match verb:
			"save": save_requested.emit()
			"shop": _shop()
			"inventory": _inventory()
			"status": _status()
			"clear": clear_screen()
			"exit":
				write_line("Sessão encerrada.")
				close()
	if visible:
		input_field.grab_focus()

func _help(args: PackedStringArray) -> void:
	if args.is_empty():
		var help_lines: PackedStringArray = ["COMANDOS"]
		for command: String in COMMANDS:
			help_lines.append("  %-14s %s" % [USAGE[command], HELP[command]])
		write_line("\n".join(help_lines))
	elif args.size() == 1:
		var command: String = String(ALIASES.get(args[0], args[0]))
		if HELP.has(command):
			write_line("Uso: %s\n%s" % [USAGE[command], HELP[command]])
		else:
			write_line("Comando desconhecido. Digite help.")
	else:
		write_line("Uso: help [comando]")

func _shop() -> void:
	write_line("SUPRIMENTOS — CRÉDITOS %d\n  ammo     300   30 cartuchos\n  medkit   500   1 kit médico\n  weapon  1800   pistola\nUse buy <produto>. Compras são guardadas ao usar save." % SupplyStock.credits)

func _buy(args: PackedStringArray) -> void:
	var product: String = " ".join(args)
	var products := {"ammo": 0, "magazine": 0, "medkit": 1, "med kit": 1, "recovery": 1, "weapon": 2}
	if not products.has(product):
		write_line("Uso: buy ammo | medkit | weapon")
		return
	var index: int = int(products[product])
	if index == 2 and SupplyStock.weapon:
		write_line("A pistola já foi adquirida.")
	elif SupplyStock.credits < int(SupplyStock.ITEMS[index]["price"]):
		write_line("Créditos insuficientes. Saldo: %d." % SupplyStock.credits)
	elif SupplyStock.buy(index):
		write_line("%s adquirido. Saldo: %d.\nUse save para guardar o estoque." % [SupplyStock.ITEMS[index]["name"], SupplyStock.credits])
	else:
		write_line("Compra indisponível: limite de estoque atingido.")

func _inventory() -> void:
	write_line("CRÉDITOS %d\nCARTUCHOS %d\nKITS MÉDICOS %d\nPISTOLA %s" % [SupplyStock.credits, SupplyStock.ammo, SupplyStock.med_kits, "ADQUIRIDA" if SupplyStock.weapon else "NÃO ADQUIRIDA"])

func _status() -> void:
	write_line("OBJETIVO: " + MissionState.objective())
	var record: Dictionary = SaveGame.read()
	write_line("Nenhum registro salvo." if record.is_empty() else "REGISTRO %d — %s" % [record["saves"], SaveGame.stamp(record)])

func _recall(direction: int) -> void:
	if history.is_empty():
		return
	if history_index == history.size():
		draft = input_field.text
	history_index = clampi(history_index + direction, 0, history.size())
	input_field.text = draft if history_index == history.size() else history[history_index]
	input_field.caret_column = input_field.text.length()
	input_field.grab_focus()

func _complete() -> void:
	var raw: String = input_field.text.to_lower()
	var candidates: PackedStringArray = []
	var prefix: String = raw
	var command: String = ""
	if raw.contains(" "):
		command = raw.get_slice(" ", 0)
		if String(ALIASES.get(command, command)) != "buy":
			return
		prefix = raw.substr(command.length() + 1).strip_edges()
		for product: String in ["ammo", "medkit", "weapon"]:
			if product.begins_with(prefix):
				candidates.append(product)
	else:
		for name: String in COMMANDS:
			if name.begins_with(prefix):
				candidates.append(name)
	if candidates.size() == 1:
		input_field.text = (command + " " if not command.is_empty() else "") + candidates[0]
		if input_field.text == "buy":
			input_field.text += " "
		input_field.caret_column = input_field.text.length()
	elif candidates.size() > 1:
		write_line("  ".join(candidates))
	input_field.grab_focus()

func close() -> void:
	if not visible:
		return
	hide()
	get_viewport().gui_release_focus()
	get_tree().paused = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.pressed:
		var handled: bool = true
		match event.keycode:
			KEY_UP: _recall(-1)
			KEY_DOWN: _recall(1)
			KEY_TAB: _complete()
			KEY_L:
				if event.ctrl_pressed:
					clear_screen()
				else:
					handled = false
			KEY_PAGEUP: scroll.scroll_vertical -= int(scroll.size.y * 0.85)
			KEY_PAGEDOWN: scroll.scroll_vertical += int(scroll.size.y * 0.85)
			_: handled = false
		if handled:
			get_viewport().set_input_as_handled()
		elif event.unicode >= 32 and not input_field.has_focus():
			input_field.grab_focus()

func _exit_tree() -> void:
	if visible:
		get_tree().paused = false
