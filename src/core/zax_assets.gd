extends Node

const MANIFEST_PATH := "res://assets/zax/manifest.json"

var _manifest: Dictionary = {}


func _ready() -> void:
	_manifest = _load_json_file(MANIFEST_PATH)


func get_manifest() -> Dictionary:
	if _manifest.is_empty():
		_manifest = _load_json_file(MANIFEST_PATH)
	return _manifest


func get_resource_path(asset_id: StringName) -> String:
	var assets: Dictionary = get_manifest().get("assets", {})
	var key := String(asset_id)
	if not assets.has(key):
		push_error("Unknown Zax asset id: %s" % key)
		return ""

	var entry: Dictionary = assets[key]
	return String(entry.get("path", ""))


func load_texture(asset_id: StringName) -> Texture2D:
	var path := get_resource_path(asset_id)
	if path.is_empty():
		return null

	return load_texture_path(path)


func load_texture_path(path: String) -> Texture2D:
	var texture := load(path)
	if texture is Texture2D:
		return texture

	push_error("Zax asset is not a Texture2D: %s" % path)
	return null


func load_json(asset_id: StringName) -> Dictionary:
	var path := get_resource_path(asset_id)
	if path.is_empty():
		return {}
	return _load_json_file(path)


func load_json_path(path: String) -> Dictionary:
	return _load_json_file(path)


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing Zax JSON asset: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open Zax JSON asset: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed

	push_error("Zax JSON asset did not parse as a dictionary: %s" % path)
	return {}
