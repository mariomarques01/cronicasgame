extends Node3D
## Original textured GLB has no skeleton or animation clips.
## Keep the visual independent of the CharacterBody collision and camera.
const MODEL = preload("res://assets/models/brave_bunny.glb")
const MODEL_MIN_Y: float = -0.9510769844
const MODEL_HEIGHT: float = 1.8986200094
const DISPLAY_HEIGHT: float = 2.5
var model: Node3D

func _ready() -> void:
	model = MODEL.instantiate()
	model.name = "BraveBunny"
	var factor := DISPLAY_HEIGHT / MODEL_HEIGHT
	model.scale = Vector3.ONE * factor
	model.position.y = -MODEL_MIN_Y * factor
	model.rotation.y = PI
	add_child(model)

func animate(_delta: float, _moving: bool, _running: bool) -> void:
	# No fabricated walk cycle: body movement comes from the controller.
	pass
