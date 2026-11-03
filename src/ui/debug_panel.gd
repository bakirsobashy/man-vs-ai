class_name DebugPanel
extends PanelContainer
## M1 tuning panel: gesture readout, A/B switches and threshold sliders. Every control is authored in hud.tscn;
## the option items carry their values as item ids (e.g. "40%" has id 40).

## Shared controls tuning that the switches and sliders edit.
@export var tuning: ControlsTuning
## Swipe sensitivity presets, in the same order as the Swipe option's item ids.
@export var swipe_presets: Array[SwipePreset] = []
## The HUD, to move the joystick zone.
@export var hud: Hud

@onready var info_label: Label = %InfoLabel
@onready var zone_hint: Control = %ZoneHint
@onready var touch_path: Line2D = %TouchPath
@onready var cover_option: OptionButton = %CoverOption
@onready var zone_option: OptionButton = %ZoneOption
@onready var swipe_option: OptionButton = %SwipeOption
@onready var anchor_option: OptionButton = %AnchorOption
@onready var show_stick_check: CheckBox = %ShowStickCheck

var _gesture := "-"
var _state := "-"


func _ready() -> void:
	EventBus.gesture_classified.connect(_on_gesture_classified)
	EventBus.player_state_changed.connect(_on_player_state_changed)
	_select_id(cover_option, tuning.cover_mode)
	_select_id(zone_option, roundi(tuning.joystick_zone_top * 100.0))
	_select_id(anchor_option, roundi(tuning.hero_anchor * 100.0))
	show_stick_check.set_pressed_no_signal(tuning.show_joystick)
	_show_debug_visuals(visible)


func _process(_delta: float) -> void:
	if not visible:
		return
	var enemy_bullets := 0
	for node: Node in get_tree().get_nodes_in_group(&"bullet_pools"):
		var pool := node as BulletPool
		if pool != null and pool.hostile:
			enemy_bullets += pool.active_count
	info_label.text = "FPS %d · enemy bullets %d\nstate: %s\ngesture: %s" % [
		Engine.get_frames_per_second(), enemy_bullets, _state, _gesture]


func _select_id(option: OptionButton, id: int) -> void:
	var index := option.get_item_index(id)
	if index >= 0:
		option.select(index)


func _show_debug_visuals(on: bool) -> void:
	zone_hint.visible = on
	touch_path.visible = on


func _on_gesture_classified(kind: StringName, details: String) -> void:
	_gesture = "%s (%s)" % [kind, details]


func _on_player_state_changed(state_name: StringName) -> void:
	_state = state_name


# --- Signals connected in hud.tscn ---

func _on_debug_button_toggled(on: bool) -> void:
	visible = on


func _on_visibility_changed() -> void:
	if is_node_ready():
		_show_debug_visuals(visible)


func _on_cover_option_item_selected(index: int) -> void:
	tuning.cover_mode = cover_option.get_item_id(index) as ControlsTuning.CoverMode


func _on_zone_option_item_selected(index: int) -> void:
	tuning.joystick_zone_top = zone_option.get_item_id(index) / 100.0
	hud.set_joystick_zone_top(tuning.joystick_zone_top)


func _on_swipe_option_item_selected(index: int) -> void:
	var preset_index := swipe_option.get_item_id(index)
	if preset_index >= 0 and preset_index < swipe_presets.size():
		swipe_presets[preset_index].apply_to(tuning)
		get_tree().call_group(&"tuning_sliders", &"refresh")


func _on_anchor_option_item_selected(index: int) -> void:
	tuning.hero_anchor = anchor_option.get_item_id(index) / 100.0


func _on_show_stick_check_toggled(on: bool) -> void:
	tuning.show_joystick = on
