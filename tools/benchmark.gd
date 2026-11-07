extends SceneTree
## Headless performance benchmark (docs/technical.md §13). Run from the repository root:
##   godot --headless --fixed-fps 60 --path . --script res://tools/benchmark.gd
## One level, stressed longer:  ... --script res://tools/benchmark.gd -- --level=3 --seconds=10
## --fixed-fps 60 makes every frame one physics step with no real-time wait, so frame times are pure logic cost.
## It plays every district's level at the worst case the budgets allow and reports script + physics time per frame,
## room transition times, and leaks. Rendering isn't measured headless: check it on the test devices with the
## debug panel's FPS readout and the 300-bullet storm.
##
## This file is only a bootstrap: the typed benchmark in benchmark_runner.gd is loaded in _initialize() (autoloads
## are registered after this script compiles).

const RUNNER_PATH := "res://tools/benchmark_runner.gd"


func _initialize() -> void:
	var runner := (load(RUNNER_PATH) as GDScript).new() as Node
	root.add_child.call_deferred(runner)
