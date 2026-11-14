extends Control
## One cached view of the real farm; movement pans the texture, never rerenders the world.
var world: Node3D
var viewport: SubViewport
var camera: Camera3D
var image: TextureRect
var overlay: Control
var click_target: Button
const MAP_EXTENT := 360.0
const VIEW_EXTENT := 92.0
var captured := false
var capture_count := 0
var map_material: ShaderMaterial
var last_position := Vector2(INF, INF)
var last_yaw := INF

class Compass extends Control:
	var world: Node3D
	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, size.x * 0.492, Color(0.1, 0.08, 0.03, 0.2), false, 3, true)
		var points := PackedVector2Array()
		for point: Vector2 in [Vector2(0, -8), Vector2(6, 6), Vector2(0, 3), Vector2(-6, 6)]:
			points.append(center + point.rotated(-world.player.camera_yaw))
		draw_colored_polygon(points, Color("ffe188"))
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 5, 15), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffe4a1"))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.name = "MapRender"
	viewport.size = Vector2i(512, 512)
	viewport.world_3d = world.get_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.positional_shadow_atlas_size = 0
	add_child(viewport)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = MAP_EXTENT
	camera.position = Vector3(0, 220, 0)
	camera.rotation_degrees = Vector3(-90, 0, 0)
	camera.far = 450
	camera.environment = Environment.new()
	camera.environment.background_mode = Environment.BG_COLOR
	camera.environment.background_color = Color("5f7954")
	camera.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	camera.environment.ambient_light_energy = 0.75
	viewport.add_child(camera)
	image = TextureRect.new()
	image.texture = viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/hud_circle.gdshader")
	mat.set_shader_parameter("sample_scale", VIEW_EXTENT / MAP_EXTENT)
	map_material = mat
	image.material = mat
	add_child(image)
	var rim := TextureRect.new()
	rim.texture = preload("res://assets/ui/hud/round_frame.svg")
	rim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rim)
	overlay = Compass.new()
	overlay.world = world
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	click_target = Button.new()
	click_target.tooltip_text = "Abrir ou fechar mapa aéreo"
	for state in ["normal", "hover", "pressed", "focus"]:
		click_target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	click_target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_target.pressed.connect(world.toggle_map)
	add_child(click_target)
	# Render while the title screen covers the scene, not on the first movement.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	captured = true
	capture_count = 1

func _process(_delta: float) -> void:
	if not world.playing or not is_visible_in_tree() or not world.player.enabled:
		return
	if not captured:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		captured = true
		capture_count += 1
	var position := Vector2(world.player.global_position.x, world.player.global_position.z)
	if position.distance_squared_to(last_position) > 0.01:
		map_material.set_shader_parameter("sample_center", Vector2.ONE * 0.5 + position / MAP_EXTENT)
		last_position = position
	if not is_finite(last_yaw) or absf(angle_difference(last_yaw, world.player.camera_yaw)) > 0.003:
		overlay.queue_redraw()
		last_yaw = world.player.camera_yaw
