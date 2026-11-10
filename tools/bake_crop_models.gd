extends SceneTree
## Source GLBs stay in an ignored folder; only compact meshes/textures ship.
func _initialize() -> void:
	for crop: String in ["cabbage", "carrots"]:
		if not bake(crop, 4000 if crop == "cabbage" else 6000):
			quit(1)
			return
	quit()

func bake(crop: String, minimum_triangles: int) -> bool:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file("res://assets/crops/source/" + crop + ".glb", state)
	if error != OK:
		push_error("Cannot read crop source: " + crop)
		return false
	var scene := document.generate_scene(state)
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	if meshes.size() != 1:
		scene.free()
		push_error("Expected one crop mesh: " + crop)
		return false
	var original: Mesh = meshes[0].mesh
	var result := ArrayMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/crops/textures/" + crop + "_albedo.png")
	material.normal_enabled = true
	material.normal_texture = load("res://assets/crops/textures/" + crop + "_normal.png")
	material.roughness_texture = load("res://assets/crops/textures/" + crop + "_roughness_metallic.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.roughness = 1.0
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for surface in original.get_surface_count():
		var arrays := original.surface_get_arrays(surface)
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		importer.generate_lods(60, 25, [])
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for level in importer.get_surface_lod_count(0):
			var candidate := importer.get_surface_lod_indices(0, level)
			if candidate.size() / 3 >= minimum_triangles and importer.get_surface_lod_size(0, level) <= original.get_aabb().size.y * 0.35:
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
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		result.surface_set_material(surface, material)
		print(crop, ": ", indices.size() / 3, " triangles; ", used.size(), " vertices")
	error = ResourceSaver.save(result, "res://assets/crops/" + crop + "_mobile.res", ResourceSaver.FLAG_COMPRESS)
	scene.free()
	return error == OK
