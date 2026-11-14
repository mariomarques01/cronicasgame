extends Node3D
## Optional low-poly exploration route, unlocked by the existing forest quest.
var world: Node3D
var checkpoint_active := false
var completed := false
var bounce_count := 0
var checkpoint_position := Vector3.ZERO
var pad_position := Vector3.ZERO
var overlook_position := Vector3.ZERO
var pad_visual: MeshInstance3D
var checkpoint_gem: MeshInstance3D
var goal_gem: MeshInstance3D
var bounce_left := 0.0
var stone: StandardMaterial3D
var moss: StandardMaterial3D
var gold: StandardMaterial3D
var cyan: StandardMaterial3D
var platforms: Array[StaticBody3D] = []
var energy_material: ShaderMaterial
var energy_mesh: ArrayMesh
var energy_bursts: Array[MeshInstance3D] = []
var energy_left: Array[float] = [0.0, 0.0]
var energy_cursor := 0

func _ready() -> void:
	name = "ForestTrail"
	stone = world.material(Color("b0b39a"))
	stone.albedo_texture = preload("res://assets/textures/stone.png")
	stone.uv1_scale = Vector3(2, 2, 1)
	moss = world.material(Color("698350"))
	gold = world.material(Color("ebce7c"), true)
	cyan = world.material(Color("71dad9"), true)
	energy_material = ShaderMaterial.new()
	energy_material.shader = preload("res://assets/shaders/trail_energy.gdshader")
	energy_mesh = ribbon_mesh()
	for i in 2:
		var burst := ribbon(Vector3.ZERO, 1.0)
		burst.visible = false
		energy_bursts.append(burst)
	checkpoint_position = world.ground(0, -61, 0.08)
	pad_position = world.ground(3.2, -66.5, 0.14)
	var first_top: float = world.ground(3.2, -72).y + 2.0
	for i in 3:
		var z := -72.0 - i * 5.0
		var top: float = first_top + i * 0.5
		platforms.append(platform(Vector2(3.2, z), top, 1.65 if i < 2 else 1.9))
		disc(Vector3(3.2, top + 0.025, z), 0.55, cyan if i < 2 else gold)
		ribbon(Vector3(3.2, top + 0.08, z), 1.0)
		overlook_position = Vector3(3.2, top, z)
	var pad := platform(Vector2(pad_position.x, pad_position.z), pad_position.y, 1.1)
	pad.name = "WindPad"
	pad_visual = disc(pad_position + Vector3.UP * 0.025, 0.95, cyan)
	ribbon(pad_position + Vector3.UP * 0.08, 1.15)
	for i in 6:
		disc(world.ground(-1.4, -62.0 - i * 5.0, 0.03), 0.18, gold)
	checkpoint_gem = gem(world.ground(-1.8, -61, 1.5), cyan)
	goal_gem = gem(overlook_position + Vector3(0.9, 0.65, 0), cyan)
	post(world.ground(-1.8, -61), 1.2)
	flame(world.ground(-1.8, -61, 1.3))
	flame(overlook_position + Vector3(0.9, 0.45, 0))
	caption("Marco dos Ventos\nPonto de retorno", world.ground(-1.8, -61, 2.3))
	caption("Fogo e Jade", pad_position + Vector3(0, 3.1, 0))
	caption("Mirante dos Ventos", overlook_position + Vector3(0, 1.8, 0))

func platform(at: Vector2, top: float, radius: float) -> StaticBody3D:
	var base: float = world.ground(at.x, at.y).y - 0.15
	var height := maxf(0.15, top - base)
	var body := StaticBody3D.new()
	body.position = Vector3(at.x, base + height * 0.5, at.y)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = stone
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	disc(Vector3(at.x, top + 0.008, at.y), radius * 0.96, moss)
	return body

func disc(at: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.025
	mesh.radial_segments = 12
	mesh.rings = 1
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	return visual

func gem(at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.4
	mesh.radial_segments = 8
	mesh.rings = 4
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	return visual

func post(at: Vector3, height: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.16
	mesh.bottom_radius = 0.24
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = stone
	visual.position = at + Vector3.UP * height * 0.5
	add_child(visual)

func caption(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 22
	label.outline_size = 3
	label.pixel_size = 0.008
	label.modulate = Color("f5e6c0")
	label.visibility_range_end = 23.0
	add_child(label)

func reset() -> void:
	checkpoint_active = false
	completed = false
	bounce_left = 0.0
	checkpoint_gem.material_override = cyan
	goal_gem.material_override = cyan
	pad_visual.scale = Vector3.ONE
	for i in energy_left.size():
		energy_left[i] = 0.0
		energy_bursts[i].hide()

func activate_checkpoint() -> bool:
	if checkpoint_active or not world.player.enabled or Game.stage != 4:
		return false
	# The return point must have floor and clearance for the unchanged player capsule.
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(checkpoint_position + Vector3.UP * 2, checkpoint_position + Vector3.DOWN * 2)
	ray.exclude = [world.player.get_rid()]
	var floor := space.intersect_ray(ray)
	if floor.is_empty() or floor.normal.y < 0.94 or absf(floor.position.y - checkpoint_position.y) > 0.6:
		return false
	var safe: Vector3 = floor.position + Vector3.UP * 0.06
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = world.player.get_child(0).shape
	query.transform = Transform3D(Basis(), safe + Vector3.UP * 0.9)
	query.exclude = [world.player.get_rid()]
	if not space.intersect_shape(query, 1).is_empty():
		return false
	world.player.respawn_position = safe
	checkpoint_active = true
	checkpoint_gem.material_override = gold
	energy_burst(checkpoint_position)
	world.ui.notify("Marco dos Ventos ativado • retorne pelas Configurações")
	return true

func _physics_process(delta: float) -> void:
	if not world.playing or not world.player.enabled or Game.stage != 4:
		return
	for i in energy_left.size():
		if energy_left[i] <= 0.0: continue
		energy_left[i] = maxf(0.0, energy_left[i] - delta)
		var progress := 1.0 - energy_left[i] / 0.4
		energy_bursts[i].scale = Vector3.ONE * (1.0 + progress * 1.4)
		energy_bursts[i].visible = energy_left[i] > 0.0
	bounce_left = maxf(0.0, bounce_left - delta)
	var pulse := sin((0.35 - bounce_left) / 0.35 * PI) if bounce_left > 0 else 0.0
	pad_visual.scale = Vector3(1 + pulse * 0.1, 1 - pulse * 0.25, 1 + pulse * 0.1)
	var at: Vector3 = world.player.global_position
	if not checkpoint_active and at.distance_to(checkpoint_position) < 2.0:
		activate_checkpoint()
	if world.player.is_on_floor() and world.player.velocity.y <= 0 and bounce_left <= 0:
		if Vector2(at.x - pad_position.x, at.z - pad_position.z).length() < 1.05 and absf(at.y - pad_position.y) < 0.18:
			world.player.launch(12.0)
			energy_burst(pad_position)
			bounce_count += 1
			bounce_left = 0.35
	if not completed and world.player.is_on_floor() and absf(at.y - overlook_position.y) < 0.15 and Vector2(at.x - overlook_position.x, at.z - overlook_position.z).length() < 1.7:
		completed = true
		energy_burst(overlook_position)
		goal_gem.material_override = gold
		world.get_node("LandingFeedback").on_collection(overlook_position + Vector3.UP)
		world.ui.notify("Mirante dos Ventos alcançado! Trilha concluída.")

func ribbon_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		var angle := TAU * i / 24.0
		var next := TAU * (i + 1) / 24.0
		var points := [Vector3(cos(angle), 0, sin(angle)) * 0.8, Vector3(cos(angle), 0, sin(angle)), Vector3(cos(next), 0, sin(next)) * 0.8, Vector3(cos(next), 0, sin(next))]
		for index in [0, 2, 1, 1, 2, 3]:
			tool.set_uv(Vector2(float(i + (1 if index >= 2 else 0)) / 24.0, 0.0 if index % 2 == 0 else 1.0))
			tool.add_vertex(points[index])
	tool.generate_normals()
	return tool.commit()

func ribbon(at: Vector3, size: float) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = energy_mesh
	visual.material_override = energy_material
	visual.position = at
	visual.scale = Vector3.ONE * size
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visibility_range_end = 50.0
	add_child(visual)
	return visual

func flame(at: Vector3) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var side := Vector3(cos(TAU * i / 3), 0, sin(TAU * i / 3)) * 0.16
		for index in 3:
			tool.set_uv(Vector2(float(index) * 0.5, 1.0 if index == 1 else 0.0))
			tool.add_vertex([side, Vector3(0.06, 0.65, 0), -side][index])
	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = energy_material
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visibility_range_end = 35.0
	add_child(visual)

func energy_burst(at: Vector3) -> void:
	var index := energy_cursor
	energy_cursor = (energy_cursor + 1) % energy_bursts.size()
	energy_bursts[index].position = at + Vector3.UP * 0.15
	energy_bursts[index].scale = Vector3.ONE
	energy_bursts[index].show()
	energy_left[index] = 0.4
