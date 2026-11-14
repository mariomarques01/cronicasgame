extends StaticBody3D
const MODEL: ArrayMesh = preload("res://assets/models/lia_wolf_mobile.res")
const HEIGHT := 2.5
var visual: MeshInstance3D
var model_pivot := Vector3.ZERO

func _ready() -> void:
	name = "Lia"
	visual = MeshInstance3D.new()
	visual.name = "WolfCharacter"
	visual.mesh = MODEL
	var bounds := MODEL.get_aabb()
	var factor := HEIGHT / bounds.size.y
	visual.scale = Vector3.ONE * factor
	model_pivot = Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	visual.position = -model_pivot * factor
	add_child(visual)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.2
	collision.shape = capsule
	collision.position.y = capsule.height * 0.5
	add_child(collision)

func face_toward(point: Vector3, weight: float = 1.0) -> void:
	var direction := point - global_position
	direction.y = 0
	if direction.length_squared() < 0.0025:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), clampf(weight, 0, 1))
	# Keep the supplied mesh centered on the unchanged capsule while turning it.
	visual.position = -(visual.basis * model_pivot)

func _process(delta: float) -> void:
	var world := get_parent()
	if not world.playing or not is_instance_valid(world.player) or not world.player.enabled:
		return
	if global_position.distance_to(world.player.global_position) < 5.0:
		face_toward(world.player.global_position, 1.0 - exp(-4.0 * delta))
