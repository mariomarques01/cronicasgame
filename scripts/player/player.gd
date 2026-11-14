extends CharacterBody3D
signal landed(impact_speed: float)
var yaw: Node3D
var pitch: SpringArm3D
var camera: Camera3D
var state: String = "idle"
var enabled: bool = false
var touch_axis := Vector2.ZERO
var touch_jump: bool = false
var avatar: Node3D
var respawn_position := Vector3(0, 5, 12)
const CAMERA_MIN_PITCH := -55.0 * PI / 180.0
const CAMERA_MAX_PITCH := -8.0 * PI / 180.0
const CAMERA_DEFAULT_PITCH := -20.0 * PI / 180.0
const CAMERA_FOCUS := Vector3(0, 1.6, 0)
var camera_yaw := 0.0
var camera_pitch := CAMERA_DEFAULT_PITCH
const WALK_SPEED := 4.5
const RUN_SPEED := 8.0
const GROUND_ACCELERATION := 36.0
const GROUND_BRAKING := 60.0
const AIR_ACCELERATION := 14.0
const TURN_SPEED := 12.0
const GRAVITY := 24.0
const JUMP_SPEED := 8.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const STEP_HEIGHT := 0.28
var movement_speed := 0.0
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _running_gait := false

func _ready() -> void:
	floor_snap_length = 0.35
	floor_stop_on_slope = true
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	avatar = Node3D.new()
	avatar.set_script(preload("res://scripts/player/imported_bunny.gd"))
	add_child(avatar)
	yaw = Node3D.new()
	add_child(yaw)
	# Follow translation independently so jumping does not jerk the entire view.
	yaw.top_level = true
	yaw.global_position = global_position + CAMERA_FOCUS
	pitch = SpringArm3D.new()
	pitch.spring_length = 7.0
	pitch.rotation.x = CAMERA_DEFAULT_PITCH
	pitch.margin = 0.25
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.2
	pitch.shape = camera_shape
	pitch.add_excluded_object(get_rid())
	yaw.add_child(pitch)
	camera = Camera3D.new()
	camera.current = true
	camera.far = 450
	camera.fov = 68.0
	camera.near = 0.15
	pitch.add_child(camera)

func rotate_camera(motion: Vector2) -> void:
	if not enabled or not camera.current:
		return
	camera_yaw = wrapf(camera_yaw - motion.x * 0.0022, -PI, PI)
	camera_pitch = clampf(camera_pitch - motion.y * 0.0018, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)

func rotate_touch_camera(motion: Vector2, view_size: Vector2) -> void:
	if not enabled or not camera.current:
		return
	# ScreenTouch is already transformed into CSS/layout coordinates by Godot.
	var sensitivity := PI / maxf(320.0, minf(view_size.x, view_size.y))
	camera_yaw = wrapf(camera_yaw - motion.x * sensitivity, -PI, PI)
	camera_pitch = clampf(camera_pitch - motion.y * sensitivity * 0.75, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)

func center_camera() -> void:
	if enabled:
		camera.make_current()
		camera_yaw = avatar.rotation.y
		camera_pitch = CAMERA_DEFAULT_PITCH

func _process(delta: float) -> void:
	if not enabled or not camera.current:
		return
	update_camera(delta)

func update_camera(delta: float) -> void:
	var rotation_weight := 1.0 - exp(-20.0 * delta)
	yaw.rotation = Vector3(0, lerp_angle(yaw.rotation.y, camera_yaw, rotation_weight), 0)
	pitch.rotation = Vector3(lerpf(pitch.rotation.x, camera_pitch, rotation_weight), 0, 0)
	var look_ahead := (Vector3(velocity.x, 0, velocity.z) * 0.12).limit_length(0.8)
	var focus := global_position + CAMERA_FOCUS + look_ahead
	if yaw.global_position.distance_to(focus) > 15.0:
		yaw.global_position = focus
	else:
		var horizontal_weight := 1.0 - exp(-22.0 * delta)
		yaw.global_position.x = lerpf(yaw.global_position.x, focus.x, horizontal_weight)
		yaw.global_position.z = lerpf(yaw.global_position.z, focus.z, horizontal_weight)
		yaw.global_position.y = lerpf(yaw.global_position.y, focus.y, 1.0 - exp(-8.0 * delta))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_center"):
		center_camera()
	if enabled and event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.screen_relative)

func _physics_process(delta: float) -> void:
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0
		movement_speed = 0.0
		_jump_buffer_left = 0.0
		return
	var grounded_before := is_on_floor()
	var keyboard_axis := Input.get_vector("left", "right", "forward", "back")
	var axis := (keyboard_axis + touch_axis).limit_length()
	var direction := yaw.global_basis * Vector3(axis.x, 0, axis.y)
	direction.y = 0
	direction = direction.normalized()
	var top_speed := RUN_SPEED if keyboard_axis.is_zero_approx() or Input.is_action_pressed("run") else WALK_SPEED
	var target := Vector2(direction.x, direction.z) * top_speed * axis.length()
	var horizontal := Vector2(velocity.x, velocity.z)
	var acceleration := AIR_ACCELERATION
	if is_on_floor():
		acceleration = GROUND_BRAKING if axis.is_zero_approx() or horizontal.dot(target) < 0 else GROUND_ACCELERATION
	horizontal = horizontal.move_toward(target, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	_coyote_left = COYOTE_TIME if is_on_floor() else maxf(0.0, _coyote_left - delta)
	_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)
	if Input.is_action_just_pressed("jump") or touch_jump:
		_jump_buffer_left = JUMP_BUFFER_TIME
	touch_jump = false
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if _jump_buffer_left > 0 and _coyote_left > 0 and velocity.y <= 0:
		velocity.y = JUMP_SPEED
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
	if direction.length() > 0.1:
		avatar.rotation.y = rotate_toward(avatar.rotation.y, atan2(-direction.x, -direction.z), TURN_SPEED * delta)
	if is_on_floor() and velocity.y <= 0:
		try_small_step(Vector3(velocity.x, 0, velocity.z) * delta)
	var impact_speed := maxf(0.0, -velocity.y)
	move_and_slide()
	if not grounded_before and is_on_floor():
		landed.emit(impact_speed)
	movement_speed = Vector2(velocity.x, velocity.z).length()
	if movement_speed > 5.6:
		_running_gait = true
	elif movement_speed < 4.9:
		_running_gait = false
	state = "air" if not is_on_floor() else ("idle" if movement_speed < 0.15 else ("run" if _running_gait else "walk"))
	avatar.animate(delta, movement_speed > 0.15, _running_gait, is_on_floor() and velocity.y <= 0, velocity.y, movement_speed)
	position.x = clampf(position.x, -125, 125)
	position.z = clampf(position.z, -125, 125)
	if position.y < -25:
		position = respawn_position

func try_small_step(motion: Vector3) -> void:
	if motion.length_squared() < 0.000001:
		return
	var front := KinematicCollision3D.new()
	if not test_move(global_transform, motion, front):
		return
	if front.get_normal().y >= cos(floor_max_angle):
		return # Ordinary ramps are already handled by move_and_slide.
	var rise := Vector3.UP * STEP_HEIGHT
	if test_move(global_transform, rise):
		return # Keep head clearance under roofs and low ceilings.
	var raised := global_transform.translated(rise)
	if test_move(raised, motion):
		return # Fences, walls and characters remain obstacles.
	# Probe beyond the rounded toe, so an edge normal is not mistaken for its top.
	var support_probe := motion.normalized() * maxf(motion.length(), 0.42)
	if test_move(raised, support_probe):
		return
	var down := KinematicCollision3D.new()
	if not test_move(raised.translated(support_probe), Vector3.DOWN * (STEP_HEIGHT + 0.02), down):
		return # Never step into empty space.
	if down.get_normal().y < cos(floor_max_angle):
		return
	var lift := STEP_HEIGHT + down.get_travel().y
	if lift > 0.01 and lift <= STEP_HEIGHT:
		global_position.y += lift + 0.002
