class_name ZaxPlayer
extends CharacterBody2D

@export var move_speed := 260.0
@export var texture_asset_id: StringName = &"animation_zax_frame_0000"

var level_bounds := Rect2()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	if texture_asset_id != &"":
		var assets := get_node_or_null("/root/ZaxAssets")
		if assets != null:
			_sprite.texture = assets.call("load_texture", texture_asset_id)
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
