extends SceneTree

const ZaxLevelDataScript := preload("res://src/core/zax_level_data.gd")
const ZaxWaypointMapScript := preload("res://src/core/zax_waypoint_map.gd")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_project_settings()
	_test_manifest()
	_test_level_data()
	_test_waypoint_data()
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


func _test_manifest() -> void:
	var manifest := _load_json("res://assets/zax/manifest.json")
	var assets: Dictionary = manifest.get("assets", {})
	for asset_id in ["manifest_extraction", "manifest_ida_coverage", "level_01_main", "waypoints_01_main", "texture_01_main"]:
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


func _test_waypoint_data() -> void:
	var raw := _load_json("res://assets/zax/waypoints/data/01 Main.json")
	var waypoint_map: ZaxWaypointMap = ZaxWaypointMapScript.new()
	waypoint_map.load_from_dictionary(&"waypoints_01_main", raw)

	_expect_true(waypoint_map.is_valid(), "waypoint map is valid")
	_expect_equal(waypoint_map.waypoint_count, 6863, "waypoint count")
	_expect_equal(waypoint_map.edge_count, 25495, "edge count")
	_expect_equal(waypoint_map.get_point(0), Vector2(2095, 1154), "first waypoint position")
	_expect_true(waypoint_map.get_connections(0).has(43.0), "first waypoint connections")


func _test_scene_instantiation() -> void:
	var scene := load("res://scenes/app/app.tscn")
	_expect_true(scene is PackedScene, "app scene loads")
	if scene is PackedScene:
		var packed_scene := scene as PackedScene
		var instance: Node = packed_scene.instantiate()
		_expect_true(instance != null, "app scene instantiates")
		if instance != null:
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
