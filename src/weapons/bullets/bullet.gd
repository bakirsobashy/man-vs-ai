class_name Bullet
extends Area2D
## A projectile. BulletPools make copies of the authored bullet scenes; this script moves them and
## despawns them on walls, cover, screen exit or old age. Hurtboxes detect bullets (they monitor the bullet layers).
## Physics flags are never toggled: an inactive bullet is hidden and parked at its pool's position,
## which the level scene places far outside the playfield.

## Travel speed.
@export_range(0.0, 2000.0, 1.0, "suffix:px/s") var speed := 160.0
## Damage to whatever it hits (hero: half-hearts; enemies: HP). A weapon can override it per shot.
@export_range(0, 999) var damage := 1
## Damage to cover it hits.
@export_range(0, 999) var cover_damage := 4
## Despawn after this long even if nothing was hit.
@export_range(0.1, 20.0, 0.1, "suffix:s") var lifetime := 4.0
## Extra enemies the bullet passes through before it stops (Rivet Driver: 1).
@export_range(0, 10) var pierce := 0
## Explosions ignore cover protection.
@export var explosive := false
## Fired from above (drones): ignores cover protection.
@export var aerial := false
## Ricochet Carbine: bounces off walls this many times (the WallProbe ray finds the wall's normal).
@export_range(0, 5) var bounces := 0
## Optional: the ray that finds a wall's normal for bounces.
@export var wall_probe: RayCast2D
## Magnet Coil: turn rate toward the nearest robot within homing_range (0 = flies straight).
@export_range(0.0, 720.0, 1.0, "suffix:°/s") var homing := 0.0
@export_range(0.0, 400.0, 1.0, "suffix:px") var homing_range := 160.0
## Volt Shotgun: robots hit are stunned this long.
@export_range(0.0, 2.0, 0.05, "suffix:s") var stun_time := 0.0
## Firecracker: copied at the hit point whenever the bullet hits something.
@export var blast_scene: PackedScene
## Junk Cannon: hits of at least knockback_min_damage shove the robot this far.
@export_range(0.0, 64.0, 1.0, "suffix:px") var knockback := 0.0
@export_range(0, 999) var knockback_min_damage := 15
## Cryo Sprayer: chill added to each robot hit; at 1 the robot freezes (a stun) for freeze_time.
@export_range(0.0, 1.0, 0.01) var chill := 0.0
@export_range(0.0, 5.0, 0.1, "suffix:s") var freeze_time := 1.5
## Rail Spike: passes through cover (damaging it) and enemy shields; only walls stop it.
@export var pierce_cover := false
## Arc Caster: after a hit, lightning jumps to this many more robots within chain_range.
@export_range(0, 6) var chain_count := 0
@export_range(0.0, 200.0, 1.0, "suffix:px") var chain_range := 72.0
## The lightning effect copied between chained robots (it reads its two points from set_points).
@export var arc_scene: PackedScene

var pool: BulletPool
var active := false
var direction := Vector2.RIGHT
var hit_damage := 0
var _age := 0.0
var _hits_left := 1
var _hit_ids: Array[int] = []
var _bounces_left := 0
var _homing_target: Node2D
var _retarget := 0.0


func launch(at: Vector2, travel_direction: Vector2, damage_override := -1) -> void:
	global_position = at
	direction = travel_direction.normalized()
	rotation = direction.angle()
	hit_damage = damage if damage_override < 0 else damage_override
	_age = 0.0
	_hits_left = pierce + 1
	_hit_ids.clear()
	_bounces_left = bounces
	_homing_target = null
	_retarget = 0.0
	active = true
	visible = true
	set_physics_process(true)


## Called by whatever the bullet hits. False if this target was already hit by this bullet.
## Uses up one hit; the bullet despawns when it has none left.
func try_hit(target: Object) -> bool:
	if not active:
		return false
	var id := target.get_instance_id()
	if _hit_ids.has(id):
		return false
	_hit_ids.append(id)
	_hits_left -= 1
	_pop()
	if chain_count > 0 and target is Node2D:
		_chain(target as Node2D)
	if _hits_left <= 0:
		despawn()
	return true


func despawn() -> void:
	if not active:
		return
	deactivate()
	if pool != null:
		pool.release(self)


func deactivate() -> void:
	active = false
	visible = false
	set_physics_process(false)
	_park.call_deferred()


## Back to the pool node's position, unless the bullet was relaunched in the meantime.
func _park() -> void:
	if not active:
		position = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if homing > 0.0:
		_steer(delta)
	if Player.highlight_aimed and pool != null and pool.hostile:
		var to_hero := Player.hero_position - global_position
		var aimed := to_hero.length() < 220.0 and direction.dot(to_hero.normalized()) > 0.97
		self_modulate = Color(1, 0.35, 0.35) if aimed else Color.WHITE
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		despawn()


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	var cover := body as Cover
	if pierce_cover and not _is_wall(body):
		if cover != null:
			cover.take_damage(cover_damage)
		return
	if cover != null:
		cover.take_damage(cover_damage)
	elif _bounces_left > 0 and wall_probe != null:
		wall_probe.force_raycast_update()
		if wall_probe.is_colliding():
			_bounces_left -= 1
			direction = direction.bounce(wall_probe.get_collision_normal()).normalized()
			rotation = direction.angle()
			return
	_pop()
	despawn()


## Wall tiles and other world-layer bodies (a locked door's blocker).
func _is_wall(body: Node2D) -> bool:
	var solid := body as CollisionObject2D
	return body is TileMapLayer or (solid != null and (solid.collision_layer & 1) != 0)


## Turns toward the nearest robot in range (re-picked a few times a second).
func _steer(delta: float) -> void:
	_retarget -= delta
	if _retarget <= 0.0 or not is_instance_valid(_homing_target):
		_retarget = 0.15
		_homing_target = null
		var best := homing_range
		for node: Node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy := node as Node2D
			if enemy != null and enemy.is_visible_in_tree():
				var distance := enemy.global_position.distance_to(global_position)
				if distance < best:
					best = distance
					_homing_target = enemy
	if _homing_target != null:
		var angle := rotate_toward(direction.angle(), (_homing_target.global_position - global_position).angle(),
			deg_to_rad(homing) * delta)
		direction = Vector2.from_angle(angle)
		rotation = angle


## Arc Caster: damages up to chain_count more robots near `from`, one after another.
func _chain(from: Node2D) -> void:
	var hit: Array[Node] = [from]
	var at := from
	for _i: int in chain_count:
		var next: Enemy = null
		var best := chain_range
		for node: Node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy := node as Enemy
			if enemy == null or hit.has(enemy) or not enemy.is_targetable():
				continue
			var distance := enemy.global_position.distance_to(at.global_position)
			if distance < best:
				best = distance
				next = enemy
		if next == null:
			return
		hit.append(next)
		_draw_arc(at.global_position, next.global_position)
		next.take_damage(hit_damage)
		at = next


func _draw_arc(from: Vector2, to: Vector2) -> void:
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if arc_scene == null or layer == null:
		return
	var arc := arc_scene.instantiate() as ArcFx
	layer.add_child.call_deferred(arc)
	arc.set_points.call_deferred(layer.to_local(from), layer.to_local(to))


func _pop() -> void:
	if blast_scene == null:
		return
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if layer == null:
		return
	var blast := blast_scene.instantiate() as Node2D
	blast.position = layer.to_local(global_position)
	layer.add_child.call_deferred(blast)


func _on_screen_notifier_screen_exited() -> void:
	despawn()
