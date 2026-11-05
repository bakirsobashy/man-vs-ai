class_name Enemy
extends CharacterBody2D
## Base for every robot (docs/content.md §2). Behavior lives in the state nodes under the StateMachine,
## each tuned in the Inspector; this script holds what all states share.

enum SpawnKind { GROUND = 1, FLYER = 2, STATIONARY = 4 }
## Elite modifiers (docs/content.md §2). The WaveSpawner picks one; make_elite() applies it.
enum Elite { NONE, OVERCLOCKED, ARMORED, SPLITTER, SHIELDED }

const ELITE_COLORS: Array[Color] = [Color.WHITE, Color(1, 0.3, 0.25), Color(0.75, 0.78, 0.85), Color(1, 0.85, 0.3), Color(0.4, 0.75, 1)]

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
## Optional: paths around walls and cover (moving enemies). Without one, enemies steer straight.
@export var nav_agent: NavigationAgent2D
## Bosses report their health to the HUD's boss bar.
@export var is_boss := false
## Groups whose members (a boss's decoys, minions or drones) are removed when this robot dies.
@export var clears_groups_on_death: Array[StringName] = []

@onready var sprite: Sprite2D = %Sprite
@onready var health: Health = %Health
@onready var state_machine: StateMachine = %StateMachine
@onready var drops: Drops = %Drops
@onready var line_of_sight: RayCast2D = %LineOfSight
@onready var flash_animation: AnimationPlayer = %FlashAnimation
## Optional "HitSound" node (AudioStreamPlayer2D), played on every hit that lands.
@onready var hit_sound: AudioStreamPlayer2D = get_node_or_null(^"HitSound") as AudioStreamPlayer2D
## Optional elite ring and shield bubble (hidden Sprite2D nodes in the enemy scene).
@onready var elite_fx: CanvasItem = get_node_or_null(^"EliteFX") as CanvasItem
@onready var shield_bubble: CanvasItem = get_node_or_null(^"ShieldBubble") as CanvasItem

var player: Node2D
## True while the SpawnIn state runs: harmless, untargetable, bullets pass through.
var spawning := true
## Direction remembered by a tell (chargers).
var locked_direction := Vector2.DOWN
var elite := Elite.NONE
## Overclocked elites attack this much faster (states divide their waits by it).
var attack_rate := 1.0
## Hits a shield absorbs before damage gets through (Shielded elites, a Hacker's shield).
var shield_hits := 0
## Cryo build-up; at 1 the robot freezes.
var chill := 0.0
## Damage taken is multiplied by this (FORGEMOTHER's exposed core: 2).
var damage_taken_scale := 1.0
## True during a dodge roll (Null Knight, ZERO): bullets pass through, like the hero's i-frames.
var dodging := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group(&"player") as Node2D


func is_alive() -> bool:
	return health.is_alive()


func is_targetable() -> bool:
	return not spawning and not dodging and health.is_alive()


func to_player() -> Vector2:
	return player.global_position - global_position if player != null else Vector2.ZERO


func can_see_player() -> bool:
	if player == null:
		return false
	line_of_sight.target_position = line_of_sight.to_local(player.global_position)
	line_of_sight.force_raycast_update()
	return not line_of_sight.is_colliding()


## Direction to move toward `target`: along the navigation path when there is one, else straight.
func direction_toward(target: Vector2) -> Vector2:
	if nav_agent != null:
		if nav_agent.target_position.distance_to(target) > 8.0:
			nav_agent.target_position = target
		var step := nav_agent.get_next_path_position() - global_position
		if step.length() > 0.5:
			return step.normalized()
	var straight := target - global_position
	return straight.normalized() if straight != Vector2.ZERO else Vector2.ZERO


## Turns this copy into an elite (2× threat, 3× RAM; docs/content.md §2).
func make_elite(kind: Elite) -> void:
	elite = kind
	drops.ram_mb *= 3
	match kind:
		Elite.OVERCLOCKED:
			move_speed *= 1.5
			attack_rate = 1.5
			if attack_animation != null:
				attack_animation.speed_scale = 1.5
			for child: Node in get_children():
				if child is BulletEmitter:
					(child as BulletEmitter).burst_interval /= 1.5
		Elite.ARMORED:
			health.max_hp *= 2
			health.hp = health.max_hp
			move_speed *= 0.8
		Elite.SHIELDED:
			give_shield(3)
	if elite_fx != null:
		elite_fx.visible = true
		elite_fx.self_modulate = ELITE_COLORS[kind]


## A shield that absorbs the next `hits` hits (a Hacker shields its allies this way).
func give_shield(hits: int) -> void:
	shield_hits = maxi(shield_hits, hits)
	if shield_bubble != null:
		shield_bubble.visible = true


## `through_shields` (the Peacekeeper) skips shield hits.
func take_damage(amount: int, through_shields := false) -> void:
	if not is_targetable():
		return
	if shield_hits > 0 and not through_shields:
		shield_hits -= 1
		if shield_bubble != null:
			shield_bubble.visible = shield_hits > 0
		flash_animation.stop()
		flash_animation.play(&"hurt")
		return
	health.take_hit(roundi(amount * damage_taken_scale))
	if hit_sound != null:
		hit_sound.play()
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
	take_damage(bullet.hit_damage, bullet.ignores_shields)
	if bullet.stun_time > 0.0 and health.is_alive() and not is_boss:
		stun(bullet.stun_time)
	if bullet.chill > 0.0 and health.is_alive() and not is_boss:
		chill += bullet.chill
		if chill >= 1.0:
			chill = 0.0
			stun(bullet.freeze_time)
	if bullet.knockback > 0.0 and bullet.hit_damage >= bullet.knockback_min_damage and health.is_alive() and not is_boss:
		_shove.call_deferred(bullet.direction * bullet.knockback)


## Knockback: a short push that walls and cover stop.
func _shove(offset: Vector2) -> void:
	if is_inside_tree():
		move_and_collide(offset)


func _on_health_changed(hp: int, max_hp: int, _armor: int, _damaged: bool) -> void:
	if is_boss:
		EventBus.boss_health_changed.emit(hp, max_hp)


func _on_health_died() -> void:
	for group: StringName in clears_groups_on_death:
		for summon: Node in get_tree().get_nodes_in_group(group):
			summon.queue_free()
	drops.drop(global_position)
	var layer := get_tree().get_first_node_in_group(&"drop_layer")
	if death_fx_scene != null and layer != null:
		var effect := death_fx_scene.instantiate() as Node2D
		effect.position = (layer as Node2D).to_local(global_position) if layer is Node2D else global_position
		layer.add_child.call_deferred(effect)
	EventBus.enemy_killed.emit(self)
	queue_free()
