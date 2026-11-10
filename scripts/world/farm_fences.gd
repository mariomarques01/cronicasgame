extends Node3D
const FENCE: ArrayMesh = preload("res://assets/models/mossy_fence_mobile.res")
const WORLD_SCALE := 55.0
const HEIGHT := 1.35
const BASE_Y := -0.10
var section_count := 0

func _ready() -> void:
	name = "MossyGardenFences"
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_fences.json"))
	var transforms: Array[Transform3D] = []
	var collisions := StaticBody3D.new()
	collisions.name = "MossyFenceCollisions"
	add_child(collisions)
	var bounds := FENCE.get_aabb()
	var uniform_scale := HEIGHT / bounds.size.y
	var module_width := bounds.size.x * uniform_scale
	var pivot := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	for path: Dictionary in layout.paths:
		var total := 0.0
		for i in range(path.points.size() - 1):
			total += point(path.points[i]).distance_to(point(path.points[i + 1]))
		var offset := 0.0
		for i in range(path.points.size() - 1):
			var start := point(path.points[i])
			var end := point(path.points[i + 1])
			var length := start.distance_to(end)
			var spans: Array[Vector2] = [Vector2(0, length)]
			for gap: Array in path.gaps:
				var low := float(gap[0]) * total - offset
				var high := float(gap[1]) * total - offset
				var remaining: Array[Vector2] = []
				for span: Vector2 in spans:
					if high <= span.x or low >= span.y:
						remaining.append(span)
					else:
						if low > span.x:
							remaining.append(Vector2(span.x, low))
						if high < span.y:
							remaining.append(Vector2(high, span.y))
				spans = remaining
			var direction := (end - start).normalized()
			var along := Vector3(direction.x, 0, direction.y)
			var across := Vector3(-direction.y, 0, direction.x)
			for span: Vector2 in spans:
				var count := maxi(1, int(ceil((span.y - span.x) / module_width)))
				var width := (span.y - span.x) / count
				for section in count:
					var center := start + direction * (span.x + (section + 0.5) * width)
					var basis := Basis(along * (width / bounds.size.x), Vector3.UP * uniform_scale, across * uniform_scale)
					var origin := Vector3(center.x, BASE_Y, center.y)
					transforms.append(Transform3D(basis, origin - basis * pivot))
					var shape := CollisionShape3D.new()
					var box := BoxShape3D.new()
					box.size = Vector3(width, HEIGHT, 0.55)
					shape.shape = box
					shape.transform = Transform3D(Basis(along, Vector3.UP, across), origin + Vector3.UP * HEIGHT * 0.5)
					collisions.add_child(shape)
			offset += length
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = FENCE
	instances.instance_count = transforms.size()
	for i in transforms.size():
		instances.set_instance_transform(i, transforms[i])
	var batch := MultiMeshInstance3D.new()
	batch.multimesh = instances
	batch.name = "FenceSections"
	add_child(batch)
	section_count = transforms.size()
	build_south_entry()

func build_south_entry() -> void:
	# The old fused arch left an actual hole in the source terrain. Bridge it
	# at path level, including the approach outside the perimeter.
	var ground := StaticBody3D.new()
	ground.name = "SouthEntranceGround"
	ground.position = Vector3(0, 0.01, 45.05)
	var surface := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(11, 21.9)
	surface.mesh = plane
	surface.position.y = 0.002 # Keep the dirt approach above the continuous meadow.
	surface.material_override = get_parent().get_parent().terrain.ground_material
	ground.add_child(surface)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(11, 0.2, 21.9)
	collider.shape = box
	collider.position.y = -0.1
	ground.add_child(collider)
	add_child(ground)

func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) * WORLD_SCALE
