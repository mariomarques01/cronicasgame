extends SceneTree
const JOBS := {"forest_tree":"res://assets/models/forest_tree_mobile.res", "farm_pine":"res://assets/models/farm_pine_mobile.res", "mossy_fence":"res://assets/models/mossy_fence_mobile.res", "cabbage":"res://assets/crops/cabbage_mobile.res", "carrots":"res://assets/crops/carrots_mobile.res"}
var model: Node3D
var animation_player: AnimationPlayer
const JUMP_MODEL = preload("res://assets/models/Jumping.fbx")
const CONTACT_TIME := 1.10
var build_directory: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Provide the Blender output directory after --")
		quit(2)
		return
	build_directory = args[0]
	for id: String in JOBS:
		bake(id,JOBS[id])
	bake("bunny", "res://assets/models/bunny_mobile.res")
	pack_bunny()
	quit()
func bake(id: String, target: String) -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(build_directory.path_join(id+".glb"),state)==OK)
	var scene := doc.generate_scene(state)
	var source := scene.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	var original: Mesh
	var old_scene: Node3D
	var original_skin: Skin
	if id == "bunny":
		old_scene=load("res://assets/models/bunny_animated.glb").instantiate()
		var old_node := old_scene.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		original=old_node.mesh
		original_skin=old_node.skin
	else:
		original=load(target)
	var remap: Dictionary={}
	if id == "bunny":
		var sk := source.get_node(source.skeleton) as Skeleton3D
		for bind in source.skin.get_bind_count():
			var bone_name := source.skin.get_bind_name(bind)
			if bone_name == &"": bone_name=sk.get_bone_name(source.skin.get_bind_bone(bind))
			for old_bind in original_skin.get_bind_count():
				if original_skin.get_bind_name(old_bind)==bone_name:
					remap[bind]=old_bind
					break
			assert(remap.has(bind),"Missing bone mapping: "+bone_name)
	var result := ArrayMesh.new()
	for surface in source.mesh.get_surface_count():
		var arrays := source.mesh.surface_get_arrays(surface)
		if id == "bunny":
			var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			for i in bones.size(): bones[i]=remap[bones[i]]
			arrays[Mesh.ARRAY_BONES]=bones
		else:
			# Keep the exact placement bounds used by fence modules and crop spacing.
			var before := original.get_aabb()
			var after := source.mesh.get_aabb()
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for i in vertices.size(): vertices[i]=before.position+(vertices[i]-after.position)*before.size/after.size
			arrays[Mesh.ARRAY_VERTEX]=vertices
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var material := original.surface_get_material(mini(surface,original.get_surface_count()-1)).duplicate() as Material
		result.surface_set_material(surface,material)
	assert(ResourceSaver.save(result,target,ResourceSaver.FLAG_COMPRESS)==OK)
	print("MOBILE_SAVED ",id," ",result.get_faces().size()/3," triangles")
	if old_scene!=null:old_scene.free()
	scene.free()

func pack_bunny() -> void:
	var scene: Node3D = load("res://assets/models/bunny_animated.glb").instantiate()
	scene.scene_file_path = ""
	var mesh_node := scene.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
	mesh_node.mesh=load("res://assets/models/bunny_mobile.res")
	mesh_node.skin=mesh_node.skin.duplicate(true)
	var player := scene.find_child("AnimationPlayer",true,false) as AnimationPlayer
	for lib: StringName in player.get_animation_library_list():
		var duplicate := player.get_animation_library(lib).duplicate(true) as AnimationLibrary
		player.remove_animation_library(lib)
		player.add_animation_library(lib,duplicate)
	model = scene
	animation_player = player
	bake_jump()
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,"res://assets/models/bunny_mobile.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("MOBILE_BUNNY_PACKED ",player.get_animation_list())
	scene.free()


func bake_jump() -> void:
	var source: Node3D = JUMP_MODEL.instantiate()
	var source_skeleton := source.find_child("Skeleton3D", true, false) as Skeleton3D
	var target := model.find_child("Skeleton3D", true, false) as Skeleton3D
	var source_player := source.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var original := source_player.get_animation("mixamo_com")
	var jump := Animation.new()
	jump.length = original.length
	jump.loop_mode = Animation.LOOP_NONE
	for track in original.get_track_count():
		# Physics owns translation. Retarget rotations without changing bone lengths.
		if original.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var bone_name := original.track_get_path(track).get_subname(0)
		var source_bone := source_skeleton.find_bone(bone_name)
		var target_bone := target.find_bone(bone_name)
		if source_bone < 0 or target_bone < 0:
			continue
		var source_rest := source_skeleton.get_bone_global_rest(source_bone).basis.get_rotation_quaternion()
		var target_rest := target.get_bone_global_rest(target_bone).basis.get_rotation_quaternion()
		var source_local := source_skeleton.get_bone_rest(source_bone).basis.get_rotation_quaternion()
		var target_local := target.get_bone_rest(target_bone).basis.get_rotation_quaternion()
		var source_parent := source_rest * source_local.inverse()
		var target_parent := target_rest * target_local.inverse()
		var new_track := jump.add_track(Animation.TYPE_ROTATION_3D)
		jump.track_set_path(new_track, NodePath(str(model.get_path_to(target)) + ":" + bone_name))
		for key in original.track_get_key_count(track):
			var rotation: Quaternion = original.track_get_key_value(track, key)
			var adapted := (target_parent.inverse() * source_parent * rotation * source_rest.inverse() * target_rest).normalized()
			jump.rotation_track_insert_key(new_track, original.track_get_key_time(track, key), adapted)
	# Keep only local crouch compression, never the FBX's ballistic/root motion.
	var hips := target.find_bone("mixamorig_Hips")
	var source_hips := source_skeleton.find_bone("mixamorig_Hips")
	var rest := target.get_bone_rest(hips).origin
	var ratio := rest.y / source_skeleton.get_bone_rest(source_hips).origin.y
	var hip_track := jump.add_track(Animation.TYPE_POSITION_3D)
	jump.track_set_path(hip_track, NodePath(str(model.get_path_to(target)) + ":mixamorig_Hips"))
	for key in original.track_get_key_count(0):
		var offset: Vector3 = original.track_get_key_value(0, key)
		jump.position_track_insert_key(hip_track, original.track_get_key_time(0, key), rest + Vector3.DOWN * maxf(0.0, 0.969123 - offset.y) * ratio)
	var landing := Animation.new()
	landing.length = 0.55
	for track in jump.get_track_count():
		var new_track := landing.add_track(jump.track_get_type(track))
		landing.track_set_path(new_track, jump.track_get_path(track))
		for frame in range(18):
			var time := minf(float(frame) / 30.0, landing.length)
			var source_time := CONTACT_TIME + time
			if jump.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				landing.rotation_track_insert_key(new_track, time, jump.rotation_track_interpolate(track, source_time))
			else:
				landing.position_track_insert_key(new_track, time, jump.position_track_interpolate(track, source_time))
	animation_player.get_animation_library("").add_animation("Jumping", jump)
	animation_player.get_animation_library("").add_animation("JumpLanding", landing)
	source.free()

