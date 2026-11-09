extends CharacterBody3D
var yaw: Node3D
var pitch: SpringArm3D
var camera: Camera3D
var state: String = "idle"
var enabled: bool = false
var touch_axis := Vector2.ZERO
var touch_running: bool = false
var touch_jump: bool = false
var avatar: Node3D
var respawn_position := Vector3(0, 5, 12)
const CAMERA_MIN_PITCH := -55.0 * PI / 180.0
const CAMERA_MAX_PITCH := -8.0 * PI / 180.0
const CAMERA_DEFAULT_PITCH := -20.0 * PI / 180.0
const CAMERA_FOCUS := Vector3(0, 1.6, 0)
var camera_yaw := 0.0
var camera_pitch := CAMERA_DEFAULT_PITCH

func _ready() -> void:
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
	pitch.spring_length = 6.5
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
	camera.fov = 65.0
	camera.near = 0.15
	pitch.add_child(camera)

func rotate_camera(motion: Vector2) -> void:
	if not enabled or not camera.current:
		return
	camera_yaw = wrapf(camera_yaw - motion.x * 0.0022, -PI, PI)
	camera_pitch = clampf(camera_pitch - motion.y * 0.0018, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)

func _process(delta: float) -> void:
	if not enabled or not camera.current:
		return
	update_camera(delta)

func update_camera(delta: float) -> void:
	var rotation_weight := 1.0 - exp(-16.0 * delta)
	yaw.rotation = Vector3(0, lerp_angle(yaw.rotation.y, camera_yaw, rotation_weight), 0)
	pitch.rotation = Vector3(lerpf(pitch.rotation.x, camera_pitch, rotation_weight), 0, 0)
	var focus := global_position + CAMERA_FOCUS
	if yaw.global_position.distance_to(focus) > 15.0:
		yaw.global_position = focus
	else:
		var horizontal_weight := 1.0 - exp(-22.0 * delta)
		yaw.global_position.x = lerpf(yaw.global_position.x, focus.x, horizontal_weight)
		yaw.global_position.z = lerpf(yaw.global_position.z, focus.z, horizontal_weight)
		yaw.global_position.y = lerpf(yaw.global_position.y, focus.y, 1.0 - exp(-8.0 * delta))

func _unhandled_input(event: InputEvent) -> void:
	if enabled and event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.screen_relative)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var axis := Input.get_vector("left", "right", "forward", "back")
	axis = (axis + touch_axis).limit_length()
	var direction := yaw.global_basis * Vector3(axis.x, 0, axis.y)
	direction.y = 0
	direction = direction.normalized()
	var speed: float = 8.0 if (Input.is_action_pressed("run") or touch_running) else 4.5
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 24 * delta
	elif Input.is_action_just_pressed("jump") or touch_jump:
		velocity.y = 8
	state = "air" if not is_on_floor() else ("run" if speed > 5 and axis.length() > 0 else ("walk" if axis.length() > 0 else "idle"))
	touch_jump = false
	if direction.length() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-direction.x, -direction.z), delta * 12)
	avatar.animate(delta, axis.length() > 0.1, speed > 5, is_on_floor() and velocity.y <= 0, velocity.y)
	move_and_slide()
	position.x = clampf(position.x, -125, 125)
	position.z = clampf(position.z, -125, 125)
	if position.y < -25:
		position = respawn_position
