extends Node3D
const MODEL = preload("res://assets/models/bunny_mobile.scn")
const DISPLAY_HEIGHT: float = 2.5
var model: Node3D
var animation_player: AnimationPlayer
var airborne := false
var air_time := 0.0
var landing_time := 0.0
var fall_delay := 0.0
var locomotion_rate := 1.0
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
	var idle := animation_player.get_animation("Walking").duplicate() as Animation
	idle.length = 0.5
	idle.loop_mode = Animation.LOOP_LINEAR
	for track in idle.get_track_count():
		var pose: Variant = idle.track_get_key_value(track, 0)
		while idle.track_get_key_count(track) > 0:
			idle.track_remove_key(track, 0)
		idle.track_insert_key(track, 0.0, pose)
	animation_player.get_animation_library("").add_animation("Rest", idle)
	_set_idle_pose()

func _set_idle_pose() -> void:
	animation_player.play("Rest", 0.18)

func animate(delta: float, moving: bool, running: bool, grounded: bool = true, vertical_velocity: float = NAN, locomotion_speed: float = NAN) -> void:
	if animation_player == null:
		return
	animation_player.speed_scale = 1.0
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
		if animation_player.assigned_animation != "Rest":
			_set_idle_pose()
		return
	var clip := "Running" if running else "Walking"
	if is_finite(locomotion_speed):
		var target_rate := clampf(locomotion_speed / (8.0 if running else 4.5), 0.25, 1.3)
		locomotion_rate = lerpf(locomotion_rate, target_rate, 1.0 - exp(-14.0 * delta))
		animation_player.speed_scale = locomotion_rate
	if animation_player.current_animation != clip or not animation_player.is_playing():
		animation_player.play(clip, 0.12)

func animate_motion(delta: float, turn_rate: float, acceleration: float, grounded: bool) -> void:
	# Small additive visual response; physics capsule and animation bones are untouched.
	var weight := 1.0 - exp(-10.0 * delta)
	var roll := clampf(-turn_rate * 0.012, -0.07, 0.07) if grounded else 0.0
	var lean := clampf(acceleration * 0.0015, -0.045, 0.045) if grounded else 0.0
	model.rotation.z = lerpf(model.rotation.z, roll, weight)
	model.rotation.x = lerpf(model.rotation.x, lean, weight)

func reset_motion() -> void:
	model.rotation.y = PI
	airborne = false
	air_time = 0.0
	landing_time = 0.0
	fall_delay = 0.0
	model.rotation.x = 0.0
	model.rotation.z = 0.0
	_set_idle_pose()
