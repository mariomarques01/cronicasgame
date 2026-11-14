extends Node3D
const PlayerScript = preload("res://scripts/player/player.gd")
const TerrainScript = preload("res://scripts/world/terrain.gd")
const UIScript = preload("res://scripts/ui/interface.gd")
var terrain: StaticBody3D
var player: CharacterBody3D
var ui: CanvasLayer
var gate: StaticBody3D
var gate_mesh: MeshInstance3D
var targets: Array[Dictionary] = []
var stones: Dictionary = {}
var sun: DirectionalLight3D
var playing: bool = false
var clock: float = 0.3
const DAY_SPEED := 0.0006
var day_speed: float = DAY_SPEED
var atmosphere: Node3D
var nearest: String = ""
var map_camera: Camera3D
var windmill: Node3D
var crop_positions: Array[Dictionary] = []

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func prop(mesh: Mesh, pos: Vector3, color: Color, solid: bool = false, glow: bool = false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.position = pos
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material(color, glow)
	root.add_child(visual)
	if solid:
		var collision := CollisionShape3D.new()
		collision.shape = mesh.create_convex_shape()
		root.add_child(collision)
	add_child(root)
	return root

func box(size: Vector3, pos: Vector3, color: Color, solid: bool = true) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return prop(mesh, pos, color, solid)

func ground(x: float, z: float, up: float = 0) -> Vector3:
	return Vector3(x, terrain.height_at(x, z) + up, z)

func _ready() -> void:
	terrain = StaticBody3D.new()
	terrain.set_script(TerrainScript)
	add_child(terrain)
	atmosphere = Node3D.new()
	atmosphere.set_script(preload("res://scripts/world/valley_atmosphere.gd"))
	atmosphere.world = self
	add_child(atmosphere)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 0.95
	sun.light_angular_distance = 0.7
	sun.shadow_bias = 0.035
	sun.directional_shadow_blend_splits = true
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	build_farm()
	build_vegetation()
	build_interactions()
	var meadow := Node3D.new()
	meadow.set_script(preload("res://scripts/world/meadow_details.gd"))
	meadow.world = self
	add_child(meadow)
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = ground(-29, 33, 2)
	add_child(player)
	player.respawn_position = ground(-29, 33, 2)
	var landing_feedback := Node3D.new()
	landing_feedback.set_script(preload("res://scripts/player/landing_feedback.gd"))
	landing_feedback.player = player
	add_child(landing_feedback)
	map_camera = Camera3D.new()
	map_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	map_camera.size = 112
	map_camera.keep_aspect = Camera3D.KEEP_WIDTH
	map_camera.position = Vector3(0, 105, 75)
	add_child(map_camera)
	map_camera.look_at(Vector3(0, 0, -2))
	ui = CanvasLayer.new()
	ui.set_script(UIScript)
	ui.world = self
	add_child(ui)
	Game.changed.connect(sync_state)
	Game.notice.connect(ui.notify)
	sync_state()

func build_farm() -> void:
	var farm := Node3D.new()
	farm.set_script(preload("res://scripts/world/imported_farm.gd"))
	add_child(farm)
	terrain.farm = farm

func build_vegetation() -> void:
	var trees := Node3D.new()
	trees.set_script(preload("res://scripts/world/trees.gd"))
	trees.world = self
	add_child(trees)

func build_interactions() -> void:
	var lia := StaticBody3D.new()
	lia.set_script(preload("res://scripts/world/lia.gd"))
	lia.position = ground(-30, 9)
	add_child(lia)
	add_target("lia", "E • Conversar com Lia", ground(-30, 9, 1), "Lia • Guardiã do vale")
	var positions := [Vector2(27, 12), Vector2(-30, -17), Vector2(9, -23)]
	for i in range(3):
		var pos: Vector2 = positions[i]
		var mesh := SphereMesh.new()
		mesh.radius = 0.65
		mesh.height = 1.3
		var id := "stone_%d" % i
		stones[id] = prop(mesh, ground(pos.x, pos.y, 0.85), Color("62d4ea"), false, true)
		var beam := CylinderMesh.new()
		beam.top_radius = 0.09
		beam.bottom_radius = 0.09
		beam.height = 6
		var marker := MeshInstance3D.new()
		marker.mesh = beam
		marker.position.y = 3
		marker.material_override = material(Color("79cad3"), true)
		stones[id].add_child(marker)
		add_target(id, "E • Recolher pedra antiga", ground(pos.x, pos.y, 1), "Pedra antiga")
	gate = box(Vector3(9, 5, 0.8), ground(0, -52, 2.5), Color("655237"))
	gate_mesh = gate.get_child(0)
	box(Vector3(1.2, 2.4, 1.2), ground(7, -47, 1.2), Color("d8ba65"))
	add_target("gate", "E • Ativar mecanismo", ground(7, -47, 1.2), "Mecanismo ancestral")

func add_target(id: String, hint: String, pos: Vector3, title: String) -> void:
	targets.append({"id": id, "hint": hint, "position": pos})
	var label := Label3D.new()
	label.text = title
	label.position = pos + Vector3(0, 2.4, 0)
	label.font_size = 32
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	if stones.has(id):
		label.reparent(stones[id], true)

func sync_state() -> void:
	for id: String in stones:
		stones[id].visible = not id in Game.collected
	var opened: bool = Game.stage == 4
	gate.visible = not opened
	gate.get_child(1).set_deferred("disabled", opened)
	if is_instance_valid(ui):
		ui.refresh()

func toggle_map() -> void:
	if map_camera.current:
		player.camera.make_current()
	else:
		map_camera.make_current()

func start_game(load_existing: bool) -> void:
	if load_existing:
		if not Game.load_game():
			return
	else:
		Game.reset()
	player.position = Game.player_position if load_existing else ground(-29, 33, 2)
	# Older saves may put the player below the imported landscape.
	player.position.y = maxf(player.position.y, terrain.height_at(player.position.x, player.position.z) + 1.0)
	playing = true
	ui.show_play()
	sync_state()

func interact(id: String) -> void:
	if id == "lia":
		var lia: StaticBody3D = get_node("Lia")
		var direction := lia.global_position - player.global_position
		player.velocity.x = 0
		player.velocity.z = 0
		if Vector2(direction.x, direction.z).length_squared() > 0.0025:
			player.avatar.rotation.y = atan2(-direction.x, -direction.z)
		lia.face_toward(player.global_position)
		ui.dialogue(Game.talk())
	elif id.begins_with("stone_"):
		if not Game.collect(id):
			ui.notify("Converse com Lia para investigar as pedras.")
	elif id == "gate":
		if Game.activate_gate():
			Game.save_game(player.position)
		else:
			ui.notify("O mecanismo aguarda as três pedras e a orientação de Lia.")

func _process(delta: float) -> void:
	if is_instance_valid(map_camera):
		map_camera.size = maxf(112, 85 * get_viewport().get_visible_rect().size.aspect())
	if not playing or not player.enabled:
		return
	if is_instance_valid(windmill):
		windmill.rotation.z += delta * 0.35
	clock = fmod(clock + delta * day_speed, 1.0)
	sun.rotation.x = -clock * TAU
	var daylight := clampf(sin(clock * TAU), 0.0, 1.0)
	sun.light_energy = lerpf(0.08, 0.95, daylight)
	sun.light_color = Color("d5b7a2").lerp(Color("fff0d6"), daylight)
	atmosphere.set_daylight(daylight)
	nearest = ""
	var distance := 3.5
	for target: Dictionary in targets:
		if target.id in Game.collected or (target.id == "gate" and Game.stage == 4):
			continue
		var d: float = player.position.distance_to(target.position)
		if d < distance:
			distance = d
			nearest = target.id
			ui.hint.text = target.hint
	if nearest.is_empty():
		ui.hint.text = ""
	if player.position.z < -57:
		ui.region.text = "FLORESTA DOS SUSSURROS" if Game.stage == 4 else "VALE DA FAZENDA"
	else:
		ui.region.text = "VALE DA FAZENDA"
	# Physical barrier also prevents jumping around the intended quest boundary.
	if Game.stage < 4 and player.position.z < -49:
		player.position.z = -49
	if Input.is_action_just_pressed("interact") and not nearest.is_empty():
		interact(nearest)
	if Input.is_action_just_pressed("save"):
		Game.save_game(player.position)
	if Input.is_action_just_pressed("load") and Game.load_game():
		player.position = Game.player_position
		player.position.y = maxf(player.position.y, terrain.height_at(player.position.x, player.position.z) + 1.0)
