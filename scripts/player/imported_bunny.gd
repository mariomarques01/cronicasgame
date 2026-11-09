extends Node3D
const MODEL = preload("res://assets/models/bunny_animated.glb")
const JUMP_MODEL = preload("res://assets/models/Jumping.fbx")
const DISPLAY_HEIGHT: float = 2.5
var model: Node3D
var animation_player: AnimationPlayer
var airborne := false
var air_time := 0.0
var landing_time := 0.0
var fall_delay := 0.0
const TAKEOFF_TIME := 0.50
const APEX_TIME := 0.78
const CONTACT_TIME := 1.10
const LANDING_DURATION := 0.20

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

func _set_idle_pose() -> void:
	animation_player.play("Walking")
	animation_player.seek(0.0, true)
	animation_player.pause()

func animate(delta: float, moving: bool, running: bool, grounded: bool = true, vertical_velocity: float = NAN) -> void:
	if animation_player == null:
		return
	if not grounded:
		if not airborne:
			# Ignore momentary floor loss on uneven terrain, but jump immediately.
			if is_finite(vertical_velocity) and vertical_velocity <= 0.0:
				fall_delay += delta
				if fall_delay < 0.10:
					return
			air_time = 0.0
			landing_time = 0.0
			animation_player.play("Jumping", 0.08, 0.0)
		airborne = true
		air_time += delta
		var sample: float
		if is_finite(vertical_velocity):
			if vertical_velocity > 0:
				sample = lerpf(TAKEOFF_TIME, APEX_TIME, 1.0 - clampf(vertical_velocity / 8.0, 0.0, 1.0))
			else:
				sample = lerpf(APEX_TIME, CONTACT_TIME, clampf(-vertical_velocity / 8.0, 0.0, 1.0))
		else:
			sample = lerpf(TAKEOFF_TIME, CONTACT_TIME, clampf(air_time / (2.0 * 8.0 / 24.0), 0.0, 1.0))
		# Hold the descending pose during long falls; never crouch before contact.
		animation_player.seek(sample, false)
		return
	fall_delay = 0.0
	if airborne:
		airborne = false
		landing_time = LANDING_DURATION
		animation_player.play("JumpLanding", 0.04, 0.55 / LANDING_DURATION)
	if landing_time > 0.0:
		landing_time = maxf(0.0, landing_time - delta)
		if landing_time > 0.0:
			return
	if not moving:
		if animation_player.assigned_animation != "Walking" or animation_player.is_playing() or animation_player.current_animation_position != 0.0:
			_set_idle_pose()
		return
	var clip := "Running" if running else "Walking"
	if animation_player.current_animation != clip or not animation_player.is_playing():
		animation_player.play(clip, 0.12)
