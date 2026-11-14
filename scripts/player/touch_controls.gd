extends Control
var player: CharacterBody3D
var stick_id: int = -1
var look_id: int = -1
var stick_center := Vector2.ZERO
var stick_offset := Vector2.ZERO
var radius: float = 60
var active: bool = false
var action_buttons: Array[Button] = []
var look_blockers: Array[Control] = []
const DEADZONE := 0.14

func home_center() -> Vector2:
	var view_size := get_viewport_rect().size
	return Vector2(85 if view_size.x < 600 else 135, view_size.y - 120)

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
	player.touch_jump = false
	stick_center = home_center()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active or not player.enabled:
		reset()
		return
	var viewport_size := get_viewport_rect().size
	if stick_id == -1:
		stick_center = home_center()
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			for button: Button in action_buttons:
				if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
					button.pressed.emit()
					get_viewport().set_input_as_handled()
					return
			for blocker: Control in look_blockers:
				if blocker.is_visible_in_tree() and blocker.get_global_rect().has_point(event.position):
					return
			if event.position.x < viewport_size.x * 0.43 and event.position.y > viewport_size.y * 0.45 and stick_id == -1:
				stick_id = event.index
				stick_center = event.position
				update_stick(event.position)
			elif event.position.x > viewport_size.x * 0.43 and look_id == -1:
				look_id = event.index
		else:
			if event.index == stick_id:
				stick_id = -1
				stick_offset = Vector2.ZERO
				player.touch_axis = Vector2.ZERO
				stick_center = home_center()
			if event.index == look_id:
				look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == stick_id:
			update_stick(event.position)
		elif event.index == look_id:
			player.rotate_touch_camera(event.relative, viewport_size)
	queue_redraw()

func update_stick(pos: Vector2) -> void:
	stick_offset = (pos - stick_center).limit_length(radius)
	var strength := stick_offset.length() / radius
	if strength <= DEADZONE:
		player.touch_axis = Vector2.ZERO
	else:
		player.touch_axis = stick_offset.normalized() * ((strength - DEADZONE) / (1.0 - DEADZONE))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):
		reset()

func _draw() -> void:
	if not active or not player.enabled:
		return
	if stick_id == -1:
		stick_center = home_center()
	draw_circle(stick_center, radius + 3, Color(0.08, 0.09, 0.04, 0.5))
	draw_circle(stick_center, radius, Color(0.035, 0.065, 0.035, 0.6))
	draw_arc(stick_center, radius, 0, TAU, 64, Color("e8cc82"), 2.5, true)
	draw_arc(stick_center, radius - 4, 0, TAU, 64, Color(0.5, 0.4, 0.17, 0.65), 1, true)
	draw_arc(stick_center, radius - 1, 0.1, 1.2, 24, Color("fff0aa"), 1.5, true)
	for direction in 4:
		var angle := float(direction) * PI * 0.5
		var arrow := PackedVector2Array()
		for point: Vector2 in [Vector2(0, -radius + 9), Vector2(-4, -radius + 16), Vector2(0, -radius + 14), Vector2(4, -radius + 16)]:
			arrow.append(stick_center + point.rotated(angle))
		draw_colored_polygon(arrow, Color(0.8, 0.69, 0.4, 0.7))
	var knob := stick_center + stick_offset
	draw_circle(knob + Vector2(1, 2), 26, Color(0.03, 0.04, 0.02, 0.55))
	draw_circle(knob, 25, Color("d5bd7c"))
	draw_circle(knob, 22, Color("897e53"))
	draw_arc(knob, 24, PI, TAU, 32, Color("fff1af"), 1.4, true)
	draw_arc(knob, 21, 0, PI, 32, Color("4b462e"), 1.4, true)

func _process(_delta: float) -> void:
	queue_redraw()
