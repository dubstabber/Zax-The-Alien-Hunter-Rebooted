extends Control

const LEVEL_ID := &"level_01_main"
const WAYPOINT_ID := &"waypoints_01_main"
const TEXTURE_ID := &"texture_01_main"
const POLYGON_INDEX_ID := &"polygons_01_main"

const MIN_ZOOM := 0.08
const MAX_ZOOM := 1.2
const DEFAULT_ZOOM := 0.13
const POINT_LIMIT := 1200
const EDGE_LIMIT := 1800
const ENTITY_LIMIT := 900

var _level: ZaxLevelData
var _waypoint_map: ZaxWaypointMap
var _polygon_index: RefCounted
var _zoom := DEFAULT_ZOOM
var _pan := Vector2(44.0, 74.0)
var _dragging := false
var _last_mouse_position := Vector2.ZERO

@onready var _title_label: Label = %TitleLabel
@onready var _meta_label: Label = %MetaLabel
@onready var _texture_rect: TextureRect = %ReferenceTexture


func _ready() -> void:
	_level = ZaxLevels.load_level(LEVEL_ID) as ZaxLevelData
	_waypoint_map = ZaxLevels.load_waypoints(WAYPOINT_ID) as ZaxWaypointMap
	_polygon_index = ZaxLevels.load_model_polygon_index(POLYGON_INDEX_ID)
	_texture_rect.texture = ZaxAssets.load_texture(TEXTURE_ID)
	_update_labels()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_set_zoom(_zoom * 1.12, mouse_button.position)
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_set_zoom(_zoom / 1.12, mouse_button.position)
		elif mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse_button.pressed
			_last_mouse_position = mouse_button.position
	elif event is InputEventMouseMotion and _dragging:
		var mouse_motion := event as InputEventMouseMotion
		_pan += mouse_motion.position - _last_mouse_position
		_last_mouse_position = mouse_motion.position
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("viewer_reset"):
		_zoom = DEFAULT_ZOOM
		_pan = Vector2(44.0, 74.0)
		queue_redraw()


func _draw() -> void:
	if _level == null or _waypoint_map == null or not _level.is_valid():
		return

	var map_size := _level.get_size()
	var map_rect := Rect2(_pan, map_size * _zoom)
	draw_rect(map_rect, Color(0.075, 0.083, 0.087), true)
	draw_rect(map_rect, Color(0.72, 0.76, 0.68), false, 2.0)

	_draw_waypoint_edges()
	_draw_entity_footprints()
	_draw_waypoint_points()
	_draw_view_marker()


func _draw_waypoint_edges() -> void:
	var drawn_edges := 0
	for index in min(_waypoint_map.waypoints.size(), POINT_LIMIT):
		var from := _world_to_view(_waypoint_map.get_point(index))
		for raw_connection: Variant in _waypoint_map.get_connections(index):
			if drawn_edges >= EDGE_LIMIT:
				return
			var target := int(raw_connection)
			if target <= index or target >= _waypoint_map.waypoints.size():
				continue
			var to := _world_to_view(_waypoint_map.get_point(target))
			draw_line(from, to, Color(0.22, 0.42, 0.44, 0.42), 1.0)
			drawn_edges += 1


func _draw_waypoint_points() -> void:
	for index in min(_waypoint_map.waypoints.size(), POINT_LIMIT):
		draw_circle(_world_to_view(_waypoint_map.get_point(index)), 1.8, Color(0.76, 0.94, 0.81, 0.78))


func _draw_entity_footprints() -> void:
	if _polygon_index == null or not bool(_polygon_index.call("is_valid")):
		return

	for index in min(_level.entities.size(), ENTITY_LIMIT):
		var entity := _level.entities[index]
		var model_path := String(entity.get("model_path"))
		var polygon := _polygon_index.call("load_polygon", model_path) as RefCounted
		if polygon == null or not bool(polygon.call("is_valid")):
			continue

		var color := _entity_color(entity)
		var points := PackedVector2Array()
		var world_vertices: PackedVector2Array = polygon.call("get_world_vertices", entity.get("position"))
		for world_point in world_vertices:
			points.append(_world_to_view(world_point))

		if points.size() < 3:
			continue

		var outline_points := points.duplicate()
		outline_points.append(points[0])
		draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.16))
		draw_polyline(outline_points, Color(color.r, color.g, color.b, 0.72), 1.2, true)
		draw_circle(_world_to_view(entity.get("position")), 2.6, Color(color.r, color.g, color.b, 0.95))


func _draw_view_marker() -> void:
	var center := _world_to_view(_level.view_position)
	draw_circle(center, 7.0, Color(1.0, 0.82, 0.3))
	draw_line(center + Vector2.LEFT * 13.0, center + Vector2.RIGHT * 13.0, Color(1.0, 0.82, 0.3), 2.0)
	draw_line(center + Vector2.UP * 13.0, center + Vector2.DOWN * 13.0, Color(1.0, 0.82, 0.3), 2.0)


func _world_to_view(world_position: Vector2) -> Vector2:
	return _pan + world_position * _zoom


func _set_zoom(new_zoom: float, anchor: Vector2) -> void:
	var clamped_zoom := clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	var world_anchor := (anchor - _pan) / _zoom
	_zoom = clamped_zoom
	_pan = anchor - world_anchor * _zoom
	queue_redraw()


func _entity_color(entity: RefCounted) -> Color:
	if bool(entity.call("has_category_tag", "Enemy")):
		return Color(0.96, 0.38, 0.34)

	if bool(entity.call("has_category_tag", "NonInteractiveSequence Actor")):
		return Color(0.47, 0.64, 1.0)

	var model_path := String(entity.get("model_path"))
	if model_path.begins_with("Editor/"):
		return Color(1.0, 0.67, 0.25)

	return Color(0.78, 0.82, 0.58)


func _update_labels() -> void:
	_title_label.text = "01 Main - %s" % _level.description
	_meta_label.text = "Map %dx%d | view %s | waypoints %d | edges %d | entities %d" % [
		int(_level.width),
		int(_level.height),
		_level.int_view_position,
		_waypoint_map.waypoint_count,
		_waypoint_map.edge_count,
		_level.get_entity_count(),
	]
