extends CharacterBody3D
var yaw: Node3D
var pitch: SpringArm3D
var camera: Camera3D
var state: String = "idle"
var enabled: bool = false

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.36
	body.height = 1.8
	mesh.mesh = body
	mesh.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("945737")
	mesh.material_override = mat
	add_child(mesh)
	yaw = Node3D.new()
	yaw.position.y = 1.6
	add_child(yaw)
	pitch = SpringArm3D.new()
	pitch.spring_length = 5.5
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

func _unhandled_input(event: InputEvent) -> void:
	if enabled and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw.rotation.y -= event.relative.x * 0.003
		pitch.rotation.x = clampf(pitch.rotation.x - event.relative.y * 0.003, -1.1, 0.55)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var axis := Input.get_vector("left", "right", "forward", "back")
	var direction := yaw.global_basis * Vector3(axis.x, 0, axis.y)
	direction.y = 0
	direction = direction.normalized()
	var speed: float = 8.0 if Input.is_action_pressed("run") else 4.5
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 24 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 8
	state = "air" if not is_on_floor() else ("run" if speed > 5 and axis.length() > 0 else ("walk" if axis.length() > 0 else "idle"))
	move_and_slide()
	position.x = clampf(position.x, -125, 125)
	position.z = clampf(position.z, -125, 125)
	if position.y < -25:
		position = Vector3(0, 5, 12)
