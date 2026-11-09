extends Node3D
const HOUSE: ArrayMesh = preload("res://assets/models/cozy_timber_house_mobile.res")
var visual: MeshInstance3D

func _ready() -> void:
	name = "CozyTimberHouse"
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_fences.json"))
	var placement: Dictionary = layout.main_house
	position = Vector3(placement.position[0], placement.position[1], placement.position[2])
	var bounds := HOUSE.get_aabb()
	var house_scale := float(placement.width) / bounds.size.x
	var pivot := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	visual = MeshInstance3D.new()
	visual.name = "CozyTimberVisual"
	visual.mesh = HOUSE
	visual.scale = Vector3.ONE * house_scale
	visual.position = -pivot * house_scale
	add_child(visual)
	var body := StaticBody3D.new()
	body.name = "HouseCollision"
	var collider := CollisionShape3D.new()
	var geometry := ConcavePolygonShape3D.new()
	geometry.backface_collision = true
	var faces := HOUSE.get_faces()
	for i in faces.size():
		faces[i] = visual.transform * faces[i]
	geometry.set_faces(faces)
	collider.shape = geometry
	body.add_child(collider)
	add_child(body)
	build_courtyard(placement.cleared_bounds)

func build_courtyard(bounds: Array) -> void:
	# Cover the collapsed old facade/roof UVs with the courtyard surface.
	var ground := StaticBody3D.new()
	ground.name = "HouseCourtyard"
	var center := Vector3((float(bounds[0]) + float(bounds[1])) * 27.5, 0.025, (float(bounds[2]) + float(bounds[3])) * 27.5)
	ground.position = center - position
	var size := Vector2((float(bounds[1]) - float(bounds[0])) * 55, (float(bounds[3]) - float(bounds[2])) * 55)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	surface.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/textures/dirt.png")
	material.uv1_scale = Vector3(12, 8, 1)
	material.roughness = 1.0
	surface.material_override = material
	ground.add_child(surface)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	collision.shape = box
	collision.position.y = -0.1
	ground.add_child(collision)
	add_child(ground)
