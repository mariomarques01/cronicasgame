extends CanvasLayer
var world: Node3D
var root: Control
var menu: PanelContainer
var content: VBoxContainer
var hud: Control
var objective: Label
var region: Label
var hint: Label
var message: Label
var notice_time: float = 0

func label(text: String, size: int = 20) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_constant_override("outline_size", 4)
	node.add_theme_color_override("font_outline_color", Color("17231b"))
	node.add_theme_color_override("font_color", Color("eee3bd"))
	return node

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.08, 0.96)
	style.border_color = Color("b99b58")
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	theme.set_stylebox("panel", "PanelContainer", style)
	root.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	region = label("VALE DA FAZENDA", 26)
	region.position = Vector2(32, 24)
	hud.add_child(region)
	objective = label("", 20)
	objective.position = Vector2(32, 65)
	hud.add_child(objective)
	var controls := label("WASD mover  •  Mouse câmera  •  Shift correr  •  Espaço pular
E interagir  •  I inventário  •  Esc pausa  •  F5 salvar  •  F9 carregar", 16)
	controls.position = Vector2(32, 640)
	hud.add_child(controls)
	hint = label("", 24)
	hint.position = Vector2(440, 580)
	hud.add_child(hint)
	message = label("", 20)
	message.position = Vector2(32, 110)
	hud.add_child(message)
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	menu.position = Vector2(320, 180)
	menu.custom_minimum_size = Vector2(640, 340)
	root.add_child(menu)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	menu.add_child(content)
	main_menu()

func clear_menu(title: String) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.add_child(label(title, 30))
	menu.show()
	world.player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func button(text: String, callback: Callable) -> void:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.pressed.connect(callback)
	content.add_child(node)

func main_menu() -> void:
	hud.hide()
	clear_menu("As Crônicas de Eldervale")
	content.add_child(label("O Segredo da Árvore Celestial", 21))
	content.add_child(label("Protótipo jogável • Vale da Fazenda", 17))
	button("Iniciar uma nova jornada", func(): world.start_game(false))
	if FileAccess.file_exists(Game.SAVE_PATH):
		button("Continuar jornada", func(): world.start_game(true))
	if not OS.has_feature("web"):
		button("Sair", func(): get_tree().quit())

func show_play() -> void:
	menu.hide()
	hud.show()
	world.player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	refresh()

func refresh() -> void:
	if is_instance_valid(objective):
		objective.text = "O CHAMADO DA FLORESTA
" + Game.objective()

func dialogue(text: String) -> void:
	clear_menu("O Chamado da Floresta")
	var body := label(text, 19)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 560
	content.add_child(body)
	button("Continuar", show_play)

func notify(text: String) -> void:
	message.text = text
	notice_time = 5
	if menu.visible and not world.playing:
		content.add_child(label(text, 16))

func pause_menu() -> void:
	clear_menu("Um descanso no vale")
	button("Retomar", show_play)
	button("Salvar jornada", func(): Game.save_game(world.player.position))
	button("Carregar jornada", func():
		if Game.load_game():
			world.player.position = Game.player_position
			show_play())
	button("Alternar ciclo dia / noite", func(): world.day_speed = 0.006 if world.day_speed == 0 else 0.0)
	button("Alternar sombras", func(): world.sun.shadow_enabled = not world.sun.shadow_enabled)
	button("Menu inicial", func():
		world.playing = false
		main_menu())

func _unhandled_input(event: InputEvent) -> void:
	if not world.playing:
		return
	if event.is_action_pressed("pause"):
		if menu.visible:
			show_play()
		else:
			pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and world.player.enabled:
		clear_menu("Mochila • %d / %d espaços" % [Game.inventory.size(), Game.capacity])
		content.add_child(label("Pedras antigas: %d
Itens de missão • não consumíveis" % int(Game.inventory.get("ancient_stone", 0))))
		button("Voltar", show_play)

func _process(delta: float) -> void:
	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			message.text = ""
