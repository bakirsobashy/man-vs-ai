class_name FirewallLaser
extends Node2D
## A firewall (Syndicate Core): a wall of light (%Wall, an Area2D across the room) that sweeps `travel` px along the
## node's local +Y and back, one round trip per `period`. It hurts the hero on contact and on every TickTimer tick
## while he's in it; a roll passes through, and that's the way past. ZERO's closing edges start with `active` off.
## The SweepAnimation animates `progress`; the Wall and TickTimer signals are connected in the scene.

## Half-hearts per hit.
@export_range(1, 6) var damage := 1
## How far the wall sweeps from its starting line.
@export_range(0.0, 800.0, 1.0, "suffix:px") var travel := 160.0
## Seconds for one sweep out and back.
@export_range(0.5, 30.0, 0.1, "suffix:s") var period := 5.0
## Seconds into the sweep when it starts.
@export_range(0.0, 30.0, 0.1, "suffix:s") var start_offset := 0.0
## Off: hidden and harmless until set_active(true).
@export var active := true
## 0 at the starting line, 1 at full travel (keyed by the SweepAnimation).
@export_range(0.0, 1.0, 0.01) var progress := 0.0:
	set(value):
		progress = value
		if is_node_ready():
			wall.position.y = progress * travel

@onready var wall: Area2D = %Wall
@onready var sweep_animation: AnimationPlayer = %SweepAnimation


func _ready() -> void:
	wall.position.y = progress * travel
	set_active(active)


func set_active(on: bool) -> void:
	active = on
	visible = on
	if on:
		sweep_animation.play(&"sweep")
		sweep_animation.speed_scale = 1.0 / period
		sweep_animation.seek(fmod(start_offset, period) / period, true)
		if is_inside_tree():
			_burn_overlapping.call_deferred()
	else:
		sweep_animation.stop()


func _burn_overlapping() -> void:
	if not active:
		return
	for body: Node2D in wall.get_overlapping_bodies():
		var hero := body as Player
		if hero != null:
			hero.take_hazard_hit(damage, false)


func _on_wall_body_entered(body: Node2D) -> void:
	if active and body is Player:
		(body as Player).take_hazard_hit(damage, false)


func _on_tick_timer_timeout() -> void:
	_burn_overlapping()
