class_name ZaxWaypointMap
extends RefCounted

var id: StringName
var source_path := ""
var waypoint_count := 0
var edge_count := 0
var min_distance_between_waypoints := 0
var max_distance_to_connect := 0
var waypoints: Array[Dictionary] = []


func load_from_dictionary(waypoint_id: StringName, raw: Dictionary) -> void:
	id = waypoint_id
	source_path = String(raw.get("source", ""))
	waypoint_count = int(raw.get("waypoint_count", 0))
	edge_count = int(raw.get("edge_count", 0))
	min_distance_between_waypoints = int(raw.get("min_dist_between_waypoints", 0))
	max_distance_to_connect = int(raw.get("max_dist_to_connect", 0))

	waypoints.clear()
	var raw_waypoints: Array = raw.get("waypoints", [])
	for waypoint: Variant in raw_waypoints:
		if waypoint is Dictionary:
			waypoints.append(waypoint)


func is_valid() -> bool:
	return waypoint_count > 0 and waypoints.size() == waypoint_count


func get_point(index: int) -> Vector2:
	if index < 0 or index >= waypoints.size():
		return Vector2.ZERO

	var waypoint := waypoints[index]
	return Vector2(float(waypoint.get("x", 0.0)), float(waypoint.get("y", 0.0)))


func get_connections(index: int) -> Array:
	if index < 0 or index >= waypoints.size():
		return []
	return waypoints[index].get("connections", [])
