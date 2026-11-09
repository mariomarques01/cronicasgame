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
	yaw.position.y = 1.6
	add_child(yaw)
	pitch = SpringArm3D.new()
	pitch.spring_length = 7.0
	pitch.rotation.x = -0.25
	pitch.margin = 0.2
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.2
	pitch.shape = camera_shape
	pitch.add_excluded_object(get_rid())
	yaw.add_child(pitch)
	camera = Camera3D.new()
	camera.current = true
	camera.far = 450
	pitch.add_child(camera)

func rotate_camera(motion: Vector2) -> void:
	yaw.rotation.y -= motion.x * 0.003
	pitch.rotation.x = clampf(pitch.rotation.x - motion.y * 0.003, -1.1, 0.55)

func _unhandled_input(event: InputEvent) -> void:
	if enabled and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative)

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
	avatar.animate(delta, axis.length() > 0.1, speed > 5)
	move_and_slide()
	position.x = clampf(position.x, -125, 125)
	position.z = clampf(position.z, -125, 125)
	if position.y < -25:
		position = Vector3(0, 5, 12)
