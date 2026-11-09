extends Node3D
## Golden Acres supplied by the user. Preserve embedded Meshy materials.
const MODEL = preload("res://assets/models/golden_acres.glb")
const CLEARED_FARM: ArrayMesh = preload("res://assets/models/farm_without_fences.res")
const MODEL_SCALE := 55.0
const MODEL_OFFSET := Vector3(0, 9.8, 0)
var faces := PackedVector3Array()
var height_cache: Dictionary = {}

func _ready() -> void:
	name = "GoldenAcres"
	var model: Node3D = MODEL.instantiate()
	add_child(model)
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		visual.mesh = CLEARED_FARM
	model.scale = Vector3.ONE * MODEL_SCALE
	model.position = MODEL_OFFSET
	build_collision(model)
	var fences := Node3D.new()
	fences.set_script(preload("res://scripts/world/farm_fences.gd"))
	add_child(fences)

func build_collision(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var transform: Transform3D = global_transform.affine_inverse() * node.global_transform
		var mesh_faces: PackedVector3Array = node.mesh.get_faces()
		for vertex in mesh_faces:
			faces.append(transform * vertex)
		var body := StaticBody3D.new()
		body.name = "FarmCollision"
		var shape := CollisionShape3D.new()
		var triangles := ConcavePolygonShape3D.new()
		triangles.backface_collision = true
		triangles.set_faces(faces)
		shape.shape = triangles
		body.add_child(shape)
		add_child(body)
	for child in node.get_children():
		build_collision(child)

func surface_height(x: float, z: float) -> float:
	var key := Vector2(x, z)
	if height_cache.has(key):
		return height_cache[key]
	var highest := -INF
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i + 1] - a
		var c := faces[i + 2] - a
		var determinant := b.x * c.z - b.z * c.x
		if absf(determinant) < 0.000001:
			continue
		var u := ((x - a.x) * c.z - (z - a.z) * c.x) / determinant
		var v := (b.x * (z - a.z) - b.z * (x - a.x)) / determinant
		if u >= 0 and v >= 0 and u + v <= 1:
			highest = maxf(highest, a.y + u * b.y + v * c.y)
	height_cache[key] = highest
	return highest
