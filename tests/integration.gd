extends SceneTree
var failures: int = 0
var game: Node
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
	else:
		print("PASS: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = root.get_node("Game")
	var previous := ""
	if FileAccess.file_exists(game.SAVE_PATH):
		previous = FileAccess.get_file_as_string(game.SAVE_PATH)
	var world: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	check(world.ui.menu.position == Vector2(320, 180), "Menu posicionado dentro da janela")
	world.start_game(false)
	await physics_frame
	check(world.player.camera != null, "Terceira pessoa e câmera criadas")
	check(InputMap.has_action("jump") and InputMap.has_action("interact"), "Input Map configurado")
	check(not game.collect("stone_0"), "Pedras bloqueadas antes da conversa")
	check(not game.activate_gate(), "Portão bloqueado antes da missão")
	check(not game.collect("unknown"), "Item desconhecido rejeitado")
	game.talk()
	check(game.stage == 1, "Conversa ativa missão")
	for i in range(3):
		check(game.collect("stone_%d" % i), "Coleta pedra %d" % i)
	check(not game.collect("stone_0"), "Coleta duplicada rejeitada")
	check(game.stage == 2 and game.inventory.ancient_stone == 3, "Inventário e retorno a Lia")
	check(not game.activate_gate(), "Exige retorno a Lia")
	game.talk()
	check(game.activate_gate(), "Mecanismo conclui missão")
	check(not game.activate_gate(), "Recompensa não duplica")
	await physics_frame
	check(not world.gate.visible and world.gate.get_child(1).disabled, "Portão invisível e colisão desativada")
	check(game.save_game(Vector3(0, 4, -60)), "Grava salvamento")
	game.reset()
	check(game.load_game(), "Carrega salvamento")
	await physics_frame
	check(game.stage == 4 and "forest" in game.regions and world.gate.get_child(1).disabled, "Desbloqueio persiste")
	var query := PhysicsRayQueryParameters3D.create(Vector3(60, 40, 40), Vector3(60, -20, 40))
	check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Terreno possui colisão")
	world.player.position = Vector3(0, 5, 12)
	for i in range(150):
		await physics_frame
	check(world.player.is_on_floor(), "Personagem pousa sobre terreno")
	var valid: Variant = JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	valid.collected.append("stone_0")
	check(not game.valid_save(valid), "Rejeita coleta duplicada no save")
	var file := FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(not game.load_game(), "Arquivo inválido não causa falha")
	check(game.stage == 4, "Falha de carga preserva estado atual")
	DirAccess.remove_absolute(game.SAVE_PATH)
	check(not game.load_game(), "Arquivo ausente tratado")
	if not previous.is_empty():
		file = FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
		file.store_string(previous)
		file.close()
	world.queue_free()
	await process_frame
	print("RESULTADO: %d falhas" % failures)
	quit(1 if failures else 0)
