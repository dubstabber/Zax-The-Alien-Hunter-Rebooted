class_name ZaxLevelEntity
extends RefCounted

var source_index := -1
var name := ""
var category := ""
var team_number := ""
var used_in := ""
var current_target := ""
var broadcaster := ""
var model_path := ""
var position := Vector2.ZERO
var rendering_height := 0.0
var rendering_height_float := 0.0
var current_sequence := ""
var has_category_field := false
var visible := false
var collideable := false
var stationary := false
var active := false
var tries_to_collide := false
var has_hit_points := false
var raw_fields: Dictionary = {}


func load_from_entries(entity_index: int, entries: Array) -> void:
	source_index = entity_index
	raw_fields.clear()

	for entry: Variant in entries:
		if not entry is Dictionary:
			continue

		var key := String(entry.get("key", ""))
		if key.is_empty():
			continue

		if entry.has("value"):
			raw_fields[key] = _variant_to_string(entry.get("value", ""))
		elif entry.has("object"):
			raw_fields[key] = entry.get("object", {})

	name = _string_field("Name")
	has_category_field = raw_fields.has("Category")
	category = _string_field("Category")
	team_number = _string_field("Team Number")
	used_in = _string_field("Used In")
	current_target = _string_field("Current Target")
	broadcaster = _string_field("Broadcaster")
	model_path = _string_field("Model")
	position = Vector2(_float_field("Position X"), _float_field("Position Y"))
	rendering_height = _float_field("Rendering Height")
	rendering_height_float = _float_field("Rendering Height Float")
	current_sequence = _string_field("Cur Sequence")
	visible = _bool_field("Visible")
	collideable = _bool_field("Collideable")
	stationary = _bool_field("Stationary")
	active = _bool_field("Active")
	tries_to_collide = _bool_field("Tries To Collide")
	has_hit_points = _bool_field("Has Hit Points")


func has_category_tag(tag: String) -> bool:
	for raw_tag in category.split(",", false):
		if raw_tag.strip_edges() == tag:
			return true
	return false


func _string_field(key: String) -> String:
	return _variant_to_string(raw_fields.get(key, ""))


func _float_field(key: String) -> float:
	var text := _string_field(key)
	if text.is_valid_float():
		return text.to_float()
	return 0.0


func _bool_field(key: String) -> bool:
	return _string_field(key) == "1"


func _variant_to_string(value: Variant) -> String:
	if value == null:
		return ""
	if value is String:
		return value
	return str(value)
