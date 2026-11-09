extends Control
signal new_journey
signal continue_journey
const ART = preload("res://assets/ui/title_screen.png")
var frame: Control
var start_button: Button
var continue_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blur := Shader.new()
	blur.code = """shader_type canvas_item;
	void fragment() {
		vec4 color = vec4(0.0);
		// Extend only the scenery at the image edges, never duplicate the logo.
		vec2 scenery = vec2(mix(0.025, 0.975, step(0.5, UV.x)), UV.y);
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				color += texture(TEXTURE, clamp(scenery + vec2(float(x) * 0.012, float(y) * 0.035), vec2(0.0), vec2(1.0)));
			}
		}
		COLOR = vec4(color.rgb / 9.0 * 0.32, 1.0);
	}"""
	var backdrop_material := ShaderMaterial.new()
	backdrop_material.shader = blur
	backdrop.material = backdrop_material
	add_child(backdrop)
	frame = Control.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var art := TextureRect.new()
	art.texture = ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	start_button = Button.new()
	start_button.name = "StartJourney"
	start_button.text = "Iniciar nova jornada"
	start_button.tooltip_text = start_button.text
	start_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 0.9, 0.5, 0.10 if state == "hover" else (0.18 if state == "pressed" else 0.0))
		style.set_corner_radius_all(22)
		if state == "focus":
			style.border_color = Color("ffe19b")
			style.set_border_width_all(3)
		start_button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_outline_color"]:
		start_button.add_theme_color_override(state, Color.TRANSPARENT)
	start_button.pressed.connect(func(): new_journey.emit())
	frame.add_child(start_button)
	continue_button = secondary_button("Continuar jornada", func(): continue_journey.emit())
	resized.connect(layout_art)
	layout_art()

func secondary_button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.12, 0.04, 0.90)
	style.border_color = Color("d4ad55")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	node.add_theme_stylebox_override("normal", style)
	node.add_theme_color_override("font_color", Color("fff0c2"))
	node.pressed.connect(action)
	frame.add_child(node)
	return node

func refresh() -> void:
	continue_button.visible = FileAccess.file_exists(Game.SAVE_PATH)

func layout_art() -> void:
	if not is_instance_valid(frame):
		return
	var scale_factor := minf(size.x / 960.0, size.y / 1280.0)
	frame.size = Vector2(960, 1280) * scale_factor
	frame.position = (size - frame.size) * 0.5
	# Match the painted green/gold button in the supplied 960 × 1280 art.
	start_button.position = Vector2(145, 834) * scale_factor
	start_button.size = Vector2(670, 145) * scale_factor
	continue_button.position = Vector2(230, 1010) * scale_factor
	continue_button.size = Vector2(500, 85) * scale_factor
	continue_button.add_theme_font_size_override("font_size", maxi(16, int(34 * scale_factor)))
