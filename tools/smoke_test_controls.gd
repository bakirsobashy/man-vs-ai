extends SceneTree
## Headless smoke test for the M1 controls greybox (docs/roadmap.md, M1).
## Run from the repository root:
##   godot --headless --path . --script res://tools/smoke_test_controls.gd
##
## This file is only a bootstrap. Project autoloads (EventBus) are registered after this script
## compiles, so the typed test in controls_smoke_test.gd is loaded here, in _initialize().

const RUNNER_PATH := "res://tools/controls_smoke_test.gd"


func _initialize() -> void:
	var runner := (load(RUNNER_PATH) as GDScript).new() as Node
	root.add_child.call_deferred(runner)
