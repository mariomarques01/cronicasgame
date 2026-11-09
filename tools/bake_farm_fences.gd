extends SceneTree
## Run from the project root: godot --headless --script tools/bake_farm_fences.gd
## Sources remain unchanged; regenerate the cleared farm and optimized prop meshes.
func _initialize() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_fences.json"))
	var trees: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_trees.json"))
	var tree_geometry := preload("res://scripts/world/tree_geometry.gd")
	var buildings: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_buildings.json"))
	var footprints := preload("res://scripts/world/building_geometry.gd").prepare(buildings)
	var segments: Array = []
	for path: Dictionary in layout.paths:
		for i in range(path.points.size() - 1):
			segments.append([Vector2(path.points[i][0], path.points[i][1]), Vector2(path.points[i + 1][0], path.points[i + 1][1]), float(path.get("erase_half_width", layout.erase_half_width))])
	var source: Node3D = load("res://assets/models/golden_acres.glb").instantiate()
	var original: Mesh = source.find_children("*", "MeshInstance3D", true, false)[0].mesh
	var cleared := ArrayMesh.new()
	var changed := 0
	var removed_tree_faces := 0
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
			if preload("res://scripts/world/building_geometry.gd").contains(point, footprints):
				erase = true
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
			if tree_geometry.in_old_tree(vertices[a], trees) or tree_geometry.in_old_tree(vertices[b], trees) or tree_geometry.in_old_tree(vertices[c], trees):
				removed_tree_faces += 1
				continue
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
	for region: Dictionary in trees.plant_regions:
		var signature := tree_geometry.plant_signature(cleared, region.bounds, trees, footprints)
		if signature.sha256 != region.baseline.sha256 or signature.triangles != int(region.baseline.triangles):
			push_error("Plant geometry/UV preservation failed: " + str(region.id))
			quit(1)
			return
	assert(ResourceSaver.save(cleared, "res://assets/models/farm_without_fences.res", ResourceSaver.FLAG_COMPRESS) == OK)
	print("Farm edited vertices lowered: ", changed)
	print("Old tree triangles removed: ", removed_tree_faces, "; all plant signatures preserved")
	source.free()
	bake_module("res://assets/models/mossy_fence.glb", "res://assets/models/mossy_fence_mobile.res", 4000)
	bake_module("res://assets/models/cozy_timber_house.glb", "res://assets/models/cozy_timber_house_mobile.res", 40000)
	bake_module("res://assets/models/farm_pine.glb", "res://assets/models/farm_pine_mobile.res", 5000, 0.08)
	bake_module("res://assets/models/forest_tree.glb", "res://assets/models/forest_tree_mobile.res", 5000, 0.08)
	for building: Dictionary in buildings:
		var minimum := 25000 if building.asset == "workshop" else 40000
		bake_module("res://assets/models/" + building.asset + ".glb", "res://assets/models/" + building.asset + "_mobile.res", minimum, 0.08)
	bake_windmill_rotor()
	quit()

func bake_windmill_rotor() -> void:
	var full: Mesh = load("res://assets/models/windmill_mobile.res")
	var stationary := ArrayMesh.new()
	var rotating := ArrayMesh.new()
	for surface in full.get_surface_count():
		var arrays: Array = full.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var static_indices := PackedInt32Array()
		var rotor_indices := PackedInt32Array()
		for i in range(0, indices.size(), 3):
			var center := (vertices[indices[i]] + vertices[indices[i + 1]] + vertices[indices[i + 2]]) / 3.0
			# Front rotor plane; exclude the lower central doorway and its trim.
			var is_rotor := center.z > 0.25 and center.y > 0.28 and (center.y > 0.40 or absf(center.x - 0.0028) > 0.145)
			if is_rotor:
				rotor_indices.append_array(PackedInt32Array([indices[i], indices[i + 1], indices[i + 2]]))
			else:
				static_indices.append_array(PackedInt32Array([indices[i], indices[i + 1], indices[i + 2]]))
		var static_arrays := arrays.duplicate()
		static_arrays[Mesh.ARRAY_INDEX] = static_indices
		stationary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, static_arrays)
		stationary.surface_set_material(surface, full.surface_get_material(surface))
		var rotor_arrays := arrays.duplicate()
		rotor_arrays[Mesh.ARRAY_INDEX] = rotor_indices
		rotating.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, rotor_arrays)
		rotating.surface_set_material(surface, full.surface_get_material(surface))
		print("Windmill split: ", static_indices.size() / 3, " static, ", rotor_indices.size() / 3, " rotor triangles")
	assert(ResourceSaver.save(stationary, "res://assets/models/windmill_static.res", ResourceSaver.FLAG_COMPRESS) == OK)
	assert(ResourceSaver.save(rotating, "res://assets/models/windmill_rotor.res", ResourceSaver.FLAG_COMPRESS) == OK)

func bake_module(source_path: String, output_path: String, minimum_triangles: int, maximum_error_ratio: float = INF) -> void:
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
			if candidate.size() / 3 >= minimum_triangles and importer.get_surface_lod_size(0, level) <= original.get_aabb().size.y * maximum_error_ratio:
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
