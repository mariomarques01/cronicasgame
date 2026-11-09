extends Node3D
const MODEL = preload("res://assets/models/bunny_animated.glb")
const DISPLAY_HEIGHT: float = 2.5
var model: Node3D
var animation_player: AnimationPlayer

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
	_set_idle_pose()

func _set_idle_pose() -> void:
	animation_player.play("Walking")
	animation_player.seek(0.0, true)
	animation_player.pause()

func animate(_delta: float, moving: bool, running: bool, grounded: bool = true) -> void:
	if animation_player == null:
		return
	if not grounded:
		animation_player.pause()
		return
	if not moving:
		if animation_player.is_playing() or animation_player.current_animation_position != 0.0:
			_set_idle_pose()
		return
	var clip := "Running" if running else "Walking"
	if animation_player.current_animation != clip or not animation_player.is_playing():
		animation_player.play(clip, 0.18)
