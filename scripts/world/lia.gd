extends StaticBody3D
const MODEL: ArrayMesh = preload("res://assets/models/lia_wolf_mobile.res")
const HEIGHT := 2.5

func _ready() -> void:
	name = "Lia"
	var visual := MeshInstance3D.new()
	visual.name = "WolfCharacter"
	visual.mesh = MODEL
	var bounds := MODEL.get_aabb()
	var factor := HEIGHT / bounds.size.y
	visual.scale = Vector3.ONE * factor
	visual.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	add_child(visual)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.2
	collision.shape = capsule
	collision.position.y = capsule.height * 0.5
	add_child(collision)
