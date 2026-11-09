extends Node3D
const PINE: ArrayMesh = preload("res://assets/models/farm_pine_mobile.res")
const TREE: ArrayMesh = preload("res://assets/models/forest_tree_mobile.res")
const CELL_SIZE := 32.0
var world: Node3D
var boundary := PackedVector2Array()
var placements: Array[Dictionary] = []
var pine_count := 0
var tree_count := 0

func _ready() -> void:
	name = "Trees"
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_fences.json"))
	for id in ["outer_west", "outer_east"]:
		for path: Dictionary in layout.paths:
			if path.name == id:
				for point: Array in path.points:
					boundary.append(Vector2(point[0], point[1]) * 55.0)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_trees.json"))
	for tree: Dictionary in config.embedded_trees:
		var center := Vector2(tree.center[0], tree.center[1]) * 55.0
		add_tree(Vector3(center.x, 0.015, center.y), float(tree.height), true)
		build_root_ground(center, Vector2(tree.radii[0], tree.radii[1]) * 55.0)
	for volume: Dictionary in config.get("extra_removal_volumes", []):
		build_root_ground(Vector2(volume.center[0], volume.center[1]) * 55.0, Vector2(volume.radii[0], volume.radii[1]) * 55.0)
	# Reuse the previous forest's seed, positions and exclusion of the quest path.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7421
	var exterior_index := 0
	for i in range(380):
		var x := rng.randf_range(-122, 122)
		var z := rng.randf_range(-122, 122)
		if absf(x) < 48 and z > -55 and z < 49:
			continue
		if absf(x) < 6 or Vector2(x + 36, z + 19).length() < 13:
			continue
		var variation := rng.randf_range(0.8, 1.5)
		var inside := is_inside(Vector2(x, z))
		if not inside:
			exterior_index += 1
			if exterior_index % 2 == 0:
				continue
		add_tree(world.ground(x, z), (12.0 if inside else 8.0) * variation, inside)
	# The quest landmark uses the same supplied exterior tree, at a larger scale.
	add_tree(world.ground(0, -94), 24.0, false)
	var landmark := Marker3D.new()
	landmark.name = "AncientTree"
	landmark.position = world.ground(0, -94)
	add_child(landmark)
	build_batches()

func is_inside(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, boundary)

func add_tree(point: Vector3, height: float, inside: bool) -> void:
	placements.append({"position": point, "height": height, "pine": inside})
	if inside:
		pine_count += 1
	else:
		tree_count += 1

func build_batches() -> void:
	for inside in [true, false]:
		var mesh := PINE if inside else TREE
		var bounds := mesh.get_aabb()
		var pivot := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
		var cells: Dictionary = {}
		for tree: Dictionary in placements:
			if tree.pine != inside:
				continue
			var cell := Vector2i(floori(tree.position.x / CELL_SIZE), floori(tree.position.z / CELL_SIZE))
			if not cells.has(cell):
				cells[cell] = []
			cells[cell].append(tree)
		for cell: Vector2i in cells:
			var origin := Vector3((cell.x + 0.5) * CELL_SIZE, 0, (cell.y + 0.5) * CELL_SIZE)
			var body := StaticBody3D.new()
			body.name = "PineTrunks" if inside else "TreeTrunks"
			body.position = origin
			add_child(body)
			var batch := MultiMeshInstance3D.new()
			batch.name = "PineTrees" if inside else "ForestTrees"
			batch.position = origin
			var instances := MultiMesh.new()
			instances.transform_format = MultiMesh.TRANSFORM_3D
			instances.mesh = mesh
			instances.instance_count = cells[cell].size()
			for i in cells[cell].size():
				var tree: Dictionary = cells[cell][i]
				var factor := float(tree.height) / bounds.size.y
				var angle := fposmod(tree.position.x * 0.17 + tree.position.z * 0.29, TAU)
				var basis := Basis(Vector3.UP, angle).scaled(Vector3.ONE * factor)
				instances.set_instance_transform(i, Transform3D(basis, tree.position - origin - basis * pivot))
				var shape := CollisionShape3D.new()
				var cylinder := CylinderShape3D.new()
				cylinder.radius = 0.35 * float(tree.height) / 10.0
				cylinder.height = float(tree.height) * 0.55
				shape.shape = cylinder
				shape.position = tree.position - origin + Vector3.UP * cylinder.height * 0.5
				body.add_child(shape)
			batch.multimesh = instances
			if not inside:
				batch.visibility_range_end = 125.0
				batch.visibility_range_end_margin = 12.0
			add_child(batch)

func build_root_ground(center: Vector2, radii: Vector2) -> void:
	# Close only the footprint formerly occupied by the fused tree, below plants.
	var ground := StaticBody3D.new()
	ground.name = "TreeRootGround"
	ground.position = Vector3(center.x, 0.015, center.y)
	radii *= 1.12
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 32:
		var a := Vector2(cos(float(i) * TAU / 32), sin(float(i) * TAU / 32))
		var b := Vector2(cos(float(i + 1) * TAU / 32), sin(float(i + 1) * TAU / 32))
		for point: Vector2 in [Vector2.ZERO, b, a]:
			tool.set_uv(Vector2(0.5, 0.5) + point * 0.5)
			tool.add_vertex(Vector3(point.x * radii.x, 0, point.y * radii.y))
	tool.generate_normals()
	var mesh := tool.commit()
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/textures/grass.png")
	material.uv1_scale = Vector3(4, 4, 1)
	material.roughness = 1.0
	visual.material_override = material
	ground.add_child(visual)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	ground.add_child(collider)
	add_child(ground)
