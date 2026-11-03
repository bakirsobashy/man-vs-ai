extends SceneTree
## Scene check (docs/technical.md §0.7).
## Loads and instantiates every .tscn under res://src, and verifies that every signal
## connection saved in a scene still points to an existing node, signal and method.
## Run from the repository root:
##   godot --headless --path . --script res://tools/check_scenes.gd

const SCENE_ROOT := "res://src"


# _initialize (not _init): it runs after the project's autoloads are registered,
# so scripts that use autoloads such as EventBus compile.
func _initialize() -> void:
	var failures := 0
	var scenes := _find_scenes(SCENE_ROOT)
	for path: String in scenes:
		failures += _check_scene(path)
	print("Scenes checked: %d, failures: %d" % [scenes.size(), failures])
	quit(1 if failures > 0 else 0)


func _check_scene(path: String) -> int:
	var packed := load(path) as PackedScene
	if packed == null:
		printerr("FAIL %s: cannot be loaded as a scene" % path)
		return 1
	var instance := packed.instantiate()
	if instance == null:
		printerr("FAIL %s: cannot be instantiated" % path)
		return 1
	var failures := _check_connections(packed.get_state(), instance, path)
	instance.free()
	return failures


func _check_connections(state: SceneState, instance: Node, path: String) -> int:
	var failures := 0
	for i: int in state.get_connection_count():
		var signal_name := state.get_connection_signal(i)
		var method := state.get_connection_method(i)
		var source := instance.get_node_or_null(state.get_connection_source(i))
		var target := instance.get_node_or_null(state.get_connection_target(i))
		if source == null or target == null:
			printerr("FAIL %s: connection %s -> %s points to a missing node" % [path, signal_name, method])
			failures += 1
		elif not source.has_signal(signal_name):
			printerr("FAIL %s: node %s has no signal '%s'" % [path, source.name, signal_name])
			failures += 1
		elif not target.has_method(method):
			printerr("FAIL %s: node %s has no method '%s' for signal '%s'" % [path, target.name, method, signal_name])
			failures += 1
	return failures


func _find_scenes(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for file: String in dir.get_files():
		if file.ends_with(".tscn"):
			result.append(dir_path.path_join(file))
	for sub: String in dir.get_directories():
		result.append_array(_find_scenes(dir_path.path_join(sub)))
	return result
