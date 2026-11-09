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
var touch: Control
var mobile_buttons: Control
var controls: Label
var title_screen: Control

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
	controls = label("WASD mover  •  Mouse câmera  •  Shift correr  •  Espaço pular
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
	touch = Control.new()
	touch.set_script(preload("res://scripts/player/touch_controls.gd"))
	touch.player = world.player
	hud.add_child(touch)
	mobile_buttons = Control.new()
	mobile_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_buttons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(mobile_buttons)
	mobile_button("Pular", Vector2(-150,-145), func(): world.player.touch_jump = true)
	mobile_button("Interagir", Vector2(-285,-235), func():
		if not world.nearest.is_empty():
			world.interact(world.nearest))
	mobile_button("Mochila", Vector2(-285,-145), open_inventory)
	mobile_button("Pausa", Vector2(-150,-235), pause_menu)
	var map_button := Button.new()
	map_button.text = "Mapa / voltar"
	map_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_button.position = Vector2(-190,24)
	map_button.size = Vector2(165,60)
	map_button.pressed.connect(world.toggle_map)
	hud.add_child(map_button)
	touch.action_buttons.append(map_button)
	if touch.active:
		map_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen = Control.new()
	title_screen.set_script(preload("res://scripts/ui/title_screen.gd"))
	root.add_child(title_screen)
	title_screen.new_journey.connect(func(): world.start_game(false))
	title_screen.continue_journey.connect(func(): world.start_game(true))
	main_menu()

func clear_menu(title: String) -> void:
	if is_instance_valid(title_screen):
		title_screen.hide()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.add_child(label(title, 30))
	menu.show()
	world.player.enabled = false
	world.player.avatar.animate(0, false, false)
	if is_instance_valid(touch):
		touch.reset()
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
	menu.hide()
	title_screen.refresh()
	title_screen.show()

func show_play() -> void:
	title_screen.hide()
	menu.hide()
	hud.show()
	world.player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if touch.active else Input.MOUSE_MODE_CAPTURED
	refresh()

func refresh() -> void:
	if is_instance_valid(objective):
		objective.text = "O CHAMADO DA FLORESTA
" + Game.objective()

func dialogue(text: String) -> void:
	clear_menu("O Chamado da Floresta")
	var body := label(text, 19)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = minf(560, get_viewport().get_visible_rect().size.x - 100)
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
		open_inventory()

func open_inventory() -> void:
	clear_menu("Mochila • %d / %d espaços" % [Game.inventory.size(), Game.capacity])
	content.add_child(label("Pedras antigas: %d" % int(Game.inventory.get("ancient_stone", 0))))
	button("Voltar", show_play)

func mobile_button(text: String, offset: Vector2, callback: Callable) -> void:
	var node := Button.new()
	node.text = text
	node.add_theme_font_size_override("font_size", 24)
	node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	node.position = offset
	node.size = Vector2(125,90)
	node.pressed.connect(callback)
	mobile_buttons.add_child(node)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch.action_buttons.append(node)

func _process(delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	menu.position = (viewport_size - menu.size) * 0.5
	mobile_buttons.visible = touch.active
	controls.visible = not touch.active
	controls.position.y = viewport_size.y - 65
	hint.position = Vector2(32, viewport_size.y - (310 if touch.active else 110))
	message.position.y = 150
	if touch.active:
		objective.add_theme_font_size_override("font_size",24)
		touch.visible = world.player.enabled

	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			message.text = ""
