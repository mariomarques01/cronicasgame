extends RefCounted
## Shared terrain/foliage reservation; evaluated only while generating the world.
static var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/ancient_ruins.json"))
const BOUNDS := Rect2(-40, -96, 28, 28)
const FLOOR_Y := -0.65

static func height_at(point: Vector2, original: float) -> float:
	var nearest := point.clamp(BOUNDS.position, BOUNDS.end)
	var distance := point.distance_to(nearest)
	if distance >= 6.0: return original
	return lerpf(FLOOR_Y, original, smoothstep(0, 6, distance))

static func reserved(point: Vector2, padding: float = 0.0) -> bool:
	if point.y > -48 or point.x < -48 or point.x > 7: return false
	if BOUNDS.grow(padding).has_point(point): return true
	for path: Dictionary in config.paths:
		for i in path.points.size() - 1:
			var a := Vector2(path.points[i][0], path.points[i][1])
			var b := Vector2(path.points[i+1][0], path.points[i+1][1])
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)) < float(path.width)*0.5 + padding:
				return true
	return false
