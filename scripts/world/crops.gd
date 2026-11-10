extends Node3D
## Shared crop meshes, in rows inside the existing lower field enclosure.
const MODELS := {
	"cabbage": preload("res://assets/crops/cabbage_mobile.res"),
	"carrots": preload("res://assets/crops/carrots_mobile.res")
}
var placements: Array[Dictionary] = []
var beds: Array = []
var crop_counts: Dictionary = {}
var instance_transforms: Dictionary = {}

func _ready() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/farm_crops.json"))
	beds = layout.beds
	for bed: Dictionary in beds:
		add_soil(str(bed.id) + "Soil", bed.bounds)
		var bounds: Array = bed.bounds
		for row in int(bed.rows):
			for column in int(bed.columns):
				var point := Vector3(lerpf(bounds[0], bounds[2], (column + 0.5) / float(bed.columns)), float(layout.ground_y), lerpf(bounds[1], bounds[3], (row + 0.5) / float(bed.rows)))
				placements.append({"crop": bed.crop, "bed": bed.id, "position": point, "width": float(bed.patch_width), "angle": float((row + column) % 4) * PI * 0.5 if bed.crop == "cabbage" else 0.0})
	# The former lateral garden is cleared, ready for later crops.
	add_soil("EmptyLateralGarden", layout.empty_garden)
	for crop: String in MODELS:
		var mesh: ArrayMesh = MODELS[crop]
		var bounds := mesh.get_aabb()
		var pivot := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
		var transforms: Array[Transform3D] = []
		for placement: Dictionary in placements:
			if placement.crop != crop:
				continue
			var factor := float(placement.width) / maxf(bounds.size.x, bounds.size.z)
			var basis := Basis(Vector3.UP, float(placement.angle)).scaled(Vector3.ONE * factor)
			transforms.append(Transform3D(basis, placement.position - basis * pivot))
		var instances := MultiMesh.new()
		# Retain layout transforms for validation when the headless renderer cannot read them back.
		instance_transforms[crop] = transforms
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = transforms.size()
		for i in transforms.size():
			instances.set_instance_transform(i, transforms[i])
		var batch := MultiMeshInstance3D.new()
		batch.name = "Cabbages" if crop == "cabbage" else "Carrots"
		batch.multimesh = instances
		add_child(batch)
		crop_counts[crop] = transforms.size()

func add_soil(label: String, bounds: Array) -> void:
	var visual := MeshInstance3D.new()
	visual.name = label
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(bounds[2]) - float(bounds[0]), float(bounds[3]) - float(bounds[1]))
	visual.mesh = plane
	visual.position = Vector3((float(bounds[0]) + float(bounds[2])) * 0.5, 0.015, (float(bounds[1]) + float(bounds[3])) * 0.5)
	var material := StandardMaterial3D.new()
	material.albedo_texture = preload("res://assets/textures/dirt.png")
	material.albedo_color = Color(0.52, 0.40, 0.28)
	material.uv1_scale = Vector3(plane.size.x / 2.0, plane.size.y / 2.0, 1)
	material.roughness = 1.0
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
