extends SceneTree
## Real Compatibility renders, with identical framing for before/after comparisons.
## DISPLAY=:99 godot --path . --script tools/capture_visuals.gd -- /absolute/output
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/eldervale-captures"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	var world: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.start_game(false)
	world.day_speed = 0.0
	world.clock = 0.3
	world.ui.root.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var views := [
		{"id": "farm", "position": Vector3(-29, 1.0, 26), "yaw": -0.56},
		{"id": "garden", "position": Vector3(6, 1.0, 36), "yaw": 0.13},
		{"id": "forest", "position": Vector3(0, 1.0, -76), "yaw": 0.0}
	]
	if "--hud-only" in args:
		views = []
	for view: Dictionary in views:
		if view.id == "forest":
			root.get_node("Game").stage = 4
		world.player.position = view.position
		world.player.velocity = Vector3.ZERO
		world.player.avatar.rotation.y = view.yaw
		world.player.camera_yaw = view.yaw
		world.player.yaw.rotation.y = view.yaw
		world.player.yaw.global_position = world.player.global_position + world.player.CAMERA_FOCUS
		world.player.camera_pitch = world.player.CAMERA_DEFAULT_PITCH
		world.player.pitch.rotation.x = world.player.CAMERA_DEFAULT_PITCH
		for frame in 24:
			await physics_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var result := image.save_png(output.path_join(view.id + ".png"))
		print("CAPTURE ", view.id, ": ", result)
	root.get_node("Game").reset()
	world.player.position = Vector3(-29, 1, 26)
	world.player.velocity = Vector3.ZERO
	world.player.camera_yaw = -0.56
	world.player.yaw.rotation.y = -0.56
	world.player.yaw.global_position = world.player.global_position + world.player.CAMERA_FOCUS
	world.ui.root.show()
	for spec: Dictionary in [
		{"id": "hud-desktop", "size": Vector2i(1280, 720), "touch": false},
		{"id": "hud-portrait", "size": Vector2i(390, 844), "touch": true},
		{"id": "hud-landscape", "size": Vector2i(844, 390), "touch": true}
	]:
		root.size = spec.size
		world.ui.touch.active = spec.touch
		for frame in (4 if "--quick" in args else 12):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(spec.id + ".png"))
		print("CAPTURE ", spec.id)
	world.queue_free()
	await process_frame
	quit()
