extends Node3D
## Bounded, reusable gameplay effects. No runtime textures or emitters allocated on contact.
var player: CharacterBody3D
var bursts: Array[CPUParticles3D] = []
var trigger_count := 0
var cursor := 0
const MIN_IMPACT := 3.5
var step_distance := 0.0
var skid_cooldown := 0.0
var step_count := 0
var jump_count := 0
var skid_count := 0
var collection_count := 0
var last_position := Vector3.ZERO

func _ready() -> void:
	name = "LandingFeedback"
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.65), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	texture.gradient = fade
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.albedo_color = Color("b8a789")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.4, 0.4)
	mesh.material = mat
	for i in 8:
		var burst := CPUParticles3D.new()
		burst.name = "Dust%d" % i
		burst.emitting = false
		burst.one_shot = true
		burst.amount = 8
		burst.lifetime = 0.35
		burst.explosiveness = 1.0
		burst.local_coords = false
		burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		burst.emission_sphere_radius = 0.18
		burst.direction = Vector3.UP
		burst.spread = 75
		burst.initial_velocity_min = 0.6
		burst.initial_velocity_max = 1.3
		burst.gravity = Vector3(0, -1, 0)
		burst.scale_amount_min = 0.3
		burst.scale_amount_max = 0.6
		burst.color_ramp = fade
		burst.mesh = mesh
		burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(burst)
		bursts.append(burst)
	player.landed.connect(on_landed)
	player.jumped.connect(on_jump)
	player.skidded.connect(on_skid)
	last_position = player.global_position

func on_landed(impact_speed: float) -> void:
	if impact_speed < MIN_IMPACT or not player.enabled:
		return
	emit_burst(player.global_position, clampf(impact_speed / 8.0, 0.6, 1.5), Color("b8a789"))
	trigger_count += 1

func emit_burst(at: Vector3, strength: float, tint: Color, sparkling: bool = false) -> void:
	var burst := bursts[cursor]
	cursor = (cursor + 1) % bursts.size()
	burst.global_position = at + Vector3.UP * 0.08
	burst.color = tint
	burst.amount = 12 if sparkling else 8
	burst.lifetime = 0.55 if sparkling else 0.35
	burst.initial_velocity_min = 0.6 * strength
	burst.initial_velocity_max = 1.3 * strength
	burst.scale_amount_min = (0.12 if sparkling else 0.3) * strength
	burst.scale_amount_max = (0.28 if sparkling else 0.6) * strength
	burst.gravity = Vector3(0, 0.5 if sparkling else -1.0, 0)
	burst.restart()
	burst.emitting = true

func on_jump() -> void:
	if not player.enabled:
		return
	emit_burst(player.global_position, 0.65, Color("c1b69a"))
	jump_count += 1

func on_skid() -> void:
	if skid_cooldown > 0.0 or not player.enabled:
		return
	skid_cooldown = 0.28
	emit_burst(player.global_position, 0.8, Color("b8a789"))
	skid_count += 1

func on_collection(at: Vector3) -> void:
	if not player.enabled:
		return
	emit_burst(at, 1.1, Color("72e9ff"), true)
	collection_count += 1

func _physics_process(delta: float) -> void:
	var distance := Vector2(player.global_position.x - last_position.x, player.global_position.z - last_position.z).length()
	last_position = player.global_position
	if not player.enabled:
		step_distance = 0.0
		return
	skid_cooldown = maxf(0.0, skid_cooldown - delta)
	if player.is_on_floor() and player.movement_speed > 4.9 and distance < 1.0:
		step_distance += distance
		if step_distance >= 1.8:
			step_distance = fmod(step_distance, 1.8)
			emit_burst(player.global_position, 0.35, Color("b8a789"))
			step_count += 1
	else:
		step_distance = 0.0

func _process(_delta: float) -> void:
	for burst: CPUParticles3D in bursts:
		burst.speed_scale = 1.0 if player.enabled else 0.0
