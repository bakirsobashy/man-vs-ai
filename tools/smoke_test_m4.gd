extends SceneTree
## Headless smoke test for M4 vertical slice gameplay (docs/roadmap.md, M4).
## Run from the repository root:
##   godot --headless --path . --script res://tools/smoke_test_m4.gd
##
## This file is only a bootstrap. Project autoloads (EventBus, RunState) are registered after this script
## compiles, so the typed test in m4_smoke_test.gd is loaded here, in _initialize().

const RUNNER_PATH := "res://tools/m4_smoke_test.gd"


func _initialize() -> void:
	var runner := (load(RUNNER_PATH) as GDScript).new() as Node
	root.add_child.call_deferred(runner)
