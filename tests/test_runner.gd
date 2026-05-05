extends SceneTree

const ZaxLevelDataScript := preload("res://src/core/zax_level_data.gd")
const ZaxLevelActorScript := preload("res://src/level/zax_level_actor.gd")
const ZaxLevelWorldScript := preload("res://src/level/level_world.gd")
const ZaxModelPolygonIndexScript := preload("res://src/core/zax_model_polygon_index.gd")
const ZaxWaypointMapScript := preload("res://src/core/zax_waypoint_map.gd")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_project_settings()
	_test_manifest()
	_test_level_data()
	_test_waypoint_data()
	_test_polygon_index()
	_test_spawn_resolution()
	_test_runtime_actor_candidates()
	_test_static_collision_candidates()
	_test_actor_node()
	_test_player_scene()
	_test_scene_instantiation()

	if _failures > 0:
		printerr("Zax test runner failed with %d failure(s)." % _failures)
		quit(1)
	else:
		print("Zax test runner passed.")
		quit(0)


func _test_project_settings() -> void:
	_expect_equal(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/app/app.tscn", "main scene")
	_expect_equal(ProjectSettings.get_setting("autoload/ZaxAssets"), "*res://src/core/zax_assets.gd", "ZaxAssets autoload")
	_expect_equal(ProjectSettings.get_setting("autoload/ZaxLevels"), "*res://src/core/zax_levels.gd", "ZaxLevels autoload")
	for action in ["move_left", "move_right", "move_up", "move_down", "debug_toggle_overlay"]:
		_expect_true(InputMap.has_action(action), "input action: %s" % action)


func _test_manifest() -> void:
	var manifest := _load_json("res://assets/zax/manifest.json")
	var assets: Dictionary = manifest.get("assets", {})
	for asset_id in ["manifest_extraction", "manifest_ida_coverage", "level_01_main", "waypoints_01_main", "texture_01_main", "animation_zax_metadata", "animation_zax_frame_0000", "polygons_01_main"]:
		_expect_true(assets.has(asset_id), "manifest has %s" % asset_id)
		if assets.has(asset_id):
			_expect_true(FileAccess.file_exists(assets[asset_id]["path"]), "asset exists: %s" % asset_id)

	var coverage := _load_json("res://assets/zax/manifests/ida_asset_coverage_audit.json")
	var summary: Dictionary = coverage.get("summary", {})
	_expect_equal(summary.get("status"), "ok", "IDA coverage status")
	_expect_equal(summary.get("blocker_count"), 0.0, "IDA coverage blockers")


func _test_level_data() -> void:
	var raw := _load_json("res://assets/zax/levels/data/01 Main.json")
	var level: ZaxLevelData = ZaxLevelDataScript.new()
	level.load_from_dictionary(&"level_01_main", raw)

	_expect_true(level.is_valid(), "level data is valid")
	_expect_equal(level.description, "Ship Crash Site", "level description")
	_expect_equal(level.width, 5000.0, "level width")
	_expect_equal(level.height, 5000.0, "level height")
	_expect_equal(level.int_view_position, Vector2i(2010, 1884), "level view position")
	_expect_equal(level.music_mix.get("Full Mix Song"), "Jungle/01- Jungle 01.ogg", "music mix full song")
	_expect_equal(level.get_entity_count(), 1216, "level entity count")

	var first_entity := level.entities[0]
	_expect_equal(first_entity.get("model_path"), "Environments/Jungle/Trees/Jungle 2", "first entity model")
	_expect_equal(first_entity.get("position"), Vector2(174, 157), "first entity position")
	_expect_equal(first_entity.get("visible"), true, "first entity visible")
	_expect_equal(first_entity.get("collideable"), true, "first entity collideable")
	_expect_equal(first_entity.get("current_sequence"), "Idle", "first entity sequence")
	_expect_equal(first_entity.call("is_runtime_actor_candidate"), false, "first entity is environment")

	var category_counts := level.get_category_counts()
	_expect_equal(category_counts.get(""), 1152, "empty category count")
	_expect_equal(category_counts.get("Enemy"), 24, "enemy category count")
	_expect_equal(category_counts.get("NonInteractiveSequence Actor"), 6, "sequence actor category count")
	_expect_equal(category_counts.get("Enemy,NonInteractiveSequence Actor"), 4, "combined enemy sequence category count")
	_expect_equal(level.get_missing_category_count(), 30, "missing category count")
	_expect_equal(level.get_model_count("Characters/Targ"), 20, "Targ entity count")
	_expect_equal(level.team_infos.size(), 1, "team info count")


func _test_waypoint_data() -> void:
	var raw := _load_json("res://assets/zax/waypoints/data/01 Main.json")
	var waypoint_map: ZaxWaypointMap = ZaxWaypointMapScript.new()
	waypoint_map.load_from_dictionary(&"waypoints_01_main", raw)

	_expect_true(waypoint_map.is_valid(), "waypoint map is valid")
	_expect_equal(waypoint_map.waypoint_count, 6863, "waypoint count")
	_expect_equal(waypoint_map.edge_count, 25495, "edge count")
	_expect_equal(waypoint_map.get_point(0), Vector2(2095, 1154), "first waypoint position")
	_expect_true(waypoint_map.get_connections(0).has(43.0), "first waypoint connections")


func _test_polygon_index() -> void:
	var raw := _load_json("res://assets/zax/polygons/model_polygon_index.json")
	var polygon_index: RefCounted = ZaxModelPolygonIndexScript.new()
	polygon_index.load_from_dictionary(&"polygons_01_main", raw)

	_expect_true(polygon_index.is_valid(), "polygon index is valid")
	_expect_equal(polygon_index.model_count, 141, "polygon model count")
	_expect_equal(_count_zero_vertex_models(raw), 38, "zero-vertex polygon model count")
	_expect_true(polygon_index.has_model("Environments/Jungle/Trees/Jungle 2"), "polygon index has Jungle 2")

	var metadata: Dictionary = polygon_index.get_model_metadata("Environments/Jungle/Trees/Jungle 2")
	_expect_equal(metadata.get("vertex_count"), 12.0, "Jungle 2 metadata vertex count")
	_expect_true(FileAccess.file_exists(metadata.get("path")), "Jungle 2 polygon asset exists")

	var polygon: RefCounted = polygon_index.load_polygon("Environments/Jungle/Trees/Jungle 2")
	_expect_true(polygon != null, "Jungle 2 polygon loads")
	if polygon != null:
		_expect_true(polygon.call("is_valid"), "Jungle 2 polygon is valid")
		_expect_equal(polygon.get("vertex_count"), 12, "Jungle 2 polygon vertex count")
		_expect_equal(polygon.get("bounds"), Rect2(Vector2(-38, 9), Vector2(115, 75)), "Jungle 2 polygon bounds")


func _test_spawn_resolution() -> void:
	var raw := _load_json("res://assets/zax/levels/data/01 Main.json")
	var level: ZaxLevelData = ZaxLevelDataScript.new()
	level.load_from_dictionary(&"level_01_main", raw)

	_expect_equal(level.get_team_spawn_name(), "Game Start", "default team spawn name")
	var spawn_point := level.find_spawn_point("Game Start")
	_expect_true(spawn_point != null, "Game Start spawn resolves")
	if spawn_point != null:
		_expect_equal(spawn_point.get("model_path"), "Editor/Spawn Point", "Game Start spawn model")
		_expect_equal(spawn_point.get("position"), Vector2(1932, 1440), "Game Start spawn position")

	_expect_true(level.find_spawn_point("missing spawn") == null, "missing spawn returns null")


func _test_static_collision_candidates() -> void:
	var level_raw := _load_json("res://assets/zax/levels/data/01 Main.json")
	var level: ZaxLevelData = ZaxLevelDataScript.new()
	level.load_from_dictionary(&"level_01_main", level_raw)

	var polygon_raw := _load_json("res://assets/zax/polygons/model_polygon_index.json")
	var polygon_index: ZaxModelPolygonIndex = ZaxModelPolygonIndexScript.new()
	polygon_index.load_from_dictionary(&"polygons_01_main", polygon_raw)

	var candidate_count := 0
	for entity_ref: RefCounted in level.entities:
		var entity := entity_ref as ZaxLevelEntity
		if ZaxLevelWorldScript.is_collision_entity(entity, polygon_index):
			candidate_count += 1

	_expect_equal(candidate_count, 883, "static collision candidate count")


func _test_runtime_actor_candidates() -> void:
	var raw := _load_json("res://assets/zax/levels/data/01 Main.json")
	var level: ZaxLevelData = ZaxLevelDataScript.new()
	level.load_from_dictionary(&"level_01_main", raw)

	var polygon_raw := _load_json("res://assets/zax/polygons/model_polygon_index.json")
	var polygon_index: ZaxModelPolygonIndex = ZaxModelPolygonIndexScript.new()
	polygon_index.load_from_dictionary(&"polygons_01_main", polygon_raw)

	var actor_count := 0
	var actor_collision_count := 0
	var model_counts: Dictionary = {}
	var first_targ: ZaxLevelEntity
	for entity_ref: RefCounted in level.entities:
		var entity := entity_ref as ZaxLevelEntity
		if entity == null or not entity.is_runtime_actor_candidate():
			continue

		actor_count += 1
		model_counts[entity.model_path] = int(model_counts.get(entity.model_path, 0)) + 1
		if entity.model_path == "Characters/Targ" and first_targ == null:
			first_targ = entity
		if ZaxLevelWorldScript.is_actor_collision_entity(entity, polygon_index):
			actor_collision_count += 1

	_expect_equal(actor_count, 35, "runtime actor candidate count")
	_expect_equal(actor_collision_count, 28, "runtime actor collision count")
	_expect_equal(model_counts.get("Characters/Targ"), 20, "runtime Targ count")
	_expect_equal(model_counts.get("Characters/Jungle Creature"), 4, "runtime Jungle Creature count")
	_expect_equal(model_counts.get("Characters/Rogcoil/Rogcoil"), 4, "runtime Rogcoil count")
	_expect_equal(model_counts.get("Characters/Jungle Bird"), 6, "runtime Jungle Bird count")
	_expect_equal(model_counts.get("Characters/Korbo Characters/Valeth"), 1, "runtime Valeth count")
	_expect_true(first_targ != null, "first runtime Targ exists")
	if first_targ != null:
		_expect_equal(first_targ.position, Vector2(223, 1130), "first runtime Targ position")
		_expect_equal(first_targ.current_sequence, "Idle", "first runtime Targ sequence")
		_expect_equal(first_targ.movement_speed, "Walk", "first runtime Targ movement speed")
		_expect_equal(first_targ.default_death_type, "Targ Default", "first runtime Targ death behavior")


func _test_actor_node() -> void:
	var raw := _load_json("res://assets/zax/levels/data/01 Main.json")
	var level: ZaxLevelData = ZaxLevelDataScript.new()
	level.load_from_dictionary(&"level_01_main", raw)

	var polygon_raw := _load_json("res://assets/zax/polygons/model_polygon_index.json")
	var polygon_index: ZaxModelPolygonIndex = ZaxModelPolygonIndexScript.new()
	polygon_index.load_from_dictionary(&"polygons_01_main", polygon_raw)

	var first_targ: ZaxLevelEntity
	for entity_ref: RefCounted in level.entities:
		var entity := entity_ref as ZaxLevelEntity
		if entity != null and entity.model_path == "Characters/Targ":
			first_targ = entity
			break

	_expect_true(first_targ != null, "actor node source Targ exists")
	if first_targ == null:
		return

	var polygon := polygon_index.load_polygon(first_targ.model_path) as ZaxModelPolygon
	var actor: Node2D = ZaxLevelActorScript.new()
	actor.call("configure", first_targ, polygon, true)

	_expect_equal(actor.position, Vector2(223, 1130), "actor node position")
	_expect_equal(actor.get_meta("model_path"), "Characters/Targ", "actor node model metadata")
	_expect_equal(actor.get_meta("current_sequence"), "Idle", "actor node sequence metadata")
	_expect_true(bool(actor.call("has_collision_hook")), "actor node has collision hook")

	var summary: Dictionary = actor.call("get_debug_summary")
	_expect_equal(summary.get("movement_speed"), "Walk", "actor node summary movement speed")
	_expect_equal(summary.get("has_valid_polygon"), true, "actor node summary polygon")
	actor.free()


func _test_player_scene() -> void:
	var scene := load("res://scenes/player/player.tscn")
	_expect_true(scene is PackedScene, "player scene loads")
	if scene is PackedScene:
		var packed_scene := scene as PackedScene
		var instance: Node = packed_scene.instantiate()
		_expect_true(instance is CharacterBody2D, "player scene instantiates as CharacterBody2D")
		if instance != null:
			instance.free()


func _count_zero_vertex_models(raw: Dictionary) -> int:
	var count := 0
	var models: Dictionary = raw.get("models", {})
	for metadata: Variant in models.values():
		if metadata is Dictionary and int(metadata.get("vertex_count", 0)) == 0:
			count += 1
	return count


func _test_scene_instantiation() -> void:
	var scene := load("res://scenes/app/app.tscn")
	_expect_true(scene is PackedScene, "app scene loads")
	if scene is PackedScene:
		var packed_scene := scene as PackedScene
		var instance: Node = packed_scene.instantiate()
		_expect_true(instance != null, "app scene instantiates")
		if instance != null:
			_expect_true(instance.get_node_or_null("DynamicLayer/ActorLayer") != null, "app scene has actor layer")
			_expect_true(instance.get_node_or_null("DynamicLayer/PlayerLayer") != null, "app scene has player layer")
			instance.free()


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("open JSON %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed

	_fail("parse JSON %s" % path)
	return {}


func _expect_true(value: bool, label: String) -> void:
	if not value:
		_fail(label)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail("%s: expected <%s>, got <%s>" % [label, expected, actual])


func _fail(label: String) -> void:
	_failures += 1
	printerr("FAIL: %s" % label)
