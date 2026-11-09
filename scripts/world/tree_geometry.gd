extends RefCounted

static func in_old_tree(vertex: Vector3, config: Dictionary) -> bool:
	if vertex.y <= float(config.source_removal_min_y):
		return false
	var volumes: Array = config.embedded_trees.duplicate()
	volumes.append_array(config.get("extra_removal_volumes", []))
	for tree: Dictionary in volumes:
		var offset := Vector2((vertex.x - float(tree.center[0])) / float(tree.radii[0]), (vertex.z - float(tree.center[1])) / float(tree.radii[1]))
		if offset.length_squared() <= 1.0:
			return true
	return false

static func plant_signature(mesh: Mesh, bounds: Array, excluded_trees: Dictionary = {}, excluded_buildings: Array = []) -> Dictionary:
	var bytes := PackedByteArray()
	var count := 0
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0, indices.size(), 3):
			var included := true
			for j in 3:
				var v := vertices[indices[i + j]]
				if v.x < bounds[0] or v.x > bounds[1] or v.z < bounds[2] or v.z > bounds[3]:
					included = false
					break
				if not excluded_trees.is_empty() and in_old_tree(v, excluded_trees):
					included = false
					break
				if preload("res://scripts/world/building_geometry.gd").contains(Vector2(v.x, v.z), excluded_buildings):
					included = false
					break
			if included:
				for j in 3:
					bytes.append_array(PackedVector3Array([vertices[indices[i + j]]]).to_byte_array())
					bytes.append_array(PackedVector2Array([uvs[indices[i + j]]]).to_byte_array())
				count += 1
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return {"triangles": count, "sha256": hash.finish().hex_encode()}
