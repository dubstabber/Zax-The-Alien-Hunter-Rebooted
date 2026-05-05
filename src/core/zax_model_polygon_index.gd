class_name ZaxModelPolygonIndex
extends RefCounted

const ZaxModelPolygonScript := preload("res://src/core/zax_model_polygon.gd")

var id: StringName
var model_count := 0
var polygon_variant := ""
var models: Dictionary = {}
var _polygon_cache: Dictionary = {}


func load_from_dictionary(index_id: StringName, raw: Dictionary) -> void:
	id = index_id
	model_count = int(raw.get("model_count", 0))
	polygon_variant = String(raw.get("polygon_variant", ""))
	models = raw.get("models", {})
	_polygon_cache.clear()


func is_valid() -> bool:
	return model_count > 0 and models.size() == model_count


func has_model(model_path: String) -> bool:
	return models.has(model_path)


func get_model_metadata(model_path: String) -> Dictionary:
	return models.get(model_path, {})


func load_polygon(model_path: String) -> RefCounted:
	if _polygon_cache.has(model_path):
		return _polygon_cache[model_path]

	var metadata := get_model_metadata(model_path)
	var path := String(metadata.get("path", ""))
	if path.is_empty():
		return null

	var raw := _load_json_file(path)
	var polygon := ZaxModelPolygonScript.new()
	polygon.load_from_dictionary(model_path, metadata, raw)
	_polygon_cache[model_path] = polygon
	return polygon


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing Zax polygon asset: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open Zax polygon asset: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed

	push_error("Zax polygon asset did not parse as a dictionary: %s" % path)
	return {}
