class_name ZaxModelPolygon
extends RefCounted

var model_path := ""
var asset_path := ""
var source_path := ""
var format := ""
var vertex_count := 0
var bounds := Rect2()
var vertices: Array[Vector2] = []


func load_from_dictionary(level_model_path: String, metadata: Dictionary, raw: Dictionary) -> void:
	model_path = level_model_path
	asset_path = String(metadata.get("path", ""))
	source_path = String(raw.get("source", metadata.get("source", "")))
	format = String(raw.get("format", metadata.get("format", "")))
	vertex_count = int(raw.get("vertex_count", metadata.get("vertex_count", 0)))
	vertices.clear()

	for raw_vertex: Variant in raw.get("vertices", []):
		if raw_vertex is Dictionary:
			vertices.append(Vector2(float(raw_vertex.get("x", 0.0)), float(raw_vertex.get("y", 0.0))))

	var raw_bounds: Variant = raw.get("bounds", metadata.get("bounds", null))
	if raw_bounds is Dictionary:
		var min_x := float(raw_bounds.get("min_x", 0.0))
		var min_y := float(raw_bounds.get("min_y", 0.0))
		var max_x := float(raw_bounds.get("max_x", min_x))
		var max_y := float(raw_bounds.get("max_y", min_y))
		bounds = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	else:
		bounds = _calculate_bounds_from_vertices()


func is_valid() -> bool:
	return format == "POLY2D" and vertex_count > 0 and vertices.size() == vertex_count


func get_world_vertices(position: Vector2) -> PackedVector2Array:
	var world_vertices := PackedVector2Array()
	for vertex in vertices:
		world_vertices.append(position + vertex)
	return world_vertices


func _calculate_bounds_from_vertices() -> Rect2:
	if vertices.is_empty():
		return Rect2()

	var min_x := vertices[0].x
	var min_y := vertices[0].y
	var max_x := vertices[0].x
	var max_y := vertices[0].y
	for vertex in vertices:
		min_x = minf(min_x, vertex.x)
		min_y = minf(min_y, vertex.y)
		max_x = maxf(max_x, vertex.x)
		max_y = maxf(max_y, vertex.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
