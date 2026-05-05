class_name ZaxLevelData
extends RefCounted

var id: StringName
var source_path := ""
var description := ""
var width := 0.0
var height := 0.0
var view_position := Vector2.ZERO
var int_view_position := Vector2i.ZERO
var music_mix: Dictionary = {}
var raw_root: Dictionary = {}


func load_from_dictionary(level_id: StringName, raw: Dictionary) -> void:
	id = level_id
	source_path = String(raw.get("source", ""))
	raw_root = raw.get("root", {})

	var entries: Array = raw_root.get("entries", [])
	width = _float_value(entries, "Width", 0.0)
	height = _float_value(entries, "Height", 0.0)
	description = _string_value(entries, "Map Description", "")
	view_position = _vector2_value(entries, "View Position", Vector2.ZERO)
	int_view_position = _vector2i_value(entries, "Int View Position", Vector2i.ZERO)
	music_mix = _object_entries_as_dictionary(entries, "Music Mix")


func is_valid() -> bool:
	return width > 0.0 and height > 0.0


func get_size() -> Vector2:
	return Vector2(width, height)


func _find_entry(entries: Array, key: String) -> Dictionary:
	for entry: Variant in entries:
		if entry is Dictionary and String(entry.get("key", "")) == key:
			return entry
	return {}


func _string_value(entries: Array, key: String, fallback: String) -> String:
	var entry := _find_entry(entries, key)
	return String(entry.get("value", fallback))


func _float_value(entries: Array, key: String, fallback: float) -> float:
	var text := _string_value(entries, key, "")
	if text.is_valid_float():
		return text.to_float()
	return fallback


func _vector2_value(entries: Array, key: String, fallback: Vector2) -> Vector2:
	var text := _string_value(entries, key, "")
	var parts := text.split(",", false)
	if parts.size() != 2:
		return fallback
	return Vector2(parts[0].strip_edges().to_float(), parts[1].strip_edges().to_float())


func _vector2i_value(entries: Array, key: String, fallback: Vector2i) -> Vector2i:
	var vector := _vector2_value(entries, key, Vector2(fallback))
	return Vector2i(roundi(vector.x), roundi(vector.y))


func _object_entries_as_dictionary(entries: Array, key: String) -> Dictionary:
	var entry := _find_entry(entries, key)
	var object_data: Dictionary = entry.get("object", {})
	var object_entries: Array = object_data.get("entries", [])
	var result: Dictionary = {}
	for child: Variant in object_entries:
		if child is Dictionary and child.has("key"):
			result[String(child["key"])] = String(child.get("value", ""))
	return result
