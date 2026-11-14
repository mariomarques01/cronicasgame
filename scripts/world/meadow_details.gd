extends Node3D
## Lightweight, deterministic ground cover. No gameplay collision or new assets.
const CELL_SIZE := 20.0
const MAX_GRASS := 7200
const MAX_FLOWERS := 540
const Geometry = preload("res://scripts/world/building_geometry.gd")
var world: Node3D
var grass_count := 0
var flower_count := 0
var paths: Array = []
var plots: Array[Rect2] = []
var grass_placements: Array[Transform3D] = []
var flower_placements: Array[Transform3D] = []

func _ready() -> void:
	name = "MeadowDetails"
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_paths.json"))
	paths = layout.paths
	for plot: Dictionary in layout.protected_plots:
		var b: Array = plot.bounds
		plots.append(Rect2(Vector2(b[0], b[1]), Vector2(b[2] - b[0], b[3] - b[1])).grow(0.6))
	var rng := RandomNumberGenerator.new()
	rng.seed = 29471
	for i in 22000:
		var p := Vector2(rng.randf_range(-52, 52), rng.randf_range(-50, 50)) if i < 11000 else Vector2(rng.randf_range(-116, 116), rng.randf_range(-118, 112))
		var farm := absf(p.x) < 53 and absf(p.y) < 51
		if not can_plant(p):
			continue
		# Clusters leave breathing room instead of covering every metre uniformly.
		var cluster := (sin(p.x * 0.37 + sin(p.y * 0.19)) + cos(p.y * 0.43)) * 0.5
		if cluster < (-0.2 if farm else 0.0):
			continue
		var height: float = world.terrain.height_at(p.x, p.y) + 0.035
		var scale_value := rng.randf_range(0.65, 1.3)
		var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * scale_value)
		if grass_count < MAX_GRASS:
			grass_placements.append(Transform3D(basis, Vector3(p.x, height, p.y)))
			grass_count += 1
		if flower_count < MAX_FLOWERS and cluster > 0.15 and rng.randf() < (0.16 if farm else 0.055):
			flower_placements.append(Transform3D(basis, Vector3(p.x, height, p.y)))
			flower_count += 1
	# Extra foreground detail at the verges of existing roads, never in their centre.
	for path: Dictionary in paths:
		for i in range(path.points.size() - 1):
			var a := Vector2(path.points[i][0], path.points[i][1])
			var b := Vector2(path.points[i + 1][0], path.points[i + 1][1])
			var side := (b - a).normalized().orthogonal()
			for j in ceili(a.distance_to(b) * 3.0):
				var p := a.lerp(b, rng.randf()) + side * rng.randf_range(float(path.width) * 0.5 + 0.5, float(path.width) * 0.5 + 2.0) * (-1.0 if j % 2 else 1.0)
				if not can_plant(p) or grass_count >= MAX_GRASS:
					continue
				var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.65, 1.15))
				var pose := Transform3D(basis, world.ground(p.x, p.y, 0.035))
				grass_placements.append(pose)
				grass_count += 1
				if j % 4 == 0 and flower_count < MAX_FLOWERS:
					flower_placements.append(pose)
					flower_count += 1
	build_batches("Grass", grass_mesh(), grass_placements, 55.0)
	build_batches("Wildflowers", flower_mesh(), flower_placements, 65.0)

func road_clearance(p: Vector2) -> float:
	var clearance := INF
	for path: Dictionary in paths:
		for i in range(path.points.size() - 1):
			var a := Vector2(path.points[i][0], path.points[i][1])
			var b := Vector2(path.points[i + 1][0], path.points[i + 1][1])
			clearance = minf(clearance, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) - float(path.width) * 0.5)
	return clearance

func can_plant(p: Vector2) -> bool:
	if Rect2(-27, -13, 28, 26).has_point(p):
		return false # House and courtyard, including the doorway.
	if Geometry.contains(p / 55.0, world.terrain.building_footprints):
		return false
	for plot: Rect2 in plots:
		if plot.has_point(p):
			return false
	if p.y < -51 and absf(p.x) < 3.5:
		return false # Keep the quest route readable in the forest, too.
	return road_clearance(p) > 0.35

func build_batches(prefix: String, mesh: Mesh, placements: Array[Transform3D], distance: float) -> void:
	var cells: Dictionary = {}
	for pose: Transform3D in placements:
		var cell := Vector2i(floori(pose.origin.x / CELL_SIZE), floori(pose.origin.z / CELL_SIZE))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(pose)
	for cell: Vector2i in cells:
		var node := MultiMeshInstance3D.new()
		node.name = prefix + "_%d_%d" % [cell.x, cell.y]
		node.position = Vector3(cell.x * CELL_SIZE, 0, cell.y * CELL_SIZE)
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = cells[cell].size()
		for i in instances.instance_count:
			var pose: Transform3D = cells[cell][i]
			pose.origin -= node.position
			instances.set_instance_transform(i, pose)
		node.multimesh = instances
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end = distance
		node.visibility_range_end_margin = 6.0
		add_child(node)

func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	tool.set_color(color)
	for vertex: Vector3 in [a, b, c]:
		tool.add_vertex(vertex)

func finish(tool: SurfaceTool) -> ArrayMesh:
	tool.generate_normals()
	var mesh := tool.commit()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/meadow_wind.gdshader")
	mesh.surface_set_material(0, mat)
	return mesh

func grass_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var angle := float(i) * 2.4
		var base := Vector3(cos(angle), 0, sin(angle)) * (0.08 + float(i % 3) * 0.045)
		var side := Vector3(cos(angle + 1.0), 0, sin(angle + 1.0)) * 0.028
		var height := 0.17 + float(i % 4) * 0.055
		var middle := base + Vector3(0.035, height * 0.6, 0)
		var tip := base + Vector3(0.1, height, 0.02)
		var green := Color("5e813c").lerp(Color("9aa65d"), float(i % 3) / 3.0)
		triangle(tool, base - side, middle + side * 0.5, base + side, green.darkened(0.15))
		triangle(tool, base - side, middle - side * 0.5, middle + side * 0.5, green)
		triangle(tool, middle - side * 0.5, tip, middle + side * 0.5, green.lightened(0.06))
	return finish(tool)

func flower_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var angle := float(i) * 2.4
		var base := Vector3(cos(angle) * 0.16, 0, sin(angle) * 0.16)
		var center := base + Vector3(0.03, 0.32 + float(i) * 0.09, 0)
		triangle(tool, base - Vector3(0.012, 0, 0), center, base + Vector3(0.012, 0, 0), Color("648043"))
		var tint := Color("f3d38b") if i == 0 else (Color("e9e0c5") if i == 1 else Color("b7a1cc"))
		for petal in 5:
			var theta := float(petal) * TAU / 5.0
			var radial := Vector3(cos(theta), 0.25, sin(theta)) * 0.11
			var lateral := Vector3(-sin(theta), 0, cos(theta)) * 0.045
			triangle(tool, center, center + radial - lateral, center + radial + lateral, tint)
		triangle(tool, center + Vector3(-0.035, 0.01, -0.025), center + Vector3(0, 0.01, 0.04), center + Vector3(0.035, 0.01, -0.025), Color("d5a44d"))
	return finish(tool)
