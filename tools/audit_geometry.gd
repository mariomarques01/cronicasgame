extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	var rows: Array[Dictionary] = []
	for node in world.find_children("*", "", true, false):
		var mesh: Mesh
		var copies := 1
		if node is MeshInstance3D: mesh=node.mesh
		elif node is MultiMeshInstance3D:
			mesh=node.multimesh.mesh
			copies=node.multimesh.instance_count
		if mesh == null: continue
		var tris := 0
		for i in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(i)
			tris += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3
		rows.append({"node":str(world.get_path_to(node)),"triangles":tris,"copies":copies,"total":tris*copies,"surfaces":mesh.get_surface_count(),"shadow":node.cast_shadow})
	rows.sort_custom(func(a,b): return a.total>b.total)
	print("GEOMETRY ",JSON.stringify(rows))
	quit()
