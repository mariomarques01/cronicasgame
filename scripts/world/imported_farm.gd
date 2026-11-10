extends Node3D
## Flat Emerald Meadow ground with the supplied cabbage and carrot crops.
const GROUND_SIZE := Vector2(108, 104)
const GROUND_HEIGHT := 0.01

func _ready() -> void:
	name = "GoldenAcres"
	var ground := StaticBody3D.new()
	ground.name = "FarmCollision"
	ground.position.y = GROUND_HEIGHT
	var plane := PlaneMesh.new()
	plane.size = GROUND_SIZE
	var visual := MeshInstance3D.new()
	visual.name = "EmeraldMeadowGround"
	visual.mesh = plane
	visual.material_override = get_parent().terrain.ground_material
	ground.add_child(visual)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GROUND_SIZE.x, 0.2, GROUND_SIZE.y)
	collider.shape = shape
	collider.position.y = -0.1
	ground.add_child(collider)
	add_child(ground)
	var crops := Node3D.new()
	crops.name = "CultivatedPlants"
	crops.set_script(preload("res://scripts/world/crops.gd"))
	add_child(crops)
	var house := Node3D.new()
	house.set_script(preload("res://scripts/world/main_house.gd"))
	add_child(house)
	var buildings := Node3D.new()
	buildings.set_script(preload("res://scripts/world/farm_buildings.gd"))
	buildings.world = get_parent()
	add_child(buildings)
	var fences := Node3D.new()
	fences.set_script(preload("res://scripts/world/farm_fences.gd"))
	add_child(fences)

func surface_height(x: float, z: float) -> float:
	return GROUND_HEIGHT if absf(x) <= GROUND_SIZE.x * 0.5 and absf(z) <= GROUND_SIZE.y * 0.5 else -INF
