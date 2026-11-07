class_name MoltenLane
extends Area2D
## Molten metal (The Foundry). Hurts the hero on contact and every TickTimer tick while standing in it; rolling
## crosses it safely, and Filter Lungs Mk II make the hero immune. Robots ignore it.
## With a warmup (FORGEMOTHER's floods) it blinks harmlessly for WarmupTimer's wait first; with a lifetime it then
## removes itself when LifeTimer ends. Their timeouts are connected in the scene.

## Half-hearts per hit.
@export_range(1, 6) var damage := 1
## A flood: start in the warning state (the WarmupTimer must be set to autostart).
@export var starts_warming := false

@onready var lane_animation: AnimationPlayer = %LaneAnimation
@onready var tick_timer: Timer = %TickTimer

var hot := true


func _ready() -> void:
	hot = not starts_warming
	lane_animation.play(&"warn" if starts_warming else &"glow")


func _burn_overlapping() -> void:
	if not hot:
		return
	for body: Node2D in get_overlapping_bodies():
		var hero := body as Player
		if hero != null:
			hero.take_hazard_hit(damage)


func _on_body_entered(body: Node2D) -> void:
	if hot and body is Player:
		(body as Player).take_hazard_hit(damage)


func _on_tick_timer_timeout() -> void:
	_burn_overlapping()


func _on_warmup_timer_timeout() -> void:
	hot = true
	lane_animation.play(&"glow")
	_burn_overlapping()


func _on_life_timer_timeout() -> void:
	queue_free()
