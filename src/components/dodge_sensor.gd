@icon("res://assets/art/placeholder/icon_state.svg")
class_name DodgeSensor
extends Area2D
## Null Knight and ZERO mirror the hero's roll. When a live player bullet enters this area (mask: player bullets)
## while the robot is in one of `from_states`, it rolls (`roll_state`, given the bullet's direction) with `chance`,
## then can't again until `cooldown_timer` runs out. Its area_entered signal is connected in the owner scene.

@export var state_machine: StateMachine
@export var cooldown_timer: Timer
@export var roll_state := &"Dodge"
## States the robot may roll out of (empty: any).
@export var from_states: Array[StringName] = []
@export_range(0.0, 1.0, 0.05) var chance := 0.6


func _on_area_entered(area: Area2D) -> void:
	var bullet := area as Bullet
	if bullet == null or not bullet.active or not cooldown_timer.is_stopped():
		return
	if not from_states.is_empty() and not from_states.any(func(s: StringName) -> bool: return state_machine.is_in(s)):
		return
	if randf() > chance:
		return
	cooldown_timer.start()
	state_machine.transition_to(roll_state, {"bullet_direction": bullet.direction})
