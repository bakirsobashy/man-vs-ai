class_name ControlsTuning
extends Resource
## Every one-finger control threshold (docs/GDD.md §3.4), plus the M1 A/B test switches.
## Edited in the Inspector (data/controls/controls_tuning.tres); the debug panel edits it live.

enum CoverMode { NEAREST_POINT, SMART_SIDE }

@export_group("Joystick")
## Maximum stick deflection.
@export_range(16.0, 160.0, 1.0, "suffix:px") var stick_radius := 48.0
## Finger offsets smaller than this are ignored.
@export_range(0.0, 32.0, 1.0, "suffix:px") var dead_zone := 8.0
## Share of the stick radius at which the hero reaches full speed.
@export_range(0.1, 1.0, 0.05) var full_speed_at := 0.7

@export_group("Swipe (roll)")
## A roll needs touch-down to lift within this time...
@export_range(0.05, 0.6, 0.01, "suffix:s") var swipe_max_time := 0.25
## ...at least this much finger travel...
@export_range(4.0, 96.0, 1.0, "suffix:px") var swipe_min_dist := 24.0
## ...and at least this finger speed, measured over speed_window.
@export_range(50.0, 3000.0, 25.0, "suffix:px/s") var swipe_min_speed := 500.0
## Time window used to measure the flick speed.
@export_range(0.02, 0.3, 0.01, "suffix:s") var speed_window := 0.1

@export_group("Taps")
## Longest touch that still counts as a tap.
@export_range(0.05, 0.5, 0.01, "suffix:s") var tap_max_time := 0.2
## Most finger travel that still counts as a tap.
@export_range(2.0, 48.0, 1.0, "suffix:px") var tap_max_move := 12.0
## Second tap must land within this time of the first.
@export_range(0.1, 0.8, 0.01, "suffix:s") var double_tap_window := 0.3
## ...and within this distance of the first.
@export_range(8.0, 160.0, 1.0, "suffix:px") var double_tap_max_dist := 40.0

@export_group("A/B tests (M1)")
## Where the hero slides on lift: the nearest point of the cover, or the side facing away from enemies.
@export var cover_mode := CoverMode.NEAREST_POINT
## Smart side only: how strongly the safe side is preferred, as px of extra slide distance.
@export_range(0.0, 160.0, 1.0, "suffix:px") var smart_side_bias := 48.0
## Where the hero sits on screen, as a share of the screen height from the top.
@export_range(0.3, 0.7, 0.01) var hero_anchor := 0.45
## Top edge of the joystick zone, as a share of the screen height.
@export_range(0.2, 0.7, 0.01) var joystick_zone_top := 0.4
## Show the floating stick graphic. (Hidden by default in the final game; shown for M1 testing.)
@export var show_joystick := true
