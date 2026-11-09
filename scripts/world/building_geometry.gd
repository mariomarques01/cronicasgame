extends RefCounted

static func prepare(buildings: Array) -> Array[Dictionary]:
	var shapes: Array[Dictionary] = []
	for building: Dictionary in buildings:
		var shape: Dictionary = building.footprint.duplicate(true)
		if shape.has("polygon"):
			var polygon := PackedVector2Array()
			for point: Array in shape.polygon:
				polygon.append(Vector2(point[0], point[1]))
			if float(shape.get("padding", 0.0)) > 0:
				var expanded := Geometry2D.offset_polygon(polygon, float(shape.padding))
				if not expanded.is_empty():
					polygon = expanded[0]
			shape.polygon = polygon
		else:
			shape.center = Vector2(shape.ellipse.center[0], shape.ellipse.center[1])
			shape.radii = Vector2(shape.ellipse.radii[0], shape.ellipse.radii[1])
		shapes.append(shape)
	return shapes

static func contains(point: Vector2, shapes: Array) -> bool:
	for shape: Dictionary in shapes:
		if shape.has("polygon"):
			if Geometry2D.is_point_in_polygon(point, shape.polygon):
				return true
		elif ((point - shape.center) / shape.radii).length_squared() <= 1.0:
			return true
	return false
