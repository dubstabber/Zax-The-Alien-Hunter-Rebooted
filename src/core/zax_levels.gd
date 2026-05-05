extends Node

const ZaxLevelDataScript := preload("res://src/core/zax_level_data.gd")
const ZaxModelPolygonIndexScript := preload("res://src/core/zax_model_polygon_index.gd")
const ZaxWaypointMapScript := preload("res://src/core/zax_waypoint_map.gd")


func load_level(level_id: StringName) -> RefCounted:
	var raw: Dictionary = ZaxAssets.load_json(level_id)
	var level := ZaxLevelDataScript.new()
	level.load_from_dictionary(level_id, raw)
	return level


func load_waypoints(level_id: StringName) -> RefCounted:
	var raw: Dictionary = ZaxAssets.load_json(level_id)
	var waypoint_map := ZaxWaypointMapScript.new()
	waypoint_map.load_from_dictionary(level_id, raw)
	return waypoint_map


func load_model_polygon_index(index_id: StringName) -> RefCounted:
	var raw: Dictionary = ZaxAssets.load_json(index_id)
	var polygon_index := ZaxModelPolygonIndexScript.new()
	polygon_index.load_from_dictionary(index_id, raw)
	return polygon_index
