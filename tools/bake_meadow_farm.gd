extends SceneTree
## Preserve only the two cultivated regions; the old ground/decorations are not exported.
func _initialize() -> void:
	var original: ArrayMesh = load("res://assets/models/farm_without_fences.res")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_trees.json"))
	var crops := ArrayMesh.new()
	for surface in original.get_surface_count():
		var arrays := original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.set_material(original.surface_get_material(surface))
		for i in range(0, indices.size(), 3):
			var keep := false
			for region: Dictionary in config.plant_regions:
				if region.id not in ["crops", "vegetable_garden"]:
					continue
				var inside := true
				for j in 3:
					var vertex := vertices[indices[i + j]]
					if vertex.x < region.bounds[0] or vertex.x > region.bounds[1] or vertex.z < region.bounds[2] or vertex.z > region.bounds[3]:
						inside = false
						break
				keep = keep or inside
			if not keep:
				continue
			for j in 3:
				var index := indices[i + j]
				tool.set_normal(arrays[Mesh.ARRAY_NORMAL][index])
				tool.set_uv(arrays[Mesh.ARRAY_TEX_UV][index])
				tool.add_vertex(vertices[index])
		tool.generate_tangents()
		tool.index()
		tool.commit(crops)
	for region: Dictionary in config.plant_regions:
		if region.id not in ["crops", "vegetable_garden"]:
			continue
		var signature := preload("res://scripts/world/tree_geometry.gd").plant_signature(crops, region.bounds)
		if signature.sha256 != region.baseline.sha256 or signature.triangles != int(region.baseline.triangles):
			push_error("Plant preservation failed: " + str(region.id))
			quit(1)
			return
		print("Preserved ", region.id, ": ", signature.triangles, " triangles, identical positions/UVs")
	var error := ResourceSaver.save(crops, "res://assets/models/farm_crops.res", ResourceSaver.FLAG_COMPRESS)
	quit(0 if error == OK else 1)
