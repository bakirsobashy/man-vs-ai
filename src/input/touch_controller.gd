@icon("res://assets/art/placeholder/icon_touch.svg")
class_name TouchController
extends Node
## Turns one finger into intents (docs/GDD.md §3): move + fire while touching, roll on a swipe,
## lift on release, special on a double-tap. The joystick zone is the HUD's JoystickZone node.

signal touch_started
signal rolled(direction: Vector2)
signal lifted
signal special_requested

## Shared thresholds (data/controls/controls_tuning.tres).
@export var tuning: ControlsTuning
## The HUD that owns the JoystickZone node and the stick graphic.
@export var hud: Hud

## Joystick output, length 0..1. Zero while not touching.
var move_vector := Vector2.ZERO
## True while a finger that started in the joystick zone is down.
var touching := false

var _index := -1
var _in_zone := false
var _start_position := Vector2.ZERO
var _start_time := 0.0
var _center := Vector2.ZERO
var _sample_positions: Array[Vector2] = []
var _sample_times: Array[float] = []
var _last_tap_time := -INF
var _last_tap_position := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_press(touch.index, touch.position)
		elif touch.index == _index:
			_release(touch.position, touch.canceled)
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _index:
		_drag(drag.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _index != -1:
		_release(_start_position, true)


func _press(index: int, at: Vector2) -> void:
	if _index != -1:
		return
	_index = index
	_start_position = at
	_start_time = _now()
	_sample_positions = [at]
	_sample_times = [_start_time]
	_in_zone = hud.is_in_joystick_zone(at)
	hud.begin_touch_path(at)
	if _in_zone:
		_center = at
		touching = true
		move_vector = Vector2.ZERO
		hud.show_stick(_center)
		touch_started.emit()


func _drag(at: Vector2) -> void:
	var now := _now()
	_sample_positions.append(at)
	_sample_times.append(now)
	while _sample_times.size() > 2 and now - _sample_times[1] >= tuning.speed_window:
		_sample_positions.pop_front()
		_sample_times.pop_front()
	hud.add_touch_path_point(at)
	if not _in_zone:
		return
	var offset := at - _center
	if offset.length() > tuning.stick_radius:
		_center = at - offset.normalized() * tuning.stick_radius
		offset = at - _center
	move_vector = _stick_vector(offset)
	hud.update_stick(_center, offset)


func _release(at: Vector2, canceled: bool) -> void:
	var now := _now()
	var duration := now - _start_time
	var travel := at - _start_position
	var speed := _recent_speed(at, now)
	var was_in_zone := _in_zone
	_index = -1
	_in_zone = false
	touching = false
	move_vector = Vector2.ZERO
	hud.hide_stick()
	if canceled:
		if was_in_zone:
			lifted.emit()
		return
	if was_in_zone and duration <= tuning.swipe_max_time and travel.length() >= tuning.swipe_min_dist \
			and speed >= tuning.swipe_min_speed:
		rolled.emit(travel.normalized())
		_report(&"roll", duration, travel.length(), speed)
		return
	if was_in_zone:
		lifted.emit()
	var kind: StringName = &"lift" if was_in_zone else &"outside zone"
	if duration <= tuning.tap_max_time and travel.length() <= tuning.tap_max_move:
		if now - _last_tap_time <= tuning.double_tap_window \
				and at.distance_to(_last_tap_position) <= tuning.double_tap_max_dist:
			special_requested.emit()
			_last_tap_time = -INF
			kind = &"double tap"
		else:
			_last_tap_time = now
			_last_tap_position = at
			kind = &"tap"
	_report(kind, duration, travel.length(), speed)


func _stick_vector(offset: Vector2) -> Vector2:
	var length := offset.length()
	if length <= tuning.dead_zone:
		return Vector2.ZERO
	var full := tuning.stick_radius * tuning.full_speed_at
	var strength := clampf((length - tuning.dead_zone) / maxf(full - tuning.dead_zone, 1.0), 0.0, 1.0)
	return offset / length * strength


## Finger speed over the last speed_window (or the whole gesture, if it was shorter).
func _recent_speed(at: Vector2, now: float) -> float:
	var from_position := _start_position
	var from_time := _start_time
	for i: int in range(_sample_times.size() - 1, -1, -1):
		if now - _sample_times[i] >= tuning.speed_window:
			from_position = _sample_positions[i]
			from_time = _sample_times[i]
			break
	return at.distance_to(from_position) / maxf(now - from_time, 0.001)


func _report(kind: StringName, duration: float, distance: float, speed: float) -> void:
	EventBus.gesture_classified.emit(kind, "%.2f s · %d px · %d px/s" % [duration, int(distance), int(speed)])


func _now() -> float:
	return Time.get_ticks_usec() / 1_000_000.0
