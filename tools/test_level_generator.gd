extends SceneTree
## Headless test for the level generator (docs/roadmap.md, M3 exit gate: 10,000 levels pass every rule).
## Run from the repository root:
##   godot --headless --path . --script res://tools/test_level_generator.gd
##
## This file is only a bootstrap. Project autoloads (EventBus, RunState) are registered after this script
## compiles, so the typed test in level_generator_test.gd is loaded here, in _initialize().

const RUNNER_PATH := "res://tools/level_generator_test.gd"


func _initialize() -> void:
	var runner := (load(RUNNER_PATH) as GDScript).new() as Node
	root.add_child.call_deferred(runner)
