extends RefCounted
## Ornate framing and iconography based on the user's selected HUD reference.
const ART := "res://assets/ui/hud/"
var profile: Panel
var portrait: TextureRect
var portrait_rim: TextureRect
var player_name: Label
var progress: ProgressBar
var progress_text: Label
var stones: Panel
var regions: Panel
var stone_count: Label
var region_count: Label
var settings: Button
var minimap: Control
var book: TextureRect
var diamond: TextureRect
var separator: ColorRect
var bag_badge: Label

func texture_frame(button_frame: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(ART + ("button.svg" if button_frame else "panel.svg"))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 24 if button_frame else 22)
		style.set_content_margin(side, 12)
	return style

func art(parent: Node, id: String, position: Vector2, dimensions: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = load(ART + id + ".svg")
	node.position = position
	node.size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func make_label(ui: CanvasLayer, parent: Node, text: String, size_value: int) -> Label:
	var node: Label = ui.label(text, size_value)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func build(ui: CanvasLayer) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := texture_frame(true)
		if state == "hover" or state == "focus":
			style.modulate_color = Color(1.18, 1.13, 1.02)
		elif state == "pressed":
			style.modulate_color = Color(0.8, 0.83, 0.75)
		ui.root.theme.set_stylebox(state, "Button", style)
	ui.menu.add_theme_stylebox_override("panel", texture_frame())
	ui.quest_panel.add_theme_stylebox_override("panel", texture_frame())
	ui.region.hide()
	ui.quest_title.text = "O Chamado da Floresta"
	var eyebrow: Label = ui.quest_panel.get_child(0)
	eyebrow.text = "Missão Principal"
	eyebrow.add_theme_font_override("font", ui.DISPLAY_FONT)
	eyebrow.add_theme_color_override("font_color", Color("efd18a"))
	book = art(ui.quest_panel, "book", Vector2.ZERO, Vector2(24, 24))
	diamond = art(ui.quest_panel, "diamond", Vector2.ZERO, Vector2(22, 22))
	separator = ColorRect.new()
	separator.color = Color(0.78, 0.66, 0.36, 0.3)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.quest_panel.add_child(separator)
	profile = Panel.new()
	profile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile.add_theme_stylebox_override("panel", texture_frame())
	ui.hud.add_child(profile)
	portrait = TextureRect.new()
	portrait.texture = load(ART + "bunny_portrait.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var circular := ShaderMaterial.new()
	circular.shader = preload("res://assets/shaders/hud_circle.gdshader")
	portrait.material = circular
	profile.add_child(portrait)
	portrait_rim = art(profile, "portrait_frame", Vector2.ZERO, Vector2.ZERO)
	player_name = make_label(ui, profile, "Explorador", 20)
	player_name.add_theme_font_override("font", ui.DISPLAY_FONT)
	progress = ProgressBar.new()
	progress.max_value = 4
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color("08140e")
	bar.border_color = Color("a98b4c")
	bar.set_border_width_all(1)
	bar.set_corner_radius_all(4)
	progress.add_theme_stylebox_override("background", bar)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("77ae4d")
	fill.set_corner_radius_all(3)
	progress.add_theme_stylebox_override("fill", fill)
	profile.add_child(progress)
	progress_text = make_label(ui, profile, "", 11)
	progress_text.add_theme_color_override("font_color", Color("d1d6b3"))
	stones = Panel.new()
	stones.add_theme_stylebox_override("panel", texture_frame())
	stones.tooltip_text = "Pedras antigas coletadas"
	ui.hud.add_child(stones)
	art(stones, "crystal", Vector2(8, 8), Vector2(23, 23))
	stone_count = make_label(ui, stones, "", 13)
	stone_count.position = Vector2(36, 10)
	regions = Panel.new()
	regions.add_theme_stylebox_override("panel", texture_frame())
	regions.tooltip_text = "Regiões desbloqueadas"
	ui.hud.add_child(regions)
	art(regions, "region", Vector2(8, 8), Vector2(23, 23))
	region_count = make_label(ui, regions, "", 13)
	region_count.position = Vector2(36, 10)
	settings = Button.new()
	settings.tooltip_text = "Pausa e opções"
	for state in ["normal", "hover", "pressed", "focus"]:
		var compact_style := texture_frame(true)
		compact_style.set_content_margin_all(3)
		settings.add_theme_stylebox_override(state, compact_style)
	settings.icon = load(ART + "gear.svg")
	settings.expand_icon = true
	settings.add_theme_constant_override("icon_max_width", 25)
	settings.pressed.connect(ui.pause_menu)
	ui.hud.add_child(settings)
	ui.touch.action_buttons.append(settings)
	minimap = Control.new()
	minimap.set_script(preload("res://scripts/ui/minimap.gd"))
	minimap.world = ui.world
	ui.hud.add_child(minimap)
	ui.touch.action_buttons.append(minimap.click_target)
	ui.map_button.reparent(ui.hud)
	for state in ["normal", "hover", "pressed", "focus"]:
		var map_style := texture_frame()
		map_style.set_content_margin_all(5)
		ui.map_button.add_theme_stylebox_override(state, map_style)
	ui.map_button.icon = load(ART + "map.svg")
	ui.map_button.expand_icon = true
	ui.map_button.add_theme_constant_override("icon_max_width", 20)
	ui.map_button.custom_minimum_size = Vector2.ZERO
	for i in ui.mobile_buttons.get_child_count():
		var action: Button = ui.mobile_buttons.get_child(i)
		var title := action.text
		action.text = ""
		action.tooltip_text = title
		art(action, ["jump", "hand", "bag", "pause"][i], Vector2(23, 10), Vector2(28, 28))
		var caption := make_label(ui, action, title, 12)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.position = Vector2(2, 44)
		caption.size = Vector2(70, 20)
		if i == 2:
			bag_badge = make_label(ui, action, "", 11)
			bag_badge.position = Vector2(58, 0)
			bag_badge.add_theme_stylebox_override("normal", ui.frame_style(Color("8d3928"), Color("f5d28a"), 8))
	refresh(ui)

func refresh(ui: CanvasLayer) -> void:
	var game: Node = ui.world.get_node("/root/Game")
	stone_count.text = "%d / 3" % game.collected.size()
	region_count.text = "%d / 2" % game.regions.size()
	progress.value = game.stage
	progress_text.text = "Missão  %d / 4 etapas" % game.stage
	bag_badge.text = str(int(game.inventory.get("ancient_stone", 0)))
	bag_badge.visible = not game.inventory.is_empty()

func layout(ui: CanvasLayer, screen: Vector2) -> void:
	var compact := screen.x < 600
	var margin := 10.0 if compact else 20.0
	var short_screen := screen.y < 500
	var compressed := compact or short_screen
	var head_height := 50.0 if compact or short_screen else 68.0
	var profile_width := 172.0 if compact else 282.0
	profile.position = Vector2(margin, 12)
	profile.size = Vector2(profile_width, head_height)
	var portrait_size := head_height + 8
	portrait.position = Vector2(3, -1)
	portrait.size = Vector2(portrait_size - 8, portrait_size - 8)
	portrait_rim.position = Vector2(-4, -8)
	portrait_rim.size = Vector2(portrait_size + 7, portrait_size + 7)
	player_name.position = Vector2(portrait_size + 1, 5)
	player_name.add_theme_font_size_override("font_size", 13 if compact else 19)
	progress.position = Vector2(portrait_size + 2, head_height * 0.5)
	progress.size = Vector2(profile_width - portrait_size - 14, 7)
	progress_text.position = Vector2(portrait_size + 2, head_height * 0.5 + 9)
	progress_text.add_theme_font_size_override("font_size", 8 if compact else 11)
	var settings_size := 34.0 if compact else 42.0
	settings.position = Vector2(screen.x - margin - settings_size, 14)
	settings.size = Vector2(settings_size, settings_size)
	settings.mouse_filter = Control.MOUSE_FILTER_IGNORE if ui.touch.active else Control.MOUSE_FILTER_STOP
	var badge_width := (screen.x - profile_width - margin * 2 - settings_size - 18) * 0.5 if compact else 100.0
	regions.size = Vector2(badge_width, 38)
	stones.size = Vector2(badge_width, 38)
	regions.position = Vector2(settings.position.x - badge_width - 5, 15)
	stones.position = Vector2(regions.position.x - badge_width - 5, 15)
	for count: Label in [stone_count, region_count]:
		count.add_theme_font_size_override("font_size", 11 if compact else 14)
	var map_size := 90.0 if compact else (96.0 if short_screen else 132.0)
	var quest_y := 78.0 if compact or short_screen else 100.0
	minimap.position = Vector2(screen.x - margin - map_size, quest_y)
	minimap.size = Vector2(map_size, map_size)
	minimap.click_target.mouse_filter = Control.MOUSE_FILTER_IGNORE if ui.touch.active else Control.MOUSE_FILTER_STOP
	ui.map_button.position = Vector2(minimap.position.x - 3, quest_y + map_size + 5)
	ui.map_button.size = Vector2(map_size + 6, 32)
	ui.map_button.text = "Voltar" if ui.world.map_camera.current else "Mapa"
	ui.map_button.add_theme_font_size_override("font_size", 12 if compact else 15)
	ui.quest_panel.position = Vector2(margin, quest_y)
	ui.quest_panel.size = Vector2(screen.x - map_size - margin * 2 - 12 if compact else 380, 132 if compact or short_screen else 164)
	var eyebrow: Label = ui.quest_panel.get_child(0)
	eyebrow.position = Vector2(42, 13)
	eyebrow.add_theme_font_size_override("font_size", 12 if compact else 15)
	book.position = Vector2(15, 9)
	ui.quest_title.position = Vector2(18, 38)
	ui.quest_title.add_theme_font_size_override("font_size", 13 if compact else 19)
	separator.position = Vector2(18, 64 if compressed else 73)
	separator.size = Vector2(ui.quest_panel.size.x - 36, 1)
	ui.objective.position = Vector2(39, 74 if compressed else 87)
	ui.objective.size.x = ui.quest_panel.size.x - 51
	ui.objective.add_theme_font_size_override("font_size", 12 if compact else 15)
	diamond.position = Vector2(12, 73 if compressed else 87)
	ui.quest_progress.position = Vector2(20, 109 if compressed else 136)
	ui.quest_progress.add_theme_font_size_override("font_size", 9 if compact else 12)
	ui.message.position.y = quest_y + ui.quest_panel.size.y + 10
	ui.desktop_actions.visible = not ui.touch.active and not compact
	ui.desktop_actions.position = Vector2(screen.x - ui.desktop_actions.size.x - margin, screen.y - 62)
	for i in ui.mobile_buttons.get_child_count():
		var action: Button = ui.mobile_buttons.get_child(i)
		action.size = Vector2(74, 76)
		action.position = Vector2(screen.x - (94 if i in [0, 3] else 174), screen.y - (100 if i in [0, 1] else 184))
