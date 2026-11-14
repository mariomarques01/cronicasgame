extends CanvasLayer
var world: Node3D
var root: Control
var menu: PanelContainer
var content: VBoxContainer
var menu_scroll: ScrollContainer
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
var quest_panel: Panel
var quest_title: Label
var quest_progress: Label
var desktop_actions: HBoxContainer
var map_button: Button
var body_font := FontVariation.new()
var ornament: RefCounted
var display_scale := preload("res://scripts/ui/display_scale.gd").new()
const BODY_FONT = preload("res://assets/fonts/nunito.ttf")
const DISPLAY_FONT = preload("res://assets/fonts/cinzel.ttf")

func label(text: String, size: int = 20) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_constant_override("outline_size", 0)
	node.add_theme_font_override("font", body_font)
	node.add_theme_color_override("font_outline_color", Color("17231b"))
	node.add_theme_color_override("font_color", Color("eee3bd"))
	return node

func _ready() -> void:
	display_scale.refresh(get_window(), 0.0)
	body_font.base_font = BODY_FONT
	body_font.variation_opentype = {"wght": 600}
	body_font.variation_embolden = 0.3
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.06, 0.96)
	style.set_corner_radius_all(14)
	style.border_color = Color("b99b58")
	style.set_border_width_all(2)
	style.set_content_margin_all(20)
	theme.set_stylebox("panel", "PanelContainer", style)
	theme.default_font = body_font
	theme.default_font_size = 16
	for state in ["normal", "hover", "pressed", "focus"]:
		var button_style := frame_style(Color(0.055, 0.09, 0.08, 0.92), Color("8c805b"), 10)
		if state == "hover" or state == "focus":
			button_style.bg_color = Color(0.12, 0.18, 0.14, 0.98)
			button_style.border_color = Color("e3c78b")
		elif state == "pressed":
			button_style.bg_color = Color(0.18, 0.22, 0.14, 1)
		button_style.set_content_margin_all(12)
		theme.set_stylebox(state, "Button", button_style)
	theme.set_color("font_color", "Button", Color("f0e8d2"))
	theme.set_color("font_hover_color", "Button", Color("fff3cf"))
	root.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	region = label("VALE DA FAZENDA", 14)
	region.add_theme_font_override("font", DISPLAY_FONT)
	region.add_theme_stylebox_override("normal", frame_style(Color(0.035, 0.065, 0.06, 0.88), Color(0.6, 0.51, 0.31, 0.5), 8))
	region.position = Vector2(20, 18)
	hud.add_child(region)
	quest_panel = Panel.new()
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_theme_stylebox_override("panel", frame_style(Color(0.035, 0.065, 0.06, 0.91), Color(0.6, 0.51, 0.31, 0.65), 12))
	quest_panel.position = Vector2(20, 64)
	quest_panel.size = Vector2(320, 140)
	hud.add_child(quest_panel)
	var eyebrow := label("JORNADA  /  MISSÃO PRINCIPAL", 10)
	eyebrow.add_theme_color_override("font_color", Color("c1ad79"))
	eyebrow.position = Vector2(18, 13)
	quest_panel.add_child(eyebrow)
	quest_title = label("O chamado da floresta", 16)
	quest_title.add_theme_font_override("font", DISPLAY_FONT)
	quest_title.position = Vector2(18, 35)
	quest_panel.add_child(quest_title)
	objective = label("", 15)
	objective.position = Vector2(18, 65)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_color_override("font_color", Color("d6ded4"))
	quest_panel.add_child(objective)
	quest_progress = label("", 12)
	quest_progress.position = Vector2(18, 113)
	quest_progress.add_theme_color_override("font_color", Color("d1bb80"))
	quest_panel.add_child(quest_progress)
	controls = label("WASD  Mover     Shift  Correr     Espaço  Pular     E  Interagir     F5 / F9  Salvar / carregar", 12)
	controls.add_theme_stylebox_override("normal", frame_style(Color(0.035, 0.065, 0.06, 0.85), Color(0.6, 0.51, 0.31, 0.35), 8))
	hud.add_child(controls)
	hint = label("", 17)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_stylebox_override("normal", frame_style(Color(0.035, 0.065, 0.06, 0.94), Color("b9a46c"), 10))
	hud.add_child(hint)
	message = label("", 15)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_stylebox_override("normal", frame_style(Color(0.035, 0.065, 0.06, 0.94), Color("b9a46c"), 10))
	hud.add_child(message)
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	menu.position = Vector2(320, 180)
	menu.custom_minimum_size = Vector2(320, 0)
	root.add_child(menu)
	menu_scroll = ScrollContainer.new()
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	menu.add_child(menu_scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	menu_scroll.add_child(content)
	touch = Control.new()
	touch.set_script(preload("res://scripts/player/touch_controls.gd"))
	touch.player = world.player
	hud.add_child(touch)
	mobile_buttons = Control.new()
	mobile_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mobile_buttons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(mobile_buttons)
	mobile_button("Pular", Vector2(-94,-92), func(): world.player.touch_jump = true)
	mobile_button("Interagir", Vector2(-174,-92), func():
		if not world.nearest.is_empty():
			world.interact(world.nearest))
	mobile_button("Mochila", Vector2(-174,-160), open_inventory)
	desktop_actions = HBoxContainer.new()
	desktop_actions.add_theme_constant_override("separation", 8)
	hud.add_child(desktop_actions)
	map_button = Button.new()
	map_button.text = "◇  Mapa"
	map_button.custom_minimum_size = Vector2(90, 40)
	map_button.pressed.connect(world.toggle_map)
	desktop_actions.add_child(map_button)
	touch.action_buttons.append(map_button)
	for spec: Dictionary in [{"text": "Mochila · I", "callback": open_inventory}]:
		var action := Button.new()
		action.text = spec.text
		action.custom_minimum_size = Vector2(90, 40)
		action.pressed.connect(spec.callback)
		desktop_actions.add_child(action)
	ornament = preload("res://scripts/ui/fantasy_hud.gd").new()
	ornament.build(self)
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
	var heading := label(title, 24)
	heading.add_theme_font_override("font", DISPLAY_FONT)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
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
		objective.text = Game.objective()
		if ornament != null:
			ornament.refresh(self)
		quest_progress.text = "Pedras antigas  %d / 3" % Game.collected.size() if Game.stage in [1, 2] else ("Passagem da floresta aberta" if Game.stage == 4 else "Explore e converse com Lia")

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
	button("Menu inicial", func():
		world.playing = false
		main_menu())

func settings_menu() -> void:
	clear_menu("Configurações")
	button("Pausar jogo", pause_menu)
	button("Alternar ciclo dia / noite", func(): world.day_speed = world.DAY_SPEED if world.day_speed == 0 else 0.0)
	button("Alternar sombras", func(): world.sun.shadow_enabled = not world.sun.shadow_enabled)
	button("Voltar ao jogo", show_play)

func open_quest() -> void:
	clear_menu("O Chamado da Floresta")
	var body := label(Game.objective(), 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(body)
	var progress_note := label(quest_progress.text, 15)
	progress_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(progress_note)
	button("Voltar ao jogo", show_play)

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
	node.add_theme_font_size_override("font_size", 14)
	node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	node.position = offset
	node.size = Vector2(74,60)
	node.pressed.connect(callback)
	mobile_buttons.add_child(node)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch.action_buttons.append(node)

func frame_style(background: Color, border: Color, radius_value: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius_value)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _process(delta: float) -> void:
	display_scale.refresh(get_window(), delta)
	var viewport_size := get_viewport().get_visible_rect().size
	menu.custom_minimum_size.x = minf(520, viewport_size.x - 24)
	menu.size = Vector2(menu.custom_minimum_size.x, minf(content.get_combined_minimum_size().y + 40, viewport_size.y - 24))
	menu.position = (viewport_size - menu.size) * 0.5
	content.add_theme_constant_override("separation", 6 if viewport_size.y < 500 else 10)
	for child in content.get_children():
		if child is Button:
			child.custom_minimum_size.y = 32 if viewport_size.y < 500 else 42
	var compact := viewport_size.x < 600
	var margin := 12.0 if compact else 20.0
	region.position = Vector2(margin, 16)
	region.add_theme_font_size_override("font_size", 11 if compact else 14)
	region.reset_size()
	quest_panel.position = Vector2(margin, 62)
	quest_panel.size.x = minf(320, viewport_size.x - margin * 2)
	objective.size.x = quest_panel.size.x - 36
	quest_title.add_theme_font_size_override("font_size", 14 if compact else 16)
	for i in desktop_actions.get_child_count():
		var action: Button = desktop_actions.get_child(i)
		action.visible = i == 0 or (not touch.active and not compact)
		# Touch is dispatched explicitly to support a second finger on the controls.
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE if touch.active else Control.MOUSE_FILTER_STOP
	desktop_actions.reset_size()
	desktop_actions.position = Vector2(viewport_size.x - desktop_actions.size.x - margin, 14)
	map_button.text = "◇ Voltar" if world.map_camera.current else "◇ Mapa"
	mobile_buttons.visible = touch.active
	controls.visible = not touch.active and viewport_size.x >= 900
	controls.position = Vector2(margin, viewport_size.y - 49)
	hint.visible = not hint.text.is_empty() and world.player.enabled
	hint.size.x = minf(360, viewport_size.x - margin * 2)
	hint.position = Vector2((viewport_size.x - hint.size.x) * 0.5, viewport_size.y - (240 if touch.active else 110))
	message.visible = notice_time > 0 and not message.text.is_empty()
	message.size.x = minf(360, viewport_size.x - margin * 2)
	message.position = Vector2(margin, 216)
	if touch.active:
		touch.visible = world.player.enabled
	if ornament != null:
		ornament.layout(self, viewport_size)
	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			message.text = ""
