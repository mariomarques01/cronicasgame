extends Node3D
## Compatibility-friendly atmosphere: ordinary fog, distant scenery and CPU motes.
var world: Node3D
var environment: Environment
var sky_material: ProceduralSkyMaterial
var motes: CPUParticles3D
var daylight := 1.0

func _ready() -> void:
	name = "ValleyAtmosphere"
	build_environment()
	build_ridgeline()
	build_clouds()
	build_motes()
	set_daylight(0.95)

func build_environment() -> void:
	var node := WorldEnvironment.new()
	node.name = "ValleyEnvironment"
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("6597bb")
	sky_material.sky_horizon_color = Color("c4d6cf")
	sky_material.ground_bottom_color = Color("667b73")
	sky_material.ground_horizon_color = Color("c4d6cf")
	sky_material.sky_curve = 0.18
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c4d7e4")
	environment.ambient_light_energy = 0.48
	# Compatibility supports ordinary depth fog, without a volumetric/GI dependency.
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("b9ceca").srgb_to_linear()
	environment.fog_light_energy = 0.7
	environment.fog_density = 0.0017
	environment.fog_sky_affect = 0.12
	node.environment = environment
	add_child(node)

func set_daylight(value: float) -> void:
	if absf(value - daylight) < 0.003:
		return
	daylight = clampf(value, 0.0, 1.0)
	environment.ambient_light_energy = lerpf(0.18, 0.48, daylight)
	environment.ambient_light_color = Color("7186bb").lerp(Color("c4d7e4"), daylight)
	environment.fog_light_color = Color("344a70").lerp(Color("b9ceca").srgb_to_linear(), daylight)
	sky_material.sky_top_color = Color("152542").lerp(Color("6597bb"), daylight)
	sky_material.sky_horizon_color = Color("53627e").lerp(Color("c4d6cf"), daylight)
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = Color("1b2939").lerp(Color("667b73"), daylight)

func build_ridgeline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8403
	for layer in 2:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius := 195.0 + float(layer) * 82.0
		var profile: Array[Vector3] = []
		for i in 65:
			var theta := float(i % 64) * TAU / 64.0
			var height := 20.0 + 7.0 * sin(theta * 3.0 + float(layer)) + 5.0 * sin(theta * 7.0 + 1.8) + rng.randf_range(-3, 3)
			profile.append(Vector3(cos(theta) * radius, height + layer * 10.0, sin(theta) * radius))
		profile[64] = profile[0]
		for i in 64:
			var a := profile[i]
			var b := profile[i + 1]
			var base_a := Vector3(a.x * 0.65, -12, a.z * 0.65)
			var base_b := Vector3(b.x * 0.65, -12, b.z * 0.65)
			for vertex: Vector3 in [a, base_a, b, b, base_a, base_b]:
				var top := Color("718f85").srgb_to_linear() if layer == 0 else Color("94aaa9").srgb_to_linear()
				var base := Color("adc1b5").srgb_to_linear()
				tool.set_color(base.lerp(top, clampf((vertex.y + 12.0) / 32.0, 0.0, 1.0)))
				tool.add_vertex(vertex)
		tool.generate_normals()
		var node := MeshInstance3D.new()
		node.name = "DistantRidge%d" % layer
		node.mesh = tool.commit()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.WHITE
		mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 1.0
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)

func build_clouds() -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("e1e6dd")
	mat.roughness = 1.0
	mesh.material = mat
	var rng := RandomNumberGenerator.new()
	rng.seed = 9924
	for i in 12:
		var theta := float(i) * TAU / 12.0 + 0.2
		var center := Vector3(cos(theta) * 240, rng.randf_range(70, 105), sin(theta) * 240)
		for j in 4:
			var cloud := MeshInstance3D.new()
			cloud.name = "Cloud"
			cloud.mesh = mesh
			cloud.position = center + Vector3(float(j) * 12.0 - 18, rng.randf_range(-1, 3), 0)
			cloud.scale = Vector3(26, rng.randf_range(4, 7), 14)
			cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(cloud)

func build_motes() -> void:
	motes = CPUParticles3D.new()
	motes.name = "CelestialMotes"
	motes.position = world.ground(0, -91, 4)
	motes.amount = 38
	motes.lifetime = 10
	motes.preprocess = 10
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(10, 3, 9)
	motes.direction = Vector3.UP
	motes.spread = 50
	motes.gravity = Vector3(0.015, 0.025, 0)
	motes.initial_velocity_min = 0.08
	motes.initial_velocity_max = 0.18
	motes.scale_amount_min = 0.6
	motes.scale_amount_max = 1.3
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("f3dca0")
	mat.emission_enabled = true
	mat.emission = Color("f3dca0")
	mesh.material = mat
	motes.mesh = mesh
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)

func _process(_delta: float) -> void:
	motes.speed_scale = 1.0 if world.playing and is_instance_valid(world.player) and world.player.enabled else 0.0
