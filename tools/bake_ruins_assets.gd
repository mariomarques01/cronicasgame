extends SceneTree
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass the directory containing generated GLBs after --")
		quit(2)
		return
	for id in ["arch", "broken_arch", "wall", "rubble"]:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		assert(doc.append_from_file(args[0].path_join(id + ".glb"),state) == OK)
		var scene := doc.generate_scene(state)
		var node := scene.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		var result := ArrayMesh.new()
		var stone := StandardMaterial3D.new()
		stone.albedo_texture = load("res://assets/ruins/limestone.png")
		stone.albedo_color = Color.WHITE
		stone.normal_enabled = true
		stone.normal_texture = load("res://assets/ruins/limestone_normal.png")
		stone.vertex_color_use_as_albedo = true
		stone.roughness = 0.95
		var moss := StandardMaterial3D.new()
		moss.albedo_color = Color("4e6b35")
		moss.vertex_color_use_as_albedo = true
		moss.roughness = 1.0
		for surface in node.mesh.get_surface_count():
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,node.mesh.surface_get_arrays(surface))
			var material_name: String = node.mesh.surface_get_material(surface).resource_name
			result.surface_set_material(surface,moss if material_name.contains("Moss") else stone)
		assert(result.get_faces().size()/3 < 5000)
		assert(ResourceSaver.save(result,"res://assets/ruins/" + id + ".res",ResourceSaver.FLAG_COMPRESS) == OK)
		print("RUINS_BAKED ",id," ",result.get_faces().size()/3," triangles; ",result.get_surface_count()," surfaces")
		scene.free()
	quit()
