class_name ZaxLevelWorld
extends Node2D

const LEVEL_ID := &"level_01_main"
const WAYPOINT_ID := &"waypoints_01_main"
const POLYGON_INDEX_ID := &"polygons_01_main"
const PlayerScene := preload("res://scenes/player/player.tscn")

@export var build_static_collision := true
@export var show_debug_overlay := true
@export var point_draw_limit := 1200
@export var edge_draw_limit := 1800
@export var entity_draw_limit := 1100

var _level: ZaxLevelData
var _waypoint_map: ZaxWaypointMap
var _polygon_index: ZaxModelPolygonIndex
var _player: ZaxPlayer
var _static_collision_count := 0
var _player_spawn_position := Vector2.ZERO

@onready var _static_collisions: Node2D = $StaticCollisions
@onready var _player_layer: Node2D = $PlayerLayer
@onready var _status_label: Label = $Hud/TopBar/MarginContainer/StatusLabel


func _ready() -> void:
	var levels := get_node_or_null("/root/ZaxLevels")
	if levels == null:
		push_error("Missing ZaxLevels autoload")
		return

	_level = levels.call("load_level", LEVEL_ID) as ZaxLevelData
	_waypoint_map = levels.call("load_waypoints", WAYPOINT_ID) as ZaxWaypointMap
	_polygon_index = levels.call("load_model_polygon_index", POLYGON_INDEX_ID) as ZaxModelPolygonIndex

	if _level == null or not _level.is_valid():
		push_error("Unable to load Zax level world: %s" % LEVEL_ID)
		return

	if build_static_collision:
		_build_static_collisions()
	_spawn_player()
	_update_status_label()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_overlay"):
		show_debug_overlay = not show_debug_overlay
		_update_status_label()
		queue_redraw()


func _draw() -> void:
	if _level == null or not _level.is_valid():
		return

	var map_rect := Rect2(Vector2.ZERO, _level.get_size())
	draw_rect(map_rect, Color(0.075, 0.083, 0.087), true)
	draw_rect(map_rect, Color(0.72, 0.76, 0.68), false, 4.0)

	if not show_debug_overlay:
		return

	_draw_waypoint_edges()
	_draw_entity_footprints()
	_draw_waypoint_points()
	_draw_spawn_marker()


func get_static_collision_count() -> int:
	return _static_collision_count


func get_player_spawn_position() -> Vector2:
	return _player_spawn_position


static func is_collision_entity(entity: ZaxLevelEntity, polygon_index: ZaxModelPolygonIndex) -> bool:
	if entity == null or polygon_index == null:
		return false
	if not entity.is_static_collision_candidate():
		return false

	var polygon := polygon_index.load_polygon(entity.model_path) as ZaxModelPolygon
	return polygon != null and polygon.is_valid()


func _build_static_collisions() -> void:
	_static_collision_count = 0
	for child in _static_collisions.get_children():
		child.queue_free()

	for entity_ref: RefCounted in _level.entities:
		var entity := entity_ref as ZaxLevelEntity
		if entity == null or not entity.is_static_collision_candidate():
			continue

		var polygon := _polygon_index.load_polygon(entity.model_path) as ZaxModelPolygon
		if polygon == null or not polygon.is_valid():
			continue

		_add_static_collision(entity, polygon)


func _add_static_collision(entity: ZaxLevelEntity, polygon: ZaxModelPolygon) -> void:
	var points := _packed_vertices(polygon.vertices)
	if points.size() < 3:
		return

	var body := StaticBody2D.new()
	body.name = "Collision_%04d" % entity.source_index
	body.position = entity.position

	var collision := CollisionPolygon2D.new()
	collision.polygon = points
	body.add_child(collision)

	_static_collisions.add_child(body)
	_static_collision_count += 1


func _spawn_player() -> void:
	var spawn_name := _level.get_team_spawn_name()
	var spawn_point := _level.find_spawn_point(spawn_name)
	_player_spawn_position = _level.view_position
	if spawn_point != null:
		_player_spawn_position = spawn_point.position

	_player = PlayerScene.instantiate() as ZaxPlayer
	_player.name = "Player"
	_player.global_position = _player_spawn_position
	_player_layer.add_child(_player)
	_player.configure_level_bounds(Rect2(Vector2.ZERO, _level.get_size()))


func _draw_waypoint_edges() -> void:
	if _waypoint_map == null or not _waypoint_map.is_valid():
		return

	var drawn_edges := 0
	for index in min(_waypoint_map.waypoints.size(), point_draw_limit):
		var from := _waypoint_map.get_point(index)
		for raw_connection: Variant in _waypoint_map.get_connections(index):
			if drawn_edges >= edge_draw_limit:
				return

			var target := int(raw_connection)
			if target <= index or target >= _waypoint_map.waypoints.size():
				continue

			draw_line(from, _waypoint_map.get_point(target), Color(0.22, 0.42, 0.44, 0.42), 1.0)
			drawn_edges += 1


func _draw_waypoint_points() -> void:
	if _waypoint_map == null or not _waypoint_map.is_valid():
		return

	for index in min(_waypoint_map.waypoints.size(), point_draw_limit):
		draw_circle(_waypoint_map.get_point(index), 5.0, Color(0.76, 0.94, 0.81, 0.78))


func _draw_entity_footprints() -> void:
	if _polygon_index == null or not _polygon_index.is_valid():
		return

	var drawn_entities := 0
	for entity_ref: RefCounted in _level.entities:
		if drawn_entities >= entity_draw_limit:
			return

		var entity := entity_ref as ZaxLevelEntity
		if entity == null:
			continue

		var polygon := _polygon_index.load_polygon(entity.model_path) as ZaxModelPolygon
		if polygon == null or not polygon.is_valid():
			continue

		var points := polygon.get_world_vertices(entity.position)
		if points.size() < 3:
			continue

		var outline_points := points.duplicate()
		outline_points.append(points[0])
		var color := _entity_color(entity)
		draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.16))
		draw_polyline(outline_points, Color(color.r, color.g, color.b, 0.72), 1.2, true)
		drawn_entities += 1


func _draw_spawn_marker() -> void:
	draw_circle(_player_spawn_position, 14.0, Color(1.0, 0.82, 0.3))
	draw_line(_player_spawn_position + Vector2.LEFT * 24.0, _player_spawn_position + Vector2.RIGHT * 24.0, Color(1.0, 0.82, 0.3), 3.0)
	draw_line(_player_spawn_position + Vector2.UP * 24.0, _player_spawn_position + Vector2.DOWN * 24.0, Color(1.0, 0.82, 0.3), 3.0)


func _packed_vertices(vertices: Array[Vector2]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for vertex in vertices:
		points.append(vertex)
	return points


func _entity_color(entity: ZaxLevelEntity) -> Color:
	if entity.has_category_tag("Enemy"):
		return Color(0.96, 0.38, 0.34)

	if entity.has_category_tag("NonInteractiveSequence Actor"):
		return Color(0.47, 0.64, 1.0)

	if entity.model_path.begins_with("Editor/"):
		return Color(1.0, 0.67, 0.25)

	return Color(0.78, 0.82, 0.58)


func _update_status_label() -> void:
	if _status_label == null or _level == null:
		return

	_status_label.text = "01 Main - %s | spawn %s | collisions %d | debug %s" % [
		_level.description,
		_player_spawn_position,
		_static_collision_count,
		"on" if show_debug_overlay else "off",
	]
