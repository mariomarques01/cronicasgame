extends Node3D
## Small original dust bursts at real landings; the avatar owns impact animation.
var player: CharacterBody3D
var bursts: Array[CPUParticles3D] = []
var trigger_count := 0
var cursor := 0
const MIN_IMPACT := 3.5

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
	for i in 3:
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

func on_landed(impact_speed: float) -> void:
	if impact_speed < MIN_IMPACT or not player.enabled:
		return
	var burst := bursts[cursor]
	cursor = (cursor + 1) % bursts.size()
	burst.global_position = player.global_position + Vector3.UP * 0.08
	burst.initial_velocity_max = lerpf(0.8, 1.3, clampf((impact_speed - MIN_IMPACT) / 8.0, 0, 1))
	burst.restart()
	burst.emitting = true
	trigger_count += 1

func _process(_delta: float) -> void:
	for burst: CPUParticles3D in bursts:
		burst.speed_scale = 1.0 if player.enabled else 0.0
