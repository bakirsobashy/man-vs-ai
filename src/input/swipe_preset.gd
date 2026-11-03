class_name SwipePreset
extends Resource
## A swipe-sensitivity preset (data/controls/swipe_*.tres). The debug panel, and later the settings menu, apply it.

## Longest touch that can still be a roll.
@export_range(0.05, 0.6, 0.01, "suffix:s") var swipe_max_time := 0.25
## Least finger travel for a roll.
@export_range(4.0, 96.0, 1.0, "suffix:px") var swipe_min_dist := 24.0
## Least flick speed for a roll.
@export_range(50.0, 3000.0, 25.0, "suffix:px/s") var swipe_min_speed := 500.0


func apply_to(tuning: ControlsTuning) -> void:
	tuning.swipe_max_time = swipe_max_time
	tuning.swipe_min_dist = swipe_min_dist
	tuning.swipe_min_speed = swipe_min_speed
