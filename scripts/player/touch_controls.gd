extends Control
var player: CharacterBody3D
var stick_id: int = -1
var look_id: int = -1
var stick_center := Vector2.ZERO
var stick_offset := Vector2.ZERO
var radius: float = 80
var active: bool = false
var action_buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active = DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		active = bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0"))
	visible = active

func reset() -> void:
	stick_id = -1
	look_id = -1
	stick_offset = Vector2.ZERO
	player.touch_axis = Vector2.ZERO
	player.touch_running = false
	player.touch_jump = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active or not player.enabled:
		reset()
		return
	var viewport_size := get_viewport_rect().size
	stick_center = Vector2(135, viewport_size.y - 145)
	if event is InputEventScreenTouch:
		if event.pressed:
			for button: Button in action_buttons:
				if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
					button.pressed.emit()
					get_viewport().set_input_as_handled()
					return
			if event.position.distance_to(stick_center) < radius * 1.8 and stick_id == -1:
				stick_id = event.index
				update_stick(event.position)
			elif event.position.x > viewport_size.x * 0.4 and event.position.y < viewport_size.y - 260:
				look_id = event.index
		else:
			if event.index == stick_id:
				stick_id = -1
				stick_offset = Vector2.ZERO
				player.touch_axis = Vector2.ZERO
				player.touch_running = false
			if event.index == look_id:
				look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == stick_id:
			update_stick(event.position)
		elif event.index == look_id:
			player.rotate_camera(event.relative * 0.7)
	queue_redraw()

func update_stick(pos: Vector2) -> void:
	stick_offset = (pos - stick_center).limit_length(radius)
	player.touch_axis = stick_offset / radius
	if player.touch_axis.length() < 0.12:
		player.touch_axis = Vector2.ZERO
	player.touch_running = stick_offset.length() > radius * 0.85

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):
		reset()

func _draw() -> void:
	if not active or not player.enabled:
		return
	stick_center = Vector2(135, get_viewport_rect().size.y - 145)
	draw_circle(stick_center, radius, Color(0.04, 0.1, 0.07, 0.55))
	draw_arc(stick_center, radius, 0, TAU, 48, Color("d1b477"), 3, true)
	draw_circle(stick_center + stick_offset, 34, Color(0.85, 0.75, 0.5, 0.85))

func _process(_delta: float) -> void:
	queue_redraw()
