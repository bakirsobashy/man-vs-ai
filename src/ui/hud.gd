class_name Hud
extends CanvasLayer
## The in-game HUD. The layout is authored in hud.tscn; this script fills in values and moves the stick graphic.
## The joystick zone IS the JoystickZone node: resize it in the editor to change the zone.

## Shared controls tuning (stick size, zone top, show stick).
@export var tuning: ControlsTuning

@onready var joystick_zone: Control = %JoystickZone
@onready var joystick: Control = %Joystick
@onready var knob: Control = %Knob
@onready var hearts_label: Label = %HeartsLabel
@onready var emp_label: Label = %EmpLabel
@onready var ammo_label: Label = %AmmoLabel
@onready var touch_path: Line2D = %TouchPath


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_emp_changed.connect(_on_player_emp_changed)
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	set_joystick_zone_top(tuning.joystick_zone_top)
	hide_stick()


func is_in_joystick_zone(at: Vector2) -> bool:
	return joystick_zone.get_global_rect().has_point(at)


func set_joystick_zone_top(ratio: float) -> void:
	joystick_zone.anchor_top = ratio


func show_stick(center: Vector2) -> void:
	joystick.scale = Vector2.ONE * (tuning.stick_radius / (joystick.size.x * 0.5))
	update_stick(center, Vector2.ZERO)
	joystick.visible = tuning.show_joystick


func update_stick(center: Vector2, offset: Vector2) -> void:
	var stick_scale := joystick.scale.x
	joystick.position = center - joystick.size * 0.5 * stick_scale
	knob.position = (joystick.size - knob.size) * 0.5 + offset / stick_scale


func hide_stick() -> void:
	joystick.visible = false


func begin_touch_path(at: Vector2) -> void:
	touch_path.clear_points()
	touch_path.add_point(at)


func add_touch_path_point(at: Vector2) -> void:
	if touch_path.visible:
		touch_path.add_point(at)


func _on_player_health_changed(hp: int, max_hp: int, armor: int) -> void:
	var text := "HP %s/%s" % [_hearts_text(hp), _hearts_text(max_hp)]
	if armor > 0:
		text += "  +%d armor" % armor
	hearts_label.text = text


## Half-hearts as hearts: 6 -> "3", 5 -> "2.5".
static func _hearts_text(half_hearts: int) -> String:
	return str(half_hearts / 2.0) if half_hearts % 2 == 1 else str(int(half_hearts / 2.0))


func _on_player_emp_changed(charges: int) -> void:
	emp_label.text = "EMP %d" % charges


func _on_player_ammo_changed(magazine: int, magazine_size: int, reserve: int, reloading: bool) -> void:
	var text := "%d/%d" % [magazine, magazine_size]
	if reserve >= 0:
		text += "  +%d" % reserve
	if reloading:
		text += "  RELOAD"
	ammo_label.text = text
