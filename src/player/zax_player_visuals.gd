class_name ZaxPlayerVisuals
extends AnimatedSprite2D

const OCTANT_COUNT := 8

@export var model_animation_asset_id: StringName = &"model_animation_crater"
@export var idle_sequence_name: StringName = &"Idle"

var _current_sequence_name: StringName = &"Idle"
var _current_facing_octant := 2
var _sequence_names: Array[StringName] = []
var _frame_offsets_by_animation: Dictionary = {}
var _loaded := false


func _ready() -> void:
	if not frame_changed.is_connected(_apply_current_frame_offset):
		frame_changed.connect(_apply_current_frame_offset)
	configure_from_assets()


func configure_from_assets(asset_loader: Node = null) -> bool:
	var resolved_loader := asset_loader
	if resolved_loader == null:
		resolved_loader = get_node_or_null("/root/ZaxAssets")
	if resolved_loader == null:
		push_warning("ZaxPlayerVisuals could not find the ZaxAssets autoload.")
		return false

	var metadata: Dictionary = resolved_loader.call("load_json", model_animation_asset_id)
	if metadata.is_empty():
		return false

	var metadata_path := String(resolved_loader.call("get_resource_path", model_animation_asset_id))
	if metadata_path.is_empty():
		return false

	return _build_sprite_frames(resolved_loader, metadata, metadata_path)


func set_motion_state(sequence_name: StringName, facing_octant: int) -> void:
	if not _sequence_names.is_empty() and not has_sequence(sequence_name):
		_current_sequence_name = idle_sequence_name
	else:
		_current_sequence_name = sequence_name
	_current_facing_octant = wrap_octant(facing_octant)
	_apply_animation()


func has_sequence(sequence_name: StringName) -> bool:
	return _sequence_names.has(sequence_name)


func get_current_sequence_name() -> StringName:
	return _current_sequence_name


func get_current_facing_octant() -> int:
	return _current_facing_octant


func get_available_sequence_names() -> Array[StringName]:
	return _sequence_names.duplicate()


static func wrap_octant(octant: int) -> int:
	var value := octant % OCTANT_COUNT
	if value < 0:
		value += OCTANT_COUNT
	return value


static func rotation_for_octant(octant: int, rotation_count: int) -> int:
	if rotation_count <= 1:
		return 0
	return int(round(float(wrap_octant(octant)) * float(rotation_count) / float(OCTANT_COUNT))) % rotation_count


static func animation_name_for(sequence_name: StringName, facing_octant: int) -> StringName:
	return StringName("%s_%02d" % [String(sequence_name).to_lower(), wrap_octant(facing_octant)])


func _build_sprite_frames(asset_loader: Node, metadata: Dictionary, metadata_path: String) -> bool:
	var sequences: Dictionary = metadata.get("sequences", {})
	if sequences.is_empty():
		push_error("Crater model animation metadata has no sequences.")
		return false

	var base_dir := metadata_path.get_base_dir()
	var next_sprite_frames := SpriteFrames.new()
	if next_sprite_frames.has_animation(&"default"):
		next_sprite_frames.remove_animation(&"default")

	_sequence_names.clear()
	var built_animation_count := 0
	_frame_offsets_by_animation.clear()

	for sequence_key: Variant in sequences.keys():
		var sequence: Variant = sequences[sequence_key]
		if not sequence is Dictionary:
			continue

		var sequence_dict := sequence as Dictionary
		var sequence_name := StringName(String(sequence_dict.get("sequence", sequence_key)))
		_sequence_names.append(sequence_name)
		var rotation_count := maxi(1, int(sequence_dict.get("rotation_count", 1)))
		var fps := maxf(1.0, float(sequence_dict.get("fps", 10.0)))
		var frame_groups := _frames_by_rotation(sequence_dict)

		for octant in range(OCTANT_COUNT):
			var source_rotation := rotation_for_octant(octant, rotation_count)
			var source_frames: Array = frame_groups.get(source_rotation, [])
			if source_frames.is_empty():
				source_frames = frame_groups.get(0, [])
			if source_frames.is_empty():
				continue

			var animation_name := animation_name_for(sequence_name, octant)
			next_sprite_frames.add_animation(animation_name)
			next_sprite_frames.set_animation_loop(animation_name, true)
			next_sprite_frames.set_animation_speed(animation_name, fps)
			_frame_offsets_by_animation[animation_name] = []

			for frame: Dictionary in source_frames:
				var texture_path := "%s/%s" % [base_dir, String(frame.get("filename", ""))]
				var texture: Variant = asset_loader.call("load_texture_path", texture_path)
				if texture is Texture2D:
					next_sprite_frames.add_frame(animation_name, texture)
					_frame_offsets_by_animation[animation_name].append(
						Vector2(-float(frame.get("anchor_x", 0.0)), -float(frame.get("anchor_y", 0.0)))
					)

			if next_sprite_frames.get_frame_count(animation_name) > 0:
				built_animation_count += 1
			else:
				next_sprite_frames.remove_animation(animation_name)

	if built_animation_count == 0:
		push_error("Crater model animation metadata produced no usable SpriteFrames.")
		return false

	centered = false
	sprite_frames = next_sprite_frames
	_loaded = true
	_apply_animation()
	return true


func _frames_by_rotation(sequence: Dictionary) -> Dictionary:
	var groups := {}
	var frame_list: Array = sequence.get("frames", [])
	for frame: Variant in frame_list:
		if not frame is Dictionary:
			continue
		var frame_dict := frame as Dictionary
		if String(frame_dict.get("filename", "")).is_empty():
			continue
		var rotation := int(frame_dict.get("rotation", 0))
		if not groups.has(rotation):
			groups[rotation] = []
		groups[rotation].append(frame_dict)
	return groups


func _apply_animation() -> void:
	if not _loaded or sprite_frames == null:
		return

	var animation_name := animation_name_for(_current_sequence_name, _current_facing_octant)
	if not sprite_frames.has_animation(animation_name):
		animation_name = animation_name_for(idle_sequence_name, _current_facing_octant)
	if not sprite_frames.has_animation(animation_name):
		return

	if animation != animation_name or not is_playing():
		play(animation_name)
	_apply_current_frame_offset()


func _apply_current_frame_offset() -> void:
	var offsets: Array = _frame_offsets_by_animation.get(animation, [])
	if frame >= 0 and frame < offsets.size():
		offset = offsets[frame]
