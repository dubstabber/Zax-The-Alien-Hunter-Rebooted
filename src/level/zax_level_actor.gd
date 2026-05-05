class_name ZaxLevelActor
extends Node2D

const MARKER_RADIUS := 12.0

var source_entity: ZaxLevelEntity
var source_polygon: ZaxModelPolygon
var debug_visible := true

var _collision_area: Area2D


func configure(entity: ZaxLevelEntity, polygon: ZaxModelPolygon, show_debug: bool) -> void:
	source_entity = entity
	source_polygon = polygon
	debug_visible = show_debug
	_clear_children()

	if source_entity != null:
		position = source_entity.position
		_apply_source_metadata()
		_build_collision_hook()

	queue_redraw()


func set_debug_visible(value: bool) -> void:
	debug_visible = value
	queue_redraw()


func has_collision_hook() -> bool:
	return _collision_area != null


func get_debug_summary() -> Dictionary:
	if source_entity == null:
		return {}

	var summary := source_entity.get_debug_summary()
	summary["has_valid_polygon"] = _has_valid_polygon()
	summary["has_collision_hook"] = has_collision_hook()
	return summary


func _draw() -> void:
	if source_entity == null:
		return

	var color := _actor_color()
	if source_entity.visible:
		_draw_visible_actor(color)
	elif debug_visible:
		_draw_invisible_debug_marker(color)

	if debug_visible:
		_draw_debug_anchor(color)


func _draw_visible_actor(color: Color) -> void:
	if _has_valid_polygon():
		var points := _packed_vertices(source_polygon.vertices)
		if points.size() >= 3:
			var outline_points := points.duplicate()
			outline_points.append(points[0])
			draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.24))
			draw_polyline(outline_points, Color(color.r, color.g, color.b, 0.92), 1.6, true)
			return

	_draw_actor_marker(color)


func _draw_actor_marker(color: Color) -> void:
	var points := PackedVector2Array([
		Vector2(0.0, -MARKER_RADIUS),
		Vector2(MARKER_RADIUS, 0.0),
		Vector2(0.0, MARKER_RADIUS),
		Vector2(-MARKER_RADIUS, 0.0),
	])
	draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.28))
	points.append(points[0])
	draw_polyline(points, Color(color.r, color.g, color.b, 0.92), 1.5, true)


func _draw_invisible_debug_marker(color: Color) -> void:
	var ghost := Color(color.r, color.g, color.b, 0.36)
	draw_line(Vector2(-MARKER_RADIUS, -MARKER_RADIUS), Vector2(MARKER_RADIUS, MARKER_RADIUS), ghost, 1.5)
	draw_line(Vector2(-MARKER_RADIUS, MARKER_RADIUS), Vector2(MARKER_RADIUS, -MARKER_RADIUS), ghost, 1.5)


func _draw_debug_anchor(color: Color) -> void:
	var anchor_color := Color(color.r, color.g, color.b, 0.95 if source_entity.active else 0.42)
	draw_circle(Vector2.ZERO, 3.5, anchor_color)
	if not source_entity.active:
		draw_arc(Vector2.ZERO, MARKER_RADIUS + 4.0, 0.0, TAU, 24, Color(0.58, 0.58, 0.58, 0.6), 1.0)


func _build_collision_hook() -> void:
	_collision_area = null
	if source_entity == null or not source_entity.visible or not source_entity.collideable:
		return
	if not _has_valid_polygon():
		return

	var points := _packed_vertices(source_polygon.vertices)
	if points.size() < 3:
		return

	var area := Area2D.new()
	area.name = "SourceCollision"
	area.monitoring = true
	area.monitorable = true

	var collision := CollisionPolygon2D.new()
	collision.name = "CollisionPolygon2D"
	collision.polygon = points
	area.add_child(collision)

	add_child(area)
	_collision_area = area


func _apply_source_metadata() -> void:
	set_meta("source_index", source_entity.source_index)
	set_meta("source_name", source_entity.name)
	set_meta("model_path", source_entity.model_path)
	set_meta("category", source_entity.category)
	set_meta("active", source_entity.active)
	set_meta("visible", source_entity.visible)
	set_meta("collideable", source_entity.collideable)
	set_meta("current_sequence", source_entity.current_sequence)
	set_meta("movement_speed", source_entity.movement_speed)
	set_meta("default_death_type", source_entity.default_death_type)


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_collision_area = null


func _has_valid_polygon() -> bool:
	return source_polygon != null and source_polygon.is_valid()


func _packed_vertices(vertices: Array[Vector2]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for vertex in vertices:
		points.append(vertex)
	return points


func _actor_color() -> Color:
	if source_entity == null:
		return Color(0.78, 0.82, 0.58)

	if source_entity.has_category_tag("Enemy"):
		return Color(0.96, 0.38, 0.34)

	if source_entity.has_category_tag("NonInteractiveSequence Actor"):
		return Color(0.47, 0.64, 1.0)

	return Color(0.88, 0.78, 0.44)
