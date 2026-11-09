extends SceneTree
## Run from the project root: godot --headless --script tools/bake_farm_fences.gd
## Sources remain unchanged; regenerate the cleared farm and optimized prop meshes.
func _initialize() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_fences.json"))
	var segments: Array = []
	for path: Dictionary in layout.paths:
		for i in range(path.points.size() - 1):
			segments.append([Vector2(path.points[i][0], path.points[i][1]), Vector2(path.points[i + 1][0], path.points[i + 1][1]), float(path.get("erase_half_width", layout.erase_half_width))])
	var source: Node3D = load("res://assets/models/golden_acres.glb").instantiate()
	var original: Mesh = source.find_children("*", "MeshInstance3D", true, false)[0].mesh
	var cleared := ArrayMesh.new()
	var changed := 0
	for surface in original.get_surface_count():
		var arrays: Array = original.surface_get_arrays(surface).duplicate(true)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			var vertex := vertices[i]
			if vertex.y <= float(layout.ground_y):
				continue
			# The fused crop beds share the fence's stretched vertical skirts.
			# Lower those skirts with the beds, retaining the crop texture/detail.
			for bed: Array in layout.lower_raised_beds:
				if vertex.x >= bed[0] and vertex.x <= bed[1] and vertex.z >= bed[2] and vertex.z <= bed[3]:
					vertices[i].y = float(layout.ground_y) + (vertex.y - float(layout.ground_y)) * float(layout.bed_height_scale)
			var point := Vector2(vertex.x, vertex.z)
			var erase := false
			for segment: Array in segments:
				if Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1]).distance_squared_to(point) <= pow(float(segment[2]), 2):
					erase = true
					break
			for rect: Array in layout.erase_rectangles:
				if vertex.x >= rect[0] and vertex.x <= rect[1] and vertex.z >= rect[2] and vertex.z <= rect[3]:
					erase = true
			if erase:
				vertices[i].y = float(layout.ground_y)
				changed += 1
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var old_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		for i in range(0, old_indices.size(), 3):
			var a := old_indices[i]
			var b := old_indices[i + 1]
			var c := old_indices[i + 2]
			if (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).length_squared() > 0.000000000001:
				indices.append_array(PackedInt32Array([a, b, c]))
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var tool := SurfaceTool.new()
		tool.create_from(mesh, 0)
		tool.generate_normals()
		if arrays[Mesh.ARRAY_TEX_UV] != null and not arrays[Mesh.ARRAY_TEX_UV].is_empty():
			tool.generate_tangents()
		tool.set_material(original.surface_get_material(surface))
		tool.commit(cleared)
	assert(ResourceSaver.save(cleared, "res://assets/models/farm_without_fences.res", ResourceSaver.FLAG_COMPRESS) == OK)
	print("Farm edited vertices lowered: ", changed)
	source.free()
	bake_module("res://assets/models/mossy_fence.glb", "res://assets/models/mossy_fence_mobile.res", 4000)
	bake_module("res://assets/models/cozy_timber_house.glb", "res://assets/models/cozy_timber_house_mobile.res", 40000)
	quit()

func bake_module(source_path: String, output_path: String, minimum_triangles: int) -> void:
	var source: Node3D = load(source_path).instantiate()
	var original: Mesh = source.find_children("*", "MeshInstance3D", true, false)[0].mesh
	var simplified := ArrayMesh.new()
	for surface in original.get_surface_count():
		var arrays: Array = original.surface_get_arrays(surface)
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		importer.generate_lods(60, 25, [])
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for level in importer.get_surface_lod_count(0):
			var candidate := importer.get_surface_lod_indices(0, level)
			if candidate.size() / 3 >= minimum_triangles:
				indices = candidate
		var remap: Dictionary = {}
		var used := PackedInt32Array()
		for index in indices:
			if not remap.has(index):
				remap[index] = used.size()
				used.append(index)
		for i in indices.size():
			indices[i] = remap[indices[i]]
		for attribute in Mesh.ARRAY_INDEX:
			if arrays[attribute] == null or arrays[attribute].is_empty():
				continue
			var stride := 4 if attribute == Mesh.ARRAY_TANGENT else 1
			var values: Variant = arrays[attribute].duplicate()
			values.resize(used.size() * stride)
			for i in used.size():
				for component in stride:
					values[i * stride + component] = arrays[attribute][used[i] * stride + component]
			arrays[attribute] = values
		arrays[Mesh.ARRAY_INDEX] = indices
		simplified.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		simplified.surface_set_material(surface, original.surface_get_material(surface))
		print(source_path, " triangles: ", indices.size() / 3)
	assert(ResourceSaver.save(simplified, output_path, ResourceSaver.FLAG_COMPRESS) == OK)
	source.free()
