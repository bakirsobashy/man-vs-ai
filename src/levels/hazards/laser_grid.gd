class_name LaserGrid
extends Area2D
## A timed laser grid (Skyline Spires): cycles off → warning → on. While on, it hurts the hero on contact and on every
## TickTimer tick; rolling i-frames pass through it. It isn't a floor hazard, so Filter Lungs don't help. Robots
## ignore it. Rotate and scale the node in the editor to lay it across a corridor; offset neighbors with start_offset.
## The PhaseTimer and TickTimer timeouts are connected in the scene.

enum GridPhase { OFF, WARN, ON }

## Half-hearts per hit.
@export_range(1, 6) var damage := 1
@export_range(0.2, 10.0, 0.1, "suffix:s") var off_time := 2.0
## The warning blink (at least the 0.4 s minimum tell).
@export_range(0.4, 3.0, 0.1, "suffix:s") var warn_time := 0.6
@export_range(0.2, 10.0, 0.1, "suffix:s") var on_time := 1.4
## Seconds into the cycle when the room loads, so neighboring grids can take turns.
@export_range(0.0, 20.0, 0.1, "suffix:s") var start_offset := 0.0

@onready var phase_timer: Timer = %PhaseTimer
@onready var grid_animation: AnimationPlayer = %GridAnimation

var phase := GridPhase.OFF


func _ready() -> void:
	var t := fmod(start_offset, off_time + warn_time + on_time)
	if t < off_time:
		_enter(GridPhase.OFF, off_time - t)
	elif t < off_time + warn_time:
		_enter(GridPhase.WARN, off_time + warn_time - t)
	else:
		_enter(GridPhase.ON, off_time + warn_time + on_time - t)


func is_hot() -> bool:
	return phase == GridPhase.ON


func _enter(next: GridPhase, duration: float) -> void:
	phase = next
	grid_animation.play([&"off", &"warn", &"on"][next])
	phase_timer.start(maxf(duration, 0.05))
	if next == GridPhase.ON:
		_burn_overlapping()


func _burn_overlapping() -> void:
	for body: Node2D in get_overlapping_bodies():
		var hero := body as Player
		if hero != null:
			hero.take_hazard_hit(damage, false)


func _on_phase_timer_timeout() -> void:
	match phase:
		GridPhase.OFF:
			_enter(GridPhase.WARN, warn_time)
		GridPhase.WARN:
			_enter(GridPhase.ON, on_time)
		GridPhase.ON:
			_enter(GridPhase.OFF, off_time)


func _on_body_entered(body: Node2D) -> void:
	if is_hot() and body is Player:
		(body as Player).take_hazard_hit(damage, false)


func _on_tick_timer_timeout() -> void:
	if is_hot():
		_burn_overlapping()
