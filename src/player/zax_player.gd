class_name ZaxPlayer
extends CharacterBody2D

@export var move_speed := 260.0
@export var idle_sequence_name: StringName = &"Idle"
@export var walk_sequence_name: StringName = &"Walk"
@export var run_sequence_name: StringName = &"Run"
@export var weapon_count := 0

var level_bounds := Rect2()

@onready var _lower_body_visuals: ZaxPlayerVisuals = $LowerBodySprite
@onready var _upper_body_visuals: ZaxPlayerVisuals = $UpperBodySprite
@onready var _weapon_visuals: ZaxPlayerVisuals = $WeaponSprite
@onready var _camera: Camera2D = $Camera2D

var _last_facing_octant := 2
var _current_visual_sequence_name: StringName = &"Idle"
var _visual_layers: Array[ZaxPlayerVisuals] = []


func _ready() -> void:
	_visual_layers = [_lower_body_visuals, _upper_body_visuals, _weapon_visuals]
	_sync_weapon_visibility()
	update_visual_state_for_direction(Vector2.ZERO)
	_configure_camera_limits()


func configure_level_bounds(bounds: Rect2) -> void:
	level_bounds = bounds
	if _camera != null:
		_configure_camera_limits()


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	_clamp_to_level_bounds()
	update_visual_state_for_direction(direction)


func update_visual_state_for_direction(direction: Vector2) -> void:
	if direction.length_squared() > 0.0:
		_last_facing_octant = direction_to_octant(direction)
		_current_visual_sequence_name = run_sequence_name
	else:
		_current_visual_sequence_name = idle_sequence_name

	for visual_layer in _get_visual_layers():
		if visual_layer != null:
			visual_layer.set_motion_state(_current_visual_sequence_name, _last_facing_octant)


func get_current_visual_sequence_name() -> StringName:
	return _current_visual_sequence_name


func get_current_facing_octant() -> int:
	return _last_facing_octant


func set_weapon_count(value: int) -> void:
	weapon_count = maxi(0, value)
	_sync_weapon_visibility()


func set_has_weapon(value: bool) -> void:
	set_weapon_count(1 if value else 0)


func has_weapon() -> bool:
	return weapon_count > 0


static func direction_to_octant(direction: Vector2) -> int:
	if direction.length_squared() <= 0.0:
		return 2

	var angle := atan2(direction.y, direction.x)
	var octant := int(round(angle / (PI / 4.0)))
	octant %= 8
	if octant < 0:
		octant += 8
	return octant


func _get_visual_layers() -> Array:
	if _visual_layers.is_empty():
		return [
			get_node_or_null("LowerBodySprite") as ZaxPlayerVisuals,
			get_node_or_null("UpperBodySprite") as ZaxPlayerVisuals,
			get_node_or_null("WeaponSprite") as ZaxPlayerVisuals,
		]
	return _visual_layers


func _sync_weapon_visibility() -> void:
	var weapon_visuals := _weapon_visuals
	if weapon_visuals == null:
		weapon_visuals = get_node_or_null("WeaponSprite") as ZaxPlayerVisuals
	if weapon_visuals != null:
		weapon_visuals.visible = has_weapon()


func _configure_camera_limits() -> void:
	if level_bounds.size == Vector2.ZERO:
		return

	_camera.limit_left = roundi(level_bounds.position.x)
	_camera.limit_top = roundi(level_bounds.position.y)
	_camera.limit_right = roundi(level_bounds.end.x)
	_camera.limit_bottom = roundi(level_bounds.end.y)
	_camera.make_current()


func _clamp_to_level_bounds() -> void:
	if level_bounds.size == Vector2.ZERO:
		return

	global_position = Vector2(
		clampf(global_position.x, level_bounds.position.x, level_bounds.end.x),
		clampf(global_position.y, level_bounds.position.y, level_bounds.end.y)
	)
