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

var pool: BulletPool
var active := false
var direction := Vector2.RIGHT
var hit_damage := 0
var _age := 0.0
var _hits_left := 1
var _hit_ids: Array[int] = []


func launch(at: Vector2, travel_direction: Vector2, damage_override := -1) -> void:
	global_position = at
	direction = travel_direction.normalized()
	rotation = direction.angle()
	hit_damage = damage if damage_override < 0 else damage_override
	_age = 0.0
	_hits_left = pierce + 1
	_hit_ids.clear()
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
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		despawn()


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	var cover := body as Cover
	if cover != null:
		cover.take_damage(cover_damage)
	despawn()


func _on_screen_notifier_screen_exited() -> void:
	despawn()
