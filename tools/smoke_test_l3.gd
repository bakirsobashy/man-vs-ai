extends SceneTree
## Headless smoke test for Level 3 (The Foundry) (docs/roadmap.md, M5).
## Run from the repository root:
##   godot --headless --path . --script res://tools/smoke_test_l3.gd
##
## This file is only a bootstrap. Project autoloads (EventBus, RunState) are registered after this script
## compiles, so the typed test in l3_smoke_test.gd is loaded here, in _initialize().

const RUNNER_PATH := "res://tools/l3_smoke_test.gd"


func _initialize() -> void:
	var runner := (load(RUNNER_PATH) as GDScript).new() as Node
	root.add_child.call_deferred(runner)
