class_name ZaxLevelData
extends RefCounted

const ZaxLevelEntityScript := preload("res://src/core/zax_level_entity.gd")

var id: StringName
var source_path := ""
var description := ""
var width := 0.0
var height := 0.0
var view_position := Vector2.ZERO
var int_view_position := Vector2i.ZERO
var music_mix: Dictionary = {}
var entities: Array[RefCounted] = []
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
	_parse_entities(entries)


func is_valid() -> bool:
	return width > 0.0 and height > 0.0


func get_size() -> Vector2:
	return Vector2(width, height)


func get_entity_count() -> int:
	return entities.size()


func get_category_counts() -> Dictionary:
	var counts: Dictionary = {}
	for entity: RefCounted in entities:
		if not bool(entity.get("has_category_field")):
			continue

		var category := String(entity.get("category"))
		counts[category] = int(counts.get(category, 0)) + 1
	return counts


func get_missing_category_count() -> int:
	var count := 0
	for entity: RefCounted in entities:
		if not bool(entity.get("has_category_field")):
			count += 1
	return count


func get_model_count(model_path: String) -> int:
	var count := 0
	for entity: RefCounted in entities:
		if String(entity.get("model_path")) == model_path:
			count += 1
	return count


func _parse_entities(entries: Array) -> void:
	entities.clear()

	var tree_list := _find_entry(entries, "Tree List")
	var tree_object: Dictionary = tree_list.get("object", {})
	var tree_entries: Array = tree_object.get("entries", [])
	var entity_index := 0
	for tree_entry: Variant in tree_entries:
		if not tree_entry is Dictionary or String(tree_entry.get("key", "")) != "Level Part":
			continue

		var object_data: Dictionary = tree_entry.get("object", {})
		var entity_entries: Array = object_data.get("entries", [])
		var entity := ZaxLevelEntityScript.new()
		entity.load_from_entries(entity_index, entity_entries)
		entities.append(entity)
		entity_index += 1


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
