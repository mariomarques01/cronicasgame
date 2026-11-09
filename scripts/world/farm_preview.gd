extends Node3D
var camera: Camera3D
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera = $Camera
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(20,20)
	panel.add_theme_constant_override("separation",12)
	layer.add_child(panel)
	var title := Label.new()
	title.text = "Fazenda colorida • Prévia 3D\nArraste para girar"
	title.add_theme_font_size_override("font_size",24)
	panel.add_child(title)
	for entry: Array in [["Voltar ao menu",func(): get_tree().change_scene_to_file("res://scenes/main/main.tscn")],["Aproximar",func(): camera.size = maxf(0.5,camera.size * 0.8)],["Afastar",func(): camera.size = minf(6,camera.size * 1.25)]]:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(220,55)
		button.pressed.connect(entry[1])
		panel.add_child(button)
	camera.keep_aspect = Camera3D.KEEP_WIDTH

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		$Farm.rotation.y += event.relative.x * 0.008
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		$Farm.rotation.y += event.relative.x * 0.008
