class_name CoolantFlood
extends Area2D
## A coolant flood (Syndicate Core): cycles dry → warning → flooded. While flooded, the hero wading through it moves
## at `slow_scale` of his speed (rolls aren't slowed). Robots ignore it. Offset neighbors with start_offset.
## The PhaseTimer timeout and the body signals are connected in the scene.

enum FloodPhase { DRY, WARN, WET }

## Hero speed multiplier while he stands in the flood.
@export_range(0.1, 1.0, 0.05) var slow_scale := 0.5
@export_range(0.2, 20.0, 0.1, "suffix:s") var dry_time := 3.0
@export_range(0.4, 3.0, 0.1, "suffix:s") var warn_time := 0.8
@export_range(0.2, 20.0, 0.1, "suffix:s") var wet_time := 3.0
## Seconds into the cycle when the room loads.
@export_range(0.0, 40.0, 0.1, "suffix:s") var start_offset := 0.0

@onready var phase_timer: Timer = %PhaseTimer
@onready var flood_animation: AnimationPlayer = %FloodAnimation

var phase := FloodPhase.DRY
var _hero: Player


func _ready() -> void:
	var t := fmod(start_offset, dry_time + warn_time + wet_time)
	if t < dry_time:
		_enter(FloodPhase.DRY, dry_time - t)
	elif t < dry_time + warn_time:
		_enter(FloodPhase.WARN, dry_time + warn_time - t)
	else:
		_enter(FloodPhase.WET, dry_time + warn_time + wet_time - t)


func _exit_tree() -> void:
	if _hero != null and is_instance_valid(_hero):
		_hero.clear_slow(self)


func is_wet() -> bool:
	return phase == FloodPhase.WET


func _enter(next: FloodPhase, duration: float) -> void:
	phase = next
	flood_animation.play([&"dry", &"warn", &"wet"][next])
	phase_timer.start(maxf(duration, 0.05))
	_apply()


func _apply() -> void:
	if _hero == null:
		return
	if is_wet():
		_hero.set_slow(self, slow_scale)
	else:
		_hero.clear_slow(self)


func _on_phase_timer_timeout() -> void:
	match phase:
		FloodPhase.DRY:
			_enter(FloodPhase.WARN, warn_time)
		FloodPhase.WARN:
			_enter(FloodPhase.WET, wet_time)
		FloodPhase.WET:
			_enter(FloodPhase.DRY, dry_time)


func _on_body_entered(body: Node2D) -> void:
	var hero := body as Player
	if hero != null:
		_hero = hero
		_apply()


func _on_body_exited(body: Node2D) -> void:
	if body == _hero:
		_hero.clear_slow(self)
		_hero = null
