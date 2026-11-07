@icon("res://assets/art/placeholder/icon_state.svg")
class_name BossPhases
extends Node
## A boss's phases (docs/technical.md §6.5). Health.changed is connected to it in the boss scene; when HP drops
## below the next threshold, the boss jumps to that phase's first state and the HUD shows the phase banner.
## Each phase's states are siblings in the StateMachine, named after the phase (WreckCharge, MagnetPull…).

signal phase_changed(phase: int)

@export var state_machine: StateMachine
@export var boss_name := "boss.scrapjaw.name"
## HP shares where the next phase starts, highest first (0.6 → phase 2, 0.25 → phase 3).
@export var thresholds: Array[float] = [0.6, 0.25]
## The state each phase's loop starts from (phase 1 first).
@export var phase_states: Array[StringName] = []
## Shown in the phase banner.
@export var phase_names: Array[String] = []
## Optional: played when a new phase starts.
@export var roar: AudioStreamPlayer2D

## 0-based: 0 = phase 1.
var phase := 0


## Where the current phase's loop starts (after a stun or the spawn-in).
func loop_state() -> StringName:
	return phase_states[phase]


func _on_health_changed(hp: int, max_hp: int, _armor: int, _damaged: bool) -> void:
	if hp <= 0 or max_hp <= 0:
		return
	var target := 0
	for threshold: float in thresholds:
		if float(hp) / max_hp < threshold:
			target += 1
	target = mini(target, phase_states.size() - 1)
	if target <= phase:
		return
	phase = target
	EventBus.banner_requested.emit("%s · %s" % [tr(boss_name), tr(phase_names[phase]) if phase < phase_names.size() else ""])
	EventBus.screen_shake_requested.emit(0.5)
	if roar != null:
		roar.play()
	if not state_machine.is_in(&"SpawnIn"):
		state_machine.transition_to(phase_states[phase])
	phase_changed.emit(phase)
