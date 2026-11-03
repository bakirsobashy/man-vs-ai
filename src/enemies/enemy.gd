class_name Enemy
extends CharacterBody2D
## Base for every robot (docs/content.md §2). Behavior lives in the state nodes under the StateMachine,
## each tuned in the Inspector; this script holds what all states share.

enum SpawnKind { GROUND = 1, FLYER = 2, STATIONARY = 4 }

## Movement speed used by moving states.
@export_range(0.0, 400.0, 1.0, "suffix:px/s") var move_speed := 40.0
## Which SpawnPoints may hold this enemy.
@export var spawn_kind := SpawnKind.GROUND
## State node used when an EMP stuns this enemy.
@export var stun_state := &"Stunned"
## Copied into the drop layer when the enemy dies.
@export var death_fx_scene: PackedScene
## Optional: plays the attack tells (telegraph animations).
@export var attack_animation: AnimationPlayer

@onready var sprite: Sprite2D = %Sprite
@onready var health: Health = %Health
@onready var state_machine: StateMachine = %StateMachine
@onready var drops: Drops = %Drops
@onready var line_of_sight: RayCast2D = %LineOfSight
@onready var flash_animation: AnimationPlayer = %FlashAnimation

var player: Node2D
## True while the SpawnIn state runs: harmless, untargetable, bullets pass through.
var spawning := true
## Direction remembered by a tell (chargers).
var locked_direction := Vector2.DOWN


func _ready() -> void:
	player = get_tree().get_first_node_in_group(&"player") as Node2D


func is_alive() -> bool:
	return health.is_alive()


func is_targetable() -> bool:
	return not spawning and health.is_alive()


func to_player() -> Vector2:
	return player.global_position - global_position if player != null else Vector2.ZERO


func can_see_player() -> bool:
	if player == null:
		return false
	line_of_sight.target_position = line_of_sight.to_local(player.global_position)
	line_of_sight.force_raycast_update()
	return not line_of_sight.is_colliding()


func take_damage(amount: int) -> void:
	if not is_targetable():
		return
	health.take_hit(amount)
	if health.is_alive():
		flash_animation.stop()
		flash_animation.play(&"hurt")


func stun(duration: float) -> void:
	if is_targetable():
		state_machine.transition_to(stun_state, {"duration": duration})


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var bullet := area as Bullet
	if bullet == null or not bullet.active or not is_targetable() or not bullet.try_hit(self):
		return
	take_damage(bullet.hit_damage)


func _on_health_died() -> void:
	drops.drop(global_position)
	var layer := get_tree().get_first_node_in_group(&"drop_layer")
	if death_fx_scene != null and layer != null:
		var effect := death_fx_scene.instantiate() as Node2D
		effect.position = global_position
		layer.add_child.call_deferred(effect)
	EventBus.enemy_killed.emit(self)
	queue_free()
