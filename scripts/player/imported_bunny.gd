extends Node3D
const MODEL = preload("res://assets/models/bunny_animated.glb")
const JUMP_MODEL = preload("res://assets/models/Jumping.fbx")
const DISPLAY_HEIGHT: float = 2.5
var model: Node3D
var animation_player: AnimationPlayer
var airborne := false

func _ready() -> void:
	model = MODEL.instantiate()
	model.name = "BraveBunny"
	model.scale = Vector3.ONE * (DISPLAY_HEIGHT / 1.7)
	model.rotation.y = PI
	add_child(model)
	animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null:
		push_error("O personagem animado está sem AnimationPlayer.")
		return
	for clip: String in ["Walking", "Running"]:
		if animation_player.has_animation(clip):
			animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_import_jump()
	_set_idle_pose()

func _import_jump() -> void:
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
	animation_player.get_animation_library("").add_animation("Jumping", jump)
	source.free()

func _set_idle_pose() -> void:
	animation_player.play("Walking")
	animation_player.seek(0.0, true)
	animation_player.pause()

func animate(_delta: float, moving: bool, running: bool, grounded: bool = true) -> void:
	if animation_player == null:
		return
	if not grounded:
		if not airborne:
			# Match the one-shot clip to the normal ballistic flight (v=8, g=24).
			var speed := animation_player.get_animation("Jumping").length / (2.0 * 8.0 / 24.0)
			animation_player.play("Jumping", 0.08, speed)
		airborne = true
		return
	var landed := airborne
	airborne = false
	if not moving:
		if landed or animation_player.is_playing() or animation_player.current_animation_position != 0.0:
			_set_idle_pose()
		return
	var clip := "Running" if running else "Walking"
	if animation_player.current_animation != clip or not animation_player.is_playing():
		animation_player.play(clip, 0.18)
