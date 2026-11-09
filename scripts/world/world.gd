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
var day_speed: float = 0.006
var nearest: String = ""

func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2
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
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("5291b6")
	sky_material.sky_horizon_color = Color("e2d6b7")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b6c9bd")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("ffe4b4")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85
	add_child(sun)
	build_farm()
	build_vegetation()
	build_interactions()
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 3, 12)
	add_child(player)
	ui = CanvasLayer.new()
	ui.set_script(UIScript)
	ui.world = self
	add_child(ui)
	Game.changed.connect(sync_state)
	Game.notice.connect(ui.notify)
	sync_state()

func build_farm() -> void:
	box(Vector3(10, 5, 8), ground(-14, 1, 2.5), Color("bfa77d"))
	var roof := CylinderMesh.new()
	roof.top_radius = 0
	roof.bottom_radius = 7.5
	roof.height = 3
	roof.radial_segments = 4
	var roof_node := prop(roof, ground(-14, 1, 6.5), Color("674735"))
	roof_node.rotation.y = PI / 4
	box(Vector3(2, 3, 0.15), ground(-14, 5.1, 1.5), Color("4a3528"), false)
	for x: float in [-17.0, -11.0]:
		box(Vector3(1.4, 1.4, 0.17), ground(x, 5.15, 3), Color("efca73"), false)
	box(Vector3(11, 6, 10), ground(18, -6, 3), Color("813e32"))
	box(Vector3(12, 0.6, 11), ground(18, -6, 6.4), Color("443c32"))
	box(Vector3(3, 4, 0.2), ground(18, -0.9, 2), Color("483b2c"), false)
	for x in range(-27, -7, 3):
		for z in range(17, 28, 3):
			box(Vector3(2, 0.2, 2), ground(x, z, 0.1), Color("53432b"), false)
			box(Vector3(0.3, 0.7, 0.3), ground(x, z, 0.5), Color("8caa4b"), false)
	for x in range(-44, 45, 4):
		if abs(x) < 5:
			continue
		box(Vector3(0.4, 2.4, 0.4), ground(x, -52, 1.2), Color("69563c"))
		box(Vector3(4.2, 0.3, 0.25), ground(x, -52, 1.4), Color("9e875a"))
	# Side cliffs keep the locked passage meaningful while retaining a 256 m valley.
	for side: int in [-1, 1]:
		box(Vector3(80, 9, 5), ground(side * 86, -52, 3), Color("65705e"))
	var water := CylinderMesh.new()
	water.top_radius = 10
	water.bottom_radius = 10
	water.height = 0.15
	prop(water, ground(-36, -19, 0.2), Color("4c93a1"))

func build_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7421
	var transforms: Array[Transform3D] = []
	for i in range(380):
		var x := rng.randf_range(-122, 122)
		var z := rng.randf_range(-122, 122)
		if absf(x) < 32 and z > -55 and z < 38:
			continue
		if absf(x) < 6 or Vector2(x + 36, z + 19).length() < 13:
			continue
		var scale_value := rng.randf_range(0.8, 1.5)
		var transform := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), ground(x, z))
		transforms.append(transform)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.25
	trunk.bottom_radius = 0.45
	trunk.height = 4
	trunk.radial_segments = 8
	trunk.rings = 1
	var crown := SphereMesh.new()
	crown.radius = 2.8
	crown.height = 6
	crown.radial_segments = 12
	crown.rings = 5
	for part: int in range(2):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = trunk if part == 0 else crown
		mm.instance_count = transforms.size()
		for i in range(transforms.size()):
			var transform: Transform3D = transforms[i]
			transform.origin.y += 2 if part == 0 else 5
			mm.set_instance_transform(i, transform)
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = material(Color("63503b") if part == 0 else Color("365e3e"))
		instance.visibility_range_end = 190
		add_child(instance)
	# Ancient tree beyond the gate: intentionally a placeholder landmark.
	var ancient := CylinderMesh.new()
	ancient.top_radius = 3
	ancient.bottom_radius = 5
	ancient.height = 19
	prop(ancient, ground(0, -94, 9.5), Color("665139"), true)
	var canopy := SphereMesh.new()
	canopy.radius = 15
	canopy.height = 20
	canopy.radial_segments = 20
	canopy.rings = 10
	prop(canopy, ground(0, -94, 24), Color("477851"))

func build_interactions() -> void:
	var npc_mesh := CapsuleMesh.new()
	npc_mesh.radius = 0.45
	npc_mesh.height = 1.8
	prop(npc_mesh, ground(-3, 3, 0.9), Color("c7a65b"), true)
	add_target("lia", "E • Conversar com Lia", ground(-3, 3, 1), "Lia • Guardiã do vale")
	var positions := [Vector2(25, 9), Vector2(-25, -18), Vector2(9, -34)]
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

func start_game(load_existing: bool) -> void:
	if load_existing:
		if not Game.load_game():
			return
	else:
		Game.reset()
	player.position = Game.player_position
	playing = true
	ui.show_play()
	sync_state()

func interact(id: String) -> void:
	if id == "lia":
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
	if not playing or not player.enabled:
		return
	clock = fmod(clock + delta * day_speed, 1.0)
	sun.rotation.x = -clock * TAU
	sun.light_energy = maxf(0.12, sin(clock * TAU))
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
