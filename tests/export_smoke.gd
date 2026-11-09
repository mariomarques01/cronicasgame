extends SceneTree
var failures := 0

func check(ok: bool, description: String) -> bool:
	if ok:
		print("PACK PASS: ", description)
	else:
		failures += 1
		push_error(description)
	return ok

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	if not check(scene != null, "Cena principal incluída no pacote"):
		quit(1)
		return
	var world: Node3D = scene.instantiate()
	root.add_child(world)
	await physics_frame
	for path in ["GoldenAcres/CozyTimberHouse", "GoldenAcres/FarmBuildings/Workshop", "GoldenAcres/FarmBuildings/Barn", "GoldenAcres/FarmBuildings/Windmill/SlowRotor", "Trees"]:
		check(world.get_node_or_null(path) != null, "Recurso exportado: " + path)
	if failures > 0:
		quit(1)
		return
	var game := root.get_node("Game")
	check(typeof(game.quest) == TYPE_DICTIONARY and game.quest.has("id"), "Dados JSON da missão incluídos")
	world.start_game(false)
	check(world.playing and world.player.enabled and not world.ui.title_screen.visible, "Jornada inicia a partir do pacote")
	check(world.get_node("Trees").tree_count == 157, "Floresta externa reduzida pela metade")
	game.talk()
	for id in ["stone_0", "stone_1", "stone_2"]:
		check(game.collect(id), "Missão no pacote: " + id)
	game.talk()
	check(game.activate_gate(), "Missão desbloqueia a passagem")
	print("PACK RESULTADO: ", failures, " falhas")
	quit(0 if failures == 0 else 1)
